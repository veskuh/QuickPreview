#include "FileDiscoveryService.h"
#include <QDir>
#include <QtConcurrent>

FileDiscoveryService::FileDiscoveryService(QObject *parent)
    : QObject(parent)
{
}

void FileDiscoveryService::scanDirectory(const QString &path)
{
    QString localPath = path;
    if (path.startsWith("file://")) {
        localPath = QUrl(path).toLocalFile();
    }

    (void)QtConcurrent::run([this, localPath]() {
        doScan(localPath);
    });
}

void FileDiscoveryService::doScan(const QString &path)
{
    qDebug() << "Scanning directory:" << path;
    QDir dir(path);
    if (!dir.exists()) {
        qWarning() << "Directory does not exist:" << path;
        emit scanFinished();
        return;
    }

    QStringList filters;
    filters << "*.jpg" << "*.jpeg" << "*.png" << "*.bmp" << "*.webp"
            << "*.JPG" << "*.JPEG" << "*.PNG" << "*.BMP" << "*.WEBP";
    dir.setNameFilters(filters);
    dir.setFilter(QDir::Files | QDir::NoDotAndDotDot);

    QStringList paths;
    QFileInfoList list = dir.entryInfoList();
    for (const QFileInfo &fileInfo : list) {
        paths << fileInfo.absoluteFilePath();
    }

    qDebug() << "Found" << paths.count() << "images in" << path;

    if (!paths.isEmpty()) {
        emit imagesDiscovered(paths);
    }
    emit scanFinished();
}
