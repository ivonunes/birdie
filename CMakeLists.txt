
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
set (RELEASE_NAME "Kompano")
set (VERSION "0.2.1")
set (CMAKE_C_FLAGS "-ggdb")

configure_file (${CMAKE_SOURCE_DIR}/src/config.vala.cmake ${CMAKE_SOURCE_DIR}/src/config.vala)

#Here we load the modules we downloaded earlier and placed into the ./cmake directory
list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake )

# Vala
find_package (Vala REQUIRED)
include (ValaVersion)
ensure_vala_version ("0.16.1" MINIMUM)
include (ValaPrecompile)

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
