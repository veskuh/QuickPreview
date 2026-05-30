// tests/tst_gallerylistmodel_extended.cpp

#include <QtTest>
#include <QSignalSpy>
#include "GalleryListModel.h"

class TestGalleryListModelExtended : public QObject {
    Q_OBJECT
private slots:
    void testRoleNames();
    void testDataRoles();
    void testRemoveImageInvalid();
    void testClearSignal();
};

void TestGalleryListModelExtended::testRoleNames()
{
    GalleryListModel model;
    QHash<int, QByteArray> roles = model.roleNames();
    QVERIFY(roles.contains(GalleryListModel::FilePathRole));
    QVERIFY(roles.contains(GalleryListModel::FileNameRole));
    QVERIFY(roles.contains(GalleryListModel::RawPathRole));
    QVERIFY(roles.contains(GalleryListModel::IsFolderRole));
    QCOMPARE(roles.value(GalleryListModel::FilePathRole), QByteArray("filePath"));
    QCOMPARE(roles.value(GalleryListModel::FileNameRole), QByteArray("fileName"));
    QCOMPARE(roles.value(GalleryListModel::RawPathRole), QByteArray("rawPath"));
    QCOMPARE(roles.value(GalleryListModel::IsFolderRole), QByteArray("isFolder"));
}

void TestGalleryListModelExtended::testDataRoles()
{
    GalleryListModel model;
    model.clear();
    model.addFolders({"/tmp/folderA"});
    model.addImages({"/tmp/fileB.jpg"});

    // Folder entry at row 0
    QModelIndex folderIdx = model.index(0, 0);
    QVERIFY(folderIdx.isValid());
    QCOMPARE(model.data(folderIdx, GalleryListModel::FileNameRole).toString(), QString("folderA"));
    QCOMPARE(model.data(folderIdx, GalleryListModel::IsFolderRole).toBool(), true);
    QVERIFY(model.data(folderIdx, GalleryListModel::FilePathRole).toUrl().isValid());
    QCOMPARE(model.data(folderIdx, GalleryListModel::RawPathRole).toString(), QString("/tmp/folderA"));

    // Image entry at row 1
    QModelIndex imgIdx = model.index(1, 0);
    QVERIFY(imgIdx.isValid());
    QCOMPARE(model.data(imgIdx, GalleryListModel::FileNameRole).toString(), QString("fileB.jpg"));
    QCOMPARE(model.data(imgIdx, GalleryListModel::IsFolderRole).toBool(), false);
    QVERIFY(model.data(imgIdx, GalleryListModel::FilePathRole).toUrl().isValid());
    QCOMPARE(model.data(imgIdx, GalleryListModel::RawPathRole).toString(), QString("/tmp/fileB.jpg"));
}

void TestGalleryListModelExtended::testRemoveImageInvalid()
{
    GalleryListModel model;
    model.clear();
    model.addImages({"/tmp/one.jpg"});
    QCOMPARE(model.rowCount(), 1);

    QSignalSpy rowsRemovedSpy(&model, &GalleryListModel::rowsRemoved);
    // Negative index
    model.removeImage(-1);
    // Out of range index
    model.removeImage(5);
    // No rows should be removed
    QCOMPARE(rowsRemovedSpy.count(), 0);
    QCOMPARE(model.rowCount(), 1);
}

void TestGalleryListModelExtended::testClearSignal()
{
    GalleryListModel model;
    model.addImages({"/tmp/a.jpg", "/tmp/b.jpg"});
    QCOMPARE(model.rowCount(), 2);
    QSignalSpy clearSpy(&model, &GalleryListModel::countChanged);
    model.clear();
    QCOMPARE(clearSpy.count(), 1);
    QCOMPARE(model.rowCount(), 0);
}

QTEST_MAIN(TestGalleryListModelExtended)
#include "tst_gallerylistmodel_extended.moc"
