#include "FileActionService.h"
#include <QDesktopServices>
#include <QUrl>
#include <QFileInfo>
#include <QProcess>
#include <QFile>
#include <QDebug>

FileActionService::FileActionService(QObject *parent) : QObject(parent)
{
}

void FileActionService::showInFolder(const QString &filePath)
{
    QString localPath = filePath;
    if (filePath.startsWith("file://")) {
        localPath = QUrl(filePath).toLocalFile();
    }

#ifdef Q_OS_MAC
    QStringList args;
    args << "-e" << "tell application \"Finder\""
         << "-e" << QString("reveal POSIX file \"%1\"").arg(localPath)
         << "-e" << "activate"
         << "-e" << "end tell";
    QProcess::execute("osascript", args);
#else
    QDesktopServices::openUrl(QUrl::fromLocalFile(QFileInfo(localPath).absolutePath()));
#endif
}

void FileActionService::openExternally(const QString &filePath)
{
    QString localPath = filePath;
    if (filePath.startsWith("file://")) {
        localPath = QUrl(filePath).toLocalFile();
    }
    QDesktopServices::openUrl(QUrl::fromLocalFile(localPath));
}

bool FileActionService::moveToTrash(const QString &filePath)
{
    QString localPath = filePath;
    if (filePath.startsWith("file://")) {
        localPath = QUrl(filePath).toLocalFile();
    }
    
    qDebug() << "Moving to trash:" << localPath;
    return QFile::moveToTrash(localPath);
}
