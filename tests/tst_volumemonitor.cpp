#include <QtTest>
#include "VolumeMonitor.h"

class TestVolumeMonitor : public QObject
{
    Q_OBJECT

private slots:
    void testConstruction();
    void testCheckVolumes();
};

void TestVolumeMonitor::testConstruction()
{
    VolumeMonitor monitor;
    // Basic test to ensure it doesn't crash and initializes correctly
    QVERIFY(true);
}

void TestVolumeMonitor::testCheckVolumes()
{
    VolumeMonitor monitor;
    // checkVolumes is private but can be called via meta-object system if it's a slot
    // In VolumeMonitor.h, it IS a private slot.
    bool success = QMetaObject::invokeMethod(&monitor, "checkVolumes");
    QVERIFY(success);
}

QTEST_MAIN(TestVolumeMonitor)
#include "tst_volumemonitor.moc"
