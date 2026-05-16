#include "AsyncImageProvider.h"
#include <QImageReader>
#include <QQuickTextureFactory>
#include <QDebug>
#include <QMutex>
#include <QMutexLocker>

static QMutex s_cacheMutex;

AsyncImageResponse::AsyncImageResponse(const QString &id, const QSize &requestedSize, QCache<QString, QImage> *cache)
    : m_id(id), m_requestedSize(requestedSize), m_cache(cache)
{
    setAutoDelete(false);
}

void AsyncImageResponse::run()
{
    QString cacheKey = QString("%1_%2x%3").arg(m_id).arg(m_requestedSize.width()).arg(m_requestedSize.height());
    
    {
        QMutexLocker locker(&s_cacheMutex);
        if (m_cache->contains(cacheKey)) {
            m_image = *m_cache->object(cacheKey);
            emit finished();
            return;
        }
    }

    QImageReader reader(m_id);
    if (reader.canRead()) {
        if (m_requestedSize.isValid()) {
            QSize size = reader.size();
            size.scale(m_requestedSize, Qt::KeepAspectRatio);
            reader.setScaledSize(size);
        }
        m_image = reader.read();
        
        if (!m_image.isNull()) {
            QMutexLocker locker(&s_cacheMutex);
            m_cache->insert(cacheKey, new QImage(m_image));
        }
    } else {
        qWarning() << "AsyncImageProvider: Cannot read image" << m_id;
    }

    emit finished();
}

QQuickTextureFactory *AsyncImageResponse::textureFactory() const
{
    return QQuickTextureFactory::textureFactoryForImage(m_image);
}

AsyncImageProvider::AsyncImageProvider()
    : m_cache(100) // Cache 100 images
{
}

QQuickImageResponse *AsyncImageProvider::requestImageResponse(const QString &id, const QSize &requestedSize)
{
    AsyncImageResponse *response = new AsyncImageResponse(id, requestedSize, &m_cache);
    QThreadPool::globalInstance()->start(response);
    return response;
}
