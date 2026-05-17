#pragma once

#include <QObject>
#include <QStringList>

class FileDiscoveryService : public QObject
{
    Q_OBJECT

public:
    explicit FileDiscoveryService(QObject *parent = nullptr);

    Q_INVOKABLE void scanDirectory(const QString &path, bool recursive = false);

signals:
    void imagesDiscovered(const QStringList &paths);
    void scanFinished();

private:
    void doScan(const QString &path, bool recursive);
};
