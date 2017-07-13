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

prepare_transfer(){
    prepare_dir "${repo_dir}"
    local home="/home/frs/project/${project}/fork" repo="$1"
    if ${pull};then
        src_dir="$(connect)/fork/$repo/"
        target_dir="${repo_dir}/$repo/"
    elif ${push};then
        src_dir="${repo_dir}/$repo/"
        target_dir="$(connect)/fork/$repo/"
    fi
}

repo_push(){
    rsync "${rsync_args[@]}" "${src_dir}" "${target_dir}"
}

repo_pull(){
    rsync "${rsync_args[@]}" "${src_dir}" "${target_dir}"
}

add_repo_pkg(){
    repo="$1" pkg="$2"
    repo-add "$repo/os/${target_arch}/$repo.db.tar.xz" "$repo/os/${target_arch}/$pkg*.pkg.tar.xz"
}

del_repo_pkg(){
    repo="$1" pkg="$2"
    repo-add "$repo/os/${target_arch}/$repo.db.tar.xz" "$repo/os/${target_arch}/$pkg"
}

update_repo(){
    local repo="$1" pkg="$2"
    $add_pkg && add_repo_pkg "$repo" "$pkg"
    $del_pkg && del_repo_pkg "$repo" "$pkg"
    show_elapsed_time "${FUNCNAME}" "${timer_start}"
    exit 0
}

sync_dir(){
    local repo="$1"
    $pull && repo_pull "$repo"
    $push && repo_push "$repo"
    show_elapsed_time "${FUNCNAME}" "${timer_start}"
}
