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

gen_webseed(){
    local webseed seed="$1"
    for mirror in ${host_mirrors[@]};do
        webseed=${webseed:-}${webseed:+,}"http://${mirror}.dl.${seed}"
    done
    echo ${webseed}
}

make_torrent(){
    find ${src_dir} -type f -name "*.torrent" -delete

    if [[ -n $(find ${src_dir} -type f -name "*.iso") ]]; then
        for iso in $(ls ${src_dir}/*.iso);do
            local seed=${host}/project/${project}/${target_dir}/${iso##*/}
            local mktorrent_args=(-c "${torrent_meta}" -p -l ${piece_size} -a ${tracker_url} -w $(gen_webseed ${seed}))
            ${verbose} && mktorrent_args+=(-v)
            msg2 "Creating (%s) ..." "${iso##*/}.torrent"
            mktorrent ${mktorrent_args[*]} -o ${iso}.torrent ${iso}
        done
    fi
}

prepare_transfer(){
    target_dir="/iso/${profile}/"
    src_dir="${cache_dir_iso}/${profile}/"
    ${torrent} && make_torrent
}

sync_dir(){
    msg "Start upload [%s] ..." "${profile}"
    rsync "${rsync_args[@]}" ${src_dir} $(connect)${target_dir}
    msg "Done upload [%s]" "${profile}"
    show_elapsed_time "${FUNCNAME}" "${timer_start}"
}
