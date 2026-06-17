#ifndef PARQUEEOLICO_H
#define PARQUEEOLICO_H

#include <QAbstractListModel>
#include <QList>
#include <QTimer>
#include <QVector>
#include <QString>
#include <QStringList>
#include <QTime>
#include "turbina.h"

// ============================================================
//  ParqueEolico — Modelo principal del Gemelo Digital
//  Expuesto a QML como QAbstractListModel.
//  Gestión dinámica de turbinas + sistema de fallos aleatorios
//  + lógica de clima + registro de eventos.
// ============================================================
class ParqueEolico : public QAbstractListModel
{
    Q_OBJECT

    Q_PROPERTY(double     potenciaTotal   READ potenciaTotal     NOTIFY potenciaTotalChanged)
    Q_PROPERTY(double     potenciaPromedio READ potenciaPromedio  NOTIFY potenciaTotalChanged)
    Q_PROPERTY(bool       emergenciaGlobal READ emergenciaGlobal  WRITE setEmergenciaGlobal NOTIFY emergenciaGlobalChanged)
    Q_PROPERTY(QStringList registroEventos READ registroEventos   NOTIFY registroEventosActualizado)
    Q_PROPERTY(int        contadorTurbinas READ contadorTurbinas  NOTIFY modeloRestructurado)
    Q_PROPERTY(QString    climaActual      READ climaActual        NOTIFY climaCambiado)

public:
    enum TurbinaRoles {
        IdRole = Qt::UserRole + 1,
        NombreRole,
        VelocidadRole,
        DireccionRole,
        PotenciaRole,
        PotenciaPromedioRole,
        PotenciaFisicaRole,      // Potencia física en Watts (fórmula Betz)
        RpmRole,
        TemperaturaRole,
        PitchRole,
        EficienciaRole,
        EstadoRole,
        AlertaRole,
        TipoFalloRole,
        EnMantenimientoRole,
        SaludRole,
        FechaRevisionRole,
        HorasServicioRole,
        PosXRole,
        PosYRole
    };

    explicit ParqueEolico(int numTurbinas = 5, QObject *parent = nullptr);
    virtual ~ParqueEolico() override;

    // --- QAbstractListModel interface ---
    int     rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    // --- Propiedades Q_PROPERTY ---
    double      potenciaTotal()    const { return m_potenciaTotal; }
    double      potenciaPromedio() const;
    bool        emergenciaGlobal() const { return m_emergenciaGlobal; }
    void        setEmergenciaGlobal(bool valor);
    QStringList registroEventos()  const;
    int         contadorTurbinas() const { return m_turbinas.count(); }
    QString     climaActual()      const { return m_climaActual; }

public slots:
    // Control individual de turbinas
    Q_INVOKABLE void actualizarVelocidad(int index, double nuevaVelocidad);
    Q_INVOKABLE double velocidadDe(int index) const;
    Q_INVOKABLE void slotParadaCritica(int turbinaId);
    Q_INVOKABLE void reanudarTurbina(int turbinaId);
    Q_INVOKABLE void activarMantenimiento(int turbinaId);
    Q_INVOKABLE void completarMantenimiento(int turbinaId);

    // Gestión dinámica de turbinas (añadir/quitar)
    Q_INVOKABLE void agregarTurbina();
    Q_INVOKABLE void eliminarTurbina(int turbinaId);

    // Simulación
    void actualizarSimulacion();
    void verificarFallosAleatorios();

    // Control de clima
    Q_INVOKABLE void cambiarClima(const QString &clima);

signals:
    void potenciaTotalChanged();
    void emergenciaGlobalChanged();
    void registroEventosActualizado();
    void modeloRestructurado();
    void climaCambiado();
    void falloDetectado(int turbinaId, const QString &tipo);
    void alertaSonora(const QString &tipo); // Para QML reproduzca audio

private:
    QList<Turbina*>  m_turbinas;
    QTimer          *m_timerSimulacion;
    QTimer          *m_timerFallos;      // Timer independiente para fallos aleatorios
    double           m_potenciaTotal;
    bool             m_emergenciaGlobal;
    QVector<QString> m_eventLog;
    int              m_contadorIdsTurbinas; // ID único incremental para nuevas turbinas
    QString          m_climaActual;

    // Rango de viento según clima
    double           m_vientoMin;
    double           m_vientoMax;

    void recalcularPotenciaTotal();
    void emitirCambioFila(int row);
    int  buscarIndicePorId(int turbinaId) const;
    void registrarEvento(const QString &msg);
    void conectarTurbina(Turbina *t);
};

#endif // PARQUEEOLICO_H
