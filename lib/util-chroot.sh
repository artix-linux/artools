#!/bin/bash
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

copy_mirrorlist(){
    cp -a /etc/pacman.d/mirrorlist "$1/etc/pacman.d/"
}

copy_keyring(){
    if [[ -d /etc/pacman.d/gnupg ]] && [[ ! -d $1/etc/pacman.d/gnupg ]]; then
        cp -a /etc/pacman.d/gnupg "$1/etc/pacman.d/"
    fi
}

create_min_fs(){
    msg "Creating install root at %s" "$1"
    mkdir -m 0755 -p $1/var/{cache/pacman/pkg,lib/pacman,log} $1/{dev,etc}
    mkdir -m 1777 -p $1/{tmp,run}
    mkdir -m 0555 -p $1/{sys,proc}
    if [[ ! -f $1/etc/machine-id ]];then
        touch $1/etc/machine-id
    fi
}

is_btrfs() {
	[[ -e "$1" && "$(stat -f -c %T "$1")" == btrfs ]]
}

subvolume_delete_recursive() {
    local subvol

    is_btrfs "$1" || return 0

    while IFS= read -d $'\0' -r subvol; do
        if ! btrfs subvolume delete "$subvol" &>/dev/null; then
            error "Unable to delete subvolume %s" "$subvol"
            return 1
        fi
    done < <(find "$1" -xdev -depth -inum 256 -print0)

    return 0
}

default_locale(){
    local action="$1" mnt="$2"
    if [[ $action == "set" ]];then
        if [[ ! -f "$mnt/etc/locale.gen.bak" ]];then
            info "Setting locale ..."
            mv "$mnt/etc/locale.gen" "$mnt/etc/locale.gen.bak"
            printf '%s.UTF-8 UTF-8\n' en_US > "$mnt/etc/locale.gen"
            printf 'LANG=%s.UTF-8\n' en_US > "$mnt/etc/locale.conf"
            printf 'LC_MESSAGES=C\n' >> "$mnt/etc/locale.conf"
        fi
    elif [[ $action == "reset" ]];then
        if [[ -f "$mnt/etc/locale.gen.bak" ]];then
            info "Resetting locale ..."
            mv "$mnt/etc/locale.gen.bak" "$mnt/etc/locale.gen"
            rm "$mnt/etc/locale.conf"
        fi
    fi
}

default_mirror(){
    local mnt="$1" mirror="$2"'/$repo/os/$arch'
    [[ -f $mnt/etc/pacman.d/mirrorlist ]] && mv "$mnt"/etc/pacman.d/mirrorlist "$mnt"/etc/pacman.d/mirrorlist.bak
    echo "Server = $mirror" > $mnt/etc/pacman.d/mirrorlist
}

# $1: chroot
kill_chroot_process(){
    local prefix="$1" flink pid name
    for root_dir in /proc/*/root; do
        flink=$(readlink $root_dir)
        if [ "x$flink" != "x" ]; then
            if [ "x${flink:0:${#prefix}}" = "x$prefix" ]; then
                # this process is in the chroot...
                pid=$(basename $(dirname "$root_dir"))
                name=$(ps -p $pid -o comm=)
                info "Killing chroot process: %s (%s)" "$name" "$pid"
                kill -9 "$pid"
            fi
        fi
    done
}
