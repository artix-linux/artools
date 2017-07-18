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

import ${LIBDIR}/util-yaml.sh

write_netgroup_yaml(){
    msg2 "Writing %s ..." "${2##*/}"
    echo "---" > "$2"
    echo "- name: '$1'" >> "$2"
    echo "  description: '$1'" >> "$2"
    echo "  selected: false" >> "$2"
    echo "  hidden: false" >> "$2"
    echo "  critical: false" >> "$2"
    echo "  packages:" >> "$2"
    for p in ${packages[@]};do
        echo "       - $p" >> "$2"
    done
}

write_pacman_group_yaml(){
    packages=$(pacman -Sgq "$1")
    prepare_dir "${cache_dir_netinstall}/pacman"
    write_netgroup_yaml "$1" "${cache_dir_netinstall}/pacman/$1.yaml"
}

gen_fn(){
    echo "${yaml_dir}/$1-${target_arch}-${initsys}.yaml"
}

make_profile_yaml(){
    prepare_check "$1"
    load_pkgs "${root_list}" "${target_arch}" "${initsys}" "${kernel}"
    write_netgroup_yaml "$1" "$(gen_fn "Packages-Root")"
    if [[ -f "${desktop_list}" ]]; then
        load_pkgs "${desktop_list}" "${target_arch}" "${initsys}" "${kernel}"
        write_netgroup_yaml "$1" "$(gen_fn "Packages-Desktop")"
    fi
    ${calamares} && configure_calamares "${yaml_dir}"
    reset_profile
    unset yaml_dir
}
