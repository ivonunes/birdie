
#Here we're including the Vala package from ../cmake
find_package(Vala REQUIRED)

#Now we're including the version module to ensure we have a compatible version
include(ValaVersion)
ensure_vala_version("0.11.3" MINIMUM)

#Now we're including the precompile modules to set things up.
include(ValaPrecompile)


#We're going to load the PkgConfig module from ../cmake
#We do this to ensure we can include required modules.
#PkgConfig handles all of the querying of packages for us.
#It finds their directories, versions, and if they're installed.
find_package(PkgConfig)

#Now we're declaring GTK+ 3 and Granite as our REQUIRE dependancies.
#If PkgConfig can't find these, you need to install them in Step 1.
pkg_check_modules(DEPS REQUIRED gtk+-3.0 granite rest-0.7 json-glib-1.0 libnotify libcanberra indicate-0.7 unity)

#Now we're going to ready the libraries and get their directories to include them.
set(CFLAGS
    ${DEPS_CFLAGS} ${DEPS_CFLAGS_OTHER}
)
set(LIB_PATHS
    ${DEPS_LIBRARY_DIRS}
)
link_directories(${LIB_PATHS})

#Here is where vala precompiles all the *.vala files into *.c files.
#Then we compule the *.c files to turn them into a true executable.
add_definitions(${CFLAGS} "-DGETTEXT_PACKAGE=\"birdie\"")
vala_precompile(VALA_C
    main.vala
    config.vala
    Birdie.vala
    Twitter.vala
    Tweet.vala
    User.vala
    Widgets/TweetBox.vala
    Widgets/TweetList.vala
    Widgets/UnifiedWindow.vala
    Widgets/LightDialog.vala
    Widgets/TweetDialog.vala
    Utils/Cairo.vala
    Utils/Date.vala
    Utils/Notifications.vala
    Utils/Indicator.vala
    Utils/Launcher.vala
PACKAGES
    gtk+-3.0
    granite
    rest-0.7
    json-glib-1.0
    libnotify>=0.7.5
    libcanberra>=0.28
    Indicate-0.7
    Dbusmenu-0.4
    unity
OPTIONS
    --thread --target-glib=2.32)

#Here we define our executable name.
add_executable(birdie
    ${VALA_C} )

add_definitions (${DEPS_CFLAGS})

#We need to link the libraries with our Executable.
target_link_libraries(birdie ${DEPS_LIBRARIES})

install (TARGETS birdie RUNTIME DESTINATION bin)
