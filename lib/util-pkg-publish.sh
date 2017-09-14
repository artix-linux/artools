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
    local repo="$1" destarch="$2" pkg="$3" ver result
    local repo_path=${repos_root}/$repo/os/$destarch
    source $pkg/PKGBUILD
    for name in ${pkgname[@]};do
        [[ $arch == any ]] && CARCH=any
        ver=$(get_full_version $name)
        if ! result=$(find_cached_package "$name" "$ver" "$CARCH");then
            cd $repo_path
            repo-remove -R $repo.db.tar.xz $name
        fi
    done
}

move_to_repo(){
    local repo_src="$1" repo_dest="$2" repo_arch="$3"
    local repo_path=${repos_root}/$repo_src/os/$repo_arch
    local src=$PWD list=${workspace_dir}/$repo_src.move.txt
    [[ -n ${PKGDEST} ]] && src=${PKGDEST}
    cd $repo_path
    ls *.tar.pkg.xz > $list
    rm -v *
    repo-add $repo_src.db.tar.xz
#     rsync -v --files-from="$list" $repo_path "$src"
    repo_path=${repos_root}/$repo_dest/os/$repo_arch
    for f in $(cat $list);do
        ln -sf $src/$f{,.sig} $repo_path/
    done
    cd $repo_path
    repo-add -R $repo_dest.db.tar.xz *.pkg.tar.xz
}

add_to_repo(){
    local repo="$1" destarch="$2" pkg="$3" ver pkgfile result
    local repo_path=${repos_root}/$repo/os/$destarch
    source $pkg/PKGBUILD
    local dest=$pkg
    for name in ${pkgname[@]};do
        [[ $arch == any ]] && CARCH=any
        ver=$(get_full_version $name)
        if ! result=$(find_cached_package "$name" "$ver" "$CARCH"); then
            pkgfile=$name-$ver-$CARCH.pkg.tar.xz
            [[ -n ${PKGDEST} ]] && dest=${PKGDEST}/$pkgfile
            [[ -e $dest.sig ]] && rm $dest.sig
            signfile $dest
            ln -sf $dest{,.sig} $repo_path/
            cd $repo_path
            repo-add -R $repo.db.tar.xz $pkgfile
        fi
    done
}
