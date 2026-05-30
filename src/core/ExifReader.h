#pragma once

#include <QObject>
#include <QVariantMap>

class ExifDatabase;

class ExifReader : public QObject
{
    Q_OBJECT

public:
    explicit ExifReader(QObject *parent = nullptr);

    void setDatabase(ExifDatabase *db);

    /**
     * @brief Extracts EXIF metadata from an image file.
     * @param filePath The local file system path to the image.
     * @return A QVariantMap containing the extracted tags (ISO, Aperture, Shutter, etc.)
     */
    Q_INVOKABLE QVariantMap getExifData(const QString &filePath);

private:
    ExifDatabase *m_db{nullptr};
};
