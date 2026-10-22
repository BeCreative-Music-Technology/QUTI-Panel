#ifndef INTERFACE_BRIDGE_H
#define INTERFACE_BRIDGE_H

#include <QObject>
#include <QTcpSocket>
#include <QTimer>
#include <QString>
#include <QStringList> // Added for scanning files
#include <QVariantList>

class InterfaceBridge : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isConnected READ isConnected NOTIFY connectionStatusChanged)

public:
    explicit InterfaceBridge(QObject *parent = nullptr);
    bool isConnected() const;

public slots:
    void connectToServer();
    bool sendGraphData(const QString &jsonPayload); // Returns false when not connected

    // ---- New Preset Storage Slots ----
    bool savePresetToFile(const QString &presetName, const QString &jsonContent);
    void deletePresetFile(const QString &presetName);
    QStringList loadAllPresetFiles(); // Returns list of strings alternating: [Name1, Data1, Name2, Data2...]
    QVariantList loadBuiltInPresets(); // Returns [{name, description, data}], bundled with the app

signals:
    void connectionStatusChanged(bool connected);

private:
    QTcpSocket *socket;
    QTimer *reconnectTimer;
    bool m_isConnected;
    QString m_host;
    quint16 m_port;
    QString getPresetsDirectory() const; // Helper to locate/create Documents/QUTI_Presets
    QString presetFilePath(const QString &presetName) const;
};

#endif // INTERFACE_BRIDGE_H
