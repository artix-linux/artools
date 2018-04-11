artools
=============

#### Make flags


* PREFIX=/usr/local (if defined)
* SYSCONFDIR=/etc
* WITH-PKG0=yes
* WITH-ISO=yes


#### Dependencies

##### Buildtime:

* make
* git
* m4

##### Runtime:

- base:

  * openssh
  * rsync
  * haveged
  * os-prober
  * gnupg
  * pacman

- pkg:

  * namcap
  * git

- iso:
  * dosfstools
  * libisoburn
  * squashfs-tools
  * mkinitcpio
  * mktorrent
  * grub

#### Configuration

artools.conf is the central configuration file for artools.
By default, the config is installed in

    /etc/artools/artools.conf

A user artools.conf can be placed in

    $HOME/.config/artools/artools.conf


If the userconfig is present, artools will load the userconfig values, however, if variables have been set in the systemwide

These values take precedence over the userconfig.
Best practise is to leave systemwide file untouched.
By default it is commented and shows just initialization values done in code.

Tools configuration is done in artools.conf or by args.
Specifying args will override artools.conf settings.

Both, pacman.conf and makepkg.conf for chroots are loaded from

    /usr/share/artools/{makepkg,pacman-*}.conf

and can be overridden dropping them in

    $HOME/.config/artools/
