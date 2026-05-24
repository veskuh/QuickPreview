#pragma once

#include <QObject>
#include <QStringList>
#include <atomic>
#include <QMutex>

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
    void doScan(const QString &path, bool recursive, quint64 scanId);
    std::atomic<bool> m_isScanning{false};
    quint64 m_currentScanId{0};
    mutable QMutex m_scanMutex;
};
