pragma ComponentBehavior: Bound

import QtQuick
import Kaakao

Item {
    id: root
    anchors.fill: parent
    visible: false

    required property var model
    property int currentIndex: -1
    
    // Helper to get total count from different model types
    readonly property int modelCount: {
        let m = root.model
        if (!m) return 0
        if (m.count !== undefined) return m.count
        if (typeof m.rowCount === 'function') return m.rowCount()
        return 0
    }

    // Helper to get path from different model types
    function getPath(idx) {
        let m = root.model
        if (!m) {
            if (logger.loggingEnabled) logger.log("getPath(" + idx + ") FAILED: model is null", "Model")
            return ""
        }
        if (idx < 0) return ""
        
        let rowCount = 0
        try {
            if (typeof m.rowCount === 'function') rowCount = m.rowCount()
            else if (m.count !== undefined) rowCount = m.count
        } catch (e) {
            if (logger.loggingEnabled) logger.log("getPath(" + idx + ") EXCEPTION reading count: " + e, "Model")
            return ""
        }
        
        if (idx >= rowCount) {
            if (logger.loggingEnabled) logger.log("getPath(" + idx + ") FAILED: out of bounds (count=" + rowCount + ")", "Model")
            return ""
        }
        
        let path = ""
        try {
            // Try C++ model first
            if (typeof m.index === 'function' && typeof m.data === 'function') {
                let qidx = m.index(idx, 0)
                if (qidx) {
                    let data = m.data(qidx, 259) // RawPathRole
                    if (data !== undefined && data !== null) {
                        path = data.toString()
                    } else {
                        if (logger.loggingEnabled) logger.log("getPath(" + idx + ") FAILED: data at role 259 is null/undefined", "Model")
                    }
                } else {
                    if (logger.loggingEnabled) logger.log("getPath(" + idx + ") FAILED: index is invalid", "Model")
                }
            } else if (typeof m.get === 'function') {
                // Fallback for QML ListModel
                let item = m.get(idx)
                if (item && item.rawPath !== undefined && item.rawPath !== null) {
                    path = item.rawPath.toString()
                } else {
                    if (logger.loggingEnabled) logger.log("getPath(" + idx + ") FAILED: item.rawPath is missing/null", "Model")
                }
            } else {
                if (logger.loggingEnabled) logger.log("getPath(" + idx + ") FAILED: model has no supported access method", "Model")
            }
        } catch (e) {
            if (logger.loggingEnabled) logger.log("getPath(" + idx + ") EXCEPTION resolving path: " + e, "Model")
        }
        
        return path
    }

    readonly property string currentImagePath: root.getPath(root.currentIndex)
    readonly property string nextImagePath: root.getPath(root.currentIndex + 1)
    readonly property string prevImagePath: root.getPath(root.currentIndex - 1)

    onCurrentImagePathChanged: {
        if (logger.loggingEnabled) {
            logger.log("currentImagePath changed to: '" + currentImagePath + "' (index=" + root.currentIndex + ")", "UI")
        }
    }

    onNextImagePathChanged: {
        if (logger.loggingEnabled && nextImagePath !== "") {
            logger.log("Prefetching next image: " + nextImagePath, "UI")
        }
    }

    onPrevImagePathChanged: {
        if (logger.loggingEnabled && prevImagePath !== "") {
            logger.log("Prefetching previous image: " + prevImagePath, "UI")
        }
    }

    property bool showInfo: false

    // Zoom and Navigation state
    property real zoomLevel: 1.0
    property bool fitToScreen: true
    readonly property real fitZoomLevel: (previewImage.implicitWidth > 0 && previewImage.implicitHeight > 0)
                                         ? Math.min(root.width / previewImage.implicitWidth, root.height / previewImage.implicitHeight)
                                         : 1.0
    readonly property real currentZoom: root.fitToScreen ? root.fitZoomLevel : root.zoomLevel

    onVisibleChanged: {
        if (visible) {
            root.forceActiveFocus()
        } else {
            root.showInfo = false
            root.fitToScreen = true
            root.zoomLevel = 1.0
        }
    }

    onCurrentIndexChanged: {
        root.fitToScreen = true
        root.zoomLevel = 1.0
    }

    // Hidden pre-fetchers
    // We use a fixed 4096px sourceSize to ensure cache hits regardless of screen DPI.
    // This is large enough for 4K displays and provides high-quality 100% zoom.
    readonly property size prefetchSize: Qt.size(4096, 4096)

    Image { 
        id: nextPrefetchImage
        source: root.nextImagePath ? "image://gallery/" + root.nextImagePath : ""
        visible: false
        asynchronous: true
        cache: true
        sourceSize: root.prefetchSize
        onStatusChanged: {
            if (logger.loggingEnabled && status === Image.Ready) {
                logger.log("Pre-fetch READY: next image " + source, "Performance")
            }
        }
    }
    Image { 
        id: prevPrefetchImage
        source: root.prevImagePath ? "image://gallery/" + root.prevImagePath : ""
        visible: false
        asynchronous: true
        cache: true
        sourceSize: root.prefetchSize
        onStatusChanged: {
            if (logger.loggingEnabled && status === Image.Ready) {
                logger.log("Pre-fetch READY: previous image " + source, "Performance")
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
    }

    Flickable {
        id: flickable
        anchors.fill: parent
        contentWidth: previewImage.width
        contentHeight: previewImage.height
        boundsBehavior: Flickable.StopAtBounds
        clip: true
        interactive: !root.fitToScreen

        Image {
            id: previewImage
            width: previewImage.implicitWidth * root.currentZoom
            height: previewImage.implicitHeight * root.currentZoom
            source: root.currentImagePath ? "image://gallery/" + root.currentImagePath : ""
            onSourceChanged: {
                if (logger.loggingEnabled) logger.log("Image.source set to: " + source, "UI")
            }
            fillMode: Image.Stretch
            asynchronous: true
            cache: true
            
            // Same fixed size as pre-fetchers to ensure 100% cache hits.
            sourceSize: root.prefetchSize

            onStatusChanged: {
                if (logger.loggingEnabled) {
                    let statusStr = "Unknown"
                    if (status === Image.Null) statusStr = "Null"
                    else if (status === Image.Ready) statusStr = "Ready"
                    else if (status === Image.Loading) statusStr = "Loading"
                    else if (status === Image.Error) statusStr = "Error"
                    logger.log("Image status changed to: " + statusStr + " for " + source, "UI")
                }
            }

            // Center the image when smaller than the flickable
            x: Math.max(0, (flickable.width - width) / 2)
            y: Math.max(0, (flickable.height - height) / 2)

            KaakaoActivityOverlay {
                anchors.fill: parent
                active: previewImage.status === Image.Loading
                text: qsTr("Loading Image...")
            }
        }
    }

    // This MouseArea is strictly for the blank cursor behavior in fullscreen
    MouseArea {
        anchors.fill: parent
        cursorShape: root.visible ? Qt.BlankCursor : Qt.ArrowCursor
        enabled: false // Don't block clicks
        z: 1 
    }

    WheelHandler {
        onWheel: (event) => {
            let zoomFactor = event.angleDelta.y > 0 ? 1.1 : 0.9
            let newZoom = root.currentZoom * zoomFactor
            
            // Limit zoom levels
            newZoom = Math.max(0.01, Math.min(newZoom, 20.0))
            
            root.applyZoom(newZoom, point.position.x, point.position.y)
        }
    }

    TapHandler {
        onTapped: (event) => {
            if (logger.loggingEnabled) logger.log("Image tapped at " + point.position.x + "," + point.position.y, "UI")
            if (root.fitToScreen) {
                root.applyZoom(1.0, point.position.x, point.position.y)
            } else {
                root.fitToScreen = true
            }
        }
    }

    function applyZoom(newZoom, mouseX, mouseY) {
        // Calculate the point on the image before zooming (relative to image pixels)
        let imgX = (flickable.contentX + mouseX - previewImage.x) / root.currentZoom
        let imgY = (flickable.contentY + mouseY - previewImage.y) / root.currentZoom
        
        root.zoomLevel = newZoom
        root.fitToScreen = false
        
        // After properties update, the new centering offset will be:
        let newX = Math.max(0, (flickable.width - previewImage.implicitWidth * newZoom) / 2)
        let newY = Math.max(0, (flickable.height - previewImage.implicitHeight * newZoom) / 2)
        
        flickable.contentX = newX + imgX * newZoom - mouseX
        flickable.contentY = newY + imgY * newZoom - mouseY
    }

    ExifOverlay {
        id: infoPanel
        
        anchors {
            left: parent.left
            top: parent.top
            margins: 20
        }
                
        exifData: (root.currentImagePath && typeof exifReader !== 'undefined' && exifReader) ? exifReader.getExifData(root.currentImagePath) : ({})

        
        visible: root.showInfo && root.currentImagePath !== ""
        name: currentImagePath
   
    }

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) {
            root.visible = false
            event.accepted = true
        } else if (event.key === Qt.Key_I) {
            root.showInfo = !root.showInfo
            event.accepted = true
        } else if (event.key === Qt.Key_Plus || event.key === Qt.Key_Equal) {
            root.applyZoom(Math.min(root.currentZoom * 1.1, 20.0), flickable.width / 2, flickable.height / 2)
            event.accepted = true
        } else if (event.key === Qt.Key_Minus || event.key === Qt.Key_Hyphen) {
            root.applyZoom(Math.max(root.currentZoom * 0.9, 0.01), flickable.width / 2, flickable.height / 2)
            event.accepted = true
        } else if (event.key === Qt.Key_Space) {
            if (root.fitToScreen) {
                root.applyZoom(1.0, flickable.width / 2, flickable.height / 2)
            } else {
                root.fitToScreen = true
            }
            event.accepted = true
        } else if (event.key === Qt.Key_Right) {
            if (root.currentIndex < root.modelCount - 1) {
                if (logger.loggingEnabled) logger.log("Navigating Forward from index " + root.currentIndex, "UI")
                root.currentIndex++
            } else {
                if (logger.loggingEnabled) logger.log("Navigating Forward BLOCKED (at end of model, index " + root.currentIndex + ")", "UI")
            }
            event.accepted = true
        } else if (event.key === Qt.Key_Left) {
            if (root.currentIndex > 0) {
                if (logger.loggingEnabled) logger.log("Navigating Backward from index " + root.currentIndex, "UI")
                root.currentIndex--
            } else {
                if (logger.loggingEnabled) logger.log("Navigating Backward BLOCKED (at start of model)", "UI")
            }
            event.accepted = true
        }
    }
}
