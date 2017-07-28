#!/bin/bash
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

write_repo_conf(){
    local repos=$(find $USER_HOME -type f -name "repo_info")
    local path name
    [[ -z ${repos[@]} ]] && run_dir=${DATADIR}/iso-profiles && return 1
    for r in ${repos[@]}; do
        path=${r%/repo_info}
        name=${path##*/}
        echo "run_dir=$path" > ${AT_USERCONFDIR}/$name.conf
    done
}

load_run_dir(){
    local gitrepo='iso-profiles'
    [[ -f ${AT_USERCONFDIR}/$gitrepo.conf ]] || write_repo_conf
    [[ -r ${AT_USERCONFDIR}/$gitrepo.conf ]] && source ${AT_USERCONFDIR}/$gitrepo.conf
    return 0
}

load_profile(){
    local profdir="$1"
    local profile_conf="$profdir/profile.conf"

    [[ -f ${profile_conf} ]] || return 1

    [[ -r ${profile_conf} ]] && source ${profile_conf}

    [[ -z ${displaymanager} ]] && displaymanager="none"

    [[ -z ${autologin} ]] && autologin="true"
    [[ ${displaymanager} == 'none' ]] && autologin="false"

    [[ -z ${multilib} ]] && multilib="true"

    [[ -z ${hostname} ]] && hostname="artix"

    [[ -z ${username} ]] && username="artix"

    [[ -z ${password} ]] && password="artix"

    if [[ -z ${addgroups} ]];then
        addgroups="video,power,storage,optical,network,lp,scanner,wheel,users"
    fi

    if [[ -z ${openrc_boot[@]} ]];then
        openrc_boot=('elogind')
    fi

    if [[ -z ${openrc_default[@]} ]];then
        openrc_default=('acpid' 'bluetooth' 'cronie' 'cupsd' 'dbus' 'syslog-ng' 'NetworkManager')
    fi

    [[ ${displaymanager} != "none" ]] && openrc_default+=('xdm')

    enable_live=('artix-live' 'pacman-init')

    netgroups="https://raw.githubusercontent.com/artix-linux/iso-profiles/master/base/netgroups"

    basic='true'
    [[ -z ${extra} ]] && extra='false'

    ${extra} && basic='false'

    root_list=${run_dir}/base/Packages-Root
    [[ -f "$profdir/Packages-Root" ]] && root_list="$profdir/Packages-Root"

    root_overlay="${run_dir}/base/root-overlay"
    [[ -d "$profdir/root-overlay" ]] && root_overlay="$profdir/root-overlay"

    [[ -f "$profdir/Packages-Desktop" ]] && desktop_list=$profdir/Packages-Desktop
    [[ -d "$profdir/desktop-overlay" ]] && desktop_overlay="$profdir/desktop-overlay"

    live_list="${run_dir}/base/Packages-Live"
    [[ -f "$profdir/Packages-Live" ]] && live_list="$profdir/Packages-Live"

    live_overlay="${run_dir}/base/live-overlay"
    [[ -d "$profdir/live-overlay" ]] && live_overlay="$profdir/live-overlay"

    return 0
}

reset_profile(){
    unset displaymanager
    unset autologin
    unset multilib
    unset hostname
    unset username
    unset password
    unset addgroups
    unset openrc_boot
    unset openrc_default
    unset enable_live
    unset extra
    unset root_list
    unset desktop_list
    unset live_list
    unset root_overlay
    unset desktop_overlay
    unset live_overlay
}

write_live_session_conf(){
    local path=$1${SYSCONFDIR}
    [[ ! -d $path ]] && mkdir -p "$path"
    local conf=$path/live.conf
    msg2 "Writing %s" "${conf##*/}"
    echo '# live session configuration' > ${conf}
    echo '' >> ${conf}
    echo '# autologin' >> ${conf}
    echo "autologin=${autologin}" >> ${conf}
    echo '' >> ${conf}
    echo '# live username' >> ${conf}
    echo "username=${username}" >> ${conf}
    echo '' >> ${conf}
    echo '# live password' >> ${conf}
    echo "password=${password}" >> ${conf}
    echo '' >> ${conf}
    echo '# live group membership' >> ${conf}
    echo "addgroups='${addgroups}'" >> ${conf}
}

# $1: file name
load_pkgs(){
    local pkglist="$1" arch="$2" init="$3" _kv="$4"
    info "Loading Packages: [%s] ..." "${pkglist##*/}"

    local _init="s|>openrc||g" #_init_rm="s|>runit.*||g"

    local _basic="s|>basic.*||g"
    ${basic} && _basic="s|>basic||g"

    local _extra="s|>extra.*||g"
    ${extra} && _extra="s|>extra||g"

    local _multi _arch _arch_rm

    if [[ "$arch" == 'i686' ]];then
        _arch="s|>i686||g"
        _arch_rm="s|>x86_64.*||g"
        _multi="s|>multilib.*||g"
    else
        _arch="s|>x86_64||g"
        _arch_rm="s|>i686.*||g"
        _multi="s|>multilib.*||g"
        ${multilib} && _multi="s|>multilib||g"
    fi

    local _blacklist="s|>blacklist.*||g" \
        _kernel="s|KERNEL|$_kv|g" \
        _space="s| ||g" \
        _clean=':a;N;$!ba;s/\n/ /g' \
        _com_rm="s|#.*||g"

    packages=($(sed "$_com_rm" "$pkglist" \
            | sed "$_space" \
            | sed "$_blacklist" \
            | sed "$_purge" \
            | sed "$_init" \
            | sed "$_arch" \
            | sed "$_arch_rm" \
            | sed "$_multi" \
            | sed "$_kernel" \
            | sed "$_basic" \
            | sed "$_extra" \
            | sed "$_clean"))
}
