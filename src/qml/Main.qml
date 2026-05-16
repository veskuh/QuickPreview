import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Qt.labs.platform
import Qt.labs.settings
import Kaakao

KaakaoWindow {
    id: root
    visible: true
    width: 900
    height: 600
    title: qsTr("QuickPreview")

    Settings {
        property alias x: root.x
        property alias y: root.y
        property alias width: root.width
        property alias height: root.height
    }

    Binding {
        target: root
        property: "visibility"
        value: previewOverlay.visible ? Window.FullScreen : Window.Windowed
    }

    Component.onCompleted: {
        var pictures = StandardPaths.writableLocation(StandardPaths.PicturesLocation)
        console.log("Starting initial scan of Pictures folder:", pictures)
        galleryModel.clear()
        discoveryService.scanDirectory(pictures)
    }

    property bool showMainInfo: false

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
                            text: showMainInfo ? qsTr("Hide Info") : qsTr("Show Info")
                            onClicked: showMainInfo = !showMainInfo
                        }

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

                        onDoubleClicked: {
                            previewOverlay.currentIndex = index
                            previewOverlay.visible = true
                        }

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

        Item {
            id: mainInfoPanel
            SplitView.preferredWidth: 250
            SplitView.minimumWidth: 200
            visible: showMainInfo
            
            Rectangle {
                anchors.fill: parent
                color: Theme.windowBackground
                
                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 1
                    color: Theme.isDarkMode ? "#33FFFFFF" : "#33000000"
                }

                Column {
                    id: infoContentColumn
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 15

                    readonly property string currentPath: galleryGrid.currentIndex >= 0 ? galleryModel.data(galleryModel.index(galleryGrid.currentIndex, 0), 259) : ""
                    readonly property var exifData: (currentPath && typeof exifReader !== 'undefined' && exifReader) ? exifReader.getExifData(currentPath) : ({})

                    KaakaoLabel {
                        text: qsTr("Information")
                        role: KaakaoLabel.Header
                    }

                    Rectangle {
                        width: parent.width
                        height: 150
                        color: "#F0F0F0"
                        radius: 4
                        visible: infoContentColumn.currentPath !== ""
                        
                        Image {
                            anchors.fill: parent
                            anchors.margins: 5
                            source: infoContentColumn.currentPath ? "image://gallery/" + infoContentColumn.currentPath : ""
                            sourceSize: Qt.size(300, 300)
                            fillMode: Image.PreserveAspectFit
                        }
                    }

                    KaakaoLabel {
                        text: galleryGrid.currentIndex >= 0 ? galleryModel.data(galleryModel.index(galleryGrid.currentIndex, 0), 258) : "" // FileNameRole
                        width: parent.width
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        font.weight: Font.Bold
                    }

                    Repeater {
                        model: [
                            { label: "Make", value: infoContentColumn.exifData.Make },
                            { label: "Model", value: infoContentColumn.exifData.Model },
                            { label: "Lens", value: infoContentColumn.exifData.Lens },
                            { label: "Exposure", value: infoContentColumn.exifData.Exposure },
                            { label: "Aperture", value: infoContentColumn.exifData.Aperture },
                            { label: "ISO", value: infoContentColumn.exifData.ISO },
                            { label: "Date", value: infoContentColumn.exifData.DateTime }
                        ]
                        delegate: Column {
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
    }

    PreviewOverlay {
        id: previewOverlay
        model: galleryModel
        z: 100
    }
}
