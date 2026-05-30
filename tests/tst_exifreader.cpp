#include <QtTest>
#include <QTemporaryDir>
#include <QStandardPaths>
#include <QFile>
#include "ExifReader.h"
#include "ExifDatabase.h"

/// @brief Tests for ExifReader EXIF metadata extraction.
class TestExifReader : public QObject
{
    Q_OBJECT

private slots:
    void initTestCase();
    void testNonExistentFile();
    void testDirectoryPath();
    void testEmptyFile();
    void testInvalidFile();
    void testUnreadableFile();
    void testRealImages();
    void testWithDatabaseSaveAndCacheHit();
    void cleanupTestCase();
};

void TestExifReader::initTestCase()
{
    QStandardPaths::setTestModeEnabled(true);
}

void TestExifReader::cleanupTestCase()
{
    QStandardPaths::setTestModeEnabled(false);
}

void TestExifReader::testNonExistentFile()
{
    ExifReader reader;
    QVariantMap data = reader.getExifData("data/nothing.jpg");
    QVERIFY(data.isEmpty());
}

void TestExifReader::testDirectoryPath()
{
    // Passing a directory path should return empty data
    ExifReader reader;
    QVariantMap data = reader.getExifData("data");
    QVERIFY(data.isEmpty());
}

void TestExifReader::testEmptyFile()
{
    QTemporaryDir tempDir;
    QString path = tempDir.path() + "/empty.jpg";
    QFile file(path);
    QVERIFY(file.open(QIODevice::WriteOnly));
    file.close();

    ExifReader reader;
    QVariantMap data = reader.getExifData(path);
    QVERIFY(data.isEmpty());
}

void TestExifReader::testInvalidFile()
{
    QTemporaryDir tempDir;
    QString path = tempDir.path() + "/invalid.jpg";
    QFile file(path);
    QVERIFY(file.open(QIODevice::WriteOnly));
    file.write("Not a JPEG at all, just some text.");
    file.close();

    ExifReader reader;
    QVariantMap data = reader.getExifData(path);
    QVERIFY(data.isEmpty());
}

void TestExifReader::testUnreadableFile()
{
    QTemporaryDir tempDir;
    QString path = tempDir.path() + "/noperm.jpg";
    QFile file(path);
    QVERIFY(file.open(QIODevice::WriteOnly));
    file.write("dummy");
    file.close();

    // Remove read permission
    QVERIFY(QFile::setPermissions(path, QFileDevice::WriteOwner));

    ExifReader reader;
    QVariantMap data = reader.getExifData(path);
    QVERIFY(data.isEmpty());

    // Restore permissions for cleanup
    QFile::setPermissions(path, QFileDevice::ReadOwner | QFileDevice::WriteOwner);
}

void TestExifReader::testRealImages()
{
    ExifReader reader;
    QStringList images = {
        "data/canon-g9-x.jpg",
        "data/fuji-xt30-18-55F28-4.jpeg",
        "data/iphone-15.jpeg",
        "data/DJI_0877.JPG"
    };

    for (const QString &img : images) {
        QFile file(img);
        QVERIFY2(file.exists(), qPrintable(QString("Test image missing: %1").arg(img)));
        
        QVariantMap data = reader.getExifData(img);
        QVERIFY2(!data.isEmpty(), qPrintable(QString("Failed to extract EXIF from %1").arg(img)));
        
        // Basic common keys
        QVERIFY(data.contains("Make"));
        QVERIFY(data.contains("Model"));
        QVERIFY(data.contains("Exposure"));
        QVERIFY(data.contains("Aperture"));
        QVERIFY(data.contains("ISO"));
        
        // Robust check for unprintable characters in all string keys
        for (auto it = data.constBegin(); it != data.constEnd(); ++it) {
            if (it.value().typeId() == QMetaType::QString) {
                QString val = it.value().toString();
                for (const QChar &c : val) {
                    QVERIFY2(c.isPrint(), qPrintable(QString("Found unprintable char in file %1 key %2: %3")
                                                     .arg(img).arg(it.key()).arg(val)));
                }
            }
        }
        
        qDebug() << "Image:" << img;
        qDebug() << "  Make:" << data["Make"].toString();
        qDebug() << "  Model:" << data["Model"].toString();
        qDebug() << "  Lens:" << data["Lens"].toString();
    }
}

void TestExifReader::testWithDatabaseSaveAndCacheHit()
{
    // Use a fresh database by clearing first
    ExifDatabase db;
    QVERIFY(db.init());
    QVERIFY(db.clear());

    ExifReader reader;
    reader.setDatabase(&db);

    // First call: parses the file, saves to DB (exercises lines 109-110)
    QVariantMap data1 = reader.getExifData("data/canon-g9-x.jpg");
    QVERIFY(!data1.isEmpty());
    QVERIFY(data1.contains("Make"));

    // Verify the data was cached
    QFileInfo fi("data/canon-g9-x.jpg");
    QVERIFY(db.isCached("data/canon-g9-x.jpg", fi.size(), fi.lastModified()));

    // Second call: should hit cache (exercises line 42)
    QVariantMap data2 = reader.getExifData("data/canon-g9-x.jpg");
    QVERIFY(!data2.isEmpty());

    // Cached data should match original
    QCOMPARE(data2["Make"].toString(), data1["Make"].toString());
    QCOMPARE(data2["Model"].toString(), data1["Model"].toString());
    QCOMPARE(data2["ISO"].toInt(), data1["ISO"].toInt());
}

QTEST_MAIN(TestExifReader)
#include "tst_exifreader.moc"
