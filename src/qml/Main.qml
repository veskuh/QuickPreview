pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtCore
import Kaakao
import "."

KaakaoWindow {
    id: root
    visible: true
    visibility: Window.Windowed
    width: 900
    height: 600
    title: qsTr("NinjaView")

    Shortcut {
        id: galleryShortcut
        objectName: "galleryShortcut"
        sequences: ["Space", "Return", "Enter"]
        enabled: !previewOverlay.visible && galleryGrid.gridView.activeFocus
        onActivated: {
            if (galleryGrid.currentIndex >= 0) {
                previewOverlay.currentIndex = galleryGrid.currentIndex
                previewOverlay.visible = true
            }
        }
    }

    menuBar: MenuBar {
        Menu {
            title: qsTr("&File")
            MenuItem {
                text: qsTr("Add Folder...")
                onTriggered: folderDialog.open()
            }
            MenuItem {
                text: qsTr("Remove Folder")
                enabled: {
                    if (sidebar.currentIndex < 0 || sidebar.currentIndex >= sidebarModel.count) return false;
                    let item = sidebarModel.get(sidebar.currentIndex);
                    return item.category === qsTr("Folders") && item.path !== undefined;
                }
                onTriggered: {
                    removeConfirmationDialog.targetIndex = sidebar.currentIndex
                    removeConfirmationDialog.folderName = sidebarModel.get(sidebar.currentIndex).name
                    removeConfirmationDialog.open()
                }
            }
            MenuSeparator {}
            MenuItem {
                text: qsTr("&Refresh")
                onTriggered: {
                    galleryModel.clear()
                    let item = sidebarModel.get(sidebar.currentIndex)
                    if (sidebar.currentIndex === 0) {
                        let pictures = StandardPaths.writableLocation(StandardPaths.PicturesLocation)
                        discoveryService.scanDirectory(pictures)
                    } else if (sidebar.currentIndex === 1) {
                        if (volumeMonitor.sdCardPath !== "") {
                            discoveryService.scanDirectory(volumeMonitor.sdCardPath + "/DCIM", true)
                        }
                    } else if (item && item.path !== undefined) {
                        discoveryService.scanDirectory(item.path, false)
                    }
                }
            }
            MenuSeparator {}
            MenuItem {
                text: qsTr("&Settings...")
                onTriggered: settingsWindow.show()
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
    }

    SettingsWindow {
        id: settingsWindow
    }

    AboutDialog {
        id: aboutDialog
    }

    KaakaoMenu {
        id: sidebarContextMenu
        property int targetIndex: -1
        KaakaoMenuItem {
            text: qsTr("Remove Folder")
            enabled: {
                if (sidebarContextMenu.targetIndex < 0 || sidebarContextMenu.targetIndex >= sidebarModel.count) return false;
                let item = sidebarModel.get(sidebarContextMenu.targetIndex);
                return item.category === qsTr("Folders") && item.path !== undefined;
            }
            onTriggered: {
                removeConfirmationDialog.targetIndex = sidebarContextMenu.targetIndex
                removeConfirmationDialog.folderName = sidebarModel.get(sidebarContextMenu.targetIndex).name
                removeConfirmationDialog.open()
            }
        }
    }

    KaakaoDialog {
        id: removeConfirmationDialog
        anchors.centerIn: parent
        property int targetIndex: -1
        property string folderName: ""
        title: qsTr("Remove Folder")
        text: qsTr("Are you sure you want to remove '%1' from the sidebar?").arg(folderName)
        standardButtons: Dialog.Yes | Dialog.No
        onAccepted: {
            if (targetIndex >= 0) {
                removeFolder(targetIndex)
            }
        }
    }

    Settings {
        id: appSettings
        property alias x: root.x
        property alias y: root.y
        property alias width: root.width
        property alias height: root.height
        property string savedFolders: "[]"
    }

    ListModel {
        id: sidebarModel
    }

    FolderDialog {
        id: folderDialog
        title: qsTr("Choose a folder to add to NinjaView")
        onAccepted: {
            addFolder(selectedFolder.toString())
        }
    }

    function loadSidebar() {
        sidebarModel.clear()
        sidebarModel.append({ name: qsTr("Pictures"), icon: "🖼️", category: qsTr("Library") })
        sidebarModel.append({ name: qsTr("SD Card"), icon: "💾", category: qsTr("Devices") })
        
        let folders = JSON.parse(appSettings.savedFolders)
        for (let i = 0; i < folders.length; ++i) {
            let path = folders[i]
            // Extract folder name from path
            let parts = path.split("/")
            let name = parts[parts.length - 1] || parts[parts.length - 2] || path
            sidebarModel.append({ 
                name: name, 
                icon: "📁", 
                category: qsTr("Folders"), 
                path: path 
            })
        }
    }

    function addFolder(path) {
        // path is already a string representation of the URL
        
        // Deduplication
        for (let i = 0; i < sidebarModel.count; ++i) {
            if (sidebarModel.get(i).path === path) {
                sidebar.currentIndex = i
                return
            }
        }

        // Extract folder name from the path string
        // We handle both / and \ for cross-platform, but primarily / for URLs
        let decodedPath = decodeURIComponent(path)
        let parts = decodedPath.split("/")
        let name = parts[parts.length - 1] || parts[parts.length - 2] || decodedPath
        if (name.endsWith("/")) name = name.substring(0, name.length - 1)

        sidebarModel.append({ 
            name: name, 
            icon: "📁", 
            category: qsTr("Folders"), 
            path: path 
        })
        
        // Save
        let folders = JSON.parse(appSettings.savedFolders)
        folders.push(path)
        appSettings.savedFolders = JSON.stringify(folders)
        
        sidebar.currentIndex = sidebarModel.count - 1
    }

    function removeFolder(index) {
        let item = sidebarModel.get(index)
        if (item.path === undefined) return
        
        let path = item.path
        sidebarModel.remove(index)
        
        let folders = JSON.parse(appSettings.savedFolders)
        let newFolders = folders.filter(f => f !== path)
        appSettings.savedFolders = JSON.stringify(newFolders)
        
        if (sidebar.currentIndex === index) {
            sidebar.currentIndex = 0
        }
    }

    readonly property bool fullScreenEnabled: allowFullScreen
    readonly property int requestedVisibility: previewOverlay.visible ? Window.FullScreen : Window.Windowed

    onRequestedVisibilityChanged: {
        if (fullScreenEnabled && visibility !== requestedVisibility) {
            root.visibility = requestedVisibility
        }
    }

    Component.onCompleted: {
        loadSidebar()
        let pictures = StandardPaths.writableLocation(StandardPaths.PicturesLocation)
        console.log("Starting initial scan of Pictures folder:", pictures)
        galleryModel.clear()
        discoveryService.scanDirectory(pictures)
    }

    property bool showMainInfo: false
    property string currentTitle: qsTr("Pictures")
    property string currentFolderDescription: ""

    Connections {
        target: volumeMonitor
        function onSdCardPathChanged() {
            if (sidebar.currentIndex === 1 && volumeMonitor.sdCardPath !== "") {
                console.log("SD Card detected, scanning:", volumeMonitor.sdCardPath)
                galleryModel.clear()
                discoveryService.scanDirectory(volumeMonitor.sdCardPath + "/DCIM", true)
            }
        }
    }

    function handleDrop(url) {
        let path = url.toString()
        if (path.startsWith("file://")) {
            // We use FolderDialog to check if it's a folder or file by checking extensions
            // since QML doesn't have a direct "isFolder" check for OS paths without C++
            let extensions = [".jpg", ".jpeg", ".png", ".bmp", ".webp"]
            let lowerPath = path.toLowerCase()
            let isImage = false
            for (let ext of extensions) {
                if (lowerPath.endsWith(ext)) {
                    isImage = true
                    break
                }
            }

            if (isImage) {
                // If it's an image, add the parent folder
                let parts = path.split("/")
                parts.pop() // remove filename
                path = parts.join("/")
            }
            
            addFolder(path)
        }
    }

    KaakaoSplitView {
        anchors.fill: parent
        orientation: Qt.Horizontal

        KaakaoSidebar {
            id: sidebar
            SplitView.preferredWidth: 200
            SplitView.minimumWidth: 150
            SplitView.maximumWidth: 300

            model: sidebarModel

            DropArea {
                anchors.fill: parent
                onDropped: (drop) => {
                    if (drop.hasUrls) {
                        for (let url of drop.urls) {
                            handleDrop(url)
                        }
                    }
                }
            }

            onContextMenu: (index, pos) => {
                let item = sidebarModel.get(index)
                if (item.path !== undefined) {
                    sidebarContextMenu.targetIndex = index
                    sidebarContextMenu.popup(pos.x, pos.y)
                }
            }

            onCurrentIndexChanged: {
                if (currentIndex < 0 || currentIndex >= sidebarModel.count) return
                
                let item = sidebarModel.get(currentIndex)
                root.currentTitle = item.name
                root.currentFolderDescription = ""
                
                if (currentIndex === 0) {
                    let pictures = StandardPaths.writableLocation(StandardPaths.PicturesLocation)
                    galleryModel.clear()
                    discoveryService.scanDirectory(pictures)
                } else if (currentIndex === 1) {
                    if (volumeMonitor.sdCardPath !== "") {
                        galleryModel.clear()
                        discoveryService.scanDirectory(volumeMonitor.sdCardPath + "/DCIM", true)
                    } else {
                        galleryModel.clear()
                        console.log("No SD Card detected")
                    }
                } else if (item.path !== undefined) {
                    root.currentFolderDescription = item.path
                    galleryModel.clear()
                    discoveryService.scanDirectory(item.path, false)
                }
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
                        
                        Column {
                            spacing: 0
                            KaakaoLabel {
                                text: root.currentTitle
                                role: KaakaoLabel.Header
                                visible: root.currentFolderDescription === ""
                            }
                            KaakaoPathControl {
                                id: pathControl
                                
                                readonly property string homePath: String(StandardPaths.writableLocation(StandardPaths.HomeLocation)).replace("file://", "")
                                readonly property string displayBasePath: {
                                    let p = String(root.currentFolderDescription).replace("file://", "")
                                    if (p.startsWith(homePath)) return homePath
                                    return "/"
                                }
                                
                                rootLabel: {
                                    if (displayBasePath === "/") return qsTr("Root")
                                    return displayBasePath.substring(displayBasePath.lastIndexOf("/") + 1)
                                }
                                
                                path: {
                                    let p = String(root.currentFolderDescription).replace("file://", "")
                                    if (p.startsWith(displayBasePath)) {
                                        let rel = p.substring(displayBasePath.length)
                                        if (rel.startsWith("/")) rel = rel.substring(1)
                                        return rel
                                    }
                                    return p
                                }
                                
                                visible: root.currentFolderDescription !== ""
                                
                                onPathClicked: (targetPath) => {
                                    // Reconstruct absolute path
                                    let fullPath = displayBasePath
                                    if (targetPath !== "") {
                                        if (fullPath !== "/") {
                                            fullPath += "/" + targetPath
                                        } else {
                                            fullPath += targetPath
                                        }
                                    }
                                    
                                    // Extract folder name for title
                                    let parts = targetPath.split("/")
                                    let name = parts[parts.length - 1] || root.currentTitle
                                    if (targetPath === "") {
                                        if (displayBasePath === "/") name = qsTr("Root")
                                        else name = displayBasePath.substring(displayBasePath.lastIndexOf("/") + 1)
                                    }
                                    
                                    // Update state
                                    root.currentTitle = name
                                    root.currentFolderDescription = fullPath
                                    
                                    // Deselect sidebar since we are now browsing away from the bookmark
                                    sidebar.currentIndex = -1
                                    
                                    // Navigate
                                    galleryModel.clear()
                                    discoveryService.scanDirectory(fullPath, false)
                                }
                            }
                        }
                        
                        Item { Layout.fillWidth: true }

                        KaakaoButton {
                            text: root.showMainInfo ? qsTr("Hide Info") : qsTr("Show Info")
                            onClicked: root.showMainInfo = !root.showMainInfo
                        }

                        KaakaoButton {
                            text: qsTr("Refresh")
                            onClicked: {
                                galleryModel.clear()
                                let item = sidebarModel.get(sidebar.currentIndex)
                                if (sidebar.currentIndex === 0) {
                                    let pictures = StandardPaths.writableLocation(StandardPaths.PicturesLocation)
                                    discoveryService.scanDirectory(pictures)
                                } else if (sidebar.currentIndex === 1) {
                                    if (volumeMonitor.sdCardPath !== "") {
                                        discoveryService.scanDirectory(volumeMonitor.sdCardPath + "/DCIM", true)
                                    }
                                } else if (item && item.path !== undefined) {
                                    discoveryService.scanDirectory(item.path, false)
                                }
                            }
                        }
                    }
                }

                KaakaoGridView {
                    id: galleryGrid
                    objectName: "galleryGrid"
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
        objectName: "previewOverlay"
        model: galleryModel
        z: 100
    }
}
