#include "Logger.h"
#include <QDebug>

Logger::Logger(QObject *parent)
    : QObject(parent)
{
    QString logDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(logDir);
    m_logFilePath = logDir + "/ninjaview.log";
}

Logger::~Logger()
{
    closeLogFile();
}

void Logger::setLoggingEnabled(bool enabled)
{
    if (m_loggingEnabled == enabled)
        return;

    m_loggingEnabled = enabled;
    if (m_loggingEnabled) {
        openLogFile();
        log("Logging enabled", "System");
    } else {
        log("Logging disabled", "System");
        closeLogFile();
    }
    emit loggingEnabledChanged();
}

void Logger::log(const QString &message, const QString &category)
{
    if (!m_loggingEnabled)
        return;

    QString timestamp = QDateTime::currentDateTime().toString("yyyy-MM-dd HH:mm:ss.zzz");
    QString logEntry = QString("[%1] [%2] %3").arg(timestamp).arg(category).arg(message);

    // Also output to debug console when enabled
    qDebug().noquote() << logEntry;

    if (m_logFile.isOpen()) {
        m_logStream << logEntry << Qt::endl;
        m_logStream.flush();
    }
}

void Logger::openLogFile()
{
    if (m_logFile.isOpen())
        return;

    m_logFile.setFileName(m_logFilePath);
    if (!m_logFile.open(QIODevice::Append | QIODevice::Text)) {
        qWarning() << "Logger: Could not open log file for writing:" << m_logFilePath;
    } else {
        m_logStream.setDevice(&m_logFile);
    }
}

void Logger::closeLogFile()
{
    if (m_logFile.isOpen()) {
        m_logFile.close();
    }
}
