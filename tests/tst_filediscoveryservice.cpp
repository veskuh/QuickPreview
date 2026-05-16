#include <QtTest>
#include <QSignalSpy>
#include <QTemporaryDir>
#include <QFile>
#include "FileDiscoveryService.h"

class TestFileDiscoveryService : public QObject
{
    Q_OBJECT

private slots:
    void initTestCase();
    void testScanDirectory();
};

void TestFileDiscoveryService::initTestCase()
{
}

void TestFileDiscoveryService::testScanDirectory()
{
    QTemporaryDir tempDir;
    QVERIFY(tempDir.isValid());

    // Create dummy files
    QStringList expectedFiles;
    expectedFiles << tempDir.path() + "/img1.jpg";
    expectedFiles << tempDir.path() + "/img2.png";
    
    for (const QString &path : expectedFiles) {
        QFile file(path);
        QVERIFY(file.open(QIODevice::WriteOnly));
        file.write("dummy data");
        file.close();
    }

    // Create a file that should be filtered out
    QFile otherFile(tempDir.path() + "/not_an_image.txt");
    QVERIFY(otherFile.open(QIODevice::WriteOnly));
    otherFile.close();

    FileDiscoveryService service;
    QSignalSpy discoveredSpy(&service, &FileDiscoveryService::imagesDiscovered);
    QSignalSpy finishedSpy(&service, &FileDiscoveryService::scanFinished);

    service.scanDirectory(tempDir.path());

    // Wait for the background thread to finish
    QVERIFY(finishedSpy.wait(5000));
    
    QCOMPARE(discoveredSpy.count(), 1);
    QStringList results = discoveredSpy.at(0).at(0).toStringList();
    
    QCOMPARE(results.count(), 2);
    for (const QString &path : expectedFiles) {
        QVERIFY(results.contains(path));
    }
}

QTEST_MAIN(TestFileDiscoveryService)
#include "tst_filediscoveryservice.moc"
