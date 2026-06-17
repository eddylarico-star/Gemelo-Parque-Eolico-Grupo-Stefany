#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "parqueeolico.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;

    // Se creo el parque con 5 turbinas iniciales
    ParqueEolico miParqueEolico(5);
    miParqueEolico.setEmergenciaGlobal(false);

    // Exponer el modelo a QML con ambos nombres (compatibilidad)
    engine.rootContext()->setContextProperty("parqueEolicoModel", &miParqueEolico);
    engine.rootContext()->setContextProperty("turbineModel",      &miParqueEolico);

    const QUrl url(QStringLiteral("qrc:/ParteSantiago/qml/Main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
                         if (!obj && url == objUrl)
                             QCoreApplication::exit(-1);
                     }, Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
