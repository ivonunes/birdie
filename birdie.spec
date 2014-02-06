Name: birdie
Summary: A Twitter client for Linux
Version: 1.1
Release: 1
Group: Applications/Internet
License: GPLv3
URL: https://github.com/birdieapp/birdie
Source0: %{name}-%{version}.tar.gz
BuildRequires: cmake
BuildRequires: gcc-c++
BuildRequires: intltool
BuildRequires: vala-devel >= 0.22.1
BuildRequires: pkgconfig(glib-2.0)
BuildRequires: libpurple-devel
BuildRequires: pkgconfig(webkitgtk-3.0)
BuildRequires: sqlite-devel
BuildRequires: libXtst-devel
BuildRequires: libgee06-devel
BuildRequires: pkgconfig(rest-0.7)
BuildRequires: pkgconfig(gtk+-3.0)
BuildRequires: pkgconfig(json-glib-1.0)
BuildRequires: pkgconfig(libnotify)
BuildRequires: libcanberra-devel
BuildRequires: pkgconfig(gthread-2.0)
BuildRequires: pkgconfig(gtksourceview-3.0)
BuildRoot: %{_tmppath}/%{name}-%{version}-build

%if 0%{?suse_version} > 910
BuildRequires:  update-desktop-files
%endif

%description
Birdie is a beautiful Twitter client for Linux.

%prep
%setup -q

%build
cmake \
    -DCMAKE_INSTALL_PREFIX:PATH=%{_prefix}
make %{?_smp_mflags}

%install
%make_install

%post
%if 0%{?suse_version} > 910
%glib2_gsettings_schema_post
%icon_theme_cache_post
%desktop_database_post
%else
xdg-icon-resource forceupdate --theme hicolor
glib-compile-schemas /usr/share/glib-2.0/schemas
update-desktop-database -q
%endif

%postun
%if 0%{?suse_version} > 910
%glib2_gsettings_schema_postun
%icon_theme_cache_postun
%desktop_database_postun
%else
xdg-icon-resource forceupdate --theme hicolor
glib-compile-schemas /usr/share/glib-2.0/schemas
update-desktop-database -q
%endif

%files
%defattr(-,root,root)
%doc AUTHORS COPYING NEWS README.md
%{_bindir}/%{name}
%{_datadir}/%{name}/
%dir %{_datadir}/appdata
%dir %{_datadir}/locale
%dir %{_datadir}/indicators
%dir %{_datadir}/indicators/messages
%dir %{_datadir}/indicators/messages/applications
%dir %{_datadir}/locale/sr_RS@latin
%dir %{_datadir}/locale/*/*
%{_datadir}/glib-2.0/schemas/org.birdieapp.birdie.gschema.xml
%{_datadir}/appdata/%{name}.appdata.xml
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/*/*/*
%{_datadir}/locale/*/*/birdie.mo
%{_datadir}/indicators/messages/applications/birdie

%changelog
* Fri Feb 07 2014 Ivo Nunes <ivoavnunes@gmail.com> - 1.1
- Released.
* Sat Jan 26 2014 Ivo Nunes <ivoavnunes@gmail.com> - 1.0
- Released.