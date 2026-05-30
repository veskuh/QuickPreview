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
    void testScanDirectoryWithFolders();
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

void TestFileDiscoveryService::testScanDirectoryWithFolders()
{
    QTemporaryDir tempDir;
    QVERIFY(tempDir.isValid());

    // Create dummy image
    QString imgPath = tempDir.path() + "/img1.jpg";
    QFile file(imgPath);
    QVERIFY(file.open(QIODevice::WriteOnly));
    file.write("dummy");
    file.close();

    // Create dummy subdirectories
    QDir dir(tempDir.path());
    QVERIFY(dir.mkdir("subdir1"));
    QVERIFY(dir.mkdir("subdir2"));

    FileDiscoveryService service;
    QSignalSpy foldersSpy(&service, &FileDiscoveryService::foldersDiscovered);
    QSignalSpy imagesSpy(&service, &FileDiscoveryService::imagesDiscovered);
    QSignalSpy finishedSpy(&service, &FileDiscoveryService::scanFinished);

    service.scanDirectory(tempDir.path(), false); // non-recursive

    QVERIFY(finishedSpy.wait(5000));

    // Verify subdirectories found
    QCOMPARE(foldersSpy.count(), 1);
    QStringList folderResults = foldersSpy.at(0).at(0).toStringList();
    QCOMPARE(folderResults.count(), 2);
    QVERIFY(folderResults.contains(tempDir.path() + "/subdir1"));
    QVERIFY(folderResults.contains(tempDir.path() + "/subdir2"));

    // Verify images found
    QCOMPARE(imagesSpy.count(), 1);
    QStringList imageResults = imagesSpy.at(0).at(0).toStringList();
    QCOMPARE(imageResults.count(), 1);
    QVERIFY(imageResults.contains(imgPath));
}

QTEST_MAIN(TestFileDiscoveryService)
#include "tst_filediscoveryservice.moc"
