#pragma once

#include <QAbstractListModel>
#include <QStringList>

class GalleryListModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)

public:
    enum Roles {
        FilePathRole = Qt::UserRole + 1,
        FileNameRole,
        RawPathRole
    };

    explicit GalleryListModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE void addImages(const QStringList &newPaths);
    Q_INVOKABLE void removeImage(int index);
    Q_INVOKABLE void clear();

signals:
    void countChanged();

private:
    QStringList m_imagePaths;
};
