#include "AsyncImageProvider.h"
#include "Logger.h"
#include <QImageReader>
#include <QQuickTextureFactory>
#include <QDebug>
#include <QMutex>
#include <QMutexLocker>
#include <QStandardPaths>
#include <QDir>
#include <QDirIterator>
#include <QCryptographicHash>
#include <QFileInfo>

static QMutex s_cacheMutex;

AsyncImageResponse::AsyncImageResponse(const QString &id, const QSize &requestedSize, QCache<QString, QImage> *cache, Logger *logger)
    : m_id(id), m_requestedSize(requestedSize), m_cache(cache), m_logger(logger)
{
    setAutoDelete(false);
}

void AsyncImageResponse::run()
{
    QString cacheKey = QString("%1_%2x%3").arg(m_id).arg(m_requestedSize.width()).arg(m_requestedSize.height());
    
    // 1. Check Memory Cache
    {
        QMutexLocker locker(&s_cacheMutex);
        if (m_cache->contains(cacheKey)) {
            m_image = *m_cache->object(cacheKey);
            emit finished();
            return;
        }
    }

    // 2. Check Disk Cache
    QString cacheDir = QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + "/thumbnails";
    QString hash = QCryptographicHash::hash(cacheKey.toUtf8(), QCryptographicHash::Md5).toHex();
    QString diskPath = cacheDir + "/" + hash + ".jpg";

    if (QFile::exists(diskPath)) {
        m_image.load(diskPath);
        if (!m_image.isNull()) {
            QMutexLocker locker(&s_cacheMutex);
            m_cache->insert(cacheKey, new QImage(m_image), m_image.sizeInBytes());
            emit finished();
            return;
        }
    }

    // 3. Decode from Source
    QImageReader reader(m_id);
    reader.setAutoTransform(true);
    if (reader.canRead()) {
        if (m_requestedSize.isValid()) {
            QSize size = reader.size();
            if (size.width() > m_requestedSize.width() || size.height() > m_requestedSize.height()) {
                size.scale(m_requestedSize, Qt::KeepAspectRatio);
                reader.setScaledSize(size);
            }
        }
        m_image = reader.read();
        
        if (!m_image.isNull()) {
            // Save to memory cache
            {
                QMutexLocker locker(&s_cacheMutex);
                m_cache->insert(cacheKey, new QImage(m_image), m_image.sizeInBytes());
            }
            
            // Save to disk cache
            QDir().mkpath(cacheDir);
            m_image.save(diskPath, "JPG", 80);
        }
    }

    emit finished();
}

QQuickTextureFactory *AsyncImageResponse::textureFactory() const
{
    return QQuickTextureFactory::textureFactoryForImage(m_image);
}

AsyncImageProvider::AsyncImageProvider(Logger *logger)
    : m_cache(2048 * 1024 * 1024ULL), m_logger(logger) // 2 GB default
{
    m_diskCachePath = QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + "/thumbnails";
    ensureCacheDir();
}

qint64 AsyncImageProvider::maxMemoryCacheSize() const
{
    QMutexLocker locker(&s_cacheMutex);
    return m_cache.maxCost();
}

void AsyncImageProvider::setMaxMemoryCacheSize(qint64 size)
{
    {
        QMutexLocker locker(&s_cacheMutex);
        if (m_cache.maxCost() == size)
            return;
        m_cache.setMaxCost(size);
    }
    emit maxMemoryCacheSizeChanged();
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
}

qint64 AsyncImageProvider::cacheSize() const
{
    qint64 total = 0;
    QDirIterator it(m_diskCachePath, QDir::Files);
    while (it.hasNext()) {
        it.next();
        total += it.fileInfo().size();
    }
    return total;
}

void AsyncImageProvider::clearDiskCache()
{
    clearCache();
    QDir dir(m_diskCachePath);
    dir.removeRecursively();
    ensureCacheDir();
}

QString AsyncImageProvider::cachePath() const
{
    return m_diskCachePath;
}

void AsyncImageProvider::ensureCacheDir()
{
    QDir().mkpath(m_diskCachePath);
}
