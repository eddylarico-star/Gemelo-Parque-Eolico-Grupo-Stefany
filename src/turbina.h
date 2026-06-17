#ifndef TURBINA_H
#define TURBINA_H

#include <QObject>
#include <QString>
#include <QVector>
#include <QDateTime>
//  Clase Turbina — Gemelo Digital Parque Eólico
//  Incluye: física real
//  mantenimiento, historial técnico y coordenadas de mapa.
class Turbina : public QObject
{
    Q_OBJECT

    // --- Propiedades básicas de operación ---
    Q_PROPERTY(int     id               READ id                                                     CONSTANT)
    Q_PROPERTY(QString nombre           READ nombre                                                 CONSTANT)
    Q_PROPERTY(double  velocidadViento  READ velocidadViento  WRITE setVelocidadViento  NOTIFY datosActualizados)
    Q_PROPERTY(double  direccionViento  READ direccionViento  WRITE setDireccionViento  NOTIFY datosActualizados)
    Q_PROPERTY(double  potencia         READ potencia                                   NOTIFY datosActualizados)
    Q_PROPERTY(double  potenciaPromedio READ potenciaPromedio                           NOTIFY datosActualizados)
    Q_PROPERTY(double  rpm              READ rpm                                        NOTIFY datosActualizados)
    Q_PROPERTY(double  temperatura      READ temperatura      WRITE setTemperatura      NOTIFY datosActualizados)
    Q_PROPERTY(double  anguloPitch      READ anguloPitch      WRITE setAnguloPitch      NOTIFY datosActualizados)
    Q_PROPERTY(double  eficiencia       READ eficiencia       WRITE setEficiencia       NOTIFY datosActualizados)
    Q_PROPERTY(QString estado           READ estado                                     NOTIFY datosActualizados)
    Q_PROPERTY(bool    alerta           READ alerta                                     NOTIFY alertaCambiada)

    // Propiedades de física real (fórmula Betz)
    Q_PROPERTY(double  potenciaFisica   READ potenciaFisica                             NOTIFY datosActualizados)
    Q_PROPERTY(double  areaRotor        READ areaRotor                                  CONSTANT)

    // Propiedades de fallos y mantenimiento
    Q_PROPERTY(QString tipoFallo        READ tipoFallo                                  NOTIFY falloOcurrido)
    Q_PROPERTY(bool    enMantenimiento  READ enMantenimiento                            NOTIFY estadoMantenimientoCambiado)
    Q_PROPERTY(double  saludPorcentaje  READ saludPorcentaje                            NOTIFY datosActualizados)

    // Propiedades de historial técnico
    Q_PROPERTY(QString fechaUltimaRevision READ fechaUltimaRevision                     CONSTANT)
    Q_PROPERTY(int     horasServicio       READ horasServicio                            NOTIFY datosActualizados)

    // Coordenadas en el mapa del parque
    Q_PROPERTY(double  posX             READ posX                                       CONSTANT)
    Q_PROPERTY(double  posY             READ posY                                       CONSTANT)

public:
    explicit Turbina(int id, const QString &nombre,
                     double velocidadInicialKmh = 0.0,
                     double eficienciaInicial   = 0.42,
                     double potenciaMaximaMW    = 5.0,
                     double orientacionGrados   = 0.0,
                     double posX = 50.0,
                     double posY = 50.0,
                     QObject *parent = nullptr);

    // Getters básicos
    int     id()              const { return m_id; }
    QString nombre()          const { return m_nombre; }
    double  velocidadViento() const { return m_velocidadVientoKmh; }
    double  direccionViento() const { return m_direccionViento; }
    double  potencia()        const { return m_potencia; }
    double  potenciaPromedio()const;
    double  rpm()             const { return m_rpm; }
    double  temperatura()     const { return m_temperatura; }
    double  anguloPitch()     const { return m_anguloPitch; }
    double  eficiencia()      const { return m_eficiencia; }
    QString estado()          const { return m_estado; }
    bool    alerta()          const { return m_alerta; }

