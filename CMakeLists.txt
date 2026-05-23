cmake_minimum_required(VERSION 3.16)

# Default to the official Qt 6.8.3 installation if CMAKE_PREFIX_PATH is not set
if(NOT DEFINED CMAKE_PREFIX_PATH AND EXISTS "$ENV{HOME}/Qt/6.8.3/macos")
    set(CMAKE_PREFIX_PATH "$ENV{HOME}/Qt/6.8.3/macos" CACHE PATH "Qt Prefix Path")
endif()
project(NinjaView VERSION 0.1 LANGUAGES CXX)

# Define project version and build ID
if(NOT DEFINED NINJAVIEW_VERSION)
    set(NINJAVIEW_VERSION "${PROJECT_VERSION}")
endif()

if(NOT DEFINED NINJAVIEW_BUILD_ID)
    find_package(Git QUIET)
    if(GIT_FOUND)
        execute_process(
            COMMAND ${GIT_EXECUTABLE} log -1 --format=%h
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
            OUTPUT_VARIABLE NINJAVIEW_BUILD_ID
            OUTPUT_STRIP_TRAILING_WHITESPACE
            ERROR_QUIET
        )
    endif()
endif()
if(NOT NINJAVIEW_BUILD_ID)
    set(NINJAVIEW_BUILD_ID "local")
endif()

add_compile_definitions(
    NINJAVIEW_VERSION="${NINJAVIEW_VERSION}"
    NINJAVIEW_BUILD_ID="${NINJAVIEW_BUILD_ID}"
)

# Default install prefix to /Applications on macOS
if(APPLE AND (CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT OR CMAKE_INSTALL_PREFIX STREQUAL "/usr/local"))
    set(CMAKE_INSTALL_PREFIX "/Applications" CACHE PATH "Install prefix" FORCE)
endif()

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# Standard QML output directory for easier discovery in build tree
set(QT_QML_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/qml)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick QuickControls2 Core5Compat ShaderTools Concurrent Test QuickTest QuickDialogs2)

# Workaround for official Qt 6.8.3 on modern macOS SDKs complaining about missing AGL framework
if(APPLE AND TARGET WrapOpenGL::WrapOpenGL)
    get_target_property(_gl_libs WrapOpenGL::WrapOpenGL INTERFACE_LINK_LIBRARIES)
    if(_gl_libs)
        list(REMOVE_ITEM _gl_libs "-framework AGL" "/System/Library/Frameworks/AGL.framework")
        set_target_properties(WrapOpenGL::WrapOpenGL PROPERTIES INTERFACE_LINK_LIBRARIES "${_gl_libs}")
    endif()
endif()

qt_standard_project_setup()

enable_testing()

# Add Kaakao submodule
add_subdirectory(Kaakao)

# Add application source
add_subdirectory(src)

# Add unit tests
add_subdirectory(tests)

