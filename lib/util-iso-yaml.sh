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

write_bootloader_conf(){
    local conf="$1/bootloader.conf"
    msg2 "Writing %s ..." "${conf##*/}"
    echo '---' > "$conf"
    echo "efiBootLoader: \"grub\"" >> "$conf"
    echo "kernel: \"/vmlinuz-$kernel-${target_arch}\"" >> "$conf"
    echo "img: \"/initramfs-$kernel-${target_arch}.img\"" >> "$conf"
    echo "fallback: \"/initramfs-$kernel-${target_arch}-fallback.img\"" >> "$conf"
    echo 'timeout: "10"' >> "$conf"
    echo "kernelLine: \", with ${kernel}\"" >> "$conf"
    echo "fallbackKernelLine: \", with ${kernel} (fallback initramfs)\"" >> "$conf"
    echo 'grubInstall: "grub-install"' >> "$conf"
    echo 'grubMkconfig: "grub-mkconfig"' >> "$conf"
    echo 'grubCfg: "/boot/grub/grub.cfg"' >> "$conf"
    echo '#efiBootloaderId: "dirname"' >> "$conf"
}

write_servicescfg_conf(){
    local conf="$1/servicescfg.conf"
    msg2 "Writing %s ..." "${conf##*/}"
    echo '---' >  "$conf"
    echo '' >> "$conf"
    echo 'services:' >> "$conf"
    echo '    enabled:' >> "$conf"
    for s in ${services[@]};do
        echo "      - name: $s" >> "$conf"
        echo '        runlevel: default' >> "$conf"
    done
}

write_initcpio_conf(){
    local conf="$1/initcpio.conf"
    msg2 "Writing %s ..." "${conf##*/}"
    echo "---" > "$conf"
    echo "kernel: ${kernel}" >> "$conf"
}

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
    echo "doReusePassword: false" >> "$conf" # only used in old 'users' module
    echo "availableShells: /bin/bash, /bin/zsh" >> "$conf" # only used in new 'users' module
    echo "avatarFilePath:  ~/.face" >> "$conf"
}

write_netinstall_conf(){
    local conf="$1/netinstall.conf"
    msg2 "Writing %s ..." "${conf##*/}"
    echo "---" > "$conf"
    echo "groupsUrl: ${netgroups}" >> "$conf"
}

write_unpack_conf(){
    local conf="$1/unpackfs.conf"
    msg2 "Writing %s ..." "${conf##*/}"
    echo "---" > "$conf"
    echo "unpack:" >> "$conf"
    echo "    - source: \"/run/${iso_name}/bootmnt/${iso_name}/${target_arch}/rootfs.sfs\"" >> "$conf"
    echo "      sourcefs: \"squashfs\"" >> "$conf"
    echo "      destination: \"\"" >> "$conf"
    if [[ -f "${desktop_list}" ]] ; then
        echo "    - source: \"/run/${iso_name}/bootmnt/${iso_name}/${target_arch}/desktopfs.sfs\"" >> "$conf"
        echo "      sourcefs: \"squashfs\"" >> "$conf"
        echo "      destination: \"\"" >> "$conf"
    fi
}

configure_calamares(){
    local dest="$1" mods="$1/etc/calamares/modules"
    if [[ -d $dest/etc/calamares/modules ]];then
        info "Configuring [Calamares]"
        write_netinstall_conf "$mods"
        write_unpack_conf "$mods"
        write_users_conf "$mods"
        write_initcpio_conf "$mods"
        case ${initsys} in
            'openrc') write_servicescfg_conf "$mods" ;;
        esac
        write_bootloader_conf "$mods"
        info "Done configuring [Calamares]"
    fi
}
