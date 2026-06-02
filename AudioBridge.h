#ifndef AUDIOBRIDGE_H
#define AUDIOBRIDGE_H

#include <QObject>
#include <QTcpSocket>
#include <QTimer>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonValue>
#include <QDebug>

class AudioBridge : public QObject {
    Q_OBJECT

    Q_PROPERTY(QString status READ status NOTIFY statusChanged)
    Q_PROPERTY(float gainValue READ gainValue NOTIFY configUpdated)
    Q_PROPERTY(float frequencyValue READ frequencyValue NOTIFY configUpdated)

public:
    explicit AudioBridge(QObject *parent = nullptr) : QObject(parent) {
        socket = new QTcpSocket(this);

        connect(socket, &QTcpSocket::readyRead, this, &AudioBridge::onReadyRead);
        connect(socket, &QTcpSocket::connected, this, [this](){
            m_status = "Connected";
            emit statusChanged();
            requestConfig(); // Automatically fetch values on connection
        });
        connect(socket, &QTcpSocket::disconnected, this, [this](){
            m_status = "Disconnected";
            emit statusChanged();
        });

        reconnectTimer = new QTimer(this);
        connect(reconnectTimer, &QTimer::timeout, this, &AudioBridge::tryConnect);
        reconnectTimer->start(2000);
        tryConnect();
    }

    QString status() const { return m_status; }
    float gainValue() const { return m_gainValue; }
    float frequencyValue() const { return m_frequencyValue; }

    // QML-invokable function to modify effect settings remotely
    Q_INVOKABLE void setEffectValue(const QString &busId, const QString &effectName, float value) {
        QJsonObject innerFields;
        innerFields["bus_id"] = busId;
        innerFields["effect_name"] = effectName;
        innerFields["value"] = value;

        QJsonObject commandPayload;
        commandPayload["SetEffectValue"] = innerFields;

        sendPayload(commandPayload);
    }

    // QML-invokable function to manually poll configuration
    Q_INVOKABLE void requestConfig() {
        // Fix: Convert the raw string value using fromVariant to bypass constructor constraints
        QJsonDocument doc = QJsonDocument::fromVariant(QJsonValue("RequestConfig").toVariant());
        QByteArray data = doc.toJson(QJsonDocument::Compact) + "\n";

        if (socket->state() == QAbstractSocket::ConnectedState) {
            socket->write(data);
        }
    }

signals:
    void statusChanged();
    void configUpdated();

private slots:
    void tryConnect() {
        if (socket->state() == QAbstractSocket::UnconnectedState) {
            // Adjust address to target your Raspberry Pi 5
            socket->connectToHost("patchbox.local", 8001);
        }
    }

    void onReadyRead() {
        while (socket->canReadLine()) {
            QByteArray line = socket->readLine().trimmed();
            QJsonParseError error;
            QJsonDocument doc = QJsonDocument::fromJson(line, &error);

            if (error.error != QJsonParseError::NoError) {
                qDebug() << "Failed to parse JSON response from Pi:" << error.errorString();
                continue;
            }

            if (doc.isObject()) {
                QJsonObject responseObj = doc.object();

                // Handle ConfigData variant
                if (responseObj.contains("ConfigData")) {
                    QJsonObject configData = responseObj["ConfigData"].toObject();
                    QJsonObject busEffects = configData["bus_effects"].toObject();

                    // Pull default bus metrics ("bus_0" matches default Rust generation structure)
                    if (busEffects.contains("bus_0")) {
                        QJsonObject bus0Effects = busEffects["bus_0"].toObject();
                        m_gainValue = bus0Effects.value("gain").toDouble(20.0);
                        m_frequencyValue = bus0Effects.value("frequency").toDouble(220.0);
                        emit configUpdated();
                    }
                }
                // Handle telemetry data frames
                else if (responseObj.contains("Telemetry")) {
                    QJsonObject telemetry = responseObj["Telemetry"].toObject();
                    QString busId = telemetry["bus_id"].toString();
                    float peak = telemetry["peak_level"].toDouble();
                    // Optional: expose peak data to VU meters in QML
                }
                else if (responseObj.contains("Ack")) {
                    qDebug() << "Pi recognized instruction successfully";
                }
                else if (responseObj.contains("Error")) {
                    qDebug() << "Pi Engine processing failure:" << responseObj["Error"].toObject()["message"].toString();
                }
            }
        }
    }

private:
    void sendPayload(const QJsonObject &obj) {
        if (socket->state() == QAbstractSocket::ConnectedState) {
            QJsonDocument doc(obj);
            socket->write(doc.toJson(QJsonDocument::Compact) + "\n");
        }
    }

    QTcpSocket *socket;
    QTimer *reconnectTimer;
    QString m_status = "Connecting...";

    float m_gainValue = 20.0f;
    float m_frequencyValue = 220.0f;
};

#endif // AUDIOBRIDGE_H