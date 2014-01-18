Name: birdie
Summary: A Twitter client for Linux
Version: 0.3
Release: 1
Group: Applications/Internet
License: GPLv3
URL: https://github.com/birdieapp/birdie
Source0: %{name}-%{version}.tar.gz
BuildRequires: cmake
BuildRequires: vala-devel
BuildRequires: libpurple-devel
BuildRequires: webkitgtk3-devel
BuildRequires: sqlite-devel
BuildRequires: libXtst-devel
BuildRequires: libgee06-devel
BuildRequires: rest-devel
BuildRequires: json-glib-devel
BuildRequires: libcanberra-devel
BuildRequires: libnotify-devel
BuildRequires: libdbusmenu-devel

%description
Birdie is a beautiful Twitter client for Linux.

%prep
%setup -q
sed -i '/--fatal-warnings/d' src/CMakeLists.txt

%build
%cmake
make

%install
%make_install

%post
xdg-icon-resource forceupdate --theme hicolor
glib-compile-schemas /usr/share/glib-2.0/schemas
update-desktop-database -q

%files
%doc AUTHORS COPYING NEWS README.md
%{_bindir}/birdie
%{_datadir}/applications/birdie.desktop
%{_datadir}/birdie/default.png
%{_datadir}/glib-2.0/schemas/org.birdieapp.birdie.gschema.xml
%{_datadir}/appdata/birdie.appdata.xml
%{_datadir}/icons/hicolor/*/*/*
%{_datadir}/indicators/messages/applications/birdie
%{_datadir}/locale/*/LC_MESSAGES/birdie.mo

%changelog
* Sat Jan 18 2014 Ivo Nunes <ivoavnunes@gmail.com> - 0.3
- Initial packaging.
