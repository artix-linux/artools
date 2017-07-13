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

connect(){
    local home="/home/frs/project/${project}"
    echo "${account},${project}@frs.${host}:${home}"
}

repo_push(){
    local home="/home/frs/project/${project}/fork" repo="$1"
    msg "Start upload [%s] ..." "$repo"
    src_dir="${repo_dir}/$repo/"
    target_dir="$(connect)/fork/$repo/"
    rsync "${rsync_args[@]}" "${src_dir}" "${target_dir}"
    msg "Done upload [%s]" "$repo"
}

repo_pull(){
    local home="/home/frs/project/${project}/fork" repo="$1"
    msg "Start download [%s] ..." "$repo"
    src_dir="$(connect)/fork/$repo/"
    target_dir="${repo_dir}/$repo/"
    rsync "${rsync_args[@]}" "${src_dir}" "${target_dir}"
    msg "Done download [%s]" "$repo"
}

add_repo_pkg(){
    repo="$1" pkg="$2"
    repo-add $repo/os/x86_64/$repo.db.tar.xz $repo/os/x86_64/$pkg*.pkg.tar.xz
}

del_repo_pkg(){
    repo="$1" pkg="$2"
    repo-add $repo/os/x86_64/$repo.db.tar.xz $repo/os/x86_64/$pkg
}

sync_dir(){
    local repo="$1"
    $pull && repo_pull "$repo"
    $push && repo_push "$repo"
    show_elapsed_time "${FUNCNAME}" "${timer_start}"
}
