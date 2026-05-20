#pragma once

#include <QObject>
#include <QString>

class FileActionService : public QObject
{
    Q_OBJECT
public:
    explicit FileActionService(QObject *parent = nullptr);

    Q_INVOKABLE void showInFolder(const QString &filePath);
    Q_INVOKABLE void openExternally(const QString &filePath);
    Q_INVOKABLE bool moveToTrash(const QString &filePath);
};
