#include "FileDiscoveryService.h"
#include <QDir>
#include <QDirIterator>
#include <QtConcurrent>
#include <QMutexLocker>

FileDiscoveryService::FileDiscoveryService(QObject *parent)
    : QObject(parent)
{
}

void FileDiscoveryService::scanDirectory(const QString &path, bool recursive)
{
    QString localPath = path;
    if (path.startsWith("file://")) {
        localPath = QUrl(path).toLocalFile();
    }

    quint64 scanId = 0;
    {
        QMutexLocker locker(&m_scanMutex);
        m_currentScanId++;
        scanId = m_currentScanId;
    }

    if (!m_isScanning) {
        m_isScanning = true;
        emit isScanningChanged();
    }

    (void)QtConcurrent::run([this, localPath, recursive, scanId]() {
        doScan(localPath, recursive, scanId);
    });
}

void FileDiscoveryService::doScan(const QString &path, bool recursive, quint64 scanId)
{
    qDebug() << "Scanning directory:" << path << (recursive ? "(recursive)" : "");
    QDir dir(path);
    if (!dir.exists()) {
        qWarning() << "Directory does not exist:" << path;
        {
            QMutexLocker locker(&m_scanMutex);
            if (scanId != m_currentScanId) {
                return;
            }
        }
        m_isScanning = false;
        emit isScanningChanged();
        emit scanFinished();
        return;
    }

    QStringList filters;
    filters << "*.jpg" << "*.jpeg" << "*.png" << "*.bmp" << "*.webp"
            << "*.JPG" << "*.JPEG" << "*.PNG" << "*.BMP" << "*.WEBP";
    
    QStringList paths;
    
    if (recursive) {
        QDirIterator it(path, filters, QDir::Files | QDir::NoDotAndDotDot, QDirIterator::Subdirectories);
        while (it.hasNext()) {
            paths << it.next();
        }
    } else {
        dir.setNameFilters(filters);
        dir.setFilter(QDir::Files | QDir::NoDotAndDotDot);
        QFileInfoList list = dir.entryInfoList();
        for (const QFileInfo &fileInfo : list) {
            paths << fileInfo.absoluteFilePath();
        }
    }

    qDebug() << "Found" << paths.count() << "images in" << path;

    // Verify scanId before updating the model or emitting finished signals
    {
        QMutexLocker locker(&m_scanMutex);
        if (scanId != m_currentScanId) {
            qDebug() << "Ignoring completed scan with outdated ID:" << scanId << "current:" << m_currentScanId;
            return;
        }
    }

    if (!paths.isEmpty()) {
        emit imagesDiscovered(paths);
    }
    
    m_isScanning = false;
    emit isScanningChanged();
    emit scanFinished();
}

