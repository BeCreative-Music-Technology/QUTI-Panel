#ifndef INTERFACE_BRIDGE_H
#define INTERFACE_BRIDGE_H

#include <QObject>
#include <QTcpSocket>
#include <QString>
#include <QStringList> // Added for scanning files

class InterfaceBridge : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isConnected READ isConnected NOTIFY connectionStatusChanged)

public:
    explicit InterfaceBridge(QObject *parent = nullptr);
    bool isConnected() const;

public slots:
    void connectToServer();
    void sendGraphData(const QString &jsonPayload);

    // ---- New Preset Storage Slots ----
    void savePresetToFile(const QString &presetName, const QString &jsonContent);
    void deletePresetFile(const QString &presetName);
    QStringList loadAllPresetFiles(); // Returns list of strings alternating: [Name1, Data1, Name2, Data2...]

signals:
    void connectionStatusChanged(bool connected);

private:
    QTcpSocket *socket;
    bool m_isConnected;
    QString getPresetsDirectory() const; // Helper to locate/create Documents/QUTI_Presets
};

#endif // INTERFACE_BRIDGE_H