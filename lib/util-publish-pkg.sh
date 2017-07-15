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

update_lock(){
    local repo="$1"
    rsync "${rsync_args[@]}" --exclude="os" "${repos_local}/$repo/" "$(connect)${repos_remote}/$repo/"
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
    repo_lock "$repo"
    rsync "${rsync_args[@]}" "$(connect)${repos_remote}/$repo/" "${repos_local}/$repo/"
    user_own "${repos_local}/$repo/" -R

}

repo_upload(){
    local repo="$1"
    rsync "${rsync_args[@]}" "${repos_local}/$repo/" "$(connect)${repos_remote}/$repo/"
    repo_unlock "$repo"
}

sync_repo(){
    local repo="$1"
    ${download} && repo_download "$repo"
    ${upload} && repo_upload "$repo"
    show_elapsed_time "${FUNCNAME}" "${timer_start}"
}
