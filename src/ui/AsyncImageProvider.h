#pragma once

#include <QQuickAsyncImageProvider>
#include <QCache>
#include <QImage>
#include <QThreadPool>

class Logger;

class AsyncImageResponse : public QQuickImageResponse, public QRunnable
{
public:
    AsyncImageResponse(const QString &id, const QSize &requestedSize, QCache<QString, QImage> *cache, Logger *logger);

    void run() override;
    QQuickTextureFactory *textureFactory() const override;

private:
    QString m_id;
    QSize m_requestedSize;
    QCache<QString, QImage> *m_cache;
    Logger *m_logger;
    QImage m_image;
};

class AsyncImageProvider : public QQuickAsyncImageProvider
{
    Q_OBJECT
    Q_PROPERTY(qint64 maxMemoryCacheSize READ maxMemoryCacheSize WRITE setMaxMemoryCacheSize NOTIFY maxMemoryCacheSizeChanged)

public:
    AsyncImageProvider(Logger *logger = nullptr);
    QQuickImageResponse *requestImageResponse(const QString &id, const QSize &requestedSize) override;

    void clearCache();
    
    // Cache management for Settings
    Q_INVOKABLE qint64 cacheSize() const;
    Q_INVOKABLE void clearDiskCache();
    Q_INVOKABLE QString cachePath() const;

    qint64 maxMemoryCacheSize() const;
    void setMaxMemoryCacheSize(qint64 size);

signals:
    void maxMemoryCacheSizeChanged();

private:
    QCache<QString, QImage> m_cache;
    Logger *m_logger;
    QString m_diskCachePath;
    void ensureCacheDir();
};
