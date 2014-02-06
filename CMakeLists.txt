
# We define the minimum cmake. This is standard for elementary OS
cmake_minimum_required (VERSION 2.8)

#We define the minimum policy version
cmake_policy(VERSION 2.8)


#We define out project name.
project(birdie)

set (DATADIR "${CMAKE_INSTALL_PREFIX}/share")
set (PKGDATADIR "${DATADIR}/birdie")
set (GETTEXT_PACKAGE "birdie")
add_definitions(-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")
set (RELEASE_NAME "Flugas")
set (VERSION "1.1")

configure_file (${CMAKE_SOURCE_DIR}/src/config.vala.cmake ${CMAKE_SOURCE_DIR}/src/config.vala)

#Here we load the modules we downloaded earlier and placed into the ./cmake directory
list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake )

# Vala
find_package (Vala REQUIRED)
include (ValaVersion)
ensure_vala_version ("0.22.1" MINIMUM)
include (ValaPrecompile)

find_package(PkgConfig)
pkg_check_modules(LIBUNITY QUIET unity)
pkg_check_modules(LIBMESSAGINGMENU QUIET messaging-menu>=12.10.2)
pkg_check_modules(GRANITE QUIET granite)

# Packages
if (LIBUNITY_FOUND)
    message(STATUS "Unity support: ON")
    set(EXTRA_PKG_CONFIG
        ${EXTRA_PKG_CONFIG}
        unity
    )

    set(EXTRA_PACKAGES
        ${EXTRA_PACKAGES}
        unity
    )

    set(EXTRA_VALA_OPTIONS
        ${EXTRA_VALA_OPTIONS}
        -D HAVE_LIBUNITY
    )
else ()
    message(STATUS "Unity launcher support: OFF")
endif ()

if (LIBMESSAGINGMENU_FOUND)
    message(STATUS "Unity messaging menu support: ON")
    set(EXTRA_PKG_CONFIG
        ${EXTRA_PKG_CONFIG}
        messaging-menu
    )

    set(EXTRA_PACKAGES
        ${EXTRA_PACKAGES}
        MessagingMenu-1.0
    )

    set(EXTRA_VALA_OPTIONS
        ${EXTRA_VALA_OPTIONS}
        -D HAVE_LIBMESSAGINGMENU
    )
else ()
    message(STATUS "Unity messaging menu support: OFF")
endif ()

if (GRANITE_FOUND)
    message(STATUS "Granite support: ON")
    set(EXTRA_PKG_CONFIG
        ${EXTRA_PKG_CONFIG}
        granite
    )

    set(EXTRA_PACKAGES
        ${EXTRA_PACKAGES}
        granite
    )

    set(EXTRA_VALA_OPTIONS
        ${EXTRA_VALA_OPTIONS}
        -D HAVE_GRANITE
    )
else ()
    message(STATUS "Granite support: OFF")
endif ()

if (LIBUNITY_FOUND OR LIBMESSAGINGMENU_FOUND OR GRANITE_FOUND)
    set(EXTRA_PACKAGES
        ${EXTRA_PACKAGES}
        Dbusmenu-0.4
    )
endif ()

set(TARGET_GLIB 2.32)

pkg_check_modules(DEPS REQUIRED
	gtk+-3.0
    gtksourceview-3.0
    gee-1.0
	rest-0.7
	json-glib-1.0
	libnotify
	libcanberra
	gdk-x11-3.0
	webkitgtk-3.0
	sqlite3
	xtst
    purple
    gthread-2.0
	${EXTRA_PKG_CONFIG}
)

if (DEBUG)
  message (STATUS "DEBUG: ON")
  set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -g")
  set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -O0")
else ()
  message (STATUS "DEBUG: OFF")
  set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -O2")
  # ignore c warnings
  set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -w")
endif ()

set(CFLAGS
    ${DEPS_CFLAGS}
    ${DEPS_CFLAGS_OTHER}
    -D_VERSION=\"${VERSION}\"
    -D_INSTALL_PREFIX=\"${CMAKE_INSTALL_PREFIX}\"
    -D_SOURCE_ROOT_DIR=\"${CMAKE_SOURCE_DIR}\"
    -D_GSETTINGS_DIR=\"${CMAKE_BINARY_DIR}/gsettings\"
    -DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\"
    -DLANGUAGE_SUPPORT_DIRECTORY=\"${LANGUAGE_SUPPORT_DIRECTORY}\"
)

set(BIRDIE_PACKAGES
    gtk+-3.0 gtksourceview-3.0 libsoup-2.4 gee-1.0 rest-0.7 json-glib-1.0 libnotify>=0.7.5 libcanberra>=0.28 gdk-x11-3.0 webkitgtk-3.0 sqlite3 xtst purple posix ${EXTRA_PACKAGES}
)

set(VALAC_OPTIONS
    --vapidir=${CMAKE_SOURCE_DIR}/vapi
    --target-glib=${TARGET_GLIB}
    --thread
    --enable-deprecated
    --fatal-warnings
    ${EXTRA_VALA_OPTIONS}
)

set(LIB_PATHS ${DEPS_LIBRARY_DIRS})
link_directories(${LIB_PATHS})
add_definitions(${CFLAGS} "-DGETTEXT_PACKAGE=\"birdie\"")

configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake_uninstall.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake"
    IMMEDIATE @ONLY
)

add_custom_target(
    uninstall
    COMMAND
        ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake
    COMMAND
        ${glib_schema_compiler} ${GSETTINGS_DIR}
)

add_subdirectory(schemas)
add_subdirectory(icons)
add_subdirectory(data)
add_subdirectory (src)
add_subdirectory (po)