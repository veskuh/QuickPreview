pragma ComponentBehavior: Bound

import QtQuick
import Kaakao
import NinjaView

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
            // Try C++ model helper first
            if (typeof m.getRawPath === 'function') {
                path = m.getRawPath(idx)
            } else if (typeof m.index === 'function' && typeof m.data === 'function') {
                // Fallback for standard QAbstractItemModel
                let qidx = m.index(idx, 0)
                if (qidx) {
                    let data = m.data(qidx, 259) // RawPathRole
                    if (data !== undefined && data !== null) {
                        path = data.toString()
                    }
                }
            } else if (typeof m.get === 'function') {
                // Fallback for QML ListModel
                let item = m.get(idx)
                if (item && item.rawPath !== undefined && item.rawPath !== null) {
                    path = item.rawPath.toString()
                }
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

    // Zoom and Navigation state aliases mapped to ZoomableImage
    property alias fitToScreen: zoomableImage.fitToScreen
    property alias zoomLevel: zoomableImage.zoomLevel
    readonly property alias currentZoom: zoomableImage.currentZoom
    readonly property alias fitZoomLevel: zoomableImage.fitZoomLevel

    onVisibleChanged: {
        if (visible) {
            root.forceActiveFocus()
        } else {
            root.showInfo = false
            zoomableImage.reset()
        }
    }

    onCurrentIndexChanged: {
        zoomableImage.reset()
    }

    // Hidden pre-fetchers to cache adjacent images asynchronously
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

    // Viewport background
    Rectangle {
        anchors.fill: parent
        color: "black"
    }

    // Modular Zoomable Image viewport
    ZoomableImage {
        id: zoomableImage
        anchors.fill: parent
        source: root.currentImagePath ? "image://gallery/" + root.currentImagePath : ""
    }

    // Hidden cursor Area during fullscreen (Mac OS X viewer aesthetic)
    MouseArea {
        id: cursorMouseArea
        objectName: "cursorMouseArea"
        anchors.fill: parent
        cursorShape: root.visible ? Qt.BlankCursor : Qt.ArrowCursor
        enabled: false // Don't block clicks
        z: 1 
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

    Column {
        id: errorOverlay
        anchors.centerIn: parent
        spacing: 16
        visible: zoomableImage.isError && root.currentImagePath !== ""

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "⚠️"
            font.pixelSize: 64
        }

        KaakaoLabel {
            anchors.horizontalCenter: parent.horizontalCenter
            text: qsTr("Failed to load image")
            font.weight: Font.Bold
            font.pixelSize: 16
            color: "white"
        }

        KaakaoLabel {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.currentImagePath
            font.pixelSize: 12
            color: "#888888"
            elide: Text.ElideMiddle
            width: Math.min(root.width - 80, 400)
            horizontalAlignment: Text.AlignHCenter
        }
    }

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) {
            root.visible = false
            event.accepted = true
        } else if (event.key === Qt.Key_I) {
            root.showInfo = !root.showInfo
            event.accepted = true
        } else if (event.key === Qt.Key_Plus || event.key === Qt.Key_Equal) {
            zoomableImage.applyZoom(Math.min(zoomableImage.currentZoom * 1.1, 20.0), zoomableImage.width / 2, zoomableImage.height / 2)
            event.accepted = true
        } else if (event.key === Qt.Key_Minus || event.key === Qt.Key_Hyphen) {
            zoomableImage.applyZoom(Math.max(zoomableImage.currentZoom * 0.9, 0.01), zoomableImage.width / 2, zoomableImage.height / 2)
            event.accepted = true
        } else if (event.key === Qt.Key_Space) {
            if (zoomableImage.fitToScreen) {
                zoomableImage.applyZoom(1.0, zoomableImage.width / 2, zoomableImage.height / 2)
            } else {
                zoomableImage.fitToScreen = true
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
