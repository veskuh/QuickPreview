#include <QtTest>
#include <QSignalSpy>
#include <QTemporaryDir>
#include "ExifDatabase.h"

class TestExifDatabase : public QObject
{
    Q_OBJECT

private slots:
    void initTestCase();
    void testDatabaseOperations();
};

void TestExifDatabase::initTestCase()
{
    QCoreApplication::setOrganizationName("NinjaViewTest");
    QCoreApplication::setApplicationName("tst_exifdatabase");
}

void TestExifDatabase::testDatabaseOperations()
{
    ExifDatabase db;
    QVERIFY(db.init());

    QString filePath = "/tmp/fake_image.jpg";
    qint64 fileSize = 12345;
    QDateTime lastModified = QDateTime::currentDateTime();

    // Check uncached
    QVERIFY(!db.isCached(filePath, fileSize, lastModified));

    // Save data
    QVariantMap exif;
    exif["Make"] = "Canon";
    exif["Model"] = "EOS R5";
    exif["Lens"] = "RF 24-70mm f/2.8L IS USM";
    exif["Exposure"] = "1/125s";
    exif["Aperture"] = "f/2.8";
    exif["ISO"] = 400;
    exif["DateTime"] = "2026:05:30 12:00:00";

    QVERIFY(db.saveExifData(filePath, fileSize, lastModified, exif));

    // Check cached
    QVERIFY(db.isCached(filePath, fileSize, lastModified));

    // Check cached with wrong file size (should return false)
    QVERIFY(!db.isCached(filePath, 99999, lastModified));

    // Check cached with wrong modified date (should return false)
    QVERIFY(!db.isCached(filePath, fileSize, lastModified.addDays(1)));

    // Retrieve data and assert values
    QVariantMap retrieved = db.getExifData(filePath);
    QCOMPARE(retrieved.value("Make").toString(), QString("Canon"));
    QCOMPARE(retrieved.value("Model").toString(), QString("EOS R5"));
    QCOMPARE(retrieved.value("Lens").toString(), QString("RF 24-70mm f/2.8L IS USM"));
    QCOMPARE(retrieved.value("Exposure").toString(), QString("1/125s"));
    QCOMPARE(retrieved.value("Aperture").toString(), QString("f/2.8"));
    QCOMPARE(retrieved.value("ISO").toInt(), 400);
    QCOMPARE(retrieved.value("DateTime").toString(), QString("2026:05:30 12:00:00"));

    // Test clear database
    QVERIFY(db.clear());
    QVERIFY(!db.isCached(filePath, fileSize, lastModified));
    QVERIFY(db.getExifData(filePath).isEmpty());
}

QTEST_MAIN(TestExifDatabase)
#include "tst_exifdatabase.moc"
