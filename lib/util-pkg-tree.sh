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
    local master=$(git log --pretty=%H ...refs/heads/master^ | head -n 1)
    local master_remote=$(git ls-remote origin -h refs/heads/master | cut -f1)
    local timer=$(get_timer) repo="$1"
    msg "Checking [%s] ..." "$repo"
    msg2 "local: %s" "${master}"
    msg2 "remote: %s" "${master_remote}"
    if [[ "${master}" == "${master_remote}" ]]; then
        info "nothing to do"
    else
        info "needs sync"
        git pull origin master
    fi
    msg "Done [%s]" "$repo"
    show_elapsed_time "${FUNCNAME}" "${timer}"
}

clone_tree(){
    local timer=$(get_timer) repo="$1" host_tree="$2"
    msg "Preparing [%s] ..." "$repo"
    info "clone"
    git clone $host_tree.git
    msg "Done [%s]" "$repo"
    show_elapsed_time "${FUNCNAME}" "${timer}"
}

sync_tree_artix(){
    cd ${tree_dir_artix}
        for repo in ${repo_tree_artix[@]};do
            if [[ -d ${repo} ]];then
                cd ${repo}
                    sync_tree "${repo}"
                cd ..
            else
                clone_tree "${repo}" "${host_tree_artix}/${repo}"
            fi
        done
    cd ..
    user_own ${tree_dir_artix} -R
}

sync_tree_arch(){
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
    user_own ${tree_dir_arch} -R
}

read_import_list(){
    local name="$1"
    local _space="s| ||g" _clean=':a;N;$!ba;s/\n/ /g' _com_rm="s|#.*||g"
    import_list=$(sed "$_com_rm" "${list_dir_import}/$name.list" | sed "$_space" | sed "$_clean")
}

is_dirty() {
  [[ $(git diff --shortstat 2> /dev/null | tail -n1) != "" ]] && return 0
}

import_from_arch(){
    local timer=$(get_timer)
    for repo in ${repo_tree_artix[@]};do
        read_import_list "$repo"
        if [[ -n ${import_list[@]} ]];then
            cd ${tree_dir_artix}/$repo
            su ${OWNER} -c "git checkout archlinux"
            local arch_dir=packages
            [[ $repo == "galaxy" ]] && arch_dir=community
            msg "Import into '%s' from archlinux" "$repo"
            for pkg in ${import_list[@]};do
                msg2 "Update %s" "$pkg"
                rsync "${rsync_args[@]}" ${tree_dir_arch}/$arch_dir/$pkg/trunk/ ${tree_dir_artix}/$repo/$pkg/
            done

            $(is_dirty) && su ${OWNER} -c "git commit -m 'Archlinux import'"
            git checkout master
            user_own ${tree_dir_artix}/$repo -R
        fi
    done
    show_elapsed_time "${FUNCNAME}" "${timer}"
}
