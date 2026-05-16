# Move QML and core logic to a library
qt_add_library(QuickPreviewLib STATIC
    core/FileDiscoveryService.cpp
    core/VolumeMonitor.cpp
    ui/GalleryListModel.cpp
    ui/AsyncImageProvider.cpp
)

qt_add_qml_module(QuickPreviewLib
    URI QuickPreview
    VERSION 1.0
    RESOURCE_PREFIX "/qt/qml"
    QML_FILES
        qml/Main.qml
        qml/PreviewOverlay.qml
    DEPENDENCIES
        Kaakao
)

target_link_libraries(QuickPreviewLib PUBLIC
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Core5Compat
    Qt6::ShaderTools
    Qt6::Concurrent
    Kaakao
)

target_include_directories(QuickPreviewLib PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/core
    ${CMAKE_CURRENT_SOURCE_DIR}/ui
)

# Application executable
qt_add_executable(QuickPreviewApp
    main.cpp
)

target_link_libraries(QuickPreviewApp PRIVATE
    QuickPreviewLib
)

install(TARGETS QuickPreviewApp
    BUNDLE DESTINATION .
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
