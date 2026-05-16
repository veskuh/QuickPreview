#pragma once

#include <QObject>
#include <QStorageInfo>
#include <QTimer>
#include <QStringList>

class VolumeMonitor : public QObject
{
    Q_OBJECT

public:
    explicit VolumeMonitor(QObject *parent = nullptr);

signals:
    void volumeMounted(const QString &path);
    void volumeUnmounted(const QString &path);

private slots:
    void checkVolumes();

private:
    QStringList m_lastVolumes;
};
