# Vala
find_package(Vala REQUIRED)
include(ValaVersion)
ensure_vala_version("0.17.4" MINIMUM)
include(ValaPrecompile)

# Packages
if (LIBINDICATE_FOUND)
    message(STATUS "Indicate support: ON")
    set(EXTRA_PKG_CONFIG
        ${EXTRA_PKG_CONFIG}
        indicate-0.7
    )

    set(EXTRA_PACKAGES
        ${EXTRA_PACKAGES}
        Indicate-0.7
    )

    set(EXTRA_VALA_OPTIONS
        ${EXTRA_VALA_OPTIONS}
        -D HAVE_LIBINDICATE
    )
else ()
    message(STATUS "Indicate support: OFF")
endif ()

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
    message(STATUS "Unity support: OFF")
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

set(TARGET_GLIB 2.32)

pkg_check_modules(DEPS REQUIRED
	gtk+-3.0
	rest-0.7
	json-glib-1.0
	libnotify
	libcanberra
	libwnck-3.0
	gdk-x11-3.0
	webkitgtk-3.0
	sqlite3
	xtst
    purple
	${EXTRA_PKG_CONFIG}
)

set(CFLAGS
    ${DEPS_CFLAGS}
    ${DEPS_CFLAGS_OTHER}
    -D_VERSION=\"${VERSION}\"
    -D_INSTALL_PREFIX=\"${CMAKE_INSTALL_PREFIX}\"
    -D_SOURCE_ROOT_DIR=\"${CMAKE_SOURCE_DIR}\"
    -D_GSETTINGS_DIR=\"${CMAKE_BINARY_DIR}/gsettings\"
    -DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\"
    -DLANGUAGE_SUPPORT_DIRECTORY=\"${LANGUAGE_SUPPORT_DIRECTORY}\"
    -g
)

if (NOT DEBUG)
    set(CFLAGS
        ${CFLAGS}
        -O2
    )
endif ()

set(BIRDIE_PACKAGES
    gtk+-3.0 rest-0.7 json-glib-1.0 libnotify>=0.7.5 libcanberra>=0.28
 Dbusmenu-0.4 libwnck-3.0 gdk-x11-3.0 webkitgtk-3.0 sqlite3 xtst purple ${EXTRA_PACKAGES}
)

set(VALAC_OPTIONS
    --vapidir=${CMAKE_SOURCE_DIR}/vapi
    --target-glib=${TARGET_GLIB}
    --thread
    --enable-checking
    --debug
    --fatal-warnings
    ${EXTRA_VALA_OPTIONS}
)

set(LIB_PATHS ${DEPS_LIBRARY_DIRS})
link_directories(${LIB_PATHS})
add_definitions(${CFLAGS} "-DGETTEXT_PACKAGE=\"birdie\"")

vala_precompile(VALA_C
    main.vala
    config.vala
    Birdie.vala
    API.vala
    Twitter.vala
    Identica.vala
    Tweet.vala
    User.vala
    Imgur.vala
    Media.vala
    Database.vala
    Widgets/TweetBox.vala
    Widgets/TweetList.vala
    Widgets/UnifiedWindow.vala
    Widgets/TweetDialog.vala
    Widgets/UserBox.vala
    Widgets/MenuPopOver.vala
    Widgets/Dialogs.vala
    Widgets/LightWindowNoDrag.vala
    Utils/Cairo.vala
    Utils/Date.vala
    Utils/Notifications.vala
    Utils/Indicator.vala
    Utils/Launcher.vala
    Utils/Networking.vala
    Utils/Pixbuf.vala
    Utils/Downloader.vala
    Utils/Strings.vala
    Utils/Files.vala
    Utils/KeybindingManager.vala
PACKAGES
    ${BIRDIE_PACKAGES}
OPTIONS
    ${VALAC_OPTIONS}
)

#Here we define our executable name.
add_executable(birdie
    ${VALA_C} )

add_definitions (${DEPS_CFLAGS} -DWNCK_I_KNOW_THIS_IS_UNSTABLE)

#We need to link the libraries with our Executable.
target_link_libraries(birdie ${DEPS_LIBRARIES} -lX11)

install (TARGETS birdie RUNTIME DESTINATION bin)
