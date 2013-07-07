
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
set (RELEASE_NAME "Konversacio")
set (VERSION "0.3")
set (CMAKE_C_FLAGS "-ggdb")

configure_file (${CMAKE_SOURCE_DIR}/src/config.vala.cmake ${CMAKE_SOURCE_DIR}/src/config.vala)

#Here we load the modules we downloaded earlier and placed into the ./cmake directory
list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake )

# Vala
find_package (Vala REQUIRED)
include (ValaVersion)
ensure_vala_version ("0.16.1" MINIMUM)
include (ValaPrecompile)

find_package(PkgConfig)
pkg_check_modules(LIBINDICATE QUIET indicate-0.7)
pkg_check_modules(LIBUNITY QUIET unity)
pkg_check_modules(LIBMESSAGINGMENU QUIET messaging-menu>=12.10.2)
pkg_check_modules(GRANITE QUIET granite)

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

#Here we add the src directory. CMake will look for the CMakeLists.txt in this folder
#and work from there
add_subdirectory (src)
add_subdirectory (po)
