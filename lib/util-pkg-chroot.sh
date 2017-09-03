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

build(){
    local pkg="$1"
    check_build "${pkg}"
    msg "Start building [%s]" "${pkg}"
    cd ${pkg}
        exec mkchrootpkg "${mkchrootpkg_args[@]}" || abort
    cd ..
    msg "Finished building [%s]" "${pkg}"
    show_elapsed_time "${FUNCNAME}" "${timer_start}"
}
