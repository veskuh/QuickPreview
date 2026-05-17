import QtQuick
import QtTest
import QuickPreview
import Kaakao

TestCase {
    name: "SettingsWindowTests"
    width: 600
    height: 500
    visible: true

    // Mock Backend Objects
    QtObject {
        id: imageProvider
        function cacheSize() { return 1024 * 1024 } // 1MB
        function cachePath() { return "/tmp/mock-cache" }
        function clearDiskCache() { console.log("Mock clearDiskCache called") }
    }

    QtObject {
        id: logger
        property bool loggingEnabled: false
        property string logFilePath: "/tmp/mock.log"
    }

    SettingsWindow {
        id: settings
    }

    function test_initialization() {
        settings.hide()
        verify(settings.visible === false, "Settings window should be hidden after hide()")
        settings.show()
        verify(settings.visible, "Settings window should be visible after show()")
    }

    function test_cache_info() {
        settings.show()
        wait(100) 
        
        // SettingsWindow has a ColumnLayout as the only child of its contentItem
        verify(settings.contentItem.children.length > 0, "Window should have content")
    }

    function test_logging_toggle() {
        settings.show()
        logger.loggingEnabled = true
        compare(logger.loggingEnabled, true, "Logging should be enabled")
        
        logger.loggingEnabled = false
        compare(logger.loggingEnabled, false, "Logging should be disabled")
    }
}
