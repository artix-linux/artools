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

del_from_repo(){
    local repo="$1" arch="$2" pkg="$3"
    local repo_db=${repos_root}/$repo/os/$arch/$repo.db.tar.xz
    repo-remove -R $repo_db "${repos_root}/$repo/os/$arch/$pkg"
}

add_to_repo(){
    local repo="$1" destarch="$2" pkg="$3" ext=pkg.tar.xz ver pkgfile
    source $pkg/PKGBUILD
    local repo_db=${repos_root}/$repo/os/$destarch/$repo.db.tar.xz
    for name in ${pkgname[@]};then
        [[ $arch == any ]] && CARCH=any
        ver=$(get_full_verion $name)
        if $(find_cached_package "$name" "$ver" "$CARCH"); then
            pkgfile=$name-$ver-$CARCH.$ext
            ln -sf ${PKDDEST}/$pkgfile{,.sig} ${repos_root}/$repo/os/$destarch/
            repo-add -R $repo_db ${repos_root}/$repo/os/$destarch/$pkgfile
        fi
    done
}

# upload(){
#     local pkg="$1" repo="$2" arch="$3" ext='db.tar.xz'
#     sftp ${account}@${file_host}
#     cd $repo/os/$arch
#     put $pkg{,.sig} $repo.$ext{,.old}
#     bye
# }
