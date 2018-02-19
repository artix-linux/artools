#!/bin/bash
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

get_timer(){
    echo $(date +%s)
}

# $1: start timer
elapsed_time(){
    echo $(echo $1 $(get_timer) | awk '{ printf "%0.2f",($2-$1)/60 }')
}

show_elapsed_time(){
    info "Time %s: %s minutes" "$1" "$(elapsed_time $2)"
}

load_vars() {
    local var

    [[ -f $1 ]] || return 1

    for var in {SRC,SRCPKG,PKG,LOG}DEST MAKEFLAGS PACKAGER CARCH GPGKEY; do
        [[ -z ${!var:-} ]] && eval "$(grep -a "^${var}=" "$1")"
    done

    return 0
}

prepare_dir(){
    [[ ! -d $1 ]] && mkdir -p $1
}

get_disturl(){
    source /usr/lib/os-release
    echo "${HOME_URL}"
}

get_osname(){
    source /usr/lib/os-release
    echo "${NAME}"
}

get_osid(){
    source /usr/lib/os-release
    echo "${ID}"
}

init_artools_base(){

    target_arch=$(uname -m)

    [[ -z ${chroots_dir} ]] && chroots_dir='/var/lib/artools'

    [[ -z ${workspace_dir} ]] && workspace_dir=/home/${OWNER}/artools-workspace

    prepare_dir "${workspace_dir}"
}

init_artools_pkg(){

    [[ -z ${tree_dir_artix} ]] && tree_dir_artix=${workspace_dir}/artix

    [[ -z ${host_tree_artix} ]] && host_tree_artix='https://github.com/artix-linux'

    [[ -z ${tree_dir_arch} ]] && tree_dir_arch=${workspace_dir}/archlinux

    [[ -z ${host_tree_arch} ]] && host_tree_arch='git://projects.archlinux.org/svntogit'

    chroots_pkg="${chroots_dir}/buildpkg"

    [[ -z ${repos_root} ]] && repos_root="${workspace_dir}/repos"
}

init_artools_iso(){
    chroots_iso="${chroots_dir}/buildiso"

    [[ -z ${iso_pool} ]] && iso_pool="${workspace_dir}/iso"

    prepare_dir "${iso_pool}"

    profile='base'

    [[ -z ${iso_version} ]] && iso_version=$(date +%Y%m%d)

    iso_name=$(get_osid)

    iso_label="ARTIX_$(date +%Y%m)"

    [[ -z ${initsys} ]] && initsys="openrc"

    [[ -z ${kernel} ]] && kernel="linux"

    [[ -z ${kernel_args} ]] && kernel_args=""

    [[ -z ${gpgkey} ]] && gpgkey=''

    [[ -z ${uplimit} ]] && uplimit=100

    [[ -z ${tracker_url} ]] && tracker_url='udp://mirror.strits.dk:6969'

    [[ -z ${piece_size} ]] && piece_size=21

    [[ -z ${file_host} ]] && file_host="sourceforge.net"

    [[ -z ${project} ]] && project="artix-linux"

    [[ -z ${account} ]] && account="[SetUser]"

    [[ -z ${host_mirrors[@]} ]] && host_mirrors=('netcologne' 'freefr' 'netix' 'kent' '10gbps-io')

    torrent_meta="$(get_osname)"
}


load_config(){

    [[ -f $1 ]] || return 1

    artools_conf="$1"

    [[ -r ${artools_conf} ]] && source ${artools_conf}

    init_artools_base

    init_artools_pkg

    init_artools_iso

    return 0
}

user_own(){
    local flag=$2
    chown ${flag} "${OWNER}:$(id --group ${OWNER})" "$1"
}

user_run(){
    su ${OWNER} -c "$@"
}

clean_dir(){
    if [[ -d $1 ]]; then
        msg "Cleaning [%s] ..." "$1"
        rm -r $1/*
    fi
}

load_user_info(){
    OWNER=${SUDO_USER:-$USER}

    if [[ -n $SUDO_USER ]]; then
        eval "USER_HOME=~$SUDO_USER"
    else
        USER_HOME=$HOME
    fi

    AT_USERCONFDIR="${XDG_CONFIG_HOME:-$USER_HOME/.config}/artools"
    PAC_USERCONFDIR="${XDG_CONFIG_HOME:-$USER_HOME/.config}/pacman"
    prepare_dir "${AT_USERCONFDIR}"
}

show_version(){
    msg "artools"
    msg2 "version: %s" "${version}"
}

show_config(){
    if [[ -f ${AT_USERCONFDIR}/artools.conf ]]; then
        msg2 "config: %s" "~/.config/artools/artools.conf"
    else
        msg2 "config: %s" "${artools_conf}"
    fi
}

check_root() {
    (( EUID == 0 )) && return
    if type -P sudo >/dev/null; then
        exec sudo -- "${orig_argv[@]}"
    else
        exec su root -c "$(printf ' %q' "${orig_argv[@]}")"
    fi
}
