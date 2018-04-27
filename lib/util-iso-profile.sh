#!/bin/bash
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

init_profile(){
    local profdir="$1" base="${DATADIR}/iso-profiles/base"

    root_list="$base/Packages-Root"
    root_overlay="$base/root-overlay"
    live_list="$base/Packages-Live"
    live_overlay="$base/live-overlay"

    [[ -f "$profdir/Packages-Root" ]] && root_list="$profdir/Packages-Root"
    [[ -d "$profdir/root-overlay" ]] && root_overlay="$profdir/root-overlay"

    [[ -f "$profdir/Packages-Desktop" ]] && desktop_list="$profdir/Packages-Desktop"
    [[ -d "$profdir/desktop-overlay" ]] && desktop_overlay="$profdir/desktop-overlay"

    [[ -f "$profdir/Packages-Live" ]] && live_list="$profdir/Packages-Live"
    [[ -d "$profdir/live-overlay" ]] && live_overlay="$profdir/live-overlay"
}

load_profile(){
    local prof="$1"
    local profdir="${DATADIR}/iso-profiles/$prof"
    [[ -d ${workspace_dir}/iso-profiles/$prof ]] && profdir=${workspace_dir}/iso-profiles/$prof

    init_profile "$profdir"

    [[ -f $profdir/profile.conf ]] || return 1

    [[ -r $profdir/profile.conf ]] && source $profdir/profile.conf

    [[ -z ${displaymanager} ]] && displaymanager="none"

    [[ -z ${autologin} ]] && autologin="true"
    [[ ${displaymanager} == 'none' ]] && autologin="false"

    [[ -z ${hostname} ]] && hostname="artix"

    [[ -z ${username} ]] && username="artix"

    [[ -z ${password} ]] && password="artix"

    if [[ -z ${addgroups} ]];then
        addgroups="video,power,storage,optical,network,lp,scanner,wheel,users,log"
    fi

    if [[ -z ${services[@]} ]];then
        services=('acpid' 'bluetooth' 'cronie' 'cupsd' 'syslog-ng' 'NetworkManager')
    fi

    if [[ ${displaymanager} != "none" ]];then
        case "${initsys}" in
            'openrc') services+=('xdm') ;;
            'runit') services+=("${displaymanager}") ;;
        esac
    fi

    if [[ -z ${services_live[@]} ]];then
        services_live=('artix-live' 'pacman-init')
    fi

    [[ -z ${netgroups_url} ]] && netgroups_url="https://raw.githubusercontent.com/artix-linux/netgroups/master"

    return 0
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

load_pkgs(){
    local pkglist="$1" init="$2" _kv="$3"
    info "Loading Packages: [%s] ..." "${pkglist##*/}"

    local _init="s|>$init||g"
    case "$init" in
        'openrc') _init_rm1="s|>runit.*||g"; _init_rm2="s|>s6*||g" ;;
        's6') _init_rm1="s|>runit.*||g"; _init_rm2="s|>openrc.*||g" ;;
        'runit') _init_rm1="s|>s6.*||g"; _init_rm2="s|>openrc.*||g" ;;
    esac

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
            | sed "$_init_rm1" \
            | sed "$_init_rm2" \
            | sed "$_kernel" \
            | sed "$_clean"))
}
