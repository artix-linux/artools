DIRMODE = -dm0755
MODE =  -m0755

CPIOHOOKS = \
	$(wildcard hooks/*)

CPIOINST = \
	$(wildcard install/*)

CPIO = \
	$(wildcard script/*)

install_initcpio:
	install $(DIRMODE) $(DESTDIR)$(SYSCONFDIR)/initcpio/hooks
	install $(MODE) $(CPIOHOOKS) $(DESTDIR)$(SYSCONFDIR)/initcpio/hooks

	install $(DIRMODE) $(DESTDIR)$(SYSCONFDIR)/initcpio/install
	install $(MODE) $(CPIOINST) $(DESTDIR)$(SYSCONFDIR)/initcpio/install
	install $(MODE) $(CPIO) $(DESTDIR)$(SYSCONFDIR)/initcpio

uninstall_initcpio:
	for f in $(notdir $(CPIOHOOKS)); do $(RM) $(DESTDIR)$(SYSCONFDIR)/initcpio/hooks/$$f; done
	for f in $(notdir $(CPIOINST)); do $(RM) $(DESTDIR)$(SYSCONFDIR)/initcpio/install/$$f; done
	for f in $(notdir $(CPIO)); do $(RM) $(DESTDIR)$(SYSCONFDIR)/initcpio/$$f; done

install: install_initcpio

uninstall: uninstall_initcpio

.PHONY: install uninstall
