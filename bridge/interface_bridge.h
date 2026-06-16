#ifndef INTERFACE_BRIDGE_H
#define INTERFACE_BRIDGE_H

#include <QObject>
#include <QTcpSocket>
#include <QString>

class InterfaceBridge : public QObject
{
    Q_OBJECT
    // Expose the connection state to QML
    Q_PROPERTY(bool isConnected READ isConnected NOTIFY connectionStatusChanged)

public:
    explicit InterfaceBridge(QObject *parent = nullptr);
    bool isConnected() const;

public slots:
    void connectToServer();
    void sendGraphData(const QString &jsonPayload);

signals:
    void connectionStatusChanged(bool connected);

private:
    QTcpSocket *socket;
    bool m_isConnected;
};

#endif // INTERFACE_BRIDGE_H