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
public:
    AsyncImageProvider(Logger *logger = nullptr);
    QQuickImageResponse *requestImageResponse(const QString &id, const QSize &requestedSize) override;

    void clearCache();

private:
    QCache<QString, QImage> m_cache;
    Logger *m_logger;
};
