import QtQuick
import QtTest
import QuickPreview
import Kaakao

TestCase {
    name: "ExifOverlayTests"
    width: 400
    height: 600
    visible: true

    ExifOverlay {
        id: overlay
        name: "test_image.jpg"
        exifData: ({
            "Make": "Canon",
            "Model": "EOS R5",
            "Lens": "RF 24-70mm F2.8L IS USM",
            "Exposure": "1/100",
            "Aperture": "f/2.8",
            "ISO": "400",
            "FocalLength": "35mm",
            "DateTime": "2026:05:17 12:00:00"
        })
    }

    function test_display_data() {
        verify(overlay.visible, "Overlay should be visible by default")
        compare(overlay.name, "test_image.jpg", "Name should be set")
        compare(overlay.exifData.Make, "Canon", "Make should be set")
        
        // Check if the content is rendered. 
        // We can't easily inspect Repeater's children by text without some helper, 
        // but we can verify the properties are bound.
    }

    function test_empty_data() {
        overlay.exifData = ({})
        // The overlay should still be visible but might show fewer rows
        // (due to 'visible: modelData.value !== undefined' in delegate)
        verify(overlay.visible, "Overlay should still be visible even with empty EXIF")
    }
}
