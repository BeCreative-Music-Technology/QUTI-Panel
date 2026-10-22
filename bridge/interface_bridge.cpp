#include "interface_bridge.h"
#include <QDebug>
#include <QStandardPaths>
#include <QDir>
#include <QFile>
#include <QTextStream>
#include <QRegularExpression>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>

// Default address of the Rust DSP engine (PickupProcessor), override with QUTI_ENGINE_HOST / QUTI_ENGINE_PORT
static const char *DEFAULT_ENGINE_HOST = "patchbox.local";
static const quint16 DEFAULT_ENGINE_PORT = 31628;
static const int RECONNECT_INTERVAL_MS = 3000;

InterfaceBridge::InterfaceBridge(QObject *parent) : QObject(parent), m_isConnected(false)
{
    m_host = qEnvironmentVariable("QUTI_ENGINE_HOST", DEFAULT_ENGINE_HOST);
    bool portOk = false;
    int port = qEnvironmentVariableIntValue("QUTI_ENGINE_PORT", &portOk);
    m_port = (portOk && port > 0 && port <= 65535) ? static_cast<quint16>(port) : DEFAULT_ENGINE_PORT;

    socket = new QTcpSocket(this);

    // Keep retrying while disconnected, so the panel recovers when the guitar boots later or drops off WiFi
    reconnectTimer = new QTimer(this);
    reconnectTimer->setInterval(RECONNECT_INTERVAL_MS);
    connect(reconnectTimer, &QTimer::timeout, this, &InterfaceBridge::connectToServer);

    connect(socket, &QTcpSocket::connected, this, [this]() {
        m_isConnected = true;
        reconnectTimer->stop();
        emit connectionStatusChanged(true);
        qDebug() << "AudioBridge: Connected to Rust DSP server at" << m_host << m_port;
    });

    connect(socket, &QTcpSocket::disconnected, this, [this]() {
        m_isConnected = false;
        reconnectTimer->start();
        emit connectionStatusChanged(false);
        qDebug() << "AudioBridge: Disconnected from Rust DSP server";
    });

    connect(socket, &QTcpSocket::errorOccurred, this, [this](QAbstractSocket::SocketError) {
        qWarning() << "AudioBridge:" << socket->errorString();
        if (!m_isConnected)
            reconnectTimer->start();
    });

    connectToServer();
}

void InterfaceBridge::connectToServer()
{
    // Only start a new attempt when idle; calling connectToHost while looking up/connecting is an error
    if (socket->state() == QAbstractSocket::UnconnectedState) {
        socket->connectToHost(m_host, m_port);
    }
}

bool InterfaceBridge::isConnected() const
{
    return m_isConnected;
}

bool InterfaceBridge::sendGraphData(const QString &jsonPayload)
{
    if (socket->state() != QAbstractSocket::ConnectedState) {
        qWarning() << "AudioBridge: Cannot send data, TCP socket is not connected.";
        return false;
    }

    // The engine reads one JSON message per line
    QByteArray data = jsonPayload.toUtf8();
    data.replace('\n', ' ');
    data.append('\n');
    socket->write(data);
    socket->flush();
    qDebug() << "Sent DSP configuration via TCP:" << data.trimmed();
    return true;
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

// Returns an empty string when the name has no usable characters
QString InterfaceBridge::presetFilePath(const QString &presetName) const
{
    QString sanitizedName = presetName;
    // Strip characters that could cause file path traversal vulnerabilities
    sanitizedName.remove(QRegularExpression("[\\\\/:*?\"<>|]"));
    sanitizedName = sanitizedName.trimmed();
    if (sanitizedName.isEmpty() || sanitizedName.startsWith('.'))
        return QString();

    return getPresetsDirectory() + QDir::separator() + sanitizedName + ".json";
}

// Write the preset JSON out to a file named 'PresetName.json'
bool InterfaceBridge::savePresetToFile(const QString &presetName, const QString &jsonContent)
{
    QString filePath = presetFilePath(presetName);
    if (filePath.isEmpty()) {
        qWarning() << "Invalid preset name:" << presetName;
        return false;
    }

    QFile file(filePath);
    if (file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        QTextStream out(&file);
        out << jsonContent;
        file.close();
        qDebug() << "Saved preset successfully to:" << filePath;
        return true;
    }

    qWarning() << "Failed to write preset file at:" << filePath;
    return false;
}

// Remove the file when user hits delete
void InterfaceBridge::deletePresetFile(const QString &presetName)
{
    QString filePath = presetFilePath(presetName);
    if (filePath.isEmpty())
        return;

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

            // Append Name followed directly by its inner JSON payload string.
            // completeBaseName keeps dots in names like "v1.2" (baseName would cut it to "v1")
            localPresets.append(fileInfo.completeBaseName());
            localPresets.append(content);
        }
    }
    return localPresets;
}

// Reads the read-only presets bundled in the app resources (presets/builtin_presets.json)
QVariantList InterfaceBridge::loadBuiltInPresets()
{
    QVariantList builtInPresets;
    QFile file(":/qt/qml/QUTI_interface/presets/builtin_presets.json");
    if (!file.open(QIODevice::ReadOnly)) {
        qWarning() << "Failed to open built-in presets:" << file.errorString();
        return builtInPresets;
    }

    QJsonParseError parseError;
    QJsonDocument document = QJsonDocument::fromJson(file.readAll(), &parseError);
    if (parseError.error != QJsonParseError::NoError) {
        qWarning() << "Invalid built-in presets JSON:" << parseError.errorString();
        return builtInPresets;
    }

    const QJsonArray presets = document.object().value("presets").toArray();
    for (const QJsonValue &value : presets) {
        QJsonObject preset = value.toObject();
        QVariantMap entry;
        entry["name"] = preset.value("name").toString();
        entry["description"] = preset.value("description").toString();
        // Same format as the user preset files, so loading works identically
        entry["data"] = QString::fromUtf8(QJsonDocument(preset.value("config").toObject()).toJson(QJsonDocument::Compact));
        builtInPresets.append(entry);
    }
    return builtInPresets;
}
