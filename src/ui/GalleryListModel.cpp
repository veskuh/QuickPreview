#include "GalleryListModel.h"
#include <QFileInfo>
#include <QUrl>

GalleryListModel::GalleryListModel(bool populateDummy, QObject *parent)
    : QAbstractListModel(parent)
{
    if (populateDummy) {
        // Dummy data for initial structure testing
        QStringList dummyPaths;
        for (int i = 1; i <= 10; ++i) {
            dummyPaths << QString("/fake/path/image_%1.jpg").arg(i);
        }
        addImages(dummyPaths);
    }
}

int GalleryListModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return m_imagePaths.count();
}

QVariant GalleryListModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_imagePaths.count())
        return QVariant();

    const QString &path = m_imagePaths.at(index.row());

    switch (role) {
    case FilePathRole:
        return QUrl::fromLocalFile(path);
    case FileNameRole:
        return QFileInfo(path).fileName();
    case RawPathRole:
        return path;
    case Qt::DisplayRole:
        return QFileInfo(path).fileName();
    default:
        return QVariant();
    }
}

QHash<int, QByteArray> GalleryListModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[FilePathRole] = "filePath";
    roles[FileNameRole] = "fileName";
    roles[RawPathRole] = "rawPath";
    return roles;
}

void GalleryListModel::addImages(const QStringList &newPaths)
{
    if (newPaths.isEmpty())
        return;

    beginInsertRows(QModelIndex(), m_imagePaths.count(), m_imagePaths.count() + newPaths.count() - 1);
    m_imagePaths.append(newPaths);
    endInsertRows();
    emit countChanged();
}

void GalleryListModel::removeImage(int index)
{
    if (index < 0 || index >= m_imagePaths.count())
        return;

    beginRemoveRows(QModelIndex(), index, index);
    m_imagePaths.removeAt(index);
    endRemoveRows();
    emit countChanged();
}

void GalleryListModel::clear()
{
    beginResetModel();
    m_imagePaths.clear();
    endResetModel();
    emit countChanged();
}
