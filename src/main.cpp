#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QDebug>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    bool selfCheck = app.arguments().contains("--selfcheck");

    QQmlApplicationEngine engine;
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
