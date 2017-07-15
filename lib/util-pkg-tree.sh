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

sync_tree(){
    local master=$(git log --pretty=%H ...refs/heads/master^ | head -n 1) \
        master_remote=$(git ls-remote origin -h refs/heads/master | cut -f1) \
        timer=$(get_timer)
    msg "Checking [%s] ..." "$1"
    msg2 "local: %s" "${master}"
    msg2 "remote: %s" "${master_remote}"
    if [[ "${master}" == "${master_remote}" ]]; then
        info "nothing to do"
    else
        info "needs sync"
        git pull origin master
    fi
    msg "Done [%s]" "$1"
    show_elapsed_time "${FUNCNAME}" "${timer}"
}

clone_tree(){
    local timer=$(get_timer)
    msg "Preparing [%s] ..." "$1"
    info "clone"
    git clone $2.git
    msg "Done [%s]" "$1"
    show_elapsed_time "${FUNCNAME}" "${timer}"
}

sync_tree_artix(){
    cd ${tree_dir}
        for repo in ${repo_tree[@]};do
            if [[ -d ${repo} ]];then
                cd ${repo}
                    sync_tree "${repo}"
                cd ..
            else
                clone_tree "${repo}" "${host_tree}/${repo}"
            fi
        done
    cd ..
}

sync_tree_arch(){
    local repo_tree_arch=('packages' 'community')
    cd ${tree_dir_arch}
        for repo in ${repo_tree_arch[@]};do
            if [[ -d ${repo} ]];then
                cd ${repo}
                    sync_tree "${repo}"
                cd ..
            else
                clone_tree "${repo}" "${host_tree_arch}/${repo}"
            fi
        done
    cd ..
}

read_import_list(){
    local name="$1"
    local _space="s| ||g" _clean=':a;N;$!ba;s/\n/ /g' _com_rm="s|#.*||g"
    import_list=$(sed "$_com_rm" "${list_dir_import}/$name.list" | sed "$_space" | sed "$_clean")
}

import_from_arch(){
    for repo in ${repo_tree[@]};do
        read_import_list "$repo"
        if [[ -n ${import_list[@]} ]];then
            cd ${repos_dir}/$repo
            git checkout archlinux
        fi
        local arch_dir=packages
        [[ $repo == "galaxy" ]] && arch_dir=community
        for pkg in ${import_list[@]};do
            rsync -avWx --progress --delete --no-R --no-implied-dirs ${tree_dir_arch}/$arch_dir/$pkg/trunk/ ${repos_dir}/$repo/$pkg/
        done
        [[ -n ${import_list[@]} ]] && user_own ${repos_dir}/$repo -R
    done
}
