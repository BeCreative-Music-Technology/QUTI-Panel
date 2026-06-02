#ifndef SENSORBRIDGE_H
#define SENSORBRIDGE_H

#include <QObject>
#include <QTcpSocket>
#include <QTimer>
#include <QtMath>

class SensorBridge : public QObject {
    Q_OBJECT

    // Expose these properties to QML
    Q_PROPERTY(float yaw READ yaw NOTIFY orientationChanged)
    Q_PROPERTY(float pitch READ pitch NOTIFY orientationChanged)
    Q_PROPERTY(float roll READ roll NOTIFY orientationChanged)
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)

public:
    explicit SensorBridge(QObject *parent = nullptr) : QObject(parent) {
        socket = new QTcpSocket(this);

        connect(socket, &QTcpSocket::readyRead, this, &SensorBridge::onReadyRead);
        connect(socket, &QTcpSocket::connected, this, [this](){
            m_status = "Connected";
            emit statusChanged();
        });
        connect(socket, &QTcpSocket::disconnected, this, [this](){
            m_status = "Disconnected";
            emit statusChanged();
        });

        reconnectTimer = new QTimer(this);
        connect(reconnectTimer, &QTimer::timeout, this, &SensorBridge::tryConnect);
        reconnectTimer->start(2000);
        tryConnect();
    }

    // Getters
    float yaw() const { return m_yaw; }
    float pitch() const { return m_pitch; }
    float roll() const { return m_roll; }
    QString status() const { return m_status; }

signals:
    void orientationChanged();
    void statusChanged();

private slots:
    void tryConnect() {
        if (socket->state() == QAbstractSocket::UnconnectedState) {
            socket->connectToHost("patchbox.local", 8001);
        }
    }

    void onReadyRead() {
        while (socket->canReadLine()) {
            QString line = QString::fromUtf8(socket->readLine()).trimmed();
            QStringList values = line.split(',');

            if (values.size() >= 9) {
                // 0:ax, 1:ay, 2:az, 3:gx, 4:gy, 5:gz, 6:mx, 7:my, 8:mz
                float ax = values[0].toFloat();
                float ay = values[1].toFloat();
                float az = values[2].toFloat();
                float mx = values[6].toFloat();
                float my = values[7].toFloat();

                // Simple Euler Angle Calculations
                m_pitch = atan2(-ax, sqrt(ay * ay + az * az)) * 180.0 / M_PI;
                m_roll = atan2(ay, az) * 180.0 / M_PI;
                m_yaw = atan2(my, mx) * 180.0 / M_PI;

                emit orientationChanged();
            }
        }
    }

private:
    QTcpSocket *socket;
    QTimer *reconnectTimer;

    float m_yaw = 0.0f;
    float m_pitch = 0.0f;
    float m_roll = 0.0f;
    QString m_status = "Connecting...";
};

#endif // SENSORBRIDGE_H