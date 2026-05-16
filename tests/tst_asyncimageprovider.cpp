#include <QtTest>
#include "AsyncImageProvider.h"
#include <QTemporaryFile>
#include <QImage>
#include <QPainter>

class TestAsyncImageProvider : public QObject
{
    Q_OBJECT

private slots:
    void initTestCase();
    void testRequestImage();
};

void TestAsyncImageProvider::initTestCase()
{
}

void TestAsyncImageProvider::testRequestImage()
{
    // Create a real image file
    QTemporaryFile tempFile(QDir::tempPath() + "/testXXXXXX.png");
    QVERIFY(tempFile.open());
    QString filePath = tempFile.fileName();
    
    QImage testImage(100, 100, QImage::Format_RGB32);
    testImage.fill(Qt::red);
    QVERIFY(testImage.save(filePath, "PNG"));
    tempFile.close();

    AsyncImageProvider provider;
    QSize requestedSize(50, 50);
    
    QQuickImageResponse *response = provider.requestImageResponse(filePath, requestedSize);
    QVERIFY(response);
    
    // Wait for the async response
    QSignalSpy spy(response, &QQuickImageResponse::finished);
    QVERIFY(spy.wait(5000));
    
    QQuickTextureFactory *factory = response->textureFactory();
    QVERIFY(factory);
    
    QImage resultImage = factory->image();
    QCOMPARE(resultImage.size(), requestedSize);
    QCOMPARE(resultImage.pixelColor(0,0), QColor(Qt::red));
    
    delete response;
}

QTEST_MAIN(TestAsyncImageProvider)
#include "tst_asyncimageprovider.moc"
