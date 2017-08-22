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
    local name="$1"
    local _space="s| ||g" _clean=':a;N;$!ba;s/\n/ /g' _com_rm="s|#.*||g"
    import_list=$(sed "$_com_rm" "${list_dir_import}/$name.list" | sed "$_space" | sed "$_clean")
}

get_pkgver(){
    source PKGBUILD
    echo $pkgver-$pkgrel
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
            git pull origin $branch #&> /dev/null
            local arch_dir=packages
            [[ $repo == "galaxy" ]] && arch_dir=community
            msg "Import into [%s]" "$repo"
            for pkg in ${import_list[@]};do
                rsync "${rsync_args[@]}" ${tree_dir_arch}/$arch_dir/$pkg/trunk/ ${tree_dir_artix}/$repo/$pkg/
                if $(is_dirty) || $(is_untracked); then
                    git add $pkg
                    cd $pkg
                        local ver=$(get_pkgver)
                        msg2 "Archlinux import: [%s]" "$pkg-$ver"
                        git commit -m "Archlinux import: $pkg-$ver"
                        git push origin $branch #&> /dev/null
                    cd ..
                fi
            done
        fi
    done
    show_elapsed_time "${FUNCNAME}" "${timer}"
}
