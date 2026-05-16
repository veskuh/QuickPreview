#include <QtTest>
#include <QSignalSpy>
#include "GalleryListModel.h"

class TestGalleryListModel : public QObject
{
    Q_OBJECT

private slots:
    void initTestCase();
    void testInitialData();
    void testAddImages();
    void testClear();
};

void TestGalleryListModel::initTestCase()
{
}

void TestGalleryListModel::testInitialData()
{
    GalleryListModel model;
    // Constructor adds 10 dummy paths
    QCOMPARE(model.rowCount(), 10);
    
    QModelIndex index = model.index(0, 0);
    QVERIFY(index.isValid());
    QVERIFY(model.data(index, GalleryListModel::FilePathRole).toUrl().isValid());
    QVERIFY(!model.data(index, GalleryListModel::FileNameRole).toString().isEmpty());
}

void TestGalleryListModel::testAddImages()
{
    GalleryListModel model;
    model.clear();
    QCOMPARE(model.rowCount(), 0);

    QStringList newImages = {"/tmp/test1.jpg", "/tmp/test2.png"};
    
    QSignalSpy spy(&model, &GalleryListModel::rowsInserted);
    model.addImages(newImages);
    
    QCOMPARE(model.rowCount(), 2);
    QCOMPARE(spy.count(), 1);
    
    QCOMPARE(model.data(model.index(0,0), GalleryListModel::FileNameRole).toString(), QString("test1.jpg"));
}

void TestGalleryListModel::testClear()
{
    GalleryListModel model;
    QVERIFY(model.rowCount() > 0);
    
    model.clear();
    QCOMPARE(model.rowCount(), 0);
}

QTEST_MAIN(TestGalleryListModel)
#include "tst_gallerylistmodel.moc"
