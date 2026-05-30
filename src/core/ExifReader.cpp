#include "ExifReader.h"
#include "exif.h"
#include <QFile>
#include <QFileInfo>
#include <QDebug>

static QString cleanExifString(const std::string &s)
{
    // Use c_str() to stop at the first null byte if present
    QString res = QString::fromUtf8(s.c_str());
    QString cleaned;
    for (const QChar &c : res) {
        if (c.isPrint()) {
            cleaned.append(c);
        } else {
            break; // Stop at any non-printable character
        }
    }
    return cleaned.trimmed();
}

ExifReader::ExifReader(QObject *parent)
    : QObject(parent)
{
}

QVariantMap ExifReader::getExifData(const QString &filePath)
{
    QVariantMap data;
    QFileInfo fileInfo(filePath);
    if (!fileInfo.exists() || fileInfo.isDir()) {
        return data;
    }

    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly)) {
        qWarning() << "ExifReader: Cannot open file" << filePath;
        return data;
    }

    QByteArray buffer = file.readAll();
    easyexif::EXIFInfo info;
    
    if (info.parseFrom((unsigned char *)buffer.data(), buffer.size()) != 0) {
        // Many files might not have EXIF, just return empty map
        return data;
    }

    data["Make"] = QString::fromStdString(info.Make).trimmed();
    data["Model"] = QString::fromStdString(info.Model).trimmed();
    data["Exposure"] = info.ExposureTime > 0 ? (info.ExposureTime < 1.0 ? QString("1/%1").arg(qRound(1.0 / info.ExposureTime)) : QString("%1s").arg(info.ExposureTime)) : "0";
    data["Aperture"] = QString("f/%1").arg(info.FNumber, 0, 'f', 1);
    data["ISO"] = (int)info.ISOSpeedRatings;
    
    QString focalLength = QString("%1mm").arg(info.FocalLength, 0, 'f', 1);
    if (info.FocalLengthIn35mm > 0) {
        focalLength += QString(" (35mm: %1mm)").arg(info.FocalLengthIn35mm);
    }
    data["FocalLength"] = focalLength;
    
    data["DateTime"] = QString::fromStdString(info.DateTime);
    
    // Improved Lens info
    QString lensModel = cleanExifString(info.LensInfo.Model);
    QString lensMake = cleanExifString(info.LensInfo.Make);
    
    QString lensInfo;
    if (!lensMake.isEmpty()) {
        lensInfo = lensMake;
    }
    if (!lensModel.isEmpty()) {
        if (!lensInfo.isEmpty() && !lensModel.startsWith(lensInfo, Qt::CaseInsensitive)) {
            lensInfo += " " + lensModel;
        } else {
            lensInfo = lensModel;
        }
    }
    
    // Fallback if LensModel is missing but we have specs
    if (lensInfo.isEmpty() && info.LensInfo.FocalLengthMin > 0) {
        if (info.LensInfo.FocalLengthMin == info.LensInfo.FocalLengthMax) {
            lensInfo = QString("%1mm").arg(info.LensInfo.FocalLengthMin);
        } else {
            lensInfo = QString("%1-%2mm").arg(info.LensInfo.FocalLengthMin).arg(info.LensInfo.FocalLengthMax);
        }
        
        if (info.LensInfo.FStopMin > 0) {
            if (info.LensInfo.FStopMin == info.LensInfo.FStopMax || info.LensInfo.FStopMax == 0) {
                lensInfo += QString(" f/%1").arg(info.LensInfo.FStopMin);
            } else {
                lensInfo += QString(" f/%1-%2").arg(info.LensInfo.FStopMin).arg(info.LensInfo.FStopMax);
            }
        }
    }
    
    data["Lens"] = lensInfo;

    return data;
}
