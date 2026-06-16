#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQmlComponent>
#include <QDebug>
#include <bridge/interface_bridge.h>
#include <QQuickStyle>

int main(int argc, char *argv[])
{
    QQuickStyle::setStyle("Material");
    QGuiApplication app(argc, argv);

    InterfaceBridge interfaceBridge;

    QQmlApplicationEngine engine;

    QQmlComponent registryComponent(&engine, "qrc:/qt/qml/QUTI_interface/modules/ModuleRegistry.qml");
    if (registryComponent.isError()) {
        qWarning() << "Failed to load ModuleRegistry:" << registryComponent.errorString();
        return -1;
    }

    QObject *moduleRegistry = registryComponent.create();
    if (!moduleRegistry) {
        qWarning() << "Failed to create ModuleRegistry instance";
        return -1;
    }

    QVariant modulesVariant = moduleRegistry->property("modules");
    qDebug() << "modules property type:" << modulesVariant.typeName();
    qDebug() << "modules value:" << modulesVariant;
    if (modulesVariant.canConvert<QVariantList>()) {
        qDebug() << "List size:" << modulesVariant.toList().size();
    }

    engine.rootContext()->setContextProperty("ModuleRegistry", moduleRegistry);
    engine.rootContext()->setContextProperty("interfaceBridge", &interfaceBridge);

    engine.loadFromModule("QUTI_interface", "Main");

    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}