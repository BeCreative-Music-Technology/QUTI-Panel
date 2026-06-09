#ifndef INTERFACE_BRIDGE_H
#define INTERFACE_BRIDGE_H

#include <QObject>
#include <QTcpSocket>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>

class InterfaceBridge : public QObject
{
    Q_OBJECT
public:
    explicit InterfaceBridge(QObject *parent = nullptr);

    Q_INVOKABLE void sendBusConfiguration(const QVariantList &buses);

private:
    QTcpSocket *socket;
    void connectToServer();
};

#endif // INTERFACE_BRIDGE_H
