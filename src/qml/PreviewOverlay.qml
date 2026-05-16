import QtQuick
import Kaakao

Item {
    id: control
    anchors.fill: parent
    visible: false

    property var model
    property int currentIndex: -1
    property string currentImagePath: {
        if (!model || currentIndex < 0) return ""
        // rowCount is a function on C++ models, but a property on ListModel. 
        // We use a safe check that works for both or just rely on index() returning invalid.
        var idx = model.index(currentIndex, 0)
        if (!idx.valid) return ""
        return model.data(idx, 259) // 259 is RawPathRole
    }

    property bool showInfo: false
    property var exifData: (currentImagePath && typeof exifReader !== 'undefined' && exifReader) ? exifReader.getExifData(currentImagePath) : ({})

    onVisibleChanged: {
        if (visible) {
            forceActiveFocus()
        } else {
            showInfo = false
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: control.visible ? Qt.BlankCursor : Qt.ArrowCursor
        onClicked: control.visible = false
        // This ensures the MouseArea covers everything for cursor purposes
        z: -1 
    }

    Image {
        id: previewImage
        anchors.fill: parent
        source: currentImagePath ? "image://gallery/" + currentImagePath : ""
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
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 20
        width: 250
        height: infoColumn.height + 20
        color: Qt.rgba(0, 0, 0, 0.7)
        radius: 8
        visible: showInfo && currentImagePath !== ""

        Column {
            id: infoColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 10
            spacing: 5

            KaakaoLabel {
                text: qsTr("EXIF Information")
                role: KaakaoLabel.Header
                color: "white"
            }

            Rectangle { width: parent.width; height: 1; color: Qt.rgba(1, 1, 1, 0.3) }

            Repeater {
                model: [
                    { label: "Make", value: exifData.Make },
                    { label: "Model", value: exifData.Model },
                    { label: "Lens", value: exifData.Lens },
                    { label: "Exposure", value: exifData.Exposure },
                    { label: "Aperture", value: exifData.Aperture },
                    { label: "ISO", value: exifData.ISO },
                    { label: "Focal Length", value: exifData.FocalLength },
                    { label: "Date", value: exifData.DateTime }
                ]
                delegate: Row {
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
            control.visible = false
            event.accepted = true
        } else if (event.key === Qt.Key_I) {
            showInfo = !showInfo
            event.accepted = true
        } else if (event.key === Qt.Key_Right) {
            if (currentIndex < model.rowCount() - 1) {
                currentIndex++
            }
            event.accepted = true
        } else if (event.key === Qt.Key_Left) {
            if (currentIndex > 0) {
                currentIndex--
            }
            event.accepted = true
        }
    }
}
