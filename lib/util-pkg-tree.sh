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

show_version_table(){
    declare -A UPDATES
    msg_table_header "%-30s %-30s %-30s %-30s" "Repository" "Package" "Artix version" "Arch version"
    for repo in ${repo_tree_import[@]}; do
        for pkg in ${tree_dir_artix}/$repo/*; do
            if [[ -f $pkg/PKGBUILD ]];then
                source $pkg/PKGBUILD 2>/dev/null
                package=${pkg##*/}
                artixver=$(get_full_version $package)
                set_import_path "$repo" "$package"
                if [[ -f $src/PKGBUILD ]];then
                    source $src/PKGBUILD 2>/dev/null
                    archver=$(get_full_version $package)
                fi
                if [ $(vercmp $artixver $archver) -lt 0 ];then
                    UPDATES[$package]="$src/PKGBUILD $pkg/PKGBUILD"
                    msg_row_update "%-30s %-30s %-30s %-30s" "$repo" "$package" "$artixver" "$archver"
                else
                    msg_row "%-30s %-30s %-30s %-30s" "$repo" "$package" "$artixver" "$archver"
                fi
            fi
            unset pkgver epoch pkgrel artixver archver package
        done
    done
    for upd in "${!UPDATES[@]}"; do
        msg "Diff: %s" "$upd"
        diff -u ${UPDATES[$upd]}
    done
}

sync_tree(){
    local branch="master" repo="$1"
    git checkout $branch
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

sync_tree_artix(){
    cd ${tree_dir_artix}
        for repo in ${repo_tree_import[@]};do
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

patch_pkg(){
    local pkg="$1"
    case $pkg in
        'glibc')
            sed -e 's|{locale,systemd/system,tmpfiles.d}|{locale,tmpfiles.d}|' \
                -e '/nscd.service/d' \
                -i $pkg/PKGBUILD
        ;;
        'bash')
            sed -e 's|system.bash_logout)|system.bash_logout\n        artix.bashrc)|' \
                -e 's|etc/bash.|etc/bash/|g' \
                -e 's|install -dm755 "$pkgdir"/etc/skel/|install -dm755 "$pkgdir"/etc/{skel,bash/bashrc.d}/|' \
                -e 's|/etc/skel/.bash_logout|/etc/skel/.bash_logout\n  install -m644 artix.bashrc "$pkgdir"/etc/bash/bashrc.d/artix.bashrc|' \
                -i $pkg/PKGBUILD

            patch -p1 -i $DATADIR/patches/dot-bashrc.patch
            patch -p1 -i $DATADIR/patches/system-bashrc.patch
            patch -p1 -i $DATADIR/patches/system-bashrc_logout.patch
            patch -p1 -i $DATADIR/patches/artix-bashrc.patch
            cd $pkg
                updpkgsums
            cd ..
        ;;
    esac
}

set_import_path(){
    local arch_dir arch_repo import_path
    local repo="$1" pkg="$2"
    case $repo in
        system|world)
            if [[ "$repo" == 'system' ]];then
                arch_repo=core
                arch_dir=packages
            fi
            if [[ "$repo" == 'world' ]];then
                arch_repo=extra
                arch_dir=packages
            fi
            import_path=${tree_dir_arch}/$arch_dir/$pkg/repos
            src=$import_path/$arch_repo-x86_64
            if [[ -d $import_path/$arch_repo-any ]];then
                src=$import_path/$arch_repo-any
            elif [[ -d $import_path/testing-x86_64 ]];then
                src=$import_path/testing-x86_64
            elif [[ -d $import_path/testing-any ]];then
                src=$import_path/testing-any
            fi
        ;;
        galaxy)
            arch_repo=community
            arch_dir=$arch_repo
            import_path=${tree_dir_arch}/$arch_dir/$pkg/repos/$arch_repo
            src=$import_path-x86_64
            if [[ -d $import_path-any ]];then
                src=$import_path-any
            elif [[ -d $import_path-testing-x86_64 ]];then
                src=$import_path-testing-x86_64
            elif [[ -d $import_path-testing-any ]];then
                src=$import_path-testing-any
            fi
        ;;
        lib32)
            if [[ "$pkg" == 'llvm' ]];then
                arch_repo=extra
                arch_dir=packages
                import_path=${tree_dir_arch}/$arch_dir/$pkg/repos
                src=$import_path/extra-x86_64
                if [[ -d $import_path/testing-x86_64 ]];then
                    src=$import_path/testing-x86_64
                fi
            else
                arch_repo=multilib
                arch_dir=community
                import_path=${tree_dir_arch}/$arch_dir/$pkg/repos
                src=$import_path/$arch_repo-x86_64
                if [[ -d $import_path/$arch_repo-testing-x86_64 ]];then
                    src=$import_path/$arch_repo-testing-x86_64
                fi
            fi
        ;;
    esac
}

import_from_arch(){
    local timer=$(get_timer) branch='testing' push="$1"
    for repo in ${repo_tree_import[@]};do
        read_import_list "$repo"
        if [[ -n ${import_list[@]} ]];then
            cd ${tree_dir_artix}/$repo
            git checkout $branch &> /dev/null
            $(is_dirty) && die "[%s] has uncommited changes!" "${repo}"
            git pull origin "$branch"
            msg "Import into [%s]" "$repo"
            for pkg in ${import_list[@]};do
                source $pkg/PKGBUILD 2>/dev/null
                local ver=$(get_full_version $pkg)
                msg2 "package: %s-%s" "$pkg" "$ver"
                set_import_path "$repo" "$pkg"
                rsync "${rsync_args[@]}"  $src/ ${tree_dir_artix}/$repo/$pkg/
                if $(is_dirty) || $(is_untracked); then
                    patch_pkg "$pkg"
                    ${push} && git add "$pkg"
                    msg2 "Archlinux import: [%s]" "$pkg-$ver"
                    if ${push};then
                        git commit -m "Archlinux import: $pkg-$ver"
                        sleep 10
                        git push origin "$branch"
                    fi
                fi
                unset pkgver epoch pkgrel ver
            done
        fi
    done
    show_elapsed_time "${FUNCNAME}" "${timer}"
}
