#pragma once

#include <QQuickAsyncImageProvider>
#include <QCache>
#include <QImage>
#include <QThreadPool>

class AsyncImageResponse : public QQuickImageResponse, public QRunnable
{
public:
    AsyncImageResponse(const QString &id, const QSize &requestedSize, QCache<QString, QImage> *cache);

    void run() override;
    QQuickTextureFactory *textureFactory() const override;

private:
    QString m_id;
    QSize m_requestedSize;
    QCache<QString, QImage> *m_cache;
    QImage m_image;
};

class AsyncImageProvider : public QQuickAsyncImageProvider
{
public:
    AsyncImageProvider();
    QQuickImageResponse *requestImageResponse(const QString &id, const QSize &requestedSize) override;

    void clearCache();

private:
    QCache<QString, QImage> m_cache;
};
