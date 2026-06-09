#include "interface_bridge.h"
#include <QDebug>

InterfaceBridge::InterfaceBridge(QObject *parent) : QObject(parent)
{
    socket = new QTcpSocket(this);
    connectToServer();
}

void InterfaceBridge::connectToServer()
{
    socket->connectToHost("127.0.0.1", 12345);
    if (!socket->waitForConnected(1000)) {
        qWarning() << "AudioBridge: Could not connect to DSP server";
    }
}

void InterfaceBridge::sendBusConfiguration(const QVariantList &buses)
{
    QJsonArray busArray;
    for (const QVariant &busVar : buses) {
        QVariantMap bus = busVar.toMap();
        QJsonObject busObj;
        busObj["id"] = bus["id"].toString();
        busObj["enabled"] = bus["enabled"].toBool();

        QJsonArray effectsArray;
        QVariantList effects = bus["effects"].toList();
        for (const QVariant &fxVar : effects) {
            QVariantMap fx = fxVar.toMap();
            QJsonObject fxObj;
            fxObj["effect_type"] = fx["effect_type"].toString();
            fxObj["parameters"] = QJsonObject::fromVariantMap(fx["parameters"].toMap());
            effectsArray.append(fxObj);
        }
        busObj["effects"] = effectsArray;
        busArray.append(busObj);
    }

    QJsonDocument doc(busArray);
    QByteArray data = doc.toJson(QJsonDocument::Compact) + "\n";

    if (socket->state() == QAbstractSocket::ConnectedState) {
        socket->write(data);
        socket->flush();
    }
    qDebug() << "Sent bus configuration:" << data;
}