#include "FileDiscoveryService.h"
#include <QDir>
#include <QtConcurrent>

FileDiscoveryService::FileDiscoveryService(QObject *parent)
    : QObject(parent)
{
}

void FileDiscoveryService::scanDirectory(const QString &path)
{
    QtConcurrent::run([this, path]() {
        doScan(path);
    });
}

void FileDiscoveryService::doScan(const QString &path)
{
    QDir dir(path);
    if (!dir.exists()) {
        emit scanFinished();
        return;
    }

    QStringList filters;
    filters << "*.jpg" << "*.jpeg" << "*.png" << "*.bmp" << "*.webp";
    dir.setNameFilters(filters);
    dir.setFilter(QDir::Files | QDir::NoDotAndDotDot);

    // Initial simple implementation: find all and emit once
    // For large directories, we might want to emit in batches
    QStringList paths;
    QFileInfoList list = dir.entryInfoList();
    for (const QFileInfo &fileInfo : list) {
        paths << fileInfo.absoluteFilePath();
    }

    if (!paths.isEmpty()) {
        emit imagesDiscovered(paths);
    }
    emit scanFinished();
}
