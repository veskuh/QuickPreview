#pragma once

#include <QAbstractListModel>
#include <QStringList>

class GalleryListModel : public QAbstractListModel
{
    Q_OBJECT

public:
    enum Roles {
        FilePathRole = Qt::UserRole + 1,
        FileNameRole
    };

    explicit GalleryListModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    void addImages(const QStringList &newPaths);
    void clear();

private:
    QStringList m_imagePaths;
};
