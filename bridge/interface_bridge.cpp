#include "interface_bridge.h"
#include <QDebug>
#include <QTimer>
#include <QStandardPaths>
#include <QDir>
#include <QFile>
#include <QTextStream>
#include <QRegularExpression>

InterfaceBridge::InterfaceBridge(QObject *parent) : QObject(parent), m_isConnected(false)
{
    socket = new QTcpSocket(this);

    connect(socket, &QTcpSocket::connected, this, [this]() {
        m_isConnected = true;
        emit connectionStatusChanged(true);
        qDebug() << "AudioBridge: Connected to Rust DSP server";
    });

    connect(socket, &QTcpSocket::disconnected, this, [this]() {
        m_isConnected = false;
        emit connectionStatusChanged(false);
        qDebug() << "AudioBridge: Disconnected from Rust DSP server";
    });

    connectToServer();
}

void InterfaceBridge::connectToServer()
{
    if (socket->state() != QAbstractSocket::ConnectedState) {
        socket->connectToHost("patchbox.local", 31628);
    }
}

bool InterfaceBridge::isConnected() const
{
    return m_isConnected;
}

void InterfaceBridge::sendGraphData(const QString &jsonPayload)
{
    if (socket->state() == QAbstractSocket::ConnectedState) {
        QByteArray data = jsonPayload.toUtf8() + "\n";
        socket->write(data);
        socket->flush();
        qDebug() << "Sent DSP configuration via TCP:" << data.trimmed();
    } else {
        qWarning() << "AudioBridge: Cannot send data, TCP socket is not connected.";
    }
}

// Helper function to establish cross-platform paths inside ~/Documents
QString InterfaceBridge::getPresetsDirectory() const
{
    QString docPath = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation);
    QDir dir(docPath);

    // Create a sub-folder to keep presets organized neatly
    QString subFolderName = "QUTI_Presets";
    if (!dir.exists(subFolderName)) {
        dir.mkdir(subFolderName);
    }
    return dir.absoluteFilePath(subFolderName);
}

// Write the preset JSON out to a file named 'PresetName.json'
void InterfaceBridge::savePresetToFile(const QString &presetName, const QString &jsonContent)
{
    QString sanitizedName = presetName;
    // Strip characters that could cause file path traversal vulnerabilities
    sanitizedName.remove(QRegularExpression("[\\\\/:*?\"<>|]"));

    QString filePath = getPresetsDirectory() + QDir::separator() + sanitizedName + ".json";
    QFile file(filePath);

    if (file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        QTextStream out(&file);
        out << jsonContent;
        file.close();
        qDebug() << "Saved preset successfully to:" << filePath;
    } else {
        qWarning() << "Failed to write preset file at:" << filePath;
    }
}

// Remove the file when user hits delete
void InterfaceBridge::deletePresetFile(const QString &presetName)
{
    QString sanitizedName = presetName;
    sanitizedName.remove(QRegularExpression("[\\\\/:*?\"<>|]"));

    QString filePath = getPresetsDirectory() + QDir::separator() + sanitizedName + ".json";
    QFile file(filePath);

    if (file.exists()) {
        file.remove();
        qDebug() << "Deleted preset file:" << filePath;
    }
}

// Scans directory on launch and sends data strings back to QML ListModel
QStringList InterfaceBridge::loadAllPresetFiles()
{
    QStringList localPresets;
    QDir dir(getPresetsDirectory());

    // Filter matching only our written JSON files
    QStringList filters;
    filters << "*.json";
    dir.setNameFilters(filters);

    QFileInfoList fileList = dir.entryInfoList(QDir::Files, QDir::Name);
    for (const QFileInfo &fileInfo : fileList) {
        QFile file(fileInfo.absoluteFilePath());
        if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
            QTextStream in(&file);
            QString content = in.readAll();
            file.close();

            // Append Name followed directly by its inner JSON payload string
            localPresets.append(fileInfo.baseName());
            localPresets.append(content);
        }
    }
    return localPresets;
}