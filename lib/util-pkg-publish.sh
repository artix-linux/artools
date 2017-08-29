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

repo_update(){
    local repo="$1" arch="$2" pkg="$3" action="$4" copy="$5"
    if [[ $action == "add" ]];then
        if [[ -f ${repos_local}/$repo/os/$arch/$pkg \
            && -f ${repos_local}/$repo/os/$arch/$pkg.sig ]];then
            rm ${repos_local}/$repo/os/$arch/$pkg
            rm ${repos_local}/$repo/os/$arch/$pkg.sig
        fi
        local cmd='ln -s'
        $copy && cmd='cp'
        $cmd ${PKDDEST}/$pkg{,.sig} ${repos_local}/$repo/os/$arch/
    fi
    local dest=${repos_local}/$repo/os/$arch/$pkg
    [[ $action == "remove" ]] && dest=$pkg
    repo-$action -R ${repos_local}/$repo/os/$arch/$repo.db.tar.xz $dest
}

# add_to_repo(){
#     local repo="$1" arch="$2" pkg="$3" ext='db.tar.xz'
#     ln -s ${PKDDEST}/$pkg{,.sig} ${repos_local}/$repo/os/$arch/
#     repo-add -R ${repos_local}/$repo/os/$arch/$repo.$ext ${repos_local}/$repo/os/$arch/$pkg
# }

# upload_pkg(){
#     local pkg="$1" repo="$2" arch="$3" ext='db.tar.xz'
#     sftp ${account}@${file_host}
#     cd $repo/os/$arch
#     put $pkg{,.sig} $repo.$ext{,.old}
#     bye
# }
