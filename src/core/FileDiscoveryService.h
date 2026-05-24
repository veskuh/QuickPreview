#pragma once

#include <QObject>
#include <QStringList>
#include <atomic>

class FileDiscoveryService : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isScanning READ isScanning NOTIFY isScanningChanged)

public:
    explicit FileDiscoveryService(QObject *parent = nullptr);

    Q_INVOKABLE void scanDirectory(const QString &path, bool recursive = false);
    bool isScanning() const { return m_isScanning.load(); }

signals:
    void imagesDiscovered(const QStringList &paths);
    void scanFinished();
    void isScanningChanged();

private:
    void doScan(const QString &path, bool recursive);
    std::atomic<bool> m_isScanning{false};
};
