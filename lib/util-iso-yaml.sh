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

write_users_conf(){
    local conf="$1/users.conf"
    msg2 "Writing %s ..." "${conf##*/}"
    echo "---" > "$conf"
    echo "defaultGroups:" >> "$conf"
    local IFS=','
    for g in ${addgroups[@]};do
        echo "    - $g" >> "$conf"
    done
    unset IFS
    echo "autologinGroup:  autologin" >> "$conf"
    echo "doAutologin:     false" >> "$conf"
    echo "sudoersGroup:    wheel" >> "$conf"
    echo "setRootPassword: true" >> "$conf"
#     echo "doReusePassword: false" >> "$conf" # only used in old 'users' module
    echo "availableShells: /bin/bash, /bin/zsh" >> "$conf" # only used in new 'users' module
    echo "avatarFilePath:  ~/.face" >> "$conf"
}

write_servicescfg_conf(){
    local init="$2"
    local conf="$1"/"$init"cfg.conf state='add'
    msg2 "Writing %s ..." "${conf##*/}"
    echo '---' >  "$conf"
    if [[ "$init" == 'runit' ]];then
        state='enabled'
        echo 'svdir: /etc/runit/sv' >> "$conf"
        echo '' >> "$conf"
        echo 'runsvdir: /etc/runit/runsvdir' >> "$conf"
    fi
    echo '' >> "$conf"
    echo 'services:' >> "$conf"
    echo "    $state:" >> "$conf"
    for svc in ${services[@]};do
        echo "      - name: $svc" >> "$conf"
        echo '        runlevel: default' >> "$conf"
    done
}

write_postcfg_conf(){
    local conf="$1/postcfg.conf" init="$2"
    sed -e "s|openrc|$init|" -i "$conf"
}

write_netinstall_conf(){
    local conf="$1/netinstall.conf" init="$2"
    sed -e "s|netgroups-openrc.yaml|netgroups-$init.yaml|" -i "$conf"
}

configure_calamares(){
    local mods="$1/etc/calamares/modules" init="$2"
    if [[ -d "$mods" ]];then
        info "Configuring [Calamares]"
        write_netinstall_conf "$mods" "$init"
        write_users_conf "$mods"
        write_servicescfg_conf "$mods" "$init"
        write_postcfg_conf "$mods" "$init"
        local name="$init"cfg
        sed -e "s|openrccfg|$name|" -i "$1"/etc/calamares/settings.conf
        info "Done configuring [Calamares]"
    fi
}
