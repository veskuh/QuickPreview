#include "VolumeMonitor.h"
#include <QDebug>
#include <QDir>

VolumeMonitor::VolumeMonitor(QObject *parent)
    : QObject(parent)
{
    // Initial state
    for (const QStorageInfo &storage : QStorageInfo::mountedVolumes()) {
        if (storage.isValid() && storage.isReady()) {
            m_lastVolumes << storage.rootPath();
        }
    }
    updateSdCardPath();

    QTimer *timer = new QTimer(this);
    connect(timer, &QTimer::timeout, this, &VolumeMonitor::checkVolumes);
    timer->start(3000); // Check every 3 seconds for better responsiveness
}

void VolumeMonitor::checkVolumes()
{
    QStringList currentVolumes;
    for (const QStorageInfo &storage : QStorageInfo::mountedVolumes()) {
        if (storage.isValid() && storage.isReady()) {
            currentVolumes << storage.rootPath();
        }
    }

    bool changed = false;

    // Find new volumes
    for (const QString &path : currentVolumes) {
        if (!m_lastVolumes.contains(path)) {
            qDebug() << "Volume mounted:" << path;
            emit volumeMounted(path);
            changed = true;
        }
    }

    // Find unmounted volumes
    for (const QString &path : m_lastVolumes) {
        if (!currentVolumes.contains(path)) {
            qDebug() << "Volume unmounted:" << path;
            emit volumeUnmounted(path);
            changed = true;
        }
    }

    m_lastVolumes = currentVolumes;
    
    if (changed) {
        updateSdCardPath();
    }
}

void VolumeMonitor::updateSdCardPath()
{
    QString bestPath;
    
    for (const QStorageInfo &storage : QStorageInfo::mountedVolumes()) {
        if (!storage.isValid() || !storage.isReady() || storage.isRoot()) {
            continue;
        }
        
        QString path = storage.rootPath();
        
        // Strategy: Look for DCIM folder which is standard for cameras
        QDir dcimDir(path + "/DCIM");
        if (dcimDir.exists()) {
            bestPath = path;
            break; 
        }
    }
    
    if (m_sdCardPath != bestPath) {
        m_sdCardPath = bestPath;
        qDebug() << "SD Card Path updated:" << m_sdCardPath;
        emit sdCardPathChanged();
    }
}
