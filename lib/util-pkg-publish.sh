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
        $cmd ${cache_dir_pkg}/$arch/$repo/$pkg{,.sig} ${repos_local}/$repo/os/$arch/
    fi
    local dest=${repos_local}/$repo/os/$arch/$pkg
    [[ $action == "remove" ]] && dest=$pkg
    repo-$action -R ${repos_local}/$repo/os/$arch/$repo.db.tar.xz $dest
}

update_lock(){
    local repo="$1"
    rsync "${rsync_args[@]}" --exclude='os' "${repos_local}/$repo/" "$(connect)${repos_remote}/$repo/"
}

is_locked(){
    local repo="$1" url="https://${file_host}/projects/${project}/files/repos"
    if wget --spider -v $url/$repo/$repo.lock &>/dev/null;then
        return 0
    else
        return 1
    fi
}

repo_lock(){
    local repo="$1"
    if [[ ! -f ${repos_local}/$repo/$repo.lock ]];then
        warning "Locking %s" "$repo"
        touch ${repos_local}/$repo/$repo.lock
        update_lock "$repo"
    fi
}

repo_unlock(){
    local repo="$1"
    if [[ -f ${repos_local}/$repo/$repo.lock ]];then
        warning "Unlocking %s" "$repo"
        rm ${repos_local}/$repo/$repo.lock
        update_lock "$repo"
    fi
}

repo_download(){
    local repo="$1"
    if is_locked "$repo"; then
        die "The '%s' repository is locked" "$repo"
    else
        rsync "${rsync_args[@]}" "$(connect)${repos_remote}/$repo/" "${repos_local}/$repo/"
    fi
}

repo_upload(){
    local repo="$1"
    repo_lock "$repo"
    rsync "${rsync_args[@]}" "${repos_local}/$repo/" "$(connect)${repos_remote}/$repo/"
    repo_unlock "$repo"
}

add_to_repo(){
    local repo="$1" arch="$2" pkg="$3" ext='db.tar.xz'
    ln -s ${cache_dir_pkg}/$arch/$repo/$pkg{,.sig} ${repos_local}/$repo/os/$arch/
    repo-add -R ${repos_local}/$repo/os/$arch/$repo.$ext ${repos_local}/$repo/os/$arch/$pkg
}

# upload_pkg(){
#     local pkg="$1" repo="$2" arch="$3" ext='db.tar.xz'
#     sftp ${account}@${file_host}
#     cd $repo/os/$arch
#     put $pkg{,.sig} $repo.$ext{,.old}
#     bye
# }
