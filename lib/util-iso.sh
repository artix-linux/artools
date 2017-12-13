#!/bin/bash
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

import ${LIBDIR}/util-chroot.sh
import ${LIBDIR}/util-iso-grub.sh
import ${LIBDIR}/util-iso-yaml.sh
import ${LIBDIR}/util-iso-profile.sh

track_img() {
    info "mount: [%s]" "$2"
    mount "$@" && IMG_ACTIVE_MOUNTS=("$2" "${IMG_ACTIVE_MOUNTS[@]}")
}

mount_img() {
    IMG_ACTIVE_MOUNTS=()
    mkdir -p "$2"
    track_img "$1" "$2"
}

umount_img() {
    if [[ -n ${IMG_ACTIVE_MOUNTS[@]} ]];then
        info "umount: [%s]" "${IMG_ACTIVE_MOUNTS[@]}"
        umount "${IMG_ACTIVE_MOUNTS[@]}"
        unset IMG_ACTIVE_MOUNTS
        rm -r "$1"
    fi
}

track_fs() {
    info "overlayfs mount: [%s]" "$5"
    mount "$@" && FS_ACTIVE_MOUNTS=("$5" "${FS_ACTIVE_MOUNTS[@]}")
}

mount_overlay(){
    FS_ACTIVE_MOUNTS=()
    local lower= upper="$1" work="$2" pkglist="$3"
    local fs=${upper##*/}
    local rootfs="$work/rootfs" desktopfs="$work/desktopfs" livefs="$work/livefs"
    mkdir -p "${mnt_dir}/work"
    mkdir -p "$upper"
    case $fs in
        desktopfs) lower="$rootfs" ;;
        livefs)
            lower="$rootfs"
            [[ -f $pkglist ]] && lower="$desktopfs":"$rootfs"
        ;;
        bootfs)
            lower="$livefs":"$rootfs"
            [[ -f $pkglist ]] && lower="$livefs":"$desktopfs":"$rootfs"
        ;;
    esac
    track_fs -t overlay overlay -olowerdir="$lower",upperdir="$upper",workdir="${mnt_dir}/work" "$upper"
}

umount_overlay(){
    if [[ -n ${FS_ACTIVE_MOUNTS[@]} ]];then
        info "overlayfs umount: [%s]" "${FS_ACTIVE_MOUNTS[@]}"
        umount "${FS_ACTIVE_MOUNTS[@]}"
        unset FS_ACTIVE_MOUNTS
        rm -rf "${mnt_dir}/work"
    fi
}

error_function() {
    if [[ -p $logpipe ]]; then
        rm "$logpipe"
    fi
    local func="$1"
    # first exit all subshells, then print the error
    if (( ! BASH_SUBSHELL )); then
        error "A failure occurred in %s()." "$func"
        plain "Aborting..."
    fi
    umount_overlay
    umount_img
    exit 2
}

# $1: function
run_log(){
    local func="$1" log_dir='/var/log/artools'
    local logfile=${log_dir}/$(gen_iso_fn).$func.log
    logpipe=$(mktemp -u "/tmp/$func.pipe.XXXXXXXX")
    mkfifo "$logpipe"
    tee "$logfile" < "$logpipe" &
    local teepid=$!
    $func &> "$logpipe"
    wait $teepid
    rm "$logpipe"
}

run_safe() {
    local restoretrap func="$1"
    set -e
    set -E
    restoretrap=$(trap -p ERR)
    trap 'error_function $func' ERR

    if ${verbose};then
        run_log "$func"
    else
        "$func"
    fi

    eval $restoretrap
    set +E
    set +e
}

trap_exit() {
    local sig=$1; shift
    error "$@"
    umount_overlay
    trap -- "$sig"
    kill "-$sig" "$$"
}

prepare_traps(){
    for sig in TERM HUP QUIT; do
        trap "trap_exit $sig \"$(gettext "%s signal caught. Exiting...")\" \"$sig\"" "$sig"
    done
    trap 'trap_exit INT "$(gettext "Aborted by user! Exiting...")"' INT
#     trap 'trap_exit USR1 "$(gettext "An unknown error has occurred. Exiting...")"' ERR
}

add_svc_rc(){
    local mnt="$1" name="$2" rlvl="$3"
    if [[ -f $mnt/etc/init.d/$name ]];then
        msg2 "Setting %s ..." "$name"
        chroot $mnt rc-update add $name $rlvl &>/dev/null
    fi
}

