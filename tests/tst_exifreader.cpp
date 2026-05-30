#include <QtTest>
#include <QTemporaryDir>
#include <QFile>
#include "ExifReader.h"

class TestExifReader : public QObject
{
    Q_OBJECT

private slots:
    void testNonExistentFile();
    void testEmptyFile();
    void testInvalidFile();
    void testRealImages();
};

void TestExifReader::testNonExistentFile()
{
    ExifReader reader;
    QVariantMap data = reader.getExifData("data/nothing.jpg");
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

QTEST_MAIN(TestExifReader)
#include "tst_exifreader.moc"
