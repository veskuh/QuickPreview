#include "ExifDatabase.h"
#include <QSqlError>
#include <QSqlQuery>
#include <QStandardPaths>
#include <QDir>
#include <QDebug>
#include <QThread>
#include <QUrl>

ExifDatabase::ExifDatabase(QObject *parent)
    : QObject(parent)
{
    QString appData = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir dir(appData);
    if (!dir.exists()) {
        dir.mkpath(".");
    }
    m_dbPath = appData + "/exif_cache.db";
    qDebug() << "ExifDatabase: DB Path initialized to" << m_dbPath;
}

ExifDatabase::~ExifDatabase()
{
    QString connName = QString("exif_db_conn_%1").arg(quintptr(QThread::currentThreadId()));
    if (QSqlDatabase::contains(connName)) {
        QSqlDatabase::database(connName).close();
        QSqlDatabase::removeDatabase(connName);
    }
}

QSqlDatabase ExifDatabase::getDatabaseConnection()
{
    QString connName = QString("exif_db_conn_%1").arg(quintptr(QThread::currentThreadId()));
    if (QSqlDatabase::contains(connName)) {
        QSqlDatabase db = QSqlDatabase::database(connName);
        if (db.isOpen()) {
            return db;
        }
    }
    QSqlDatabase db = QSqlDatabase::addDatabase("QSQLITE", connName);
    db.setDatabaseName(m_dbPath);
    if (!db.open()) {
        qWarning() << "ExifDatabase: Failed to open connection" << connName << "-" << db.lastError().text();
    }
    return db;
}

bool ExifDatabase::init()
{
    QSqlDatabase db = getDatabaseConnection();
    if (!db.isOpen()) {
        return false;
    }
    QSqlQuery query(db);
    bool ok = query.exec("CREATE TABLE IF NOT EXISTS exif_cache ("
                         "file_path TEXT PRIMARY KEY, "
                         "file_size INTEGER, "
                         "last_modified TEXT, "
                         "make TEXT, "
                         "model TEXT, "
                         "lens TEXT, "
                         "exposure TEXT, "
                         "aperture TEXT, "
                         "iso INTEGER, "
                         "datetime TEXT"
                         ")");
    if (!ok) {
        qWarning() << "ExifDatabase: Schema creation failed -" << query.lastError().text();
    } else {
        qDebug() << "ExifDatabase: Schema initialized successfully";
    }
    return ok;
}

bool ExifDatabase::isCached(const QString &filePath, qint64 fileSize, const QDateTime &lastModified)
{
    QSqlDatabase db = getDatabaseConnection();
    if (!db.isOpen()) return false;

    QSqlQuery query(db);
    query.prepare("SELECT file_size, last_modified FROM exif_cache WHERE file_path = :path");
    query.bindValue(":path", filePath);
    
    if (query.exec() && query.next()) {
        qint64 size = query.value(0).toLongLong();
        QString modStr = query.value(1).toString();
        if (size == fileSize && modStr == lastModified.toString(Qt::ISODate)) {
            return true;
        }
    }
    return false;
}

QVariantMap ExifDatabase::getExifData(const QString &filePath)
{
    QVariantMap data;
    QSqlDatabase db = getDatabaseConnection();
    if (!db.isOpen()) return data;

    QSqlQuery query(db);
    query.prepare("SELECT make, model, lens, exposure, aperture, iso, datetime FROM exif_cache WHERE file_path = :path");
    query.bindValue(":path", filePath);

    if (query.exec() && query.next()) {
        data["Make"] = query.value(0).toString();
        data["Model"] = query.value(1).toString();
        data["Lens"] = query.value(2).toString();
        data["Exposure"] = query.value(3).toString();
        data["Aperture"] = query.value(4).toString();
        data["ISO"] = query.value(5).toInt();
        data["DateTime"] = query.value(6).toString();
    }
    return data;
}

bool ExifDatabase::saveExifData(const QString &filePath, qint64 fileSize, const QDateTime &lastModified, const QVariantMap &exifData)
{
    QSqlDatabase db = getDatabaseConnection();
    if (!db.isOpen()) return false;

    QSqlQuery query(db);
    query.prepare("INSERT OR REPLACE INTO exif_cache "
                  "(file_path, file_size, last_modified, make, model, lens, exposure, aperture, iso, datetime) "
                  "VALUES (:path, :size, :modified, :make, :model, :lens, :exposure, :aperture, :iso, :datetime)");
    query.bindValue(":path", filePath);
    query.bindValue(":size", fileSize);
    query.bindValue(":modified", lastModified.toString(Qt::ISODate));
    query.bindValue(":make", exifData.value("Make").toString());
    query.bindValue(":model", exifData.value("Model").toString());
    query.bindValue(":lens", exifData.value("Lens").toString());
    query.bindValue(":exposure", exifData.value("Exposure").toString());
    query.bindValue(":aperture", exifData.value("Aperture").toString());
    query.bindValue(":iso", exifData.value("ISO").toInt());
    query.bindValue(":datetime", exifData.value("DateTime").toString());

    bool ok = query.exec();
    if (!ok) {
        qWarning() << "ExifDatabase: Save failed for" << filePath << "-" << query.lastError().text();
    }
    return ok;
}

