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
    local src=$PWD
    local filelist=${workspace_dir}/$repo_src.files.txt
    local pkglist=${workspace_dir}/$repo_src.pkgs.txt
    [[ -n ${PKGDEST} ]] && src=${PKGDEST}
    cd $repo_path
    msg "Writing repo lists [%s]" "$repo_src"
    ls *.pkg.tar.xz{,.sig} > $filelist
    ls *.pkg.tar.xz > $pkglist
    rm -v *
    repo-add $repo_src.db.tar.xz
    repo_path=${repos_root}/$repo_dest/os/$repo_arch
    local move=$(cat $filelist) pkgs=$(cat $pkglist)
    msg "Reading repo lists [%s]" "$repo_dest"
    for f in ${move[@]};do
        ln -sfv $src/$f $repo_path/
    done
    cd $repo_path
    repo-add -R $repo_dest.db.tar.xz ${pkgs[@]}
}

add_to_repo(){
    local repo="$1" destarch="$2" pkg="$3" ver pkgfile result
    if [[ $pkg == 'llvm' ]];then
        if [[ ${repo#*-} == 'testing' ]];then
            repo='world-testing'
        else
            repo='world'
        fi
    fi
#     if [[ $pkg == lib32* ]];then
#         if [[ ${repo#*-} == 'testing' ]];then
#             repo='lib32-testing'
#         else
#             repo='lib32'
#         fi
#     fi
    local repo_path=${repos_root}/$repo/os/$destarch
    source $pkg/PKGBUILD
    local dest=$pkg
    for name in ${pkgname[@]};do
        info "finddeps: %s" "$name"
        finddeps $name
        [[ $arch == any ]] && CARCH=any
        ver=$(get_full_version $name)
        if ! result=$(find_cached_package "$name" "$ver" "$CARCH"); then
            pkgfile=$name-$ver-$CARCH.pkg.tar.xz
            [[ -n ${PKGDEST} ]] && dest=${PKGDEST}/$pkgfile
            info "find-libdeps: %s" "$pkgfile"
            find-libdeps $dest
            info "find-libprovides: %s" "$pkgfile"
            find-libprovides $dest
            [[ -e $dest.sig ]] && rm $dest.sig
            signfile $dest
            ln -sf $dest{,.sig} $repo_path/
            cd $repo_path
            repo-add -R $repo.db.tar.xz $pkgfile
        fi
    done

}
