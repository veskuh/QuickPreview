# Move QML and core logic to a library
qt_add_library(NinjaViewLib STATIC
    core/FileDiscoveryService.cpp
    core/VolumeMonitor.cpp
    core/ExifReader.cpp
    core/Logger.cpp
    ../3rdparty/easyexif/exif.cpp
    ui/GalleryListModel.cpp
    ui/AsyncImageProvider.cpp
)

qt_add_qml_module(NinjaViewLib
    URI NinjaView
    VERSION 1.0
    RESOURCE_PREFIX "/qt/qml"
    QML_FILES
        qml/Main.qml
        qml/PreviewOverlay.qml
        qml/AboutDialog.qml
        qml/ExifOverlay.qml
        qml/SettingsWindow.qml
    RESOURCES
        ../assets/ninja-icon.png
    DEPENDENCIES
        Kaakao
)

target_link_libraries(NinjaViewLib PUBLIC
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::QuickDialogs2
    Qt6::Core5Compat
    Qt6::ShaderTools
    Qt6::Concurrent
    Kaakao
)

target_include_directories(NinjaViewLib PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/core
    ${CMAKE_CURRENT_SOURCE_DIR}/ui
    ${CMAKE_CURRENT_SOURCE_DIR}/../3rdparty/easyexif
)

# Application executable
set(MACOSX_BUNDLE_ICON_FILE ninja-icon.icns)
set(icon_files "${CMAKE_CURRENT_SOURCE_DIR}/../assets/ninja-icon.icns")
set_source_files_properties(${icon_files} PROPERTIES MACOSX_PACKAGE_LOCATION "Resources")

qt_add_executable(NinjaViewApp
    MACOSX_BUNDLE
    main.cpp
    ${icon_files}
)

set_target_properties(NinjaViewApp PROPERTIES
    OUTPUT_NAME "NinjaView"
    MACOSX_BUNDLE_BUNDLE_NAME "NinjaView"
    MACOSX_BUNDLE_GUI_IDENTIFIER "net.veskuh.ninjaview"
)

if(UNIX AND NOT APPLE)
    set_target_properties(NinjaViewApp PROPERTIES
        OUTPUT_NAME "ninjaview"
    )
endif()

target_link_libraries(NinjaViewApp PRIVATE
    NinjaViewLib
    NinjaViewLibplugin
)

install(TARGETS NinjaViewApp
    BUNDLE DESTINATION .
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
