import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Qt.labs.platform
import Kaakao

KaakaoWindow {
    id: root
    visible: true
    width: 900
    height: 600
    title: qsTr("QuickPreview")

    Component.onCompleted: {
        var pictures = StandardPaths.writableLocation(StandardPaths.PicturesLocation)
        console.log("Starting initial scan of Pictures folder:", pictures)
        galleryModel.clear()
        discoveryService.scanDirectory(pictures)
    }

    KaakaoSplitView {
        anchors.fill: parent
        orientation: Qt.Horizontal

        KaakaoSidebar {
            id: sidebar
            SplitView.preferredWidth: 200
            SplitView.minimumWidth: 150
            SplitView.maximumWidth: 300

            model: ListModel {
                ListElement { name: qsTr("All Photos"); icon: "🖼️"; category: qsTr("Library") }
                ListElement { name: qsTr("Recent"); icon: "🕒"; category: qsTr("Library") }
                ListElement { name: qsTr("SD Card"); icon: "💾"; category: qsTr("Devices") }
            }
        }

        Item {
            SplitView.fillWidth: true
            
            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                KaakaoToolBar {
                    Layout.fillWidth: true
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        
                        KaakaoLabel {
                            text: qsTr("Library")
                            role: KaakaoLabel.Header
                        }
                        
                        Item { Layout.fillWidth: true }

                        KaakaoButton {
                            text: qsTr("Refresh")
                            onClicked: {
                                var pictures = StandardPaths.writableLocation(StandardPaths.PicturesLocation)
                                console.log("Refreshing gallery from:", pictures)
                                galleryModel.clear()
                                discoveryService.scanDirectory(pictures)
                            }
                        }
                    }
                }

                KaakaoGridView {
                    id: galleryGrid
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    
                    model: galleryModel
                    cellWidth: 120
                    cellHeight: 140

                    delegate: KaakaoGridDelegate {
                        width: galleryGrid.cellWidth
                        height: galleryGrid.cellHeight

                        Column {
                            anchors.fill: parent
                            anchors.margins: 4
                            spacing: 8

                            Item {
                                width: parent.width
                                height: width
                                
                                Rectangle {
                                    anchors.fill: parent
                                    color: "#F0F0F0"
                                    radius: 4
                                    visible: thumbnail.status !== Image.Ready
                                }

                                Image {
                                    id: thumbnail
                                    anchors.fill: parent
                                    anchors.margins: 2
                                    source: "image://gallery/" + model.rawPath
                                    sourceSize: Qt.size(200, 200)
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                    onStatusChanged: {
                                        if (status === Image.Error) {
                                            console.error("Failed to load thumbnail for:", model.rawPath)
                                        }
                                    }
                                }
                            }

                            KaakaoLabel {
                                width: parent.width
                                text: model.fileName
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideMiddle
                                font.pixelSize: 11
                                color: isSelected && galleryGrid.gridView.activeFocus ? "#FFFFFF" : Theme.primaryText
                            }
                        }
                    }
                }
            }
        }
    }
}
