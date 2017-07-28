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
import ${LIBDIR}/util-iso-chroot.sh
import ${LIBDIR}/util-iso-grub.sh
import ${LIBDIR}/util-yaml.sh
import ${LIBDIR}/util-iso-mount.sh
import ${LIBDIR}/util-profile.sh

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
    umount_fs
    umount_img
    exit 2
}

# $1: function
run_log(){
    local func="$1"
    local logfile=${log_dir}/$(gen_iso_fn).$func.log
#     local tmpfile=${tmp_dir}/$func.ansi.log
    logpipe=$(mktemp -u "${tmp_dir}/$func.pipe.XXXXXXXX")
    mkfifo "$logpipe"
    tee "$logfile" < "$logpipe" &
    local teepid=$!
    $func &> "$logpipe"
    wait $teepid
    rm "$logpipe"
#     cat $tmpfile | perl -pe 's/\e\[?.*?[\@-~]//g' > $logfile
#     rm "$tmpfile"
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
    umount_fs
    trap -- "$sig"
    kill "-$sig" "$$"
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
    msg2 "Creating md5sum ..."
    cd $idir
    md5sum $file.sfs > $file.md5
    cd ${OLDPWD}
}

# $1: image path
make_sfs() {
    local src="$1"
    if [[ ! -e "${src}" ]]; then
        error "The path %s does not exist" "${src}"
        retrun 1
    fi
    local timer=$(get_timer) dest=${iso_root}/${os_id}/${target_arch}
    local name=${1##*/}
    local sfs="${dest}/${name}.sfs"
    mkdir -p ${dest}
    msg "Generating SquashFS image for %s" "${src}"
    if [[ -f "${sfs}" ]]; then
        local has_changed_dir=$(find ${src} -newer ${sfs})
        msg2 "Possible changes for %s ..." "${src}"  >> ${tmp_dir}/buildiso.debug
        msg2 "%s" "${has_changed_dir}" >> ${tmp_dir}/buildiso.debug
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
        -volid "${dist_branding}" \
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
        -e --interval:appended_partition_2:all:: \
        -no-emul-boot \
        -iso-level 3 \
        -o ${iso_dir}/${iso_file} \
        ${iso_root}/

#         arg to add with xorriso-1.4.7
#         -iso_mbr_part_type 0x00
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
    vars+=("${os_id}")
#     vars+=("${profile}")
    vars+=("${dist_release}")
    vars+=("${target_arch}")
    for n in ${vars[@]};do
        name=${name:-}${name:+-}${n}
    done
    echo $name
}

copy_overlay(){
    local src="$1" dest="$2"
    if [[ -e "$src" ]];then
        msg2 "Copying [%s] ..." "${src##*/}"
        cp -LR "$src"/* "$dest"
    fi
}

# Base installation (rootfs)
make_image_root() {
    if [[ ! -e ${work_dir}/rootfs.lock ]]; then
        msg "Prepare [Base installation] (rootfs)"
        local rootfs="${work_dir}/rootfs"

        prepare_dir "${rootfs}"

        create_chroot "${mkchroot_args[@]}" "${rootfs}" "${packages[@]}"

        copy_overlay "${root_overlay}" "${rootfs}"

        configure_lsb "${rootfs}"

        clean_up_image "${rootfs}"

        msg "Done [Base installation] (rootfs)"
    fi
}

make_image_desktop() {
    if [[ ! -e ${work_dir}/desktopfs.lock ]]; then
        msg "Prepare [Desktop installation] (desktopfs)"
        local desktopfs="${work_dir}/desktopfs"

        prepare_dir "${desktopfs}"

        mount_fs "${desktopfs}" "${work_dir}"

        create_chroot "${mkchroot_args[@]}" "${desktopfs}" "${packages[@]}"

        copy_overlay "${desktop_overlay}" "${desktopfs}"

        umount_fs
        clean_up_image "${desktopfs}"

        msg "Done [Desktop installation] (desktopfs)"
    fi
}

make_image_live() {
    if [[ ! -e ${work_dir}/livefs.lock ]]; then
        msg "Prepare [Live installation] (livefs)"
        local livefs="${work_dir}/livefs"

        prepare_dir "${livefs}"

        mount_fs "${livefs}" "${work_dir}" "${desktop_list}"

        create_chroot "${mkchroot_args[@]}" "${livefs}" "${packages[@]}"

        copy_overlay "${live_overlay}" "${livefs}"

        configure_live_image "${livefs}"

        pacman -Qr "${livefs}" > ${iso_dir}/$(gen_iso_fn)-pkgs.txt

        umount_fs

        clean_up_image "${livefs}"

        msg "Done [Live installation] (livefs)"
    fi
}

make_image_boot() {
    if [[ ! -e ${work_dir}/bootfs.lock ]]; then
        msg "Prepare [/iso/boot]"
        local boot="${iso_root}/boot"

        prepare_dir "${boot}"

        cp ${work_dir}/rootfs/boot/vmlinuz* ${boot}/vmlinuz-${target_arch}

        local bootfs="${work_dir}/bootfs"

        mount_fs "${bootfs}" "${work_dir}" "${desktop_list}"

        prepare_initcpio "${bootfs}"
        prepare_initramfs "${bootfs}"

        cp ${bootfs}/boot/initramfs.img ${boot}/initramfs-${target_arch}.img
        prepare_boot_extras "${bootfs}" "${boot}"

        umount_fs

        rm -R ${bootfs}
        : > ${work_dir}/bootfs.lock
        msg "Done [/iso/boot]"
    fi
}

configure_grub(){
    local conf="$1"
    local default_args="artixbasedir=${os_id} artixlabel=${dist_branding}" boot_args=('quiet')

    sed -e "s|@DIST_NAME@|${dist_name}|g" \
        -e "s|@ARCH@|${target_arch}|g" \
        -e "s|@DEFAULT_ARGS@|${default_args}|g" \
        -e "s|@BOOT_ARGS@|${boot_args[*]}|g" \
        -e "s|@PROFILE@|${profile}|g" \
        -i $conf
}

configure_grub_theme(){
    local conf="$1"
    sed -e "s|@DIST@|${os_id}|" -i "$conf"
}

make_grub(){
    if [[ ! -e ${work_dir}/grub.lock ]]; then
        msg "Prepare [/iso/boot/grub]"

        prepare_grub "${work_dir}/rootfs" "${work_dir}/livefs" "${iso_root}"

        configure_grub "${iso_root}/boot/grub/kernels.cfg"
        configure_grub_theme "${iso_root}/boot/grub/variable.cfg"

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
    run_safe "make_image_root"
    if [[ -f "${desktop_list}" ]] ; then
        load_pkgs "${desktop_list}" "${target_arch}" "${initsys}" "${kernel}"
        run_safe "make_image_desktop"
    fi
    if [[ -f ${live_list} ]]; then
        load_pkgs "${live_list}" "${target_arch}" "${initsys}" "${kernel}"
        run_safe "make_image_live"
    fi
    run_safe "make_image_boot"
    run_safe "make_grub"

    show_elapsed_time "${FUNCNAME}" "${timer}"
}

check_requirements(){
    [[ -f ${run_dir}/repo_info ]] || die "%s is not a valid iso profiles directory!" "${run_dir}"

    for sig in TERM HUP QUIT; do
        trap "trap_exit $sig \"$(gettext "%s signal caught. Exiting...")\" \"$sig\"" "$sig"
    done
    trap 'trap_exit INT "$(gettext "Aborted by user! Exiting...")"' INT
    trap 'trap_exit USR1 "$(gettext "An unknown error has occurred. Exiting...")"' ERR
}

prepare_build(){
    timer_start=$(get_timer)
    local profile_dir=${run_dir}/${profile}

    load_profile "${profile_dir}"

    local pac_arch='default' pacman_conf
    [[ "${target_arch}" == 'x86_64' ]] && pac_arch='multilib'

    pacman_conf="${DATADIR}/pacman-$pac_arch.conf"

    iso_file=$(gen_iso_fn).iso

    mkchroot_args+=(-C ${pacman_conf})
    work_dir=${chroots_iso}/${profile}/${target_arch}

    iso_dir="${cache_dir_iso}/${profile}"

    iso_root=${chroots_iso}/${profile}/iso
    mnt_dir=${chroots_iso}/${profile}/mnt
    prepare_dir "${mnt_dir}"
    prepare_dir "${iso_dir}"
}

build(){
    prepare_build
    msg "Start building [%s]" "${profile}"
    if ${clean_first};then
        chroot_clean "${chroots_iso}/${profile}/${target_arch}"

        local unused_arch='i686'
        if [[ ${target_arch} == 'i686' ]];then
            unused_arch='x86_64'
        fi
        if [[ -d "${chroots_iso}/${profile}/${unused_arch}" ]];then
            chroot_clean "${chroots_iso}/${profile}/${unused_arch}"
        fi
        clean_iso_root "${iso_root}"
    fi

    if ${iso_only}; then
        [[ ! -d ${work_dir} ]] && die "Create images: buildiso -p %s -x" "${profile}"
        compress_images
        exit 1
    fi
    if ${images_only}; then
        prepare_images
        warning "Continue compress: buildiso -p %s -zc ..." "${profile}"
        exit 1
    else
        prepare_images
        compress_images
    fi
    reset_profile
    msg "Finished building [%s]" "${profile}"
    show_elapsed_time "${FUNCNAME}" "${timer_start}"
}
