#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDebug>
#include <QtPlugin>

#include "GalleryListModel.h"
#include "FileDiscoveryService.h"
#include "AsyncImageProvider.h"
#include "VolumeMonitor.h"
#include "ExifReader.h"
#include "Logger.h"

Q_IMPORT_PLUGIN(NinjaViewPlugin)

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setOrganizationName("NinjaView");
    bool selfTest = app.arguments().contains("--selftest");
    if (selfTest) {
        app.setOrganizationDomain("net.veskuh.test");
    } else {
        app.setOrganizationDomain("net.veskuh");
    }

    // Backend components (must be declared before engine to ensure they outlive it)
    Logger logger;
    GalleryListModel galleryModel;
    FileDiscoveryService discoveryService;
    VolumeMonitor volumeMonitor;
    ExifReader exifReader;
    AsyncImageProvider *imageProvider = new AsyncImageProvider(&logger);

    QQmlApplicationEngine engine;

    // Connect discovery service to model
    QObject::connect(&discoveryService, &FileDiscoveryService::imagesDiscovered,
                     &galleryModel, &GalleryListModel::addImages);

    // Connect volume monitor to cleanup actions
    QObject::connect(&volumeMonitor, &VolumeMonitor::volumeUnmounted,
                     &galleryModel, &GalleryListModel::clear);
    QObject::connect(&volumeMonitor, &VolumeMonitor::volumeUnmounted,
                     [imageProvider](const QString &path) {
        qDebug() << "Volume unmounted, clearing cache due to:" << path;
        imageProvider->clearCache();
    });

    // Register types and providers
    engine.rootContext()->setContextProperty("allowFullScreen", true);
    engine.rootContext()->setContextProperty("imageProvider", imageProvider);
    engine.rootContext()->setContextProperty("volumeMonitor", &volumeMonitor);
    engine.rootContext()->setContextProperty("logger", &logger);
    engine.rootContext()->setContextProperty("galleryModel", (QObject*)&galleryModel);
    engine.rootContext()->setContextProperty("discoveryService", (QObject*)&discoveryService);
    engine.rootContext()->setContextProperty("exifReader", (QObject*)&exifReader);
    engine.addImageProvider(QLatin1String("gallery"), imageProvider);

    using namespace Qt::StringLiterals;
    const QUrl url(u"qrc:/qt/qml/NinjaView/qml/Main.qml"_s);
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url, selfTest](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl) {
            qCritical() << "Failed to load" << url;
            QCoreApplication::exit(-1);
        } else if (selfTest) {
            qDebug() << "Self-test passed: Main.qml loaded successfully.";
            QCoreApplication::quit();
        }
    }, Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
