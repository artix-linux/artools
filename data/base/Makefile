DIRMODE = -dm0755
FILEMODE = -m0644
RMD = rm -fr --one-file-system
RM = rm -f

BASE = \
	$(wildcard Packages-*) \
	profile.conf

LIVE_ETC = \
	live-overlay/etc/fstab \
	live-overlay/etc/issue

LIVE_ETC_DEFAULT = \
	$(wildcard live-overlay/etc/default/*)

LIVE_ETC_PAM = \
	$(wildcard live-overlay/etc/pam.d/*)

LIVE_ETC_SUDOERS = \
	$(wildcard live-overlay/etc/sudoers.d/*)

install_isobase:
	install $(DIRMODE) $(DESTDIR)$(PROFDIR)
	install $(FILEMODE) $(BASE) $(DESTDIR)$(PROFDIR)

	install $(DIRMODE) $(DESTDIR)$(OVERLAYDIR)
	install $(FILEMODE) $(LIVE_ETC) $(DESTDIR)$(OVERLAYDIR)

	install $(DIRMODE) $(DESTDIR)$(OVERLAYDIR)/default
	install $(FILEMODE) $(LIVE_ETC_DEFAULT) $(DESTDIR)$(OVERLAYDIR)/default

	install $(DIRMODE) $(DESTDIR)$(OVERLAYDIR)/pam.d
	install $(FILEMODE) $(LIVE_ETC_PAM) $(DESTDIR)$(OVERLAYDIR)/pam.d

	install $(DIRMODE) $(DESTDIR)$(OVERLAYDIR)/sudoers.d
	install $(FILEMODE) $(LIVE_ETC_SUDOERS) $(DESTDIR)$(OVERLAYDIR)/sudoers.d

uninstall_isobase:
	for f in $(notdir $(BASE)); do $(RM) $(DESTDIR)$(PROFDIR)/$$f; done
	for f in $(notdir $(LIVE_ETC)); do $(RM) $(DESTDIR)$(OVERLAYDIR)/$$f; done
	for f in $(notdir $(LIVE_ETC_DEFAULT)); do $(RM) $(DESTDIR)$(OVERLAYDIR)/default/$$f; done
	for f in $(notdir $(LIVE_ETC_PAM)); do $(RM) $(DESTDIR)$(OVERLAYDIR)/pam.d/$$f; done
	for f in $(notdir $(LIVE_ETC_SUDOERS)); do $(RM) $(DESTDIR)$(OVERLAYDIR)/sudoers.d/$$f; done
	$(RMD) $(DESTDIR)$(PROFDIR)


install: install_isobase

uninstall: uninstall_isobase

.PHONY: install uninstall
