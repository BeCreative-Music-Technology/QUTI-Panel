#include "interface_bridge.h"
#include <QDebug>
#include <QTimer>

InterfaceBridge::InterfaceBridge(QObject *parent) : QObject(parent), m_isConnected(false)
{
    socket = new QTcpSocket(this);

    // Wire up socket state changes to our QML-exposed property
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
        socket->connectToHost("patchbox.local", 31628); // Ensure this port matches your Rust backend
    }
}

bool InterfaceBridge::isConnected() const
{
    return m_isConnected;
}

void InterfaceBridge::sendGraphData(const QString &jsonPayload)
{
    if (socket->state() == QAbstractSocket::ConnectedState) {
        // Rust's reader.lines() expects a newline delimiter
        QByteArray data = jsonPayload.toUtf8() + "\n";
        socket->write(data);
        socket->flush();
        qDebug() << "Sent DSP configuration via TCP:" << data.trimmed();
    } else {
        qWarning() << "AudioBridge: Cannot send data, TCP socket is not connected.";
    }
}