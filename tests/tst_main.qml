import QtQuick
import QtTest
import QuickPreview
import Kaakao

TestCase {
    name: "MainTests"
    width: 900
    height: 600
    visible: true

    // Mock Backend Objects
    QtObject {
        id: galleryModel
        function clear() { console.log("Mock galleryModel.clear()") }
        function index(r, c) { return null }
        function data(idx, role) { return "" }
    }

    QtObject {
        id: discoveryService
        function scanDirectory(path) { console.log("Mock discoveryService.scanDirectory:", path) }
    }

    QtObject {
        id: logger
        property bool loggingEnabled: false
        property string logFilePath: "/tmp/mock.log"
    }

    QtObject {
        id: exifReader
        function getExifData(path) { return {} }
    }

    Main {
        id: mainApp
    }

    function test_initialization() {
        verify(mainApp.visible, "Main window should be visible")
        compare(mainApp.title, "QuickPreview", "Title should be correct")
    }

    function test_sidebar_model() {
        // Sidebar is internal to Main, but we can verify it exists
        // sidebar has id 'sidebar'
        verify(mainApp.showMainInfo === false, "Info panel should be hidden initially")
    }

    function test_toggle_info_panel() {
        mainApp.showMainInfo = true
        verify(mainApp.showMainInfo, "Info panel should be visible after toggle")
        
        mainApp.showMainInfo = false
        verify(!mainApp.showMainInfo, "Info panel should be hidden after second toggle")
    }
}
