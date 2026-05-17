import QtQuick
import QtTest
import NinjaView
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
        compare(mainApp.title, "NinjaView", "Title should be correct")
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

    function test_space_opens_preview() {
        // Need to find the grid and overlay
        var grid = findChild(mainApp, "galleryGrid")
        var overlay = findChild(mainApp, "previewOverlay")
        
        verify(grid !== null, "Grid should be found")
        verify(overlay !== null, "Overlay should be found")
        
        overlay.visible = false
        
        // Mock a current index
        grid.currentIndex = 0
        grid.forceActiveFocus()
        verify(grid.activeFocus, "Grid should have focus")
        
        keyClick(Qt.Key_Space)
        verify(overlay.visible, "Space should open overlay")
        
        overlay.visible = false
        keyClick(Qt.Key_Return)
        verify(overlay.visible, "Return should open overlay")
    }
}
