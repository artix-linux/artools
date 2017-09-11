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

import ${LIBDIR}/util-pkg.sh

del_from_repo(){
    local repo="$1" destarch="$2" pkg="$3" ver pkgfile ext=pkg.tar.xz result
    cd $pkg
        source PKGBUILD
        local repo_db=${repos_root}/$repo/os/$destarch/$repo.db.tar.xz
        for name in ${pkgname[@]};do
            [[ $arch == any ]] && CARCH=any
            ver=$(get_full_version $name)
            if ! result=$(find_cached_package "$name" "$ver" "$CARCH");then
                pkgfile=$name-$ver-$CARCH.$ext
                repo-remove -R $repo_db $name
                rm ${repos_root}/$repo/os/$destarch/$pkgfile{,.sig}
            fi
        done
    cd ..
}

add_to_repo(){
    local repo="$1" destarch="$2" pkg="$3" ext=pkg.tar.xz ver pkgfile result
    cd $pkg
        source PKGBUILD
        local repo_db=${repos_root}/$repo/os/$destarch/$repo.db.tar.xz dest=$pkg
        for name in ${pkgname[@]};do
            [[ $arch == any ]] && CARCH=any
            ver=$(get_full_version $name)
            if ! result=$(find_cached_package "$name" "$ver" "$CARCH"); then
                pkgfile=$name-$ver-$CARCH.$ext
                [[ -n ${PKGDEST} ]] && dest=${PKGDEST}/$pkgfile
                [[ -e $dest.sig ]] && rm $dest.sig
                signfile $dest
                repo-add -R $repo_db $dest
                ln -sf $dest{,.sig} ${repos_root}/$repo/os/$destarch/
            fi
        done
    cd ..
}

# upload(){
#     local pkg="$1" repo="$2" arch="$3" ext='db.tar.xz'
#     sftp ${account}@${file_host}
#     cd $repo/os/$arch
#     put $pkg{,.sig} $repo.$ext{,.old}
#     bye
# }
