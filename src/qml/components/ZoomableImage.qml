pragma ComponentBehavior: Bound

import QtQuick
import Kaakao

Item {
    id: panel

    // Inputs/Configurations
    property string source: ""
    property bool fitToScreen: true
    property real zoomLevel: 1.0

    // Outputs
    readonly property real fitZoomLevel: (previewImage.implicitWidth > 0 && previewImage.implicitHeight > 0)
                                         ? Math.min(panel.width / previewImage.implicitWidth, panel.height / previewImage.implicitHeight)
                                         : 1.0
    readonly property real currentZoom: panel.fitToScreen ? panel.fitZoomLevel : panel.zoomLevel
    readonly property bool isError: previewImage.status === Image.Error
    readonly property bool isLoading: previewImage.status === Image.Loading

    // Fixed size to ensure 100% cache hits
    readonly property size prefetchSize: Qt.size(4096, 4096)

    function reset() {
        panel.fitToScreen = true
        panel.zoomLevel = 1.0
    }

    function applyZoom(newZoom, mouseX, mouseY) {
        // Calculate the point on the image before zooming (relative to image pixels)
        let imgX = (flickable.contentX + mouseX - previewImage.x) / panel.currentZoom
        let imgY = (flickable.contentY + mouseY - previewImage.y) / panel.currentZoom
        
        panel.zoomLevel = newZoom
        panel.fitToScreen = false
        
        // After properties update, the new centering offset will be:
        let newX = Math.max(0, (flickable.width - previewImage.implicitWidth * newZoom) / 2)
        let newY = Math.max(0, (flickable.height - previewImage.implicitHeight * newZoom) / 2)
        
        flickable.contentX = newX + imgX * newZoom - mouseX
        flickable.contentY = newY + imgY * newZoom - mouseY
    }

    Flickable {
        id: flickable
        anchors.fill: parent
        contentWidth: previewImage.width
        contentHeight: previewImage.height
        boundsBehavior: Flickable.StopAtBounds
        clip: true
        interactive: !panel.fitToScreen

        Image {
            id: previewImage
            width: previewImage.implicitWidth * panel.currentZoom
            height: previewImage.implicitHeight * panel.currentZoom
            source: panel.source
            fillMode: Image.Stretch
            asynchronous: true
            cache: true
            sourceSize: panel.prefetchSize

            // Center the image when smaller than the flickable
            x: Math.max(0, (flickable.width - width) / 2)
            y: Math.max(0, (flickable.height - height) / 2)

            KaakaoActivityOverlay {
                anchors.fill: parent
                active: panel.isLoading
                text: qsTr("Loading Image...")
            }
        }
    }

    WheelHandler {
        onWheel: (event) => {
            let zoomFactor = event.angleDelta.y > 0 ? 1.1 : 0.9
            let newZoom = panel.currentZoom * zoomFactor
            newZoom = Math.max(0.01, Math.min(newZoom, 20.0))
            panel.applyZoom(newZoom, point.position.x, point.position.y)
        }
    }

    TapHandler {
        onTapped: (event) => {
            if (panel.fitToScreen) {
                panel.applyZoom(1.0, point.position.x, point.position.y)
            } else {
                panel.fitToScreen = true
            }
        }
    }
}