QStringList ExifDatabase::getUniqueCamerasForFolder(const QString &folderPath)
{
    QStringList cameras;
    QSqlDatabase db = getDatabaseConnection();
    if (!db.isOpen()) return cameras;

    QSqlQuery query(db);
    query.prepare("SELECT DISTINCT make, model FROM exif_cache WHERE file_path LIKE :prefix AND make IS NOT NULL AND make != ''");

    QString prefix = folderPath;
    if (prefix.startsWith("file://")) {
        prefix = QUrl(prefix).toLocalFile();
    }
    if (!prefix.endsWith("/")) {
        prefix += "/";
    }

    query.bindValue(":prefix", prefix + "%");

    if (query.exec()) {
        while (query.next()) {
            QString make = query.value(0).toString().trimmed();
            QString model = query.value(1).toString().trimmed();

            // Clean up name
            QString camera = make;
            if (!model.isEmpty() && !model.startsWith(make, Qt::CaseInsensitive)) {
                camera += " " + model;
            }
            if (!cameras.contains(camera)) {
                cameras << camera;
            }
        }
    } else {
        qWarning() << "ExifDatabase: Failed to query unique cameras -" << query.lastError().text();
    }
    return cameras;
}

QVariantMap ExifDatabase::getAvailableFiltersForFolder(const QString &folderPath)
{
    QVariantMap result;
    result["hasToday"] = false;
    result["hasThisWeek"] = false;
    result["hasThisMonth"] = false;
    result["years"] = QStringList();
    result["imageTypes"] = QStringList();

    QSqlDatabase db = getDatabaseConnection();
    if (!db.isOpen()) return result;

    QSqlQuery query(db);
    query.prepare("SELECT file_path, last_modified, datetime FROM exif_cache WHERE file_path LIKE :prefix");

    QString prefix = folderPath;
    if (prefix.startsWith("file://")) {
        prefix = QUrl(prefix).toLocalFile();
    }
    if (!prefix.endsWith("/")) {
        prefix += "/";
    }
    query.bindValue(":prefix", prefix + "%");

    bool hasToday = false;
    bool hasThisWeek = false;
    bool hasThisMonth = false;
    QSet<int> yearsSet;
    QSet<QString> imageTypesSet;
    QDate current = QDate::currentDate();

    if (query.exec()) {
        while (query.next()) {
            QString filePath = query.value(0).toString();
            QString modStr = query.value(1).toString();
            QString exifStr = query.value(2).toString();

            // Extract extension
            int lastDot = filePath.lastIndexOf('.');
            if (lastDot != -1) {
                QString ext = filePath.mid(lastDot + 1).toUpper();
                if (ext == "JPEG") ext = "JPG";
                if (ext == "JPG" || ext == "PNG" || ext == "WEBP" || ext == "BMP") {
                    imageTypesSet.insert(ext);
                }
            }

            QDateTime fileDate;
            if (!exifStr.isEmpty()) {
                QDateTime parsed = QDateTime::fromString(exifStr, "yyyy:MM:dd HH:mm:ss");
                if (parsed.isValid()) {
                    fileDate = parsed;
                }
            }
            if (!fileDate.isValid() && !modStr.isEmpty()) {
                fileDate = QDateTime::fromString(modStr, Qt::ISODate);
            }

            if (fileDate.isValid()) {
                QDate date = fileDate.date();
                if (date == current) {
                    hasToday = true;
                }
                if (date >= current.addDays(-7) && date <= current) {
                    hasThisWeek = true;
                }
                if (date.month() == current.month() && date.year() == current.year()) {
                    hasThisMonth = true;
                }
                yearsSet.insert(date.year());
            }
        }
    }

    result["hasToday"] = hasToday;
    result["hasThisWeek"] = hasThisWeek;
    result["hasThisMonth"] = hasThisMonth;

    QList<int> sortedYears = yearsSet.values();
    std::sort(sortedYears.begin(), sortedYears.end(), std::greater<int>());
    QStringList yearsList;
    for (int y : sortedYears) {
        yearsList << QString::number(y);
    }
    result["years"] = yearsList;

    QStringList imageTypesList = imageTypesSet.values();
    std::sort(imageTypesList.begin(), imageTypesList.end());
    result["imageTypes"] = imageTypesList;

    return result;
}

bool ExifDatabase::clear()
{
    QSqlDatabase db = getDatabaseConnection();
    if (!db.isOpen()) return false;

    QSqlQuery query(db);
    bool ok = query.exec("DELETE FROM exif_cache");
    if (!ok) {
        qWarning() << "ExifDatabase: Clear failed -" << query.lastError().text();
    } else {
        qDebug() << "ExifDatabase: Database cleared successfully";
    }
    return ok;
}
