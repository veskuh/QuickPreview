#include "AsyncImageProvider.h"
#include "Logger.h"
#include <QImageReader>
#include <QQuickTextureFactory>
#include <QDebug>
#include <QMutex>
#include <QMutexLocker>

static QMutex s_cacheMutex;

AsyncImageResponse::AsyncImageResponse(const QString &id, const QSize &requestedSize, QCache<QString, QImage> *cache, Logger *logger)
    : m_id(id), m_requestedSize(requestedSize), m_cache(cache), m_logger(logger)
{
    setAutoDelete(false);
    if (m_logger) m_logger->log(QString("Requesting image: %1 (%2x%3)").arg(m_id).arg(m_requestedSize.width()).arg(m_requestedSize.height()), "ImageProvider");
}

void AsyncImageResponse::run()
{
    QString cacheKey = QString("%1_%2x%3").arg(m_id).arg(m_requestedSize.width()).arg(m_requestedSize.height());
    
    {
        QMutexLocker locker(&s_cacheMutex);
        if (m_cache->contains(cacheKey)) {
            m_image = *m_cache->object(cacheKey);
            if (m_logger) m_logger->log(QString("CACHE HIT: %1").arg(cacheKey), "ImageProvider");
            emit finished();
            return;
        } else {
            if (m_logger) m_logger->log(QString("CACHE MISS: %1").arg(cacheKey), "ImageProvider");
        }
    }

    QImageReader reader(m_id);
    reader.setAutoTransform(true);
    if (reader.canRead()) {
        if (m_requestedSize.isValid()) {
            QSize size = reader.size();
            // Only scale DOWN if image is larger than requested size.
            // Never scale UP as it wastes CPU/RAM and degrades quality.
            if (size.width() > m_requestedSize.width() || size.height() > m_requestedSize.height()) {
                size.scale(m_requestedSize, Qt::KeepAspectRatio);
                reader.setScaledSize(size);
                if (m_logger) m_logger->log(QString("Scaling image down to: %1x%2").arg(size.width()).arg(size.height()), "ImageProvider");
            }
        }
        m_image = reader.read();
        
        if (!m_image.isNull()) {
            if (m_logger) m_logger->log(QString("LOAD SUCCESS: %1 (%2x%3)").arg(m_id).arg(m_image.width()).arg(m_image.height()), "ImageProvider");
            QMutexLocker locker(&s_cacheMutex);
            m_cache->insert(cacheKey, new QImage(m_image));
        } else {
            if (m_logger) m_logger->log(QString("LOAD FAILED (Read error): %1 (Error: %2)").arg(m_id).arg(reader.errorString()), "ImageProvider");
            qWarning() << "AsyncImageProvider: Failed to read image data:" << m_id << "Error:" << reader.errorString();
        }
    } else {
        if (m_logger) m_logger->log(QString("LOAD FAILED (Unsupported/Missing): %1").arg(m_id), "ImageProvider");
        qWarning() << "AsyncImageProvider: Cannot read image" << m_id;
    }

    emit finished();
}

QQuickTextureFactory *AsyncImageResponse::textureFactory() const
{
    return QQuickTextureFactory::textureFactoryForImage(m_image);
}

AsyncImageProvider::AsyncImageProvider(Logger *logger)
    : m_cache(100), m_logger(logger) // Cache 100 images
{
}

QQuickImageResponse *AsyncImageProvider::requestImageResponse(const QString &id, const QSize &requestedSize)
{
    AsyncImageResponse *response = new AsyncImageResponse(id, requestedSize, &m_cache, m_logger);
    QThreadPool::globalInstance()->start(response);
    return response;
}

void AsyncImageProvider::clearCache()
{
    QMutexLocker locker(&s_cacheMutex);
    m_cache.clear();
    if (m_logger) m_logger->log("Image cache cleared.", "ImageProvider");
}
