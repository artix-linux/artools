#!/bin/bash
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

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
