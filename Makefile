VERSION=0.8

CHROOT_VERSION=0.7

TOOLS = artools
PREFIX = /usr/local
SYSCONFDIR = /etc
BINDIR = $(PREFIX)/bin
LIBDIR = $(PREFIX)/lib
DATADIR = $(PREFIX)/share

DIRMODE = -dm0755
FILEMODE = -m0644

WITH-ISO = yes
WITH-PKG = yes

PROFDIR = $(DATADIR)/$(TOOLS)/iso-profiles/base
OVERLAYDIR = $(PROFDIR)/live-overlay/etc

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
	$(wildcard data/pacman*.conf)

BIN_PKG = \
	bin/checkpkg \
	bin/lddd \
	bin/finddeps \
	bin/find-libdeps \
	bin/mkchrootpkg \
	bin/buildpkg \
	bin/buildtree \
	bin/deploypkg \
	bin/commitpkg \
	bin/mkpkgclean

LIBS_PKG = \
	$(wildcard lib/util-pkg*.sh)

SHARED_PKG = \
	data/makepkg.conf

PATCHES = \
	$(wildcard data/patches/*.patch)

COMMITPKG_SYMS = \
	extrapkg \
	corepkg \
	testingpkg \
	stagingpkg \
	communitypkg \
	community-testingpkg \
	community-stagingpkg \
	multilibpkg \
	multilib-testingpkg \
	multilib-stagingpkg

BIN_ISO = \
	bin/buildiso \
	bin/deployiso

BIN_ISO_SYMS = \
	buildiso-gremlins \
	buildiso-goblins

LIBS_ISO = \
	$(wildcard lib/util-iso*.sh)

SHARED_ISO = \
	data/mkinitcpio.conf

CPIOHOOKS = \
	$(wildcard initcpio/hooks/*)

CPIOINST = \
	$(wildcard initcpio/install/*)

CPIO = \
	$(wildcard initcpio/script/*)

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

EDIT = sed -e "s|@datadir[@]|$(DATADIR)/$(TOOLS)|g" \
	-e "s|@sysconfdir[@]|$(SYSCONFDIR)/$(TOOLS)|g" \
	-e "s|@libdir[@]|$(LIBDIR)/$(TOOLS)|g" \
	-e "s|@version@|${VERSION}|" \
	-e "s|@chroot_version@|${CHROOT_VERSION}|"

RM = rm -f
M4 = m4 -P
CHMODAW = chmod a-w
CHMODX = chmod +x

%: %.in Makefile
	@echo "GEN $@"
	@$(RM) "$@"
	@$(M4) $@.in | $(EDIT) >$@
	@$(CHMODAW) "$@"
	@$(CHMODX) "$@"

clean:
	rm -f $(BIN_BASE) ${BIN_PKG} ${BIN_ISO}

install_base:
	install $(DIRMODE) $(DESTDIR)$(SYSCONFDIR)/$(TOOLS)
	install $(FILEMODE) ${SYSCONF} $(DESTDIR)$(SYSCONFDIR)/$(TOOLS)

	install $(DIRMODE) $(DESTDIR)$(BINDIR)
	install $(FILEMODE) ${BIN_BASE} $(DESTDIR)$(BINDIR)

	install $(DIRMODE) $(DESTDIR)$(LIBDIR)/$(TOOLS)
	install $(FILEMODE) ${LIBS_BASE} $(DESTDIR)$(LIBDIR)/$(TOOLS)

	install $(DIRMODE) $(DESTDIR)$(DATADIR)/$(TOOLS)
	install $(FILEMODE) ${SHARED_BASE} $(DESTDIR)$(DATADIR)/$(TOOLS)

install_pkg:
	install $(DIRMODE) $(DESTDIR)$(BINDIR)
	install $(FILEMODE) ${BIN_PKG} $(DESTDIR)$(BINDIR)

	ln -sf find-libdeps $(DESTDIR)$(BINDIR)/find-libprovides

	for l in ${COMMITPKG_SYMS}; do ln -sf commitpkg $(DESTDIR)$(BINDIR)/$$l; done

	install $(DIRMODE) $(DESTDIR)$(LIBDIR)/$(TOOLS)
	install $(FILEMODE) ${LIBS_PKG} $(DESTDIR)$(LIBDIR)/$(TOOLS)

	install $(DIRMODE) $(DESTDIR)$(DATADIR)/$(TOOLS)
	install $(FILEMODE) ${SHARED_PKG} $(DESTDIR)$(DATADIR)/$(TOOLS)

	install $(DIRMODE) $(DESTDIR)$(DATADIR)/$(TOOLS)/patches
	install $(FILEMODE) ${PATCHES} $(DESTDIR)$(DATADIR)/$(TOOLS)/patches

install_isobase:
	install $(DIRMODE) $(DESTDIR)$(PROFDIR)
	install $(FILEMODE) ${BASE} $(DESTDIR)$(PROFDIR)

	install $(DIRMODE) $(DESTDIR)$(OVERLAYDIR)
	install $(FILEMODE) ${LIVE_ETC} $(DESTDIR)$(OVERLAYDIR)

	install $(DIRMODE) $(DESTDIR)$(OVERLAYDIR)/default
	install $(FILEMODE) ${LIVE_ETC_DEFAULT} $(DESTDIR)$(OVERLAYDIR)/default

	install $(DIRMODE) $(DESTDIR)$(OVERLAYDIR)/pam.d
	install $(FILEMODE) ${LIVE_ETC_PAM} $(DESTDIR)$(OVERLAYDIR)/pam.d

	install $(DIRMODE) $(DESTDIR)$(OVERLAYDIR)/sudoers.d
	install $(FILEMODE) ${LIVE_ETC_SUDOERS} $(DESTDIR)$(OVERLAYDIR)/sudoers.d

install_iso:
	install $(DIRMODE) $(DESTDIR)$(BINDIR)
	install $(FILEMODE) ${BIN_ISO} $(DESTDIR)$(BINDIR)

	for l in ${BIN_ISO_SYMS}; do ln -sf buildiso $(DESTDIR)$(BINDIR)/$$l; done

	install $(DIRMODE) $(DESTDIR)$(LIBDIR)/$(TOOLS)
	install $(FILEMODE) ${LIBS_ISO} $(DESTDIR)$(LIBDIR)/$(TOOLS)

	install $(DIRMODE) $(DESTDIR)$(DATADIR)/$(TOOLS)
	install $(FILEMODE) ${SHARED_ISO} $(DESTDIR)$(DATADIR)/$(TOOLS)

	install $(DIRMODE) $(DESTDIR)$(SYSCONFDIR)/initcpio/hooks
	install $(FILEMODE) ${CPIOHOOKS} $(DESTDIR)$(SYSCONFDIR)/initcpio/hooks

	install $(DIRMODE) $(DESTDIR)$(SYSCONFDIR)/initcpio/install
	install $(FILEMODE) ${CPIOINST} $(DESTDIR)$(SYSCONFDIR)/initcpio/install
	install $(FILEMODE) ${CPIO} $(DESTDIR)$(SYSCONFDIR)/initcpio

uninstall_base:
	for f in $(notdir ${SYSCONF}); do rm -f $(DESTDIR)$(SYSCONFDIR)/$(TOOLS)/$$f; done
	for f in $(notdir ${BIN_BASE}); do rm -f $(DESTDIR)$(BINDIR)/$$f; done
	for f in $(notdir ${LIBS_BASE}); do rm -f $(DESTDIR)$(LIBDIR)/$(TOOLS)/$$f; done
	for f in $(notdir ${SHARED_BASE}); do rm -f $(DESTDIR)$(DATADIR)/$(TOOLS)/$$f; done
	rm -rf --one-file-system $(DESTDIR)$(SYSCONFDIR)/$(TOOLS)
	rm -rf --one-file-system $(DESTDIR)$(LIBDIR)/$(TOOLS)
	rm -rf --one-file-system $(DESTDIR)$(DATADIR)/$(TOOLS)

uninstall_pkg:
	for f in $(notdir ${BIN_PKG}); do rm -f $(DESTDIR)$(BINDIR)/$$f; done
	rm -f $(DESTDIR)$(BINDIR)/find-libprovides
	for l in ${COMMITPKG_SYMS}; do rm -f $(DESTDIR)$(BINDIR)/$$l; done
	for f in $(notdir ${LIBS_PKG}); do rm -f $(DESTDIR)$(LIBDIR)/$(TOOLS)/$$f; done
	for f in $(notdir ${PATCHES}); do rm -f $(DESTDIR)$(DATADIR)/$(TOOLS)/patches/$$f; done
	for f in $(notdir ${SHARED_PKG}); do rm -f $(DESTDIR)$(DATADIR)/$(TOOLS)/$$f; done

uninstall_isobase:
	for f in $(notdir ${BASE}); do rm -f $(DESTDIR)$(PROFDIR)/$$f; done
	for f in $(notdir ${LIVE_ETC}); do rm -f $(DESTDIR)$(OVERLAYDIR)/$$f; done
	for f in $(notdir ${LIVE_ETC_DEFAULT}); do rm -f $(DESTDIR)$(OVERLAYDIR)/default/$$f; done
	for f in $(notdir ${LIVE_ETC_PAM}); do rm -f $(DESTDIR)$(OVERLAYDIR)/pam.d/$$f; done
	for f in $(notdir ${LIVE_ETC_SUDOERS}); do rm -f $(DESTDIR)$(OVERLAYDIR)/sudoers.d/$$f; done

uninstall_iso:
	for f in $(notdir ${BIN_ISO}); do rm -f $(DESTDIR)$(BINDIR)/$$f; done
	for l in $(notdir ${BIN_ISO_SYMS}); do rm -f $(DESTDIR)$(BINDIR)/$$l; done
	for f in $(notdir ${LIBS_ISO}); do rm -f $(DESTDIR)$(LIBDIR)/$(TOOLS)/$$f; done
	for f in $(notdir ${SHARED_ISO}); do rm -f $(DESTDIR)$(DATADIR)/$(TOOLS)/$$f; done

	for f in $(notdir ${CPIOHOOKS}); do rm -f $(DESTDIR)$(SYSCONFDIR)/initcpio/hooks/$$f; done
	for f in $(notdir ${CPIOINST}); do rm -f $(DESTDIR)$(SYSCONFDIR)/initcpio/install/$$f; done
	for f in $(notdir ${CPIO}); do rm -f $(DESTDIR)$(SYSCONFDIR)/initcpio/$$f; done

ifeq ($(WITH-PKG),yes)

install: install_pkg

uninstall: uninstall_pkg

endif

ifeq ($(WITH-ISO),yes)

install: install_iso install_isobase

uninstall: uninstall_iso uninstall_isobase

endif

install: install_base

uninstall: uninstall_base

dist:
	git archive --format=tar --prefix=$(TOOLS)-$(VERSION)/ $(VERSION) | gzip -9 > $(TOOLS)-$(VERSION).tar.gz
	gpg --detach-sign --use-agent $(TOOLS)-$(VERSION).tar.gz

.PHONY: all clean install uninstall dist