    // Getters de física real
    // P = 0.5 * rho * A * v^3 * Cp  (Watts)
    double  potenciaFisica()  const { return m_potenciaFisicaW; }
    double  areaRotor()       const { return m_areaRotor; }

    // Getters de fallos/mantenimiento
    QString tipoFallo()        const { return m_tipoFallo; }
    bool    enMantenimiento()  const { return m_enMantenimiento; }
    double  saludPorcentaje()  const { return m_saludPorcentaje; }

    // --- Getters de historial ---
    QString fechaUltimaRevision() const { return m_fechaUltimaRevision; }
    int     horasServicio()       const { return m_horasServicio; }

    // Getters de posición en mapa
    double  posX() const { return m_posX; }
    double  posY() const { return m_posY; }

    // Setters
    void setVelocidadViento(double valueKmh);
    void setDireccionViento(double valueGrados);
    void setTemperatura(double value);
    void setAnguloPitch(double value);
    void setEficiencia(double value);

    // Control operativo
    Q_INVOKABLE void paradaCritica();
    Q_INVOKABLE void reanudar();
    Q_INVOKABLE void activarMantenimiento();
    Q_INVOKABLE void completarMantenimiento();  //Restaura salud al 100%

    bool detenidaManualmente() const { return m_detenidaManualmente; }

    // Inyectar fallo externo (llamado desde ParqueEolico con QTimer)
    void inyectarFallo(const QString &tipo);

signals:
    void datosActualizados();
    void alertaCambiada();
    void falloOcurrido(int id, const QString &tipo);
    void estadoMantenimientoCambiado();

private:
    int     m_id;
    QString m_nombre;

    // Configuración física fija
    double  m_orientacionTurbina;
    double  m_potenciaMaximaMW;
    double  m_radioRotorM;        // metros, para calcular área
    double  m_areaRotor;          // π * r²  (m²)

    // Variables físicas dinámicas
    double  m_velocidadVientoKmh;
    double  m_direccionViento;
    double  m_potencia;           // MW
    double  m_potenciaFisicaW;    // Watts (fórmula física exacta)
    double  m_temperatura;
    double  m_anguloPitch;
    double  m_eficiencia;
    double  m_rpm;
    QString m_estado;
    bool    m_alerta;
    bool    m_detenidaManualmente;

    // Fallos y mantenimiento
    QString m_tipoFallo;
    bool    m_enMantenimiento;
    double  m_saludPorcentaje;    // 0-100%

    // Historial técnico
    QString m_fechaUltimaRevision;
    int     m_horasServicio;

    // Posición en el mapa del parque (0-100 en ambos ejes)
    double  m_posX;
    double  m_posY;

    // Historial de potencia para promedio
    QVector<double> m_historialPotencia;
    static const int MAX_HISTORIAL = 60;

    // Constantes físicas
    static constexpr double RHO_AIRE        = 1.225;   // kg/m³ densidad del aire
    static constexpr double LIMITE_BETZ     = 0.593;
    static constexpr double V_ARRANQUE_KMH  = 10.8;    // 3.0 m/s
    static constexpr double V_NOMINAL_KMH   = 43.2;    // 12.0 m/s
    static constexpr double VIENTO_ADVERTENCIA_KMH = 90.0;
    static constexpr double VIENTO_CORTE_KMH       = 108.0;
    static constexpr double V_MAX_RPM_KMH   = 72.0;
    static constexpr double RPM_MAX         = 20.0;

    // Métodos privados de cálculo
    void    recalcularTodo();
    double  calcularPotenciaTeorica()  const;
    double  calcularPotenciaFisicaW()  const;  // Fórmula exacta Betz
    double  calcularRPM()              const;
    void    actualizarHistorial(double potencia);
    void    evaluarAlertas();
    void    actualizarEstadoYPitchAutomatico();
};

#endif // TURBINA_H
