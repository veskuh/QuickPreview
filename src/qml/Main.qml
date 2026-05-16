import QtQuick
import Kaakao

KaakaoWindow {
    visible: true
    width: 400
    height: 300
    title: qsTr("Hello QuickPreview")

    Column {
        anchors.centerIn: parent
        spacing: 20

        KaakaoLabel {
            text: qsTr("Hello from Kaakao!")
            role: KaakaoLabel.Header
            anchors.horizontalCenter: parent.horizontalCenter
        }

        KaakaoButton {
            text: qsTr("Click Me")
            anchors.horizontalCenter: parent.horizontalCenter
            onClicked: {
                console.log("Button clicked!")
            }
        }
    }
}
