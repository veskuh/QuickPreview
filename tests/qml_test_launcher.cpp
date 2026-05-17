#include <QtQuickTest>
#include <QtPlugin>
#include <QGuiApplication>
#include <QQmlEngine>
#include "AsyncImageProvider.h"

#include <QImage>
#include <QPainter>
#include <QDir>

Q_IMPORT_PLUGIN(QuickPreviewPlugin)

class TestSetup : public QObject
{
    Q_OBJECT
public slots:
    void qmlEngineAvailable(QQmlEngine *engine)
    {
        engine->addImageProvider(QLatin1String("gallery"), new AsyncImageProvider);
        
        // Create dummy images for tests
        QStringList files = {"/tmp/test1.jpg", "/tmp/test2.jpg", "/tmp/test3.jpg"};
        QImage img(10, 10, QImage::Format_RGB32);
        img.fill(Qt::red);
        for (const auto &f : files) {
            img.save(f, "JPG");
        }
    }
};

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setOrganizationName("QuickPreview");
    app.setOrganizationDomain("net.veskuh.test");

    TestSetup setup;
    return quick_test_main_with_setup(argc, argv, "quickpreview", QUICK_TEST_SOURCE_DIR, &setup);
}

#include "qml_test_launcher.moc"
