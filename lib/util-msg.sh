#!/bin/bash
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# export LC_MESSAGES=C
export LANG=C

source /usr/share/makepkg/util.sh

if [[ -t 2 ]]; then
    colorize
else
    declare -gr ALL_OFF='' BOLD='' BLUE='' GREEN='' RED='' YELLOW=''
fi

info() {
    local mesg=$1; shift
    printf "${YELLOW} -->${ALL_OFF}${BOLD} ${mesg}${ALL_OFF}\n" "$@" >&2
}

stat_busy() {
    local mesg=$1; shift
    printf "${GREEN}==>${ALL_OFF}${BOLD} ${mesg}...${ALL_OFF}" "$@" >&2
}

stat_done() {
    printf "${BOLD}done${ALL_OFF}\n" >&2
}

lock_close() {
	local fd=$1
	exec {fd}>&-
}

lock() {
    if ! [[ "/dev/fd/$1" -ef "$2" ]]; then
        mkdir -p -- "$(dirname -- "$2")"
        eval "exec $1>"'"$2"'
    fi
    if ! flock -n $1; then
        stat_busy "$3"
        flock $1
        stat_done
    fi
}

slock() {
    if ! [[ "/dev/fd/$1" -ef "$2" ]]; then
        mkdir -p -- "$(dirname -- "$2")"
        eval "exec $1>"'"$2"'
    fi
    if ! flock -sn $1; then
        stat_busy "$3"
        flock -s $1
        stat_done
    fi
}

cleanup() {
    exit ${1:-0}
}

abort() {
    error 'Aborting...'
    cleanup 255
}

die() {
    (( $# )) && error "$@"
    cleanup 255
}

msg_table_header(){
    local mesg=$1; shift
    printf "${GREEN} ${mesg} ${ALL_OFF}\n" "$@" >&2
}

msg_row_downgrade(){
    local mesg=$1; shift
    printf "${YELLOW} ${mesg}${ALL_OFF}\n" "$@" >&2
}

msg_row_update(){
    local mesg=$1; shift
    printf "${RED}${BOLD} ${mesg} ${ALL_OFF}\n" "$@" >&2
}

import(){
    if [[ -r "$1" ]];then
        source "$1"
    else
        die 'Could not import %s' "$1"
    fi
}
