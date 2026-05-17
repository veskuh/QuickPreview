import QtQuick
import QtTest
import QuickPreview
import Kaakao

TestCase {
    name: "PreviewOverlayTests"
    width: 800
    height: 600
    visible: true

    // Mock logger for tests
    QtObject {
        id: logger
        property bool loggingEnabled: false
        property string logFilePath: ""
        function log(message, category) {}
    }

    property var mockModel: ListModel {
        ListElement { rawPath: "/tmp/test1.jpg" }
        ListElement { rawPath: "/tmp/test2.jpg" }
        ListElement { rawPath: "/tmp/test3.jpg" }
    }

    PreviewOverlay {
        id: overlay
        anchors.fill: parent
        model: mockModel
        currentIndex: 0
        visible: false
    }

    function test_visibility_and_cursor() {
        overlay.visible = true
        verify(overlay.visible, "Overlay should be visible")
        
        overlay.visible = false
        verify(!overlay.visible, "Overlay should be hidden")
    }

    function test_navigation() {
        overlay.visible = true
        overlay.currentIndex = 0
        overlay.forceActiveFocus()
        
        compare(overlay.currentIndex, 0, "Initial index should be 0")
        
        keyClick(Qt.Key_Right)
        compare(overlay.currentIndex, 1, "Index should increment on Right arrow")
        
        keyClick(Qt.Key_Right)
        compare(overlay.currentIndex, 2, "Index should increment again on Right arrow")
        
        keyClick(Qt.Key_Right)
        compare(overlay.currentIndex, 2, "Index should not increment past bounds")
        
        keyClick(Qt.Key_Left)
        compare(overlay.currentIndex, 1, "Index should decrement on Left arrow")
        
        keyClick(Qt.Key_Escape)
        verify(!overlay.visible, "Overlay should hide on Escape")
    }

    function test_zoom() {
        overlay.visible = true
        overlay.fitToScreen = true
        overlay.forceActiveFocus()
        compare(overlay.fitToScreen, true, "Should start in fit-to-screen mode")
        
        keyClick(Qt.Key_Space)
        compare(overlay.fitToScreen, false, "Should zoom in on Space")
        compare(overlay.zoomLevel, 1.0, "Should zoom to 100% (1.0)")
        
        keyClick(Qt.Key_Space)
        compare(overlay.fitToScreen, true, "Should zoom back out on Space")
    }
}
