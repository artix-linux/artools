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

    if [[ -f $AT_USERCONFDIR/makepkg.conf ]];then
        cp "$AT_USERCONFDIR/makepkg.conf" "$conf"
    else
        cp "${DATADIR}/makepkg.conf" "$conf"
    fi

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
    [[ -z $result ]] && die "%s is not a valid package!" "${bdir}"
}

build_pkg(){
    mkchrootpkg "${mkchrootpkg_args[@]}" || die
}

build(){
    local pkg="$1"
    check_build "${pkg}"
    msg "Start building [%s]" "${pkg}"
    cd ${pkg}
        build_pkg
    cd ..
    msg "Finished building [%s]" "${pkg}"
    show_elapsed_time "${FUNCNAME}" "${timer_start}"
}

