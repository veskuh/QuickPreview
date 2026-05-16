qt_add_executable(QuickPreviewApp
    main.cpp
)

qt_add_qml_module(QuickPreviewApp
    URI QuickPreview
    VERSION 1.0
    RESOURCE_PREFIX "/qt/qml"
    QML_FILES
        qml/Main.qml
)

target_link_libraries(QuickPreviewApp PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
    Kaakao
)

# Optional: include directories for future C++ files in core/ and ui/
target_include_directories(QuickPreviewApp PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/core
    ${CMAKE_CURRENT_SOURCE_DIR}/ui
)

install(TARGETS QuickPreviewApp
    BUNDLE DESTINATION .
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

qt_generate_deploy_qml_app_script(
    TARGET QuickPreviewApp
    OUTPUT_SCRIPT deploy_script.cmake
)
