enable_testing()

macro(add_quickpreview_test name)
    add_executable(${name} ${ARGN})
    target_link_libraries(${name} PRIVATE
        Qt6::Test
        Qt6::Core
        Qt6::Gui
        Qt6::Quick
        Qt6::Concurrent
    )
    add_test(NAME ${name} COMMAND ${name})
endmacro()

add_quickpreview_test(tst_gallerylistmodel tst_gallerylistmodel.cpp ../src/ui/GalleryListModel.cpp)
target_include_directories(tst_gallerylistmodel PRIVATE ../src/ui)

add_quickpreview_test(tst_filediscoveryservice tst_filediscoveryservice.cpp ../src/core/FileDiscoveryService.cpp)
target_include_directories(tst_filediscoveryservice PRIVATE ../src/core)

add_quickpreview_test(tst_asyncimageprovider tst_asyncimageprovider.cpp ../src/ui/AsyncImageProvider.cpp)
target_include_directories(tst_asyncimageprovider PRIVATE ../src/ui)
