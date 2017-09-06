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

get_local_head(){
    echo $(git log --pretty=%H ...refs/heads/$1^ | head -n 1)
}

get_remote_head(){
    echo $(git ls-remote origin -h refs/heads/$1 | cut -f1)
}

is_dirty() {
    [[ $(git diff --shortstat 2> /dev/null | tail -n1) != "" ]] || return 1
    return 0
}

sync_tree(){
    local branch="master" repo="$1"
    local local_head=$(get_local_head "$branch")
    local remote_head=$(get_remote_head "$branch")
    local timer=$(get_timer)
    msg "Checking [%s] ..." "$repo"
    msg2 "local: %s" "${local_head}"
    msg2 "remote: %s" "${remote_head}"
    if [[ "${local_head}" == "${remote_head}" ]]; then
        info "nothing to do"
    else
        info "needs sync"
        git pull origin $branch
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
}

read_import_list(){
    local repo="$1"
    local _space="s| ||g" _clean=':a;N;$!ba;s/\n/ /g' _com_rm="s|#.*||g"
    import_list=$(sed "$_com_rm" "${list_dir_import}/$repo.list" | sed "$_space" | sed "$_clean")
}

is_untracked(){
    [[ $(git ls-files --others --exclude-standard)  != "" ]] || return 1
    return 0
}

import_from_arch(){
    local timer=$(get_timer) branch='testing'
    for repo in ${repo_tree_import[@]};do
        read_import_list "$repo"
        if [[ -n ${import_list[@]} ]];then
            cd ${tree_dir_artix}/$repo
            git checkout $branch &> /dev/null
            $(is_dirty) && die "[%s] has uncommited changes!" "${repo}"
            git pull origin "$branch" #&> /dev/null
            local arch_dir arch_repo src
            msg "Import into [%s]" "$repo"
            for pkg in ${import_list[@]};do
                case $repo in
                    system)
                        arch_repo=core
                        arch_dir=packages
                        src=${tree_dir_arch}/$arch_dir/$pkg/repos/$arch_repo-x86_64
                        if [[ -d ${tree_dir_arch}/$arch_dir/$pkg/repos/testing-x86_64 ]];then
                            src=${tree_dir_arch}/$arch_dir/$pkg/repos/testing-x86_64
                        fi
                    ;;
                    world)
                        arch_repo=extra
                        arch_dir=packages
                        src=${tree_dir_arch}/$arch_dir/$pkg/repos/$arch_repo-x86_64
                        if [[ -d ${tree_dir_arch}/$arch_dir/$pkg/repos/testing-x86_64 ]];then
                            src=${tree_dir_arch}/$arch_dir/$pkg/repos/testing-x86_64
                        fi
                    ;;
                    galaxy)
                        arch_repo=community
                        arch_dir=$arch_repo
                        src=${tree_dir_arch}/$arch_dir/$pkg/repos/$arch_repo-x86_64
                        if [[ -d ${tree_dir_arch}/$arch_dir/$pkg/repos/$arch_repo-testing-x86_64 ]];then
                            src=${tree_dir_arch}/$arch_dir/$pkg/repos/$arch_repo-testing-x86_64
                        fi
                    ;;
                esac
                rsync "${rsync_args[@]}" -n "$src/" "${tree_dir_artix}/$repo/$pkg/"
                if $(is_dirty) || $(is_untracked); then
                    msg2 "package: %s" "$pkg"
                    git add "$pkg"
                    cd "$pkg"
                        local ver=$(get_full_version $pkg)
                        msg2 "Archlinux import: [%s]" "$pkg-$ver"
                        git commit -m "Archlinux import: $pkg-$ver"
                        sleep 10
                        git push origin "$branch" #&> /dev/null
                    cd ..
                fi
            done
        fi
    done
    show_elapsed_time "${FUNCNAME}" "${timer}"
}
