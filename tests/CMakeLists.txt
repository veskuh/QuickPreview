enable_testing()

macro(add_quickpreview_test name)
    add_executable(${name} ${ARGN})
    target_link_libraries(${name} PRIVATE
        Qt6::Test
        Qt6::Core
        Qt6::Gui
        Qt6::Quick
        Qt6::Concurrent
        QuickPreviewLib
    )
    add_test(NAME ${name} COMMAND ${name})
endmacro()

add_quickpreview_test(tst_gallerylistmodel tst_gallerylistmodel.cpp)
add_quickpreview_test(tst_filediscoveryservice tst_filediscoveryservice.cpp)
add_quickpreview_test(tst_asyncimageprovider tst_asyncimageprovider.cpp)

# QML UI Test
add_executable(tst_previewoverlay qml_test_launcher.cpp)
target_link_libraries(tst_previewoverlay PRIVATE 
    Qt6::Core 
    Qt6::Gui 
    Qt6::Qml 
    Qt6::Quick 
    Qt6::Test 
    Qt6::QuickTest 
    Kaakao
    QuickPreviewLibplugin
)
target_include_directories(tst_previewoverlay PRIVATE 
    ../src 
    ../src/core 
    ../src/ui 
    ../3rdparty/easyexif
)
# We need to copy the QML test file to the build directory
file(COPY tst_previewoverlay.qml DESTINATION "${CMAKE_CURRENT_BINARY_DIR}")

target_compile_definitions(tst_previewoverlay PRIVATE QUICK_TEST_SOURCE_DIR="${CMAKE_CURRENT_BINARY_DIR}")
add_test(NAME tst_previewoverlay COMMAND tst_previewoverlay -input tst_previewoverlay.qml)

# Ensure QML modules are found
set_tests_properties(tst_previewoverlay PROPERTIES ENVIRONMENT "QML_IMPORT_PATH=${CMAKE_BINARY_DIR}/qml")
