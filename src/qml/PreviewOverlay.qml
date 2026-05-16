import QtQuick
import Kaakao

Item {
    id: control
    anchors.fill: parent
    visible: false

    property var model
    property int currentIndex: -1
    property string currentImagePath: currentIndex >= 0 ? model.data(model.index(currentIndex, 0), 259) : "" // 259 is RawPathRole

    onVisibleChanged: {
        if (visible) {
            forceActiveFocus()
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

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) {
            control.visible = false
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
