pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Kaakao

Item {
    id: panel

    property string currentPath: ""
    property string fileName: ""

    readonly property var exifData: (currentPath && typeof exifReader !== 'undefined' && exifReader) ? exifReader.getExifData(currentPath) : ({})

    Rectangle {
        anchors.fill: parent
        color: Theme.windowBackground
        
        Rectangle {
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
            }
            width: 1
            color: Theme.isDarkMode ? "#33FFFFFF" : "#33000000"
        }

        Column {
            id: infoContentColumn
            anchors {
                fill: parent
                margins: 15
            }
            spacing: 15

            KaakaoLabel {
                text: qsTr("Information")
                role: KaakaoLabel.Header
            }

            Rectangle {
                width: parent.width
                height: 150
                color: Theme.isDarkMode ? "#2D2D2D" : "#F0F0F0"
                radius: 4
                visible: panel.currentPath !== ""
                
                Image {
                    anchors {
                        fill: parent
                        margins: 5
                    }
                    source: panel.currentPath ? "image://gallery/" + panel.currentPath : ""
                    sourceSize: Qt.size(300, 300)
                    fillMode: Image.PreserveAspectFit
                }
            }

            KaakaoLabel {
                text: panel.fileName
                width: parent.width
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                font.weight: Font.Bold
            }

            Repeater {
                model: [
                    { label: "Make", value: panel.exifData.Make },
                    { label: "Model", value: panel.exifData.Model },
                    { label: "Lens", value: panel.exifData.Lens },
                    { label: "Exposure", value: panel.exifData.Exposure },
                    { label: "Aperture", value: panel.exifData.Aperture },
                    { label: "ISO", value: panel.exifData.ISO },
                    { label: "Date", value: panel.exifData.DateTime }
                ]
                delegate: Column {
                    required property var modelData
                    width: parent.width
                    spacing: 2
                    visible: modelData.value !== undefined && modelData.value !== "" && modelData.value !== 0
                    
                    KaakaoLabel { 
                        text: modelData.label
                        color: "#888"
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }
                    KaakaoLabel { 
                        text: String(modelData.value)
                        width: parent.width
                        elide: Text.ElideRight
                        font.pixelSize: 12
                    }
                }
            }
        }
    }
}
