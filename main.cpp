#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <bridge/interface_bridge.h>
#include <QQuickStyle>

int main(int argc, char *argv[])
{
    QQuickStyle::setStyle("Material");
    QGuiApplication app(argc, argv);

    InterfaceBridge interfaceBridge;

    QQmlApplicationEngine engine;

    // ModuleRegistry is a QML singleton (see CMakeLists.txt), available through `import QUTI_interface`
    engine.rootContext()->setContextProperty("interfaceBridge", &interfaceBridge);

    engine.loadFromModule("QUTI_interface", "Main");

    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}