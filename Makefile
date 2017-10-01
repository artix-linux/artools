Version=0.6

PREFIX = /usr/local
SYSCONFDIR = /etc

SYSCONF = \
	data/artools.conf

BIN_BASE = \
	bin/mkchroot \
	bin/basestrap \
	bin/artools-chroot \
	bin/fstabgen \
	bin/signfile \
	bin/chroot-run

LIBS_BASE = \
	lib/util.sh \
	lib/util-msg.sh \
	lib/util-mount.sh \
	lib/util-chroot.sh \
	lib/util-fstab.sh

SHARED_BASE = \
	$(wildcard data/pacman-*.conf)

LIST_IMPORT = \
	$(wildcard data/import.list.d/*.list)

BIN_PKG = \
	bin/checkpkg \
	bin/lddd \
	bin/finddeps \
	bin/findupdates \
	bin/find-libdeps \
	bin/mkchrootpkg \
	bin/buildpkg \
	bin/buildtree \
	bin/deploypkg

LIBS_PKG = \
	$(wildcard lib/util-pkg*.sh)

SHARED_PKG = \
	$(wildcard data/makepkg-*.conf)

PATCHES = \
	$(wildcard data/patches/*.patch)

BIN_ISO = \
	bin/buildiso \
	bin/deployiso \
	bin/buildyaml

LIBS_ISO = \
	$(wildcard lib/util-iso*.sh) \
	$(wildcard lib/util-yaml*.sh) \
	lib/util-profile.sh

SHARED_ISO = \
	data/mkinitcpio.conf \
	data/linux.preset

CPIOHOOKS = \
	$(wildcard initcpio/hooks/*)

CPIOINST = \
	$(wildcard initcpio/install/*)

CPIO = \
	initcpio/script/artix_shutdown

BASE = \
	$(wildcard data/base/Packages-*) \
	data/base/profile.conf

LIVE_ETC = \
	data/base/live-overlay/etc/issue \
	data/base/live-overlay/etc/fstab

LIVE_ETC_DEFAULT = \
	$(wildcard data/base/live-overlay/etc/default/*)

LIVE_ETC_PAM = \
	$(wildcard data/base/live-overlay/etc/pam.d/*)

LIVE_ETC_SUDOERS = \
	$(wildcard data/base/live-overlay/etc/sudoers.d/*)

all: $(BIN_BASE) $(BIN_PKG) $(BIN_ISO)

edit = sed -e "s|@datadir[@]|$(DESTDIR)$(PREFIX)/share/artools|g" \
	-e "s|@sysconfdir[@]|$(DESTDIR)$(SYSCONFDIR)/artools|g" \
	-e "s|@libdir[@]|$(DESTDIR)$(PREFIX)/lib/artools|g" \
	-e "s|@version@|${Version}|"

%: %.in Makefile
	@echo "GEN $@"
	@$(RM) "$@"
	@m4 -P $@.in | $(edit) >$@
	@chmod a-w "$@"
	@chmod +x "$@"

clean:
	rm -f $(BIN_BASE) ${BIN_PKG} ${BIN_ISO}

install_base:
	install -dm0755 $(DESTDIR)$(SYSCONFDIR)/artools
	install -m0644 ${SYSCONF} $(DESTDIR)$(SYSCONFDIR)/artools

	install -dm0755 $(DESTDIR)$(PREFIX)/bin
	install -m0755 ${BIN_BASE} $(DESTDIR)$(PREFIX)/bin

	install -dm0755 $(DESTDIR)$(PREFIX)/lib/artools
	install -m0644 ${LIBS_BASE} $(DESTDIR)$(PREFIX)/lib/artools

	install -dm0755 $(DESTDIR)$(PREFIX)/share/artools
	install -m0644 ${SHARED_BASE} $(DESTDIR)$(PREFIX)/share/artools

install_pkg:
	install -dm0755 $(DESTDIR)$(SYSCONFDIR)/artools/import.list.d
	install -m0644 ${LIST_IMPORT} $(DESTDIR)$(SYSCONFDIR)/artools/import.list.d

	install -dm0755 $(DESTDIR)$(PREFIX)/bin
	install -m0755 ${BIN_PKG} $(DESTDIR)$(PREFIX)/bin

	ln -sf buildpkg $(DESTDIR)$(PREFIX)/bin/buildpkg-testing

	ln -sf find-libdeps $(DESTDIR)$(PREFIX)/bin/find-libprovides

	install -dm0755 $(DESTDIR)$(PREFIX)/lib/artools
	install -m0644 ${LIBS_PKG} $(DESTDIR)$(PREFIX)/lib/artools

	install -dm0755 $(DESTDIR)$(PREFIX)/share/artools
	install -m0644 ${SHARED_PKG} $(DESTDIR)$(PREFIX)/share/artools

	install -dm0755 $(DESTDIR)$(PREFIX)/share/artools/patches
	install -m0644 ${PATCHES} $(DESTDIR)$(PREFIX)/share/artools/patches

install_isobase:
	install -dm0755 $(DESTDIR)$(PREFIX)/share/artools/iso-profiles/base
	install -m0644 ${BASE} $(DESTDIR)$(PREFIX)/share/artools/iso-profiles/base

	install -dm0755 $(DESTDIR)$(PREFIX)/share/artools/iso-profiles/base/live-overlay/etc
	install -m0644 ${LIVE_ETC} $(DESTDIR)$(PREFIX)/share/artools/iso-profiles/base/live-overlay/etc

	install -dm0755 $(DESTDIR)$(PREFIX)/share/artools/iso-profiles/base/live-overlay/etc/default
	install -m0644 ${LIVE_ETC_DEFAULT} $(DESTDIR)$(PREFIX)/share/artools/iso-profiles/base/live-overlay/etc/default

	install -dm0755 $(DESTDIR)$(PREFIX)/share/artools/iso-profiles/base/live-overlay/etc/pam.d
	install -m0644 ${LIVE_ETC_PAM} $(DESTDIR)$(PREFIX)/share/artools/iso-profiles/base/live-overlay/etc/pam.d

	install -dm0755 $(DESTDIR)$(PREFIX)/share/artools/iso-profiles/base/live-overlay/etc/sudoers.d
	install -m0644 ${LIVE_ETC_SUDOERS} $(DESTDIR)$(PREFIX)/share/artools/iso-profiles/base/live-overlay/etc/sudoers.d

install_iso:
	install -dm0755 $(DESTDIR)$(PREFIX)/bin
	install -m0755 ${BIN_ISO} $(DESTDIR)$(PREFIX)/bin

	ln -sf buildiso $(DESTDIR)$(PREFIX)/bin/buildiso-testing

	install -dm0755 $(DESTDIR)$(PREFIX)/lib/artools
	install -m0644 ${LIBS_ISO} $(DESTDIR)$(PREFIX)/lib/artools

	install -dm0755 $(DESTDIR)$(SYSCONFDIR)/initcpio/hooks
	install -m0755 ${CPIOHOOKS} $(DESTDIR)$(SYSCONFDIR)/initcpio/hooks

	install -dm0755 $(DESTDIR)$(SYSCONFDIR)/initcpio/install
	install -m0755 ${CPIOINST} $(DESTDIR)$(SYSCONFDIR)/initcpio/install

	install -m0755 ${CPIO} $(DESTDIR)$(SYSCONFDIR)/initcpio

	install -dm0755 $(DESTDIR)$(PREFIX)/share/artools
	install -m0644 ${SHARED_ISO} $(DESTDIR)$(PREFIX)/share/artools

uninstall_base:
	for f in ${SYSCONF}; do rm -f $(DESTDIR)$(SYSCONFDIR)/artools/$$f; done
	for f in ${BIN_BASE}; do rm -f $(DESTDIR)$(PREFIX)/bin/$$f; done
	for f in ${SHARED_BASE}; do rm -f $(DESTDIR)$(PREFIX)/share/artools/$$f; done
	for f in ${LIBS_BASE}; do rm -f $(DESTDIR)$(PREFIX)/lib/artools/$$f; done

uninstall_pkg:
	for f in ${LIST_IMPORT}; do rm -f $(DESTDIR)$(SYSCONFDIR)/artools/import.list.d/$$f; done
	for f in ${BIN_PKG}; do rm -f $(DESTDIR)$(PREFIX)/bin/$$f; done
	rm -f $(DESTDIR)$(PREFIX)/bin/find-libprovides
	rm -f $(DESTDIR)$(PREFIX)/bin/buildpkg-testing
	for f in ${SHARED_PKG}; do rm -f $(DESTDIR)$(PREFIX)/share/artools/$$f; done
	for f in ${PATCHES}; do rm -f $(DESTDIR)$(PREFIX)/share/artools/patches/$$f; done
	for f in ${LIBS_PKG}; do rm -f $(DESTDIR)$(PREFIX)/lib/artools/$$f; done

uninstall_isobase:
	for f in ${BASE}; do rm -f $(DESTDIR)$(PREFIX)/share/artools/iso-profiles/base/$$f; done
	for f in ${LIVE_ETC}; do rm -f $(DESTDIR)$(PREFIX)/share/artools/iso-profiles/base/live-overlay/etc/$$f; done
	for f in ${LIVE_ETC_DEFAULT}; do rm -f $(DESTDIR)$(PREFIX)/share/artools/iso-profiles/base/live-overlay/etc/default/$$f; done
	for f in ${LIVE_ETC_PAM}; do rm -f $(DESTDIR)$(PREFIX)/share/artools/iso-profiles/base/live-overlay/etc/pam.d/$$f; done
	for f in ${LIVE_ETC_SUDOERS}; do rm -f $(DESTDIR)$(PREFIX)/share/artools/iso-profiles/base/live-overlay/etc/sudoers.d/$$f; done

uninstall_iso:
	for f in ${BIN_ISO}; do rm -f $(DESTDIR)$(PREFIX)/bin/$$f; done
	rm -f $(DESTDIR)$(PREFIX)/bin/buildiso-testing
	for f in ${SHARED_ISO}; do rm -f $(DESTDIR)$(PREFIX)/share/artools/$$f; done

	for f in ${LIBS_ISO}; do rm -f $(DESTDIR)$(PREFIX)/lib/artools/$$f; done
	for f in ${CPIOHOOKS}; do rm -f $(DESTDIR)$(SYSCONFDIR)/initcpio/hooks/$$f; done
	for f in ${CPIOINST}; do rm -f $(DESTDIR)$(SYSCONFDIR)/initcpio/install/$$f; done
	for f in ${CPIO}; do rm -f $(DESTDIR)$(SYSCONFDIR)/initcpio/$$f; done

install: install_base install_pkg install_iso install_isobase

uninstall: uninstall_base uninstall_pkg uninstall_iso uninstall_isobase

dist:
	git archive --format=tar --prefix=artools-$(Version)/ $(Version) | gzip -9 > artools-$(Version).tar.gz
	gpg --detach-sign --use-agent artools-$(Version).tar.gz

.PHONY: all clean install uninstall dist
