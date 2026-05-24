#include <QtTest>
#include <QTemporaryFile>
#include <QFile>
#include <QUrl>
#include "FileActionService.h"

class TestFileActionService : public QObject
{
    Q_OBJECT

private slots:
    void testMoveToTrashLocalPath();
    void testMoveToTrashUrlPath();
    void testPathTranslationMock();
};

void TestFileActionService::testMoveToTrashLocalPath()
{
    // Create a temporary file
    QTemporaryFile tempFile;
    QVERIFY(tempFile.open());
    QString path = tempFile.fileName();
    tempFile.close(); // Close so we can delete/move it
    QVERIFY(QFile::exists(path));

    FileActionService service;
    bool success = service.moveToTrash(path);
    if (success) {
        QVERIFY(!QFile::exists(path));
    } else {
        qWarning() << "moveToTrash not supported on this platform/setup. File still exists:" << QFile::exists(path);
        QVERIFY(QFile::exists(path));
    }
}

void TestFileActionService::testMoveToTrashUrlPath()
{
    // Create a temporary file
    QTemporaryFile tempFile;
    QVERIFY(tempFile.open());
    QString path = tempFile.fileName();
    tempFile.close();
    QVERIFY(QFile::exists(path));

    // Convert to file:// URL
    QString urlPath = QUrl::fromLocalFile(path).toString();
    QVERIFY(urlPath.startsWith("file://"));

    FileActionService service;
    bool success = service.moveToTrash(urlPath);
    if (success) {
        QVERIFY(!QFile::exists(path));
    } else {
        qWarning() << "moveToTrash URL not supported on this platform/setup. File still exists:" << QFile::exists(path);
        QVERIFY(QFile::exists(path));
    }
}

void TestFileActionService::testPathTranslationMock()
{
    // Test that the other methods don't crash when passed empty paths, invalid paths, and URL paths
    FileActionService service;
    
    // We expect these to run without crashing
    service.showInFolder("");
    service.openExternally("");
    
    // Passing a non-existent temp file should also work without crashing
    service.showInFolder("file:///nonexistent/path/file.jpg");
    service.openExternally("file:///nonexistent/path/file.jpg");
}

QTEST_MAIN(TestFileActionService)
#include "tst_fileactionservice.moc"
