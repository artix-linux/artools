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

load_compiler_settings(){
    local arch="$1" conf
    conf=${make_conf_dir}/$arch.conf

    [[ -f $conf ]] || return 1

    info "Loading compiler settings: %s" "$arch"
    source $conf

    return 0
}

get_makepkg_conf(){

    local arch="$1"
    local conf="${tmp_dir}/makepkg-${arch}.conf"

    cp "${DATADIR}/makepkg.conf" "$conf"

    load_compiler_settings "${arch}"

    sed -i "$conf" \
        -e "s|@CARCH[@]|$carch|g" \
        -e "s|@CHOST[@]|$chost|g" \
        -e "s|@CFLAGS[@]|$cflags|g"

    echo "$conf"
}

check_build(){
    local bdir="$1"
    find_pkg "${bdir}"
    [[ ! -f ${bdir}/PKGBUILD ]] && die "Directory must contain a PKGBUILD!"
}

find_pkg(){
    local bdir="$1"
    local result=$(find . -type d -name "${bdir}")
    [[ -z $result ]] && die "%s is not a valid package or build list!" "${bdir}"
}

init_base_devel(){
    if ${udev_root};then
        local _multi _space="s| ||g" _clean=':a;N;$!ba;s/\n/ /g' _com_rm="s|#.*||g"
        local file=${DATADIR}/base-devel-udev

#         info "Loading custom group: %s" "$file"
        _multi="s|>multilib.*||g"
        ${is_multilib} && _multi="s|>multilib||g"

        packages=($(sed "$_com_rm" "$file" \
                | sed "$_space" \
                | sed "$_multi" \
                | sed "$_clean"))
    else
        packages=('base-devel')
        ${is_multilib} && packages+=('multilib-devel')
    fi
}

clean_up(){
#     msg "Cleaning up ..."
    msg2 "Cleaning [%s]" "${pkg_dir}"
    find ${pkg_dir} -maxdepth 1 -name "*.*" -delete #&> /dev/null
    if [[ -z $SRCDEST ]];then
        msg2 "Cleaning [source files]"
        find $PWD -maxdepth 1 -name '*.?z?' -delete #&> /dev/null
    fi
}

sign_pkg(){
    local pkg="$1"
    su ${OWNER} -c "signfile ${pkg_dir}/${pkg}"
}

move_to_cache(){
    prepare_dir "${log_dir}"

    local src="$1"
    [[ -n $PKGDEST ]] && src="$PKGDEST/$src"
    [[ ! -f $src ]] && die
    msg2 "Moving [%s] -> [%s]" "${src##*/}" "${pkg_dir}"
    mv $src ${pkg_dir}/
    ${sign} && sign_pkg "${src##*/}"
#     [[ -n $PKGDEST ]] && rm "$src"
    user_own "${pkg_dir}" "-R"
}

archive_logs(){
    local archive name="$1" ext=log.tar.xz ver src=${tmp_dir}/archives.list dest='.'
    ver=$(get_full_version "$name")
    archive="${name}-${ver}-${target_arch}"
    if [[ -n $LOGDEST ]];then
            dest=$LOGDEST
            find ${dest} -maxdepth 1 -name "$archive*.log" -printf "%f\n" > $src
    else
            find ${dest} -maxdepth 1 -name "$archive*.log" > $src
    fi
    msg2 "Archiving log files [%s] ..." "$archive.$ext"
    tar -cJf ${log_dir}/$archive.$ext  -C "${dest}" -T $src
    msg2 "Cleaning log files ..."

    find ${dest} -maxdepth 1 -name "$archive*.log" -delete
}

post_build(){
    source PKGBUILD
    local ext='pkg.tar.xz' tarch ver src
    for pkg in ${pkgname[@]};do
        case $arch in
            any) tarch='any' ;;
            *) tarch=${target_arch}
        esac
        local ver=$(get_full_version "$pkg") src
        src=$pkg-$ver-$tarch.$ext
        move_to_cache "$src"
    done
    local name=${pkgbase:-$pkgname}
    archive_logs "$name"
}

build_pkg(){
    prepare_dir "${pkg_dir}"
    user_own "${pkg_dir}"
    ${purge} && clean_up
    setarch "${target_arch}" \
        mkchrootpkg "${mkchrootpkg_args[@]}"
    post_build
}

make_pkg(){
    local pkg="$1"
    check_build "${pkg}"
    msg "Start building [%s]" "${pkg}"
    cd ${pkg}
        build_pkg
    cd ..
    msg "Finished building [%s]" "${pkg}"
    show_elapsed_time "${FUNCNAME}" "${timer_start}"
}

