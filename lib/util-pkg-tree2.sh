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
    local repo="$1"
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

sync_tree_artix(){
    local repo="$1"
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

# patch_pkg(){
#     local pkg="$1"
#     case $pkg in
#         'glibc')
#             sed -e 's|{locale,systemd/system,tmpfiles.d}|{locale,tmpfiles.d}|' \
#                 -e '/nscd.service/d' \
#                 -i $pkg/PKGBUILD
#         ;;
#         'bash')
#             sed -e 's|system.bash_logout)|system.bash_logout\n        artix.bashrc)|' \
#                 -e 's|etc/bash.|etc/bash/|g' \
#                 -e 's|install -dm755 "$pkgdir"/etc/skel/|install -dm755 "$pkgdir"/etc/{skel,bash/bashrc.d}/|' \
#                 -e 's|/etc/skel/.bash_logout|/etc/skel/.bash_logout\n  install -m644 artix.bashrc "$pkgdir"/etc/bash/bashrc.d/artix.bashrc|' \
#                 -i $pkg/PKGBUILD
# 
#             patch -p1 -i $DATADIR/patches/dot-bashrc.patch
#             patch -p1 -i $DATADIR/patches/system-bashrc.patch
#             patch -p1 -i $DATADIR/patches/system-bashrc_logout.patch
#             patch -p1 -i $DATADIR/patches/artix-bashrc.patch
#             cd $pkg
#                 updpkgsums
#             cd ..
#         ;;
#         'tp_smapi'|'acpi_call'|'r8168')
#             sed -e 's|-ARCH|-ARTIX|g' -i $pkg/PKGBUILD
#         ;;
#     esac
# }

get_import_path(){
    local repo="$1" import_path=
    case $repo in
        packages) import_path=${tree_dir_arch}/packages ;;
        galaxy) import_path=${tree_dir_arch}/community ;;
    esac
    echo $import_path
}

import_from_arch(){
    local timer=$(get_timer) tree="$1"
    read_import_list "$tree"
    if [[ -n ${import_list[@]} ]];then
        cd ${tree_dir_artix}/$tree
#         $(is_dirty) && die "[%s] has uncommited changes!" "${tree}"
        git pull origin master
        for pkg in ${import_list[@]};do
            local src=$(get_import_path "$tree")
            local dest=${tree_dir_artix}/$tree
            source $src/$pkg/trunk/PKGBUILD 2>/dev/null
            local ver=$(get_full_version $pkg)
            msg "Package: %s-%s" "$pkg" "$ver"
            rsync "${rsync_args[@]}"  $src/$pkg/repos/ $dest/$pkg/
            unset pkgver epoch pkgrel ver
        done
    fi
    show_elapsed_time "${FUNCNAME}" "${timer}"
}
