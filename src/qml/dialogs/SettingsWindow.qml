import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Kaakao

KaakaoWindow {
    id: settingsWindow
    title: qsTr("Settings")
    width: 480
    height: 400
    
    // Make it a singleton-like behavior from Main
    flags: Qt.Window | Qt.WindowStaysOnTopHint

    ColumnLayout {
        anchors {
            fill: parent
            margins: Theme.standardPadding
        }
        spacing: Theme.layoutSpacing

        KaakaoLabel {
            text: qsTr("Application Settings")
            role: KaakaoLabel.Header
        }

        // --- Cache Section ---
        KaakaoGroupBox {
            title: qsTr("Performance & Cache")
            Layout.fillWidth: true
            
            ColumnLayout {
                anchors.fill: parent
                spacing: Theme.paddingMedium

                RowLayout {
                    Layout.fillWidth: true
                    KaakaoLabel {
                        text: qsTr("Thumbnail Cache Usage:")
                        Layout.fillWidth: true
                    }
                    KaakaoLabel {
                        id: cacheSizeLabel
                        text: formatBytes(imageProviderProxy.cacheSize)
                        font.weight: Font.Bold
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    KaakaoLabel {
                        text: qsTr("Memory Cache Limit:")
                        Layout.fillWidth: true
                    }
                    KaakaoComboBox {
                        id: memoryCacheLimitCombo
                        model: ["512 MB", "1 GB", "2 GB", "4 GB", "8 GB"]
                        currentIndex: {
                            if (typeof appSettings === "undefined") return 2;
                            let mb = appSettings.maxMemoryCacheSizeMB
                            if (mb <= 512) return 0;
                            if (mb <= 1024) return 1;
                            if (mb <= 2048) return 2;
                            if (mb <= 4096) return 3;
                            return 4;
                        }
                        onActivated: (index) => {
                            if (typeof appSettings === "undefined") return;
                            let values = [512, 1024, 2048, 4096, 8192]
                            let selectedMB = values[index]
                            appSettings.maxMemoryCacheSizeMB = selectedMB
                            imageProvider.maxMemoryCacheSize = selectedMB * 1024 * 1024
                        }
                    }
                }

                KaakaoLabel {
                    text: qsTr("Storage Location: ") + imageProviderProxy.cachePath
                    role: KaakaoLabel.Small
                    Layout.fillWidth: true
                    elide: Text.ElideMiddle
                }

                KaakaoButton {
                    text: qsTr("Clear Thumbnail Cache")
                    Layout.alignment: Qt.AlignRight
                    onClicked: {
                        imageProviderProxy.clearDiskCache()
                        refreshTimer.start()
                    }
                }
            }
        }

        // --- General Settings Section ---
        KaakaoGroupBox {
            title: qsTr("General Settings")
            Layout.fillWidth: true

            ColumnLayout {
                anchors.fill: parent
                spacing: Theme.paddingMedium

                RowLayout {
                    Layout.fillWidth: true
                    KaakaoLabel {
                        text: qsTr("Confirm before moving images to Trash")
                        Layout.fillWidth: true
                    }
                    KaakaoCheckBox {
                        checked: typeof appSettings !== "undefined" ? appSettings.confirmDeletions : true
                        onToggled: {
                            if (typeof appSettings !== "undefined") {
                                appSettings.confirmDeletions = checked;
                            }
                        }
                    }
                }
            }
        }

        // --- Diagnostics Section ---
        KaakaoGroupBox {
            title: qsTr("Diagnostics")
            Layout.fillWidth: true

            ColumnLayout {
                anchors.fill: parent
                spacing: Theme.paddingMedium

                RowLayout {
                    Layout.fillWidth: true
                    KaakaoLabel {
                        text: qsTr("Enable Developer Logging")
                        Layout.fillWidth: true
                    }
                    KaakaoCheckBox {
                        checked: logger.loggingEnabled
                        onToggled: logger.loggingEnabled = checked
                    }
                }

                KaakaoLabel {
                    text: qsTr("Log File: ") + logger.logFilePath
                    role: KaakaoLabel.Small
                    Layout.fillWidth: true
                    elide: Text.ElideMiddle
                    visible: logger.loggingEnabled
                }
            }
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true
            Item { Layout.fillWidth: true }
            KaakaoButton {
                text: qsTr("Close")
                onClicked: settingsWindow.close()
            }
        }
    }

    // Proxy object to track cache size changes
    QtObject {
        id: imageProviderProxy
        property real cacheSize: 0
        property string cachePath: ""

        Component.onCompleted: update()
        
        function update() {
            cacheSize = imageProvider.cacheSize()
            cachePath = imageProvider.cachePath()
        }
    }

    Timer {
        id: refreshTimer
        interval: 500
        onTriggered: imageProviderProxy.update()
    }

    function formatBytes(bytes) {
        if (bytes === 0) return "0 Bytes";
        if (!bytes) return "Calculating...";
        const k = 1024;
        const sizes = ['Bytes', 'KB', 'MB', 'GB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
    }
    
    onVisibleChanged: {
        if (visible) imageProviderProxy.update()
    }
}
