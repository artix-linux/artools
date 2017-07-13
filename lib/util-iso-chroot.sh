#!/bin/bash
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

add_svc_rc(){
    local mnt="$1" name="$2"
    if [[ -f $mnt/etc/init.d/$name ]];then
        msg2 "Setting %s ..." "$name"
        chroot $mnt rc-update add $name default &>/dev/null
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

configure_lsb(){
    local conf=$1/etc/lsb-release
    if [[ -e $conf ]] ; then
        msg2 "Configuring lsb-release"
        sed -i -e "s/^.*DISTRIB_RELEASE.*/DISTRIB_RELEASE=${dist_release}/" $conf
#         sed -i -e "s/^.*DISTRIB_CODENAME.*/DISTRIB_CODENAME=${dist_codename}/" $conf
    fi
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
            for svc in ${enable_openrc[@]}; do
                [[ $svc == "xdm" ]] && set_xdm "$mnt"
                add_svc_rc "$mnt" "$svc"
            done
            for svc in ${enable_live[@]}; do
                add_svc_rc "$mnt" "$svc"
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
    file=$mnt/boot/grub/grub.cfg
    if [[ -f "$file" ]]; then
        rm $file
    fi
}

chroot_clean(){
    local dest="$1"
    for root in "$dest"/*; do
        [[ -d ${root} ]] || continue
        local name=${root##*/}
        delete_chroot "${root}" "$dest"
    done
    rm -rf --one-file-system "$dest"
}

