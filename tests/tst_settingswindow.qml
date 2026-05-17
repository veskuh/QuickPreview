import QtQuick
import QtTest
import NinjaView
import Kaakao

TestCase {
    name: "SettingsWindowTests"
    width: 600
    height: 500
    visible: true

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
