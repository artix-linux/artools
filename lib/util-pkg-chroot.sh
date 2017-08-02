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

clean_up(){
    msg2 "Cleaning [%s]" "${pkg_dir}"
    find ${pkg_dir} -maxdepth 1 -name "*.*" -delete #&> /dev/null
    if [[ -z $SRCDEST ]];then
        msg2 "Cleaning [source files]"
        find $PWD -maxdepth 1 -name '*.?z?' -delete #&> /dev/null
    fi
}

sign_pkg(){
    local pkg="$1"
    [[ -f ${pkg_dir}/${pkg}.sig ]] && rm ${pkg_dir}/${pkg}.sig
    user_run "signfile ${pkg_dir}/${pkg}"
}

move_to_cache(){
    local src="$1"
    [[ -n $PKGDEST ]] && src="$PKGDEST/$src"
    [[ ! -f $src ]] && die
    msg2 "Moving [%s] -> [%s]" "${src##*/}" "${pkg_dir}"
    mv $src ${pkg_dir}/
    user_own "${pkg_dir}" -R
    ${sign} && sign_pkg "${src##*/}"
#     [[ -n $PKGDEST ]] && rm "$src"
    user_own "${pkg_dir}" -R
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
        if ${repo_add};then
            deploypkg -r "${repository}" -x -p "$src"
            user_own "${repos_local}/${repository}" -R
        fi
    done
}

build_pkg(){
    ${purge} && clean_up
#     setarch "${target_arch}"
    mkchrootpkg "${mkchrootpkg_args[@]}" || die
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

