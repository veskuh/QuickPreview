#pragma once

#include <QObject>
#include <QString>
#include <QFile>
#include <QTextStream>
#include <QStandardPaths>
#include <QDir>
#include <QDateTime>

class Logger : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool loggingEnabled READ loggingEnabled WRITE setLoggingEnabled NOTIFY loggingEnabledChanged)
    Q_PROPERTY(QString logFilePath READ logFilePath CONSTANT)

public:
    explicit Logger(QObject *parent = nullptr);
    ~Logger();

    bool loggingEnabled() const { return m_loggingEnabled; }
    void setLoggingEnabled(bool enabled);

    QString logFilePath() const { return m_logFilePath; }

    Q_INVOKABLE void log(const QString &message, const QString &category = "General");

signals:
    void loggingEnabledChanged();

private:
    bool m_loggingEnabled = false;
    QString m_logFilePath;
    QFile m_logFile;
    QTextStream m_logStream;

    void openLogFile();
    void closeLogFile();
};
