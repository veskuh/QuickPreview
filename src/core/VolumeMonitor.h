#pragma once

#include <QObject>
#include <QStorageInfo>
#include <QTimer>
#include <QStringList>

class VolumeMonitor : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString sdCardPath READ sdCardPath NOTIFY sdCardPathChanged)

public:
    explicit VolumeMonitor(QObject *parent = nullptr);
    QString sdCardPath() const { return m_sdCardPath; }

signals:
    void volumeMounted(const QString &path);
    void volumeUnmounted(const QString &path);
    void sdCardPathChanged();

private slots:
    void checkVolumes();

private:
    QStringList m_lastVolumes;
    QString m_sdCardPath;
    void updateSdCardPath();
};
