VERSION=0.8

CHROOT_VERSION=0.7

TOOLS = artools
ifdef PREFIX
PREFIX = /usr/local
endif
SYSCONFDIR = /etc
BINDIR = $(PREFIX)/bin
LIBDIR = $(PREFIX)/lib
DATADIR = $(PREFIX)/share

DIRMODE = -dm0755
FILEMODE = -m0644
MODE =  -m0755

LN = ln -sf
RM = rm -f
RMD = rm -fr --one-file-system
M4 = m4 -P
CHMODAW = chmod a-w
CHMODX = chmod +x

ifdef WITH-PKG
WITH-PKG = no
else
WITH-PKG = yes
endif
ifdef WITH-ISO
WITH-ISO = no
else
WITH-ISO = yes
endif

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

ifeq ($(WITH-PKG),yes)

all: $(BIN_PKG)

endif

ifeq ($(WITH-ISO),yes)

all: $(BIN_ISO)

endif

all: $(BIN_BASE)

EDIT = sed -e "s|@datadir[@]|$(DATADIR)/$(TOOLS)|g" \
	-e "s|@sysconfdir[@]|$(SYSCONFDIR)/$(TOOLS)|g" \
	-e "s|@libdir[@]|$(LIBDIR)/$(TOOLS)|g" \
	-e "s|@version@|$(VERSION)|" \
	-e "s|@chroot_version@|$(CHROOT_VERSION)|"

%: %.in Makefile
	@echo "GEN $@"
	@$(RM) "$@"
	@$(M4) $@.in | $(EDIT) >$@
	@$(CHMODAW) "$@"
	@$(CHMODX) "$@"

clean:
	$(RM) $(BIN_BASE) $(BIN_PKG) $(BIN_ISO)

install_base:
	install $(DIRMODE) $(DESTDIR)$(SYSCONFDIR)/$(TOOLS)
	install $(FILEMODE) $(SYSCONF) $(DESTDIR)$(SYSCONFDIR)/$(TOOLS)

	install $(DIRMODE) $(DESTDIR)$(BINDIR)
	install $(MODE) $(BIN_BASE) $(DESTDIR)$(BINDIR)

	install $(DIRMODE) $(DESTDIR)$(LIBDIR)/$(TOOLS)
	install $(FILEMODE) $(LIBS_BASE) $(DESTDIR)$(LIBDIR)/$(TOOLS)

	install $(DIRMODE) $(DESTDIR)$(DATADIR)/$(TOOLS)
	install $(FILEMODE) $(SHARED_BASE) $(DESTDIR)$(DATADIR)/$(TOOLS)

install_pkg:
	install $(DIRMODE) $(DESTDIR)$(BINDIR)
	install $(MODE) $(BIN_PKG) $(DESTDIR)$(BINDIR)

	$(LN) find-libdeps $(DESTDIR)$(BINDIR)/find-libprovides

	for l in $(COMMITPKG_SYMS); do $(LN) commitpkg $(DESTDIR)$(BINDIR)/$$l; done

	install $(DIRMODE) $(DESTDIR)$(LIBDIR)/$(TOOLS)
	install $(FILEMODE) $(LIBS_PKG) $(DESTDIR)$(LIBDIR)/$(TOOLS)

	install $(DIRMODE) $(DESTDIR)$(DATADIR)/$(TOOLS)
	install $(FILEMODE) $(SHARED_PKG) $(DESTDIR)$(DATADIR)/$(TOOLS)

	install $(DIRMODE) $(DESTDIR)$(DATADIR)/$(TOOLS)/patches
	install $(FILEMODE) $(PATCHES) $(DESTDIR)$(DATADIR)/$(TOOLS)/patches

install_iso:
	install $(DIRMODE) $(DESTDIR)$(BINDIR)
	install $(MODE) $(BIN_ISO) $(DESTDIR)$(BINDIR)

	for l in $(BIN_ISO_SYMS); do $(LN) buildiso $(DESTDIR)$(BINDIR)/$$l; done

	install $(DIRMODE) $(DESTDIR)$(LIBDIR)/$(TOOLS)
	install $(FILEMODE) $(LIBS_ISO) $(DESTDIR)$(LIBDIR)/$(TOOLS)

	install $(DIRMODE) $(DESTDIR)$(DATADIR)/$(TOOLS)
	install $(FILEMODE) $(SHARED_ISO) $(DESTDIR)$(DATADIR)/$(TOOLS)

	install $(DIRMODE) $(DESTDIR)$(SYSCONFDIR)/initcpio/hooks
	install $(MODE) $(CPIOHOOKS) $(DESTDIR)$(SYSCONFDIR)/initcpio/hooks

	install $(DIRMODE) $(DESTDIR)$(SYSCONFDIR)/initcpio/install
	install $(MODE) $(CPIOINST) $(DESTDIR)$(SYSCONFDIR)/initcpio/install
	install $(MODE) $(CPIO) $(DESTDIR)$(SYSCONFDIR)/initcpio

