#include <QtQuickTest>
#include <QtPlugin>
#include <QGuiApplication>
#include <QQmlEngine>
#include <QQmlContext>
#include <QLibraryInfo>
#include "AsyncImageProvider.h"
#include "FileDiscoveryService.h"
#include "GalleryListModel.h"
#include "FileActionService.h"
#include "VolumeMonitor.h"
#include "ExifReader.h"
#include "Logger.h"

#include "ExifDatabase.h"
#include "GalleryFilterProxyModel.h"

#include <QImage>
#include <QPainter>
#include <QDir>

Q_IMPORT_PLUGIN(NinjaViewPlugin)

class TestSetup : public QObject
{
    Q_OBJECT
public slots:
    void qmlEngineAvailable(QQmlEngine *engine)
    {
        // Real or mock objects for tests
        // Some tests might prefer to use their own mocks via 'id' if scope allows, 
        // but context properties are more robust for nested components.
        
        static Logger logger;
        static ExifDatabase exifDb;
        exifDb.init();

        static GalleryListModel rawGalleryModel;
        static GalleryFilterProxyModel galleryModel;
        galleryModel.setSourceModel(&rawGalleryModel);
        galleryModel.setDatabase(&exifDb);

        static FileDiscoveryService discoveryService;
        discoveryService.setDatabase(&exifDb);

        static VolumeMonitor volumeMonitor;
        static ExifReader exifReader;
        exifReader.setDatabase(&exifDb);

        static FileActionService fileActionService;
        static AsyncImageProvider *imageProvider = new AsyncImageProvider(&logger);

        // Connect discovery service to model in tests just like in main app
        QObject::connect(&discoveryService, &FileDiscoveryService::imagesDiscovered,
                         &rawGalleryModel, &GalleryListModel::addImages);
        QObject::connect(&discoveryService, &FileDiscoveryService::foldersDiscovered,
                         &rawGalleryModel, &GalleryListModel::addFolders);

        engine->rootContext()->setContextProperty("allowFullScreen", false);
        engine->rootContext()->setContextProperty("isSelfTest", false);
        engine->rootContext()->setContextProperty("fileActionService", &fileActionService);
        engine->rootContext()->setContextProperty("logger", &logger);
        engine->rootContext()->setContextProperty("galleryModel", &galleryModel);
        engine->rootContext()->setContextProperty("rawGalleryModel", &rawGalleryModel);
        engine->rootContext()->setContextProperty("exifDatabase", &exifDb);
        engine->rootContext()->setContextProperty("discoveryService", &discoveryService);
        engine->rootContext()->setContextProperty("volumeMonitor", &volumeMonitor);
        engine->rootContext()->setContextProperty("exifReader", &exifReader);
        engine->rootContext()->setContextProperty("imageProvider", imageProvider);
        engine->rootContext()->setContextProperty("appVersion", QString(NINJAVIEW_VERSION));
        engine->rootContext()->setContextProperty("appBuild", QString(NINJAVIEW_BUILD_ID));
        engine->rootContext()->setContextProperty("qtVersion", QString(qVersion()));
        
        engine->addImageProvider(QLatin1String("gallery"), imageProvider);
        
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
    app.setOrganizationName("NinjaView");
    app.setOrganizationDomain("net.veskuh.test");

    TestSetup setup;
    return quick_test_main_with_setup(argc, argv, "ninjaview", QUICK_TEST_SOURCE_DIR, &setup);
}

#include "qml_test_launcher.moc"
