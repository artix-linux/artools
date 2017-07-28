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
    local name="$1" yaml="$2"
    msg2 "Writing %s ..." "${yaml##*/}"
    echo "---" > "$yaml"
    echo "- name: '$name'" >> "$yaml"
    echo "  description: '$name'" >> "$yaml"
    echo "  selected: false" >> "$yaml"
    echo "  hidden: false" >> "$yaml"
    echo "  critical: false" >> "$yaml"
    echo "  packages:" >> "$yaml"
    for p in ${packages[@]};do
        echo "       - $p" >> "$yaml"
    done
}

write_pacman_group_yaml(){
    local group="$1"
    packages=$(pacman -Sgq "$group")
    prepare_dir "${cache_dir_netinstall}/pacman"
    write_netgroup_yaml "$group" "${cache_dir_netinstall}/pacman/$group.yaml"
}

gen_fn(){
    echo "${yaml_dir}/$1-${target_arch}-${initsys}.yaml"
}

prepare_build(){
    local profile_dir=${run_dir}/${profile}

    load_profile "${profile_dir}"

    yaml_dir=${cache_dir_netinstall}/${profile}/${target_arch}

    prepare_dir "${yaml_dir}"
}

build(){
    prepare_build
    load_pkgs "${root_list}" "${target_arch}" "${initsys}" "${kernel}"
    write_netgroup_yaml "${profile}" "$(gen_fn "Packages-Root")"
    if [[ -f "${desktop_list}" ]]; then
        load_pkgs "${desktop_list}" "${target_arch}" "${initsys}" "${kernel}"
        write_netgroup_yaml "${profile}" "$(gen_fn "Packages-Desktop")"
    fi
    ${calamares} && configure_calamares "${yaml_dir}"
    reset_profile
    unset yaml_dir
}