set_xdm(){
    if [[ -f $1/etc/conf.d/xdm ]];then
        local conf='DISPLAYMANAGER="'${displaymanager}'"'
        sed -i -e "s|^.*DISPLAYMANAGER=.*|${conf}|" $1/etc/conf.d/xdm
    fi
}

configure_hosts(){
    sed -e "s|localhost.localdomain|localhost.localdomain ${hostname}|" -i $1/etc/hosts
}

configure_logind(){
    local conf=$1/etc/$2/logind.conf
    if [[ -e $conf ]];then
        msg2 "Configuring logind ..."
        sed -i 's/#\(HandleSuspendKey=\)suspend/\1ignore/' "$conf"
        sed -i 's/#\(HandleLidSwitch=\)suspend/\1ignore/' "$conf"
        sed -i 's/#\(HandleHibernateKey=\)hibernate/\1ignore/' "$conf"
    fi
}

configure_services(){
    local mnt="$1"
    info "Configuring [%s]" "${initsys}"
    case ${initsys} in
        'openrc')
            for svc in ${openrc_boot[@]}; do
                add_svc_rc "$mnt" "$svc" "boot"
            done
            for svc in ${openrc_default[@]}; do
                [[ $svc == "xdm" ]] && set_xdm "$mnt"
                add_svc_rc "$mnt" "$svc" "default"
            done
            for svc in ${enable_live[@]}; do
                add_svc_rc "$mnt" "$svc" "default"
            done
        ;;
    esac
    info "Done configuring [%s]" "${initsys}"
}

configure_system(){
    local mnt="$1"
    case ${initsys} in
        'openrc')
            configure_logind "$mnt" "elogind"
        ;;
    esac
    echo ${hostname} > $mnt/etc/hostname
}

clean_iso_root(){
    local dest="$1"
    msg "Deleting isoroot [%s] ..." "${dest##*/}"
    rm -rf --one-file-system "$dest"
}