install_base_profile:
	make OVERLAYDIR=$(OVERLAYDIR) PROFDIR=$(PROFDIR) DESTDIR=$(DESTDIR) -C data/base install

uninstall_base:
	for f in $(notdir $(SYSCONF)); do $(RM) $(DESTDIR)$(SYSCONFDIR)/$(TOOLS)/$$f; done
	for f in $(notdir $(BIN_BASE)); do $(RM) $(DESTDIR)$(BINDIR)/$$f; done
	for f in $(notdir $(LIBS_BASE)); do $(RM) $(DESTDIR)$(LIBDIR)/$(TOOLS)/$$f; done
	for f in $(notdir $(SHARED_BASE)); do $(RM) $(DESTDIR)$(DATADIR)/$(TOOLS)/$$f; done
	$(RMD) $(DESTDIR)$(SYSCONFDIR)/$(TOOLS)
	$(RMD) $(DESTDIR)$(LIBDIR)/$(TOOLS)
	$(RMD) $(DESTDIR)$(DATADIR)/$(TOOLS)

uninstall_pkg:
	for f in $(notdir $(BIN_PKG)); do $(RM) $(DESTDIR)$(BINDIR)/$$f; done
	$(RM) $(DESTDIR)$(BINDIR)/find-libprovides
	for l in $(COMMITPKG_SYMS); do $(RM) $(DESTDIR)$(BINDIR)/$$l; done
	for f in $(notdir $(LIBS_PKG)); do $(RM) $(DESTDIR)$(LIBDIR)/$(TOOLS)/$$f; done
	for f in $(notdir $(PATCHES)); do $(RM) $(DESTDIR)$(DATADIR)/$(TOOLS)/patches/$$f; done
	for f in $(notdir $(SHARED_PKG)); do $(RM) $(DESTDIR)$(DATADIR)/$(TOOLS)/$$f; done

uninstall_iso:
	for f in $(notdir $(BIN_ISO)); do $(RM) $(DESTDIR)$(BINDIR)/$$f; done
	for l in $(notdir $(BIN_ISO_SYMS)); do $(RM) $(DESTDIR)$(BINDIR)/$$l; done
	for f in $(notdir $(LIBS_ISO)); do $(RM) $(DESTDIR)$(LIBDIR)/$(TOOLS)/$$f; done
	for f in $(notdir $(SHARED_ISO)); do $(RM) $(DESTDIR)$(DATADIR)/$(TOOLS)/$$f; done

	for f in $(notdir $(CPIOHOOKS)); do $(RM) $(DESTDIR)$(SYSCONFDIR)/initcpio/hooks/$$f; done
	for f in $(notdir $(CPIOINST)); do $(RM) $(DESTDIR)$(SYSCONFDIR)/initcpio/install/$$f; done
	for f in $(notdir $(CPIO)); do $(RM) $(DESTDIR)$(SYSCONFDIR)/initcpio/$$f; done

uninstall_base_profile:
	make OVERLAYDIR=$(OVERLAYDIR) PROFDIR=$(PROFDIR) DESTDIR=$(DESTDIR) -C data/base uninstall

ifeq ($(WITH-PKG),yes)

install: install_pkg

uninstall: uninstall_pkg

endif

ifeq ($(WITH-ISO),yes)

install: install_iso install_base_profile

uninstall: uninstall_iso uninstall_base_profile

endif

install: install_base

uninstall: uninstall_base

dist:
	git archive --format=tar --prefix=$(TOOLS)-$(VERSION)/ $(VERSION) | gzip -9 > $(TOOLS)-$(VERSION).tar.gz
	gpg --detach-sign --use-agent $(TOOLS)-$(VERSION).tar.gz

.PHONY: all clean install uninstall dist
