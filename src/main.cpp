#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDebug>

#include "GalleryListModel.h"
#include "FileDiscoveryService.h"
#include "AsyncImageProvider.h"
#include "VolumeMonitor.h"
#include "ExifReader.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setOrganizationName("QuickPreview");

    bool selfCheck = app.arguments().contains("--selfcheck");
    if (selfCheck) {
        app.setOrganizationDomain("net.veskuh.test");
    } else {
        app.setOrganizationDomain("net.veskuh");
    }

    QQmlApplicationEngine engine;

    // Backend components
    GalleryListModel galleryModel;
    FileDiscoveryService discoveryService;
    VolumeMonitor volumeMonitor;
    ExifReader exifReader;
    AsyncImageProvider *imageProvider = new AsyncImageProvider;

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
    engine.rootContext()->setContextProperty("galleryModel", (QObject*)&galleryModel);
    engine.rootContext()->setContextProperty("discoveryService", (QObject*)&discoveryService);
    engine.rootContext()->setContextProperty("exifReader", (QObject*)&exifReader);
    engine.addImageProvider(QLatin1String("gallery"), imageProvider);

    const QUrl url(u"qrc:/qt/qml/QuickPreview/qml/Main.qml"_qs);
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url, selfCheck](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl) {
            qCritical() << "Failed to load" << url;
            QCoreApplication::exit(-1);
        } else if (selfCheck) {
            qDebug() << "Self-check passed: Main.qml loaded successfully.";
            QCoreApplication::quit();
        }
    }, Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
