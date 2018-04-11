DIRMODE = -dm0755
MODE =  -m0755
RM = rm -f

CPIOHOOKS = \
	$(wildcard hooks/*)

CPIOINST = \
	$(wildcard install/*)

SCRIPT = \
	$(wildcard script/*)

install_initcpio:
	install $(DIRMODE) $(DESTDIR)$(CPIODIR)/hooks
	install $(MODE) $(CPIOHOOKS) $(DESTDIR)$(CPIODIR)/hooks

	install $(DIRMODE) $(DESTDIR)$(CPIODIR)/install
	install $(MODE) $(CPIOINST) $(DESTDIR)$(CPIODIR)/install
	install $(MODE) $(SCRIPT) $(DESTDIR)$(CPIODIR)

uninstall_initcpio:
	for f in $(notdir $(CPIOHOOKS)); do $(RM) $(DESTDIR)$(CPIODIR)/hooks/$$f; done
	for f in $(notdir $(CPIOINST)); do $(RM) $(DESTDIR)$(CPIODIR)/install/$$f; done
	for f in $(notdir $(SCRIPT)); do $(RM) $(DESTDIR)$(CPIODIR)/$$f; done

install: install_initcpio

uninstall: uninstall_initcpio

.PHONY: install uninstall
