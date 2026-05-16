import QtQuick
import QtTest
import QuickPreview
import Kaakao

TestCase {
    name: "PreviewOverlayTests"
    width: 800
    height: 600
    visible: true

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
        // We can't easily test cursor shape in QML unit tests without C++ hooks, 
        // but we can verify it doesn't crash.
        
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

    function test_mouse_exit() {
        overlay.visible = true
        mouseClick(overlay)
        verify(!overlay.visible, "Overlay should hide on mouse click")
    }
}
