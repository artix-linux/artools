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
    for s in ${openrc_boot[@]};do
        echo "      - name: $s" >> "$conf"
        echo '        runlevel: boot' >> "$conf"
    done
    for s in ${openrc_default[@]};do
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
    echo "    - source: \"/run/miso/bootmnt/${iso_name}/${target_arch}/rootfs.sfs\"" >> "$conf"
    echo "      sourcefs: \"squashfs\"" >> "$conf"
    echo "      destination: \"\"" >> "$conf"
#     if [[ -f "${desktop_list}" ]] ; then
    echo "    - source: \"/run/miso/bootmnt/${iso_name}/${target_arch}/desktopfs.sfs\"" >> "$conf"
    echo "      sourcefs: \"squashfs\"" >> "$conf"
    echo "      destination: \"\"" >> "$conf"
#     fi
}

write_welcome_conf(){
    local conf="$1/welcome.conf"
    msg2 "Writing %s ..." "${conf##*/}"
    echo "---" > "$conf" >> "$conf"
    echo "showSupportUrl:         true" >> "$conf"
    echo "showKnownIssuesUrl:     true" >> "$conf"
    echo "showReleaseNotesUrl:    true" >> "$conf"
    echo '' >> "$conf"
    echo "requirements:" >> "$conf"
    echo "    requiredStorage:    7.9" >> "$conf"
    echo "    requiredRam:        1.0" >> "$conf"
    echo "    internetCheckUrl:   https://artixlinux.org" >> "$conf"
    echo "    check:" >> "$conf"
    echo "      - storage" >> "$conf"
    echo "      - ram" >> "$conf"
    echo "      - power" >> "$conf"
    echo "      - internet" >> "$conf"
    echo "      - root" >> "$conf"
    echo "    required:" >> "$conf"
    echo "      - storage" >> "$conf"
    echo "      - ram" >> "$conf"
    echo "      - root" >> "$conf"
    if ${netinstall};then
        echo "      - internet" >> "$conf"
    fi
}

write_settings_conf(){
    local conf="$1/etc/calamares/settings.conf"
    msg2 "Writing %s ..." "${conf##*/}"
    echo "---" > "$conf"
    echo "modules-search: [ local ]" >> "$conf"
    echo '' >> "$conf"
    echo "sequence:" >> "$conf"
    echo "    - show:" >> "$conf"
    echo "        - welcome" >> "$conf"
    echo "        - locale" >> "$conf"
    echo "        - keyboard" >> "$conf"
    echo "        - partition" >> "$conf"
    echo "        - users" >> "$conf"
    if ${netinstall};then
        echo "        - netinstall" >> "$conf"
    fi
    echo "        - summary" >> "$conf"
    echo "    - exec:" >> "$conf"
    echo "        - partition" >> "$conf"
    echo "        - mount" >> "$conf"
    if ${netinstall};then
        echo "        - chrootcfg" >> "$conf"
    else
        echo "        - unpackfs" >> "$conf"
    fi
    echo "        - networkcfg" >> "$conf"
    echo "        - machineid" >> "$conf"
    echo "        - fstab" >> "$conf"
    echo "        - locale" >> "$conf"
    echo "        - keyboard" >> "$conf"
    echo "        - localecfg" >> "$conf"
    echo "        - luksopenswaphookcfg" >> "$conf"
    echo "        - luksbootkeyfile" >> "$conf"
    echo "        - initcpiocfg" >> "$conf"
    echo "        - initcpio" >> "$conf"
    echo "        - users" >> "$conf"
    echo "        - displaymanager" >> "$conf"
    echo "        - hwclock" >> "$conf"
    case ${initsys} in
        'openrc') echo "        - servicescfg" >> "$conf" ;;
    esac
    echo "        - grubcfg" >> "$conf"
    echo "        - bootloader" >> "$conf"
    echo "        - postcfg" >> "$conf"
    echo "        - umount" >> "$conf"
    echo "    - show:" >> "$conf"
    echo "        - finished" >> "$conf"
    echo '' >> "$conf"
    echo "branding: ${iso_name}" >> "$conf"
    echo '' >> "$conf"
    echo "prompt-install: false" >> "$conf"
    echo '' >> "$conf"
    echo "dont-chroot: false" >> "$conf"
}

configure_calamares(){
    local dest="$1"
    if [[ -d $dest/etc/calamares/modules ]];then
        info "Configuring [Calamares]"
        write_settings_conf "$dest"
        write_users_conf "$dest/etc/calamares/modules"
        write_netinstall_conf "$dest/etc/calamares/modules"
        write_initcpio_conf "$dest/etc/calamares/modules"
        write_unpack_conf "$dest/etc/calamares/modules"
        write_welcome_conf "$dest/etc/calamares/modules"
        case ${initsys} in
            'openrc') write_servicescfg_conf "$dest/etc/calamares/modules" ;;
        esac
        write_bootloader_conf "$dest/etc/calamares/modules"
        info "Done configuring [Calamares]"
    fi
}
