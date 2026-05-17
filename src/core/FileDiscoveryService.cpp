#include "FileDiscoveryService.h"
#include <QDir>
#include <QDirIterator>
#include <QtConcurrent>

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

    (void)QtConcurrent::run([this, localPath, recursive]() {
        doScan(localPath, recursive);
    });
}

void FileDiscoveryService::doScan(const QString &path, bool recursive)
{
    qDebug() << "Scanning directory:" << path << (recursive ? "(recursive)" : "");
    QDir dir(path);
    if (!dir.exists()) {
        qWarning() << "Directory does not exist:" << path;
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

    if (!paths.isEmpty()) {
        emit imagesDiscovered(paths);
    }
    emit scanFinished();
}
