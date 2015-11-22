AC_PREREQ(2.63)
AC_INIT([birdie],
        [2.0],
        [https://github.com/birdieapp/birdie/issues/new],
        [birdie],
        [http://www.birdieapp.eu/])
AC_CONFIG_MACRO_DIR([m4])
AC_CONFIG_SRCDIR([Makefile.am])
AC_CONFIG_HEADERS(config.h)
AM_INIT_AUTOMAKE([1.11 tar-ustar dist-xz no-dist-gzip -Wno-portability subdir-objects])
AM_MAINTAINER_MODE([enable])
m4_ifdef([AM_SILENT_RULES],[AM_SILENT_RULES([yes])])

AM_PATH_PYTHON([2])

GETTEXT_PACKAGE=birdie
AC_SUBST(GETTEXT_PACKAGE)
AC_DEFINE_UNQUOTED(GETTEXT_PACKAGE, "$GETTEXT_PACKAGE",
                   [The prefix for our gettext translation domains.])
IT_PROG_INTLTOOL(0.26)

YELP_HELP_INIT

AC_PROG_CC
AM_PROG_CC_C_O
LT_INIT([disable-static])

PKG_PROG_PKG_CONFIG([0.22])

GLIB_GSETTINGS
GOBJECT_INTROSPECTION_REQUIRE([1.35.9])
PKG_CHECK_MODULES([GTK], [gtk+-3.0 >= 3.8])
PKG_CHECK_EXISTS([gtk+-3.0 >= 3.9.0], [GTK_OR_GD=Gtk], [GTK_OR_GD=Gd])
AC_SUBST(GTK_OR_GD)

GLIB_COMPILE_RESOURCES=`$PKG_CONFIG --variable glib_compile_resources gio-2.0`
AC_SUBST(GLIB_COMPILE_RESOURCES)

AC_CONFIG_FILES([
  Makefile
  data/Makefile
  birdieapp/Makefile
  birdieapp/api/Makefile
  birdieapp/gui/Makefile
  birdieapp/utils/Makefile
  birdieapp/twython/Makefile
  birdieapp/twython/streaming/Makefile
  po/Makefile.in
])
AC_OUTPUT
