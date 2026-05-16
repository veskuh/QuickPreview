import QtQuick
import Kaakao

pragma ComponentBehavior: Bound

Item {
    id: root
    anchors.fill: parent
    visible: false

    required property var model
    property int currentIndex: -1
    readonly property string currentImagePath: {
        if (!root.model || root.currentIndex < 0) return ""
        let idx = root.model.index(root.currentIndex, 0)
        if (!idx.valid) return ""
        return root.model.data(idx, 259) // 259 is RawPathRole
    }

    property bool showInfo: false
    readonly property var exifData: (root.currentImagePath && typeof exifReader !== 'undefined' && exifReader) ? exifReader.getExifData(root.currentImagePath) : ({})

    onVisibleChanged: {
        if (visible) {
            root.forceActiveFocus()
        } else {
            root.showInfo = false
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: root.visible ? Qt.BlankCursor : Qt.ArrowCursor
        onClicked: root.visible = false
        // This ensures the MouseArea covers everything for cursor purposes
        z: -1 
    }

    Image {
        id: previewImage
        anchors.fill: parent
        source: root.currentImagePath ? "image://gallery/" + root.currentImagePath : ""
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        cache: true
        
        // Use a larger source size for fullscreen preview
        sourceSize: Qt.size(Screen.width, Screen.height)

        KaakaoActivityOverlay {
            anchors.fill: parent
            active: previewImage.status === Image.Loading
            text: qsTr("Loading Image...")
        }
    }

    Rectangle {
        id: infoPanel
        anchors {
            left: parent.left
            top: parent.top
            margins: 20
        }
        width: 250
        height: infoColumn.height + 20
        color: Qt.rgba(0, 0, 0, 0.7)
        radius: 8
        visible: root.showInfo && root.currentImagePath !== ""

        Column {
            id: infoColumn
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 10
            }
            spacing: 5

            KaakaoLabel {
                text: qsTr("EXIF Information")
                role: KaakaoLabel.Header
                color: "white"
            }

            Rectangle { width: parent.width; height: 1; color: Qt.rgba(1, 1, 1, 0.3) }

            Repeater {
                model: [
                    { label: "Make", value: root.exifData.Make },
                    { label: "Model", value: root.exifData.Model },
                    { label: "Lens", value: root.exifData.Lens },
                    { label: "Exposure", value: root.exifData.Exposure },
                    { label: "Aperture", value: root.exifData.Aperture },
                    { label: "ISO", value: root.exifData.ISO },
                    { label: "Focal Length", value: root.exifData.FocalLength },
                    { label: "Date", value: root.exifData.DateTime }
                ]
                delegate: Row {
                    required property var modelData
                    width: parent.width
                    spacing: 10
                    visible: modelData.value !== undefined && modelData.value !== "" && modelData.value !== 0
                    KaakaoLabel { 
                        text: modelData.label + ":"
                        width: 80
                        color: "#AAA"
                        font.pixelSize: 11
                    }
                    KaakaoLabel { 
                        text: String(modelData.value)
                        width: parent.width - 90 // 80 (label) + 10 (spacing)
                        elide: Text.ElideRight
                        color: "white"
                        font.pixelSize: 11
                    }
                }
            }
        }
    }

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) {
            root.visible = false
            event.accepted = true
        } else if (event.key === Qt.Key_I) {
            root.showInfo = !root.showInfo
            event.accepted = true
        } else if (event.key === Qt.Key_Right) {
            if (root.currentIndex < root.model.rowCount() - 1) {
                root.currentIndex++
            }
            event.accepted = true
        } else if (event.key === Qt.Key_Left) {
            if (root.currentIndex > 0) {
                root.currentIndex--
            }
            event.accepted = true
        }
    }
}
