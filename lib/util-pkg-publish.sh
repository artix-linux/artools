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
    local repo="$1" arch="$2" pkg="$3" action="$4" cmd
    if [[ $action == "add" ]];then
        ln -s ${cache_dir_pkg}/$arch/$pkg{,.sig} ${repos_local}/$repo/os/$arch/
    fi
    repo-$action -R ${repos_local}/$repo/os/$arch/$repo.db.tar.xz ${repos_local}/$repo/os/$arch/$pkg
}

update_lock(){
    local repo="$1"
    rsync "${rsync_args[@]}" --exclude='os' "${repos_local}/$repo/" "$(connect)${repos_remote}/$repo/"
}

is_locked(){
    local repo="$1" url="https://${host}/projects/${project}/files/repos"
    if wget --spider -v $url/$repo/$repo.lock;then
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
