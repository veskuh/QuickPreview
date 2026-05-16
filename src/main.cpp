#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDebug>

#include "GalleryListModel.h"
#include "FileDiscoveryService.h"
#include "AsyncImageProvider.h"

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

    // Connect discovery service to model
    QObject::connect(&discoveryService, &FileDiscoveryService::imagesDiscovered,
                     &galleryModel, &GalleryListModel::addImages);

    // Register types and providers
    engine.rootContext()->setContextProperty("galleryModel", (QObject*)&galleryModel);
    engine.rootContext()->setContextProperty("discoveryService", (QObject*)&discoveryService);
    engine.addImageProvider(QLatin1String("gallery"), new AsyncImageProvider);

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
