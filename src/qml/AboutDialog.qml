import QtQuick
import QtQuick.Layouts
import Kaakao

pragma ComponentBehavior: Bound

KaakaoWindow {
    id: root
    
    width: 320
    height: 440
    minimumWidth: width
    maximumWidth: width
    minimumHeight: height
    maximumHeight: height
    
    title: qsTr("About NinjaView")
    
    Column {
        anchors {
            fill: parent
            margins: 24
        }
        spacing: Theme.layoutSpacing

        // App Icon
        Image {
            source: "qrc:/qt/qml/NinjaView/assets/ninja-icon.png"
            width: 120
            height: 120
            fillMode: Image.PreserveAspectFit
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Column {
            width: parent.width
            spacing: 4
            
            KaakaoLabel {
                text: "NinjaView"
                role: KaakaoLabel.Role.Header
                anchors.horizontalCenter: parent.horizontalCenter
            }

            KaakaoLabel {
                text: qsTr("Version 0.1")
                role: KaakaoLabel.Role.Secondary
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        KaakaoLabel {
            text: qsTr("A high-performance image viewer for rapid photo triage.")
            width: parent.width
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: 12
        }

        Column {
            width: parent.width
            spacing: 8
            KaakaoLabel {
                text: qsTr("Credits:")
                role: KaakaoLabel.Role.Small
                font.weight: Font.Bold
            }
            KaakaoLabel {
                text: "• Kaakao UI Components\n• easyexif (Copyright © 2010-2016 Mayank Lahiri)"
                role: KaakaoLabel.Role.Small
                width: parent.width
                wrapMode: Text.WordWrap
            }
        }

        Item { Layout.fillHeight: true; width: 1 } // Spacer

        KaakaoLabel {
            text: "Copyright © 2026 Vesa-Matti Hartikainen"
            role: KaakaoLabel.Role.Small
            anchors.horizontalCenter: parent.horizontalCenter
        }

        KaakaoButton {
            text: qsTr("Close")
            anchors.horizontalCenter: parent.horizontalCenter
            onClicked: root.close()
        }
    }
}
