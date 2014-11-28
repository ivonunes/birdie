resource_files = $(shell $(GLIB_COMPILE_RESOURCES) --sourcedir=$(srcdir) --sourcedir=$(builddir) --generate-dependencies $(srcdir)/birdie.gresource.xml) 
birdie.gresource: birdie.gresource.xml $(resource_files)
	$(AM_V_GEN) $(GLIB_COMPILE_RESOURCES) --target=$@ --sourcedir=$(srcdir) $<

resourcedir = $(pkgdatadir)
resource_DATA = birdie.gresource

defaultimgdir = $(pkgdatadir)
defaultimg_DATA = default.png

appsdir = $(datadir)/applications
apps_DATA = birdie.desktop

@INTLTOOL_DESKTOP_RULE@

appdatadir = $(datadir)/appdata
appdata_DATA = $(appdata_in_files:.xml.in=.xml)
appdata_in_files = birdie.appdata.xml.in

@INTLTOOL_XML_RULE@

icon1dir = $(datadir)/icons/hicolor/24x24/actions
icon1_DATA = icons/hicolor/24x24/actions/twitter-delete.svg
icon2dir = $(datadir)/icons/hicolor/24x24/actions
icon2_DATA = icons/hicolor/24x24/actions/twitter-dm.svg
icon3dir = $(datadir)/icons/hicolor/24x24/actions
icon3_DATA = icons/hicolor/24x24/actions/twitter-fav.svg
icon4dir = $(datadir)/icons/hicolor/24x24/actions
icon4_DATA = icons/hicolor/24x24/actions/twitter-favd.svg
icon5dir = $(datadir)/icons/hicolor/24x24/actions
icon5_DATA = icons/hicolor/24x24/actions/twitter-home.svg
icon6dir = $(datadir)/icons/hicolor/24x24/actions
icon6_DATA = icons/hicolor/24x24/actions/twitter-mentions.svg
icon7dir = $(datadir)/icons/hicolor/24x24/actions
icon7_DATA = icons/hicolor/24x24/actions/twitter-mentions-urgent.svg
icon8dir = $(datadir)/icons/hicolor/24x24/actions
icon8_DATA = icons/hicolor/24x24/actions/twitter-profile.svg
icon9dir = $(datadir)/icons/hicolor/24x24/actions
icon9_DATA = icons/hicolor/24x24/actions/twitter-reply.svg
icon10dir = $(datadir)/icons/hicolor/24x24/actions
icon10_DATA = icons/hicolor/24x24/actions/twitter-retweet.svg
icon11dir = $(datadir)/icons/hicolor/24x24/actions
icon11_DATA = icons/hicolor/24x24/actions/twitter-retweeted.svg
icon12dir = $(datadir)/icons/hicolor/24x24/actions
icon12_DATA = icons/hicolor/24x24/actions/twitter-search.svg
icon13dir = $(datadir)/icons/hicolor/24x24/actions
icon13_DATA = icons/hicolor/24x24/actions/twitter-thread.svg
icon14dir = $(datadir)/icons/hicolor/24x24/actions
icon14_DATA = icons/hicolor/24x24/actions/twitter-verified.png

appicon16dir = $(datadir)/icons/hicolor/16x16/apps
appicon16_DATA = icons/hicolor/16x16/apps/birdie.png
appicon22dir = $(datadir)/icons/hicolor/22x22/apps
appicon22_DATA = icons/hicolor/22x22/apps/birdie.png
appicon32dir = $(datadir)/icons/hicolor/32x32/apps
appicon32_DATA = icons/hicolor/32x32/apps/birdie.png
appicon48dir = $(datadir)/icons/hicolor/48x48/apps
appicon48_DATA = icons/hicolor/48x48/apps/birdie.png
appicon256dir = $(datadir)/icons/hicolor/256x256/apps
appicon256_DATA = icons/hicolor/256x256/apps/birdie.png
appiconscalabledir = $(datadir)/icons/hicolor/scalable/apps
appiconscalable_DATA = icons/hicolor/scalable/apps/birdie.svg

messagesfiledir = $(datadir)/indicators/messages/applications
messagesfile_DATA = birdie

# icons
icon_files = \
    $(icon1_DATA) \
    $(icon2_DATA) \
    $(icon3_DATA) \
    $(icon4_DATA) \
    $(icon5_DATA) \
    $(icon6_DATA) \
    $(icon7_DATA) \
    $(icon8_DATA) \
    $(icon9_DATA) \
    $(icon10_DATA) \
    $(icon11_DATA) \
    $(icon12_DATA) \
    $(icon13_DATA) \
    $(icon14_DATA) \
	$(appicon16_DATA) \
	$(appicon22_DATA) \
	$(appicon32_DATA) \
	$(appicon48_DATA) \
	$(appicon256_DATA) \
    $(appiconscalable_DATA)

gtk_update_icon_cache = gtk-update-icon-cache -f -t $(datadir)/icons/hicolor

install-data-hook: update-icon-cache
uninstall-hook: update-icon-cache
update-icon-cache:
	@-if test -z "$(DESTDIR)"; then \
		echo "Updating Gtk icon cache."; \
		$(gtk_update_icon_cache); \
	else \
		echo "*** Icon cache not updated.  After (un)install, run this:"; \
		echo "***   $(gtk_update_icon_cache)"; \
	fi


gsettings_SCHEMAS = org.birdie-app.Birdie.gschema.xml

# For uninstalled use
gschemas.compiled: $(gsettings_SCHEMAS) Makefile
	$(AM_V_GEN) $(GLIB_COMPILE_SCHEMAS) $(builddir)

@GSETTINGS_RULES@

EXTRA_DIST = \
	$(icon_files) \
	$(resource_files) \
    $(defaultimg_DATA) \
	birdie.appdata.xml.in \
	birdie.desktop.in \
	birdie.gresource.xml \
	org.birdie-app.Birdie.gschema.xml \
	$(NULL)

CLEANFILES = \
	birdie.gresource \
	birdie.appdata.xml \
	$(apps_DATA) \
	*.valid \
	gschemas.compiled \
	$(NULL)

all-local: gschemas.compiled

-include $(top_srcdir)/git.mk
