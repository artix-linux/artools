DIRMODE = -dm0755
MODE =  -m0755

CPIOHOOKS = \
	$(wildcard hooks/*)

CPIOINST = \
	$(wildcard install/*)

CPIO = \
	$(wildcard script/*)

install_initcpio:
	install $(DIRMODE) $(DESTDIR)$(CPIODIR)/hooks
	install $(MODE) $(CPIOHOOKS) $(DESTDIR)$(CPIODIR)/hooks

	install $(DIRMODE) $(DESTDIR)$(CPIODIR)/install
	install $(MODE) $(CPIOINST) $(DESTDIR)$(CPIODIR)/install
	install $(MODE) $(CPIO) $(DESTDIR)$(CPIODIR)

uninstall_initcpio:
	for f in $(notdir $(CPIOHOOKS)); do $(RM) $(DESTDIR)$(CPIODIR)/hooks/$$f; done
	for f in $(notdir $(CPIOINST)); do $(RM) $(DESTDIR)$(CPIODIR)/install/$$f; done
	for f in $(notdir $(CPIO)); do $(RM) $(DESTDIR)$(CPIODIR)/$$f; done

install: install_initcpio

uninstall: uninstall_initcpio

.PHONY: install uninstall
