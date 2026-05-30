#pragma once

#include <QObject>
#include <QSqlDatabase>
#include <QVariantMap>
#include <QDateTime>

class ExifDatabase : public QObject
{
    Q_OBJECT
public:
    explicit ExifDatabase(QObject *parent = nullptr);
    ~ExifDatabase();

    bool init();

    bool isCached(const QString &filePath, qint64 fileSize, const QDateTime &lastModified);
    QVariantMap getExifData(const QString &filePath);
    bool saveExifData(const QString &filePath, qint64 fileSize, const QDateTime &lastModified, const QVariantMap &exifData);
    Q_INVOKABLE QStringList getUniqueCamerasForFolder(const QString &folderPath);
    Q_INVOKABLE QVariantMap getAvailableFiltersForFolder(const QString &folderPath);
    Q_INVOKABLE bool clear();

private:
    QSqlDatabase getDatabaseConnection();
    QString m_dbPath;
};
