pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCore
import Kaakao

KaakaoWindow {
    id: root
    visible: true
    width: 900
    height: 600
    title: qsTr("QuickPreview")

    menuBar: MenuBar {
        Menu {
            title: qsTr("&File")
            MenuItem {
                text: qsTr("&Refresh")
                onTriggered: {
                    let pictures = StandardPaths.writableLocation(StandardPaths.PicturesLocation)
                    console.log("Refreshing gallery from:", pictures)
                    galleryModel.clear()
                    discoveryService.scanDirectory(pictures)
                }
            }
            MenuSeparator {}
            MenuItem {
                text: qsTr("&About")
                onTriggered: aboutDialog.show()
            }
            MenuSeparator {}
            MenuItem {
                text: qsTr("&Quit")
                onTriggered: Qt.quit()
            }
        }
        Menu {
            title: qsTr("&View")
            MenuItem {
                text: root.showMainInfo ? qsTr("Hide &Info") : qsTr("Show &Info")
                onTriggered: root.showMainInfo = !root.showMainInfo
            }
        }
        Menu {
            title: qsTr("&Developer")
            MenuItem {
                text: qsTr("&Logging Enabled")
                checkable: true
                checked: logger.loggingEnabled
                onTriggered: {
                    logger.loggingEnabled = checked
                    if (checked) {
                        logPathDisplay.text = logger.logFilePath
                        logNotification.open()
                    }
                }
            }
        }
    }

    Dialog {
        id: logNotification
        title: qsTr("Developer Logging")
        standardButtons: Dialog.Ok
        anchors.centerIn: parent
        modal: true
        
        ColumnLayout {
            spacing: 10
            KaakaoLabel {
                text: qsTr("Diagnostic logging is now active. You can find the log file at:")
                Layout.maximumWidth: 400
                wrapMode: Text.WordWrap
            }
            KaakaoTextArea {
                id: logPathDisplay
                readOnly: true
                Layout.fillWidth: true
                font.family: "Monaco"
                font.pixelSize: 11
                background: Rectangle {
                    color: Theme.isDarkMode ? "#222" : "#EEE"
                    radius: 4
                }
            }
        }
    }


    AboutDialog {
        id: aboutDialog
    }

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
        let pictures = StandardPaths.writableLocation(StandardPaths.PicturesLocation)
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
                        anchors {
                            fill: parent
                            leftMargin: 10
                            rightMargin: 10
                        }
                        
                        KaakaoLabel {
                            text: qsTr("Library")
                            role: KaakaoLabel.Header
                        }
                        
                        Item { Layout.fillWidth: true }

                        KaakaoButton {
                            text: root.showMainInfo ? qsTr("Hide Info") : qsTr("Show Info")
                            onClicked: root.showMainInfo = !root.showMainInfo
                        }

                        KaakaoButton {
                            text: qsTr("Refresh")
                            onClicked: {
                                let pictures = StandardPaths.writableLocation(StandardPaths.PicturesLocation)
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
                        required property var model
                        required property int index

                        width: galleryGrid.cellWidth
                        height: galleryGrid.cellHeight

                        onDoubleClicked: {
                            previewOverlay.currentIndex = index
                            previewOverlay.visible = true
                        }

                        Column {
                            anchors {
                                fill: parent
                                margins: 4
                            }
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
                                    anchors {
                                        fill: parent
                                        margins: 2
                                    }
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
            visible: root.showMainInfo
            
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
                            anchors {
                                fill: parent
                                margins: 5
                            }
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
    }

    PreviewOverlay {
        id: previewOverlay
        model: galleryModel
        z: 100
    }
}
