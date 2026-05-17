import QtQuick
import QtTest
import NinjaView
import Kaakao

TestCase {
    name: "MainTests"
    width: 900
    height: 600
    visible: true

    Main {
        id: mainApp
    }

    function test_initialization() {
        verify(mainApp.visible, "Main window should be visible")
        compare(mainApp.title, "NinjaView", "Title should be correct")
    }

    function test_sidebar_model() {
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
        var shortcut = findChild(mainApp, "galleryShortcut")
        
        verify(grid !== null, "Grid should be found")
        verify(overlay !== null, "Overlay should be found")
        verify(shortcut !== null, "Shortcut should be found")
        
        overlay.visible = false
        
        // Mock a current index and focus the internal gridView
        grid.currentIndex = 0
        grid.gridView.forceActiveFocus()
        
        // Test shortcut logic directly
        shortcut.activated()
        tryVerify(function() { return overlay.visible }, 2000, "Shortcut should open overlay")
    }
}
