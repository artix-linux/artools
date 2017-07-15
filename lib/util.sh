#!/bin/bash
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# $1: section
parse_section() {
    local is_section=0
    while read line; do
        [[ $line =~ ^\ {0,}# ]] && continue
        [[ -z "$line" ]] && continue
        if [ $is_section == 0 ]; then
            if [[ $line =~ ^\[.*?\] ]]; then
                line=${line:1:$((${#line}-2))}
                section=${line// /}
                if [[ $section == $1 ]]; then
                    is_section=1
                    continue
                fi
                continue
            fi
        elif [[ $line =~ ^\[.*?\] && $is_section == 1 ]]; then
            break
        else
            pc_key=${line%%=*}
            pc_key=${pc_key// /}
            pc_value=${line##*=}
            pc_value=${pc_value## }
            eval "$pc_key='$pc_value'"
        fi
    done < "$2"
}

get_repos() {
    local section repos=() filter='^\ {0,}#'
    while read line; do
        [[ $line =~ "${filter}" ]] && continue
        [[ -z "$line" ]] && continue
        if [[ $line =~ ^\[.*?\] ]]; then
            line=${line:1:$((${#line}-2))}
            section=${line// /}
            case ${section} in
                "options") continue ;;
                *) repos+=("${section}") ;;
            esac
        fi
    done < "$1"
    echo ${repos[@]}
}

check_user_repos_conf(){
    local repositories=$(get_repos "$1") uri='file://'
    for repo in ${repositories[@]}; do
        msg2 "parsing repo [%s] ..." "${repo}"
        parse_section "${repo}" "$1"
        [[ ${pc_value} == $uri* ]] && die "Using local repositories is not supported!"
    done
}

# $1: list_dir
show_build_lists(){
    local list temp
    for item in $(ls $1/*.list); do
        temp=${item##*/}
        list=${list:-}${list:+|}${temp%.list}
    done
    echo $list
}

# $1: make_conf_dir
show_build_profiles(){
    local cpuarch temp
    for item in $(ls $1/*.conf); do
        temp=${item##*/}
        cpuarch=${cpuarch:-}${cpuarch:+|}${temp%.conf}
    done
    echo $cpuarch
}

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
        [[ -z ${!var} ]] && eval $(grep -a "^${var}=" "$1")
    done

    return 0
}

prepare_dir(){
    [[ ! -d $1 ]] && mkdir -p $1
}

init_common(){

    [[ -z ${target_arch} ]] && target_arch=$(uname -m)

    [[ -z ${cache_dir} ]] && cache_dir='/var/cache/artools'

    [[ -z ${chroots_dir} ]] && chroots_dir='/var/lib/artools'

    [[ -z ${build_mirror} ]] && build_mirror='https://downloads.sourceforge.net/project/artix-linux/repos'

    log_dir='/var/log/artools'

    tmp_dir='/tmp'

    host="sourceforge.net"

    [[ -z ${host_mirrors[@]} ]] && host_mirrors=('netcologne' 'freefr' 'netix' 'kent' '10gbps-io')

    [[ -z ${project} ]] && project="artix-linux"

    [[ -z ${account} ]] && account="[SetUser]"
}

init_buildtree(){

    tree_dir=${cache_dir}/pkgtree

    [[ -z ${tree_dir_artix} ]] && tree_dir_artix=${tree_dir}/artix

    [[ -z ${repo_tree_artix[@]} ]] && repo_tree_artix=('system' 'world' 'galaxy')

    [[ -z ${host_tree_artix} ]] && host_tree_artix='https://github.com/artix-linux'

    [[ -z ${tree_dir_arch} ]] && tree_dir_arch=${tree_dir}/archlinux

    [[ -z ${repo_tree_arch} ]] && repo_tree_arch=('packages' 'community')

    [[ -z ${host_tree_arch} ]] && host_tree_arch='git://projects.archlinux.org/svntogit'

    list_dir_import="${SYSCONFDIR}/import.list.d"

    [[ -d ${AT_USERCONFDIR}/import.list.d ]] && list_dir_import=${AT_USERCONFDIR}/import.list.d
}

init_buildpkg(){
    chroots_pkg="${chroots_dir}/buildpkg"

    list_dir_pkg="${SYSCONFDIR}/pkg.list.d"

    make_conf_dir="${SYSCONFDIR}/make.conf.d"

    [[ -d ${AT_USERCONFDIR}/pkg.list.d ]] && list_dir_pkg=${AT_USERCONFDIR}/pkg.list.d

    [[ -z ${build_list_pkg} ]] && build_list_pkg='default'

    cache_dir_pkg=${cache_dir}/pkg
}

get_release(){
    source /etc/lsb-release
    echo "${DISTRIB_RELEASE}"
}

get_distname(){
    source /etc/lsb-release
    echo "${DISTRIB_ID%Linux}"
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

init_buildiso(){
    chroots_iso="${chroots_dir}/buildiso"

    list_dir_iso="${SYSCONFDIR}/iso.list.d"

    [[ -d ${AT_USERCONFDIR}/iso.list.d ]] && list_dir_iso=${AT_USERCONFDIR}/iso.list.d

    [[ -z ${build_list_iso} ]] && build_list_iso='default'

    cache_dir_iso="${cache_dir}/iso"

    ##### iso settings #####

    [[ -z ${dist_release} ]] && dist_release=$(get_release)

    dist_name=$(get_distname)

    os_id=$(get_osid)

    [[ -z ${dist_branding} ]] && dist_branding="ARTIX"

    [[ -z ${initsys} ]] && initsys="openrc"

    [[ -z ${kernel} ]] && kernel="linux-lts"

    [[ -z ${gpgkey} ]] && gpgkey=''
}

init_deployiso(){

    [[ -z ${uplimit} ]] && uplimit=100

    [[ -z ${tracker_url} ]] && tracker_url='udp://mirror.strits.dk:6969'

    [[ -z ${piece_size} ]] && piece_size=21

    torrent_meta="$(get_osname)"
}

init_deploypkg(){

    repository='system'

    [[ -z ${repos_local} ]] && repos_local="${cache_dir}/repos"

    repos_remote="/${repos_local##*/}"
}

load_config(){

    [[ -f $1 ]] || return 1

    artools_conf="$1"

    [[ -r ${artools_conf} ]] && source ${artools_conf}

    init_common

    init_buildtree

    init_buildpkg

    init_buildiso

    init_deployiso

    init_deploypkg

    return 0
}

user_own(){
    local flag=$2
    chown ${flag} "${OWNER}:$(id --group ${OWNER})" "$1"
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

read_build_list(){
    local _space="s| ||g" _clean=':a;N;$!ba;s/\n/ /g' _com_rm="s|#.*||g"
    build_list=$(sed "$_com_rm" "$1.list" | sed "$_space" | sed "$_clean")
}

# $1: list_dir
# $2: build list
eval_build_list(){
    eval "case $2 in
        $(show_build_lists $1)) is_build_list=true; read_build_list $1/$2 ;;
        *) is_build_list=false ;;
    esac"
}

run(){
    if ${is_build_list};then
        for item in ${build_list[@]};do
            $1 $item
        done
    else
        $1 $2
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

connect(){
    local home="/home/frs/project/${project}"
    echo "${account},${project}@frs.${host}:${home}"
}