clean_up_image(){
    local path mnt="$1"
    msg2 "Cleaning [%s]" "${mnt##*/}"

    default_locale "reset" "$mnt"
    path=$mnt/boot
    if [[ -d "$path" ]]; then
        find "$path" -name 'initramfs*.img' -delete &> /dev/null
    fi
    path=$mnt/var/lib/pacman/sync
    if [[ -d $path ]];then
        find "$path" -type f -delete &> /dev/null
    fi
    path=$mnt/var/cache/pacman/pkg
    if [[ -d $path ]]; then
        find "$path" -type f -delete &> /dev/null
    fi
    path=$mnt/var/log
    if [[ -d $path ]]; then
        find "$path" -type f -delete &> /dev/null
    fi
    path=$mnt/var/tmp
    if [[ -d $path ]];then
        find "$path" -mindepth 1 -delete &> /dev/null
    fi
    path=$mnt/tmp
    if [[ -d $path ]];then
        find "$path" -mindepth 1 -delete &> /dev/null
    fi

    if [[ ${mnt##*/} == 'livefs' ]];then
        rm -rf "$mnt/etc/pacman.d/gnupg"
    fi

    find "$mnt" -name *.pacnew -name *.pacsave -name *.pacorig -delete
    if [[ -f "$mnt/boot/grub/grub.cfg" ]]; then
        rm $mnt/boot/grub/grub.cfg
    fi
    if [[ -f "$mnt/etc/machine-id" ]]; then
        rm $mnt/etc/machine-id
    fi
}

configure_live_image(){
    local fs="$1"
    msg "Configuring [livefs]"
    configure_hosts "$fs"
    configure_system "$fs"
    configure_services "$fs"
    configure_calamares "$fs"
    write_live_session_conf "$fs"
    msg "Done configuring [livefs]"
}

make_sig () {
    local idir="$1" file="$2"
    msg2 "Creating signature file..."
    cd "$idir"
    user_own "$idir"
    user_run "gpg --detach-sign --default-key ${gpgkey} $file.sfs"
    chown -R root "$idir"
    cd ${OLDPWD}
}

make_checksum(){
    local idir="$1" file="$2"
    msg2 "Creating sha512sum ..."
    cd $idir
    sha512sum $file.sfs > $file.sha512
    cd ${OLDPWD}
}

# $1: image path
make_sfs() {
    local src="$1"
    if [[ ! -e "${src}" ]]; then
        error "The path %s does not exist" "${src}"
        retrun 1
    fi
    local timer=$(get_timer) dest=${iso_root}/${iso_name}/${target_arch}
    local name=${1##*/}
    local sfs="${dest}/${name}.sfs"
    mkdir -p ${dest}
    msg "Generating SquashFS image for %s" "${src}"
    if [[ -f "${sfs}" ]]; then
        local has_changed_dir=$(find ${src} -newer ${sfs})
        msg2 "Possible changes for %s ..." "${src}"  >> /tmp/buildiso.debug
        msg2 "%s" "${has_changed_dir}" >> /tmp/buildiso.debug
        if [[ -n "${has_changed_dir}" ]]; then
            msg2 "SquashFS image %s is not up to date, rebuilding..." "${sfs}"
            rm "${sfs}"
        else
            msg2 "SquashFS image %s is up to date, skipping." "${sfs}"
            return
        fi
    fi

    if ${persist};then
        local size=32G
        local mnt="${mnt_dir}/${name}"
        msg2 "Creating ext4 image of %s ..." "${size}"
        truncate -s ${size} "${src}.img"
        local ext4_args=()
        ${verbose} && ext4_args+=(-q)
        ext4_args+=(-O ^has_journal,^resize_inode -E lazy_itable_init=0 -m 0)
        mkfs.ext4 ${ext4_args[@]} -F "${src}.img" &>/dev/null
        tune2fs -c 0 -i 0 "${src}.img" &> /dev/null
        mount_img "${work_dir}/${name}.img" "${mnt}"
        msg2 "Copying %s ..." "${src}/"
        cp -aT "${src}/" "${mnt}/"
        umount_img "${mnt}"

    fi

    msg2 "Creating SquashFS image, this may take some time..."
    local mksfs_args=()
    if ${persist};then
        mksfs_args+=(${work_dir}/${name}.img)
    else
        mksfs_args+=(${src})
    fi

    mksfs_args+=(${sfs} -noappend)

    local highcomp="-b 256K -Xbcj x86" comp='xz'

    mksfs_args+=(-comp ${comp} ${highcomp})
    if ${verbose};then
        mksquashfs "${mksfs_args[@]}" >/dev/null
    else
        mksquashfs "${mksfs_args[@]}"
    fi
    make_checksum "${dest}" "${name}"
    ${persist} && rm "${src}.img"

    if [[ -n ${gpgkey} ]];then
        make_sig "${dest}" "${name}"
    fi

    show_elapsed_time "${FUNCNAME}" "${timer_start}"
}

assemble_iso(){
    msg "Creating ISO image..."
    local mod_date=$(date -u +%Y-%m-%d-%H-%M-%S-00  | sed -e s/-//g)

    xorriso -as mkisofs \
        --modification-date=${mod_date} \
        --protective-msdos-label \
        -volid "${iso_label}" \
        -appid "$(get_osname) Live/Rescue CD" \
        -publisher "$(get_osname) <$(get_disturl)>" \
        -preparer "Prepared by artools/${0##*/}" \
        -r -graft-points -no-pad \
        --sort-weight 0 / \
        --sort-weight 1 /boot \
        --grub2-mbr ${iso_root}/boot/grub/i386-pc/boot_hybrid.img \
        -partition_offset 16 \
        -b boot/grub/i386-pc/eltorito.img \
        -c boot.catalog \
        -no-emul-boot -boot-load-size 4 -boot-info-table --grub2-boot-info \
        -eltorito-alt-boot \
        -append_partition 2 0xef ${iso_root}/efi.img \
        -e --interval:appended_partition_2:all:: -iso_mbr_part_type 0x00 \
        -no-emul-boot \
        -iso-level 3 \
        -o ${iso_dir}/${iso_file} \
        ${iso_root}/
}

# Build ISO
make_iso() {
    msg "Start [Build ISO]"
    touch "${iso_root}/.artix"
    for sfs_dir in $(find "${work_dir}" -maxdepth 1 -type d); do
        if [[ "${sfs_dir}" != "${work_dir}" ]]; then
            make_sfs "${sfs_dir}"
        fi
    done

    msg "Making bootable image"
    # Sanity checks
    [[ ! -d "${iso_root}" ]] && return 1
    if [[ -f "${iso_dir}/${iso_file}" ]]; then
        msg2 "Removing existing bootable image..."
        rm -rf "${iso_dir}/${iso_file}"
    fi
    assemble_iso
    msg "Done [Build ISO]"
}

gen_iso_fn(){
    local vars=() name
    vars+=("${iso_name}")
    vars+=("${profile}")
    vars+=("${iso_version}")
    vars+=("${target_arch}")
    for n in ${vars[@]};do
        name=${name:-}${name:+-}${n}
    done
    echo $name
}

install_packages(){
    local fs="$1"
    setarch "${target_arch}" mkchroot \
        "${mkchroot_args[@]}" "${fs}" "${packages[@]}"
}

copy_overlay(){
    local src="$1" dest="$2"
    if [[ -e "$src" ]];then
        msg2 "Copying [%s] ..." "${src##*/}"
        cp -LR "$src"/* "$dest"
    fi
}

make_rootfs() {
    if [[ ! -e ${work_dir}/rootfs.lock ]]; then
        msg "Prepare [Base installation] (rootfs)"
        local rootfs="${work_dir}/rootfs"

        prepare_dir "${rootfs}"

        install_packages "${rootfs}"

        copy_overlay "${root_overlay}" "${rootfs}"

        clean_up_image "${rootfs}"

        msg "Done [Base installation] (rootfs)"
    fi
}

make_desktopfs() {
    if [[ ! -e ${work_dir}/desktopfs.lock ]]; then
        msg "Prepare [Desktop installation] (desktopfs)"
        local desktopfs="${work_dir}/desktopfs"

        prepare_dir "${desktopfs}"

        mount_overlay "${desktopfs}" "${work_dir}"

        install_packages "${desktopfs}"

        copy_overlay "${desktop_overlay}" "${desktopfs}"

        umount_overlay
        clean_up_image "${desktopfs}"

        msg "Done [Desktop installation] (desktopfs)"
    fi
}

make_livefs() {
    if [[ ! -e ${work_dir}/livefs.lock ]]; then
        msg "Prepare [Live installation] (livefs)"
        local livefs="${work_dir}/livefs"

        prepare_dir "${livefs}"

        mount_overlay "${livefs}" "${work_dir}" "${desktop_list}"

        install_packages "${livefs}"

        copy_overlay "${live_overlay}" "${livefs}"

        configure_live_image "${livefs}"

        pacman -Qr "${livefs}" > ${iso_dir}/$(gen_iso_fn)-pkgs.txt

        umount_overlay

        clean_up_image "${livefs}"

        msg "Done [Live installation] (livefs)"
    fi
}

make_bootfs() {
    if [[ ! -e ${work_dir}/bootfs.lock ]]; then
        msg "Prepare [/iso/boot]"
        local boot="${iso_root}/boot"

        prepare_dir "${boot}"

        cp ${work_dir}/rootfs/boot/vmlinuz* ${boot}/vmlinuz-${target_arch}

        local bootfs="${work_dir}/bootfs"

        mount_overlay "${bootfs}" "${work_dir}" "${desktop_list}"

        prepare_initcpio "${bootfs}"
        prepare_initramfs "${bootfs}"

        cp ${bootfs}/boot/initramfs.img ${boot}/initramfs-${target_arch}.img
        prepare_boot_extras "${bootfs}" "${boot}"

        umount_overlay

        rm -R ${bootfs}
        : > ${work_dir}/bootfs.lock
        msg "Done [/iso/boot]"
    fi
}

make_grub(){
    if [[ ! -e ${work_dir}/grub.lock ]]; then
        msg "Prepare [/iso/boot/grub]"

        prepare_grub "${work_dir}/rootfs" "${work_dir}/livefs" "${iso_root}"

        configure_grub "${iso_root}/boot/grub/kernels.cfg"

        : > ${work_dir}/grub.lock
        msg "Done [/iso/boot/grub]"
    fi
}

compress_images(){
    local timer=$(get_timer)
    run_safe "make_iso"
    user_own "${iso_dir}" "-R"
    show_elapsed_time "${FUNCNAME}" "${timer}"
}

prepare_images(){
    local timer=$(get_timer)
    load_pkgs "${root_list}" "${target_arch}" "${initsys}" "${kernel}"
    run_safe "make_rootfs"
    if [[ -f "${desktop_list}" ]] ; then
        load_pkgs "${desktop_list}" "${target_arch}" "${initsys}" "${kernel}"
        run_safe "make_desktopfs"
    fi
    if [[ -f ${live_list} ]]; then
        load_pkgs "${live_list}" "${target_arch}" "${initsys}" "${kernel}"
        run_safe "make_livefs"
    fi
    run_safe "make_bootfs"
    run_safe "make_grub"

    show_elapsed_time "${FUNCNAME}" "${timer}"
}
