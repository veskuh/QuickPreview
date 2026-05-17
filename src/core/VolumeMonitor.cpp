#include "VolumeMonitor.h"
#include <QDebug>

VolumeMonitor::VolumeMonitor(QObject *parent)
    : QObject(parent)
{
    // Initial state
    for (const QStorageInfo &storage : QStorageInfo::mountedVolumes()) {
        if (storage.isValid() && storage.isReady()) {
            m_lastVolumes << storage.rootPath();
        }
    }

    QTimer *timer = new QTimer(this);
    connect(timer, &QTimer::timeout, this, &VolumeMonitor::checkVolumes);
    timer->start(10000); // Check every 10 seconds
}

void VolumeMonitor::checkVolumes()
{
    QStringList currentVolumes;
    for (const QStorageInfo &storage : QStorageInfo::mountedVolumes()) {
        if (storage.isValid() && storage.isReady()) {
            currentVolumes << storage.rootPath();
        }
    }

    // Find new volumes
    for (const QString &path : currentVolumes) {
        if (!m_lastVolumes.contains(path)) {
            qDebug() << "Volume mounted:" << path;
            emit volumeMounted(path);
        }
    }

    // Find unmounted volumes
    for (const QString &path : m_lastVolumes) {
        if (!currentVolumes.contains(path)) {
            qDebug() << "Volume unmounted:" << path;
            emit volumeUnmounted(path);
        }
    }

    m_lastVolumes = currentVolumes;
}
