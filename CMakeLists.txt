cmake_minimum_required(VERSION 3.16)

project(QuickPreview VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# Standard QML output directory for easier discovery in build tree
set(QT_QML_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/qml)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick QuickControls2 Core5Compat ShaderTools)
...
qt_standard_project_setup()

# Add Kaakao submodule
add_subdirectory(Kaakao)

# Add application source
add_subdirectory(src)
