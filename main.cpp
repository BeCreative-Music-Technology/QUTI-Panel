#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "AudioBridge.h" // Renamed from SensorBridge.h

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);

    AudioBridge audioBridge; // Handles JSON TCP communication

    QQmlApplicationEngine engine;
    // Inject into QML context under the name "audioBridge"
    engine.rootContext()->setContextProperty("audioBridge", &audioBridge);

    engine.loadFromModule("DoFTestApp", "Main");
    return app.exec();
}