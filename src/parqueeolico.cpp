#include "parqueeolico.h"
#include <QRandomGenerator>
#include <QDebug>

// ============================================================
//  Constructor: crea las turbinas iniciales con coordenadas
//  distribuidas en el mapa del parque (posX, posY ∈ 0-100).
// ============================================================
ParqueEolico::ParqueEolico(int numTurbinas, QObject *parent)
    : QAbstractListModel(parent),
      m_potenciaTotal(0.0),
      m_emergenciaGlobal(false),
      m_contadorIdsTurbinas(numTurbinas),
      m_climaActual("Día Soleado"),
      m_vientoMin(10.0),
      m_vientoMax(55.0)
{
    // Configuración inicial de cada turbina con posición en el mapa
    struct ConfigTurbina {
        QString nombre;
        double  eficiencia;
        double  potenciaMaxMW;
        double  orientacion;
        double  vientoInicialKmh;
        double  dirInicial;
        double  posX;
        double  posY;
    };

    const QList<ConfigTurbina> configs = {
        { "Turbina Alfa-01",    0.42, 5.0,   0.0, 18.0, 30.0, 20.0, 30.0 },
        { "Turbina Beta-02",    0.38, 4.5,  45.0, 22.3, 45.0, 55.0, 20.0 },
        { "Turbina Gamma-03",   0.45, 5.5,  90.0, 25.6, 60.0, 80.0, 35.0 },
        { "Turbina Delta-04",   0.40, 4.8, 135.0, 28.9, 75.0, 65.0, 65.0 },
        { "Turbina Epsilon-05", 0.43, 5.2, 180.0, 32.2, 90.0, 30.0, 70.0 }
    };

    for (int i = 0; i < numTurbinas && i < configs.size(); ++i) {
        const ConfigTurbina &c = configs[i];
        Turbina *t = new Turbina(i + 1, c.nombre, c.vientoInicialKmh,
                                  c.eficiencia, c.potenciaMaxMW, c.orientacion,
                                  c.posX, c.posY, this);
        t->setDireccionViento(c.dirInicial);
        conectarTurbina(t);
        m_turbinas.append(t);
    }

    recalcularPotenciaTotal();

    // Timer de simulación de física (cada 1 segundo)
    m_timerSimulacion = new QTimer(this);
    connect(m_timerSimulacion, &QTimer::timeout, this, &ParqueEolico::actualizarSimulacion);
    m_timerSimulacion->start(1000);

    // Timer de fallos aleatorios (cada 8 segundos)
    m_timerFallos = new QTimer(this);
    connect(m_timerFallos, &QTimer::timeout, this, &ParqueEolico::verificarFallosAleatorios);
    m_timerFallos->start(8000);

    registrarEvento("Sistema inicializado. " + QString::number(numTurbinas) + " turbinas activas.");
}

ParqueEolico::~ParqueEolico()
{
    qDeleteAll(m_turbinas);
    m_turbinas.clear();
}

// ============================================================
//  QAbstractListModel
// ============================================================
int ParqueEolico::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) return 0;
    return m_turbinas.count();
}

QVariant ParqueEolico::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_turbinas.count())
        return QVariant();

    const Turbina *t = m_turbinas.at(index.row());

    switch (role) {
    case IdRole:               return t->id();
    case NombreRole:           return t->nombre();
    case VelocidadRole:        return t->velocidadViento();
    case DireccionRole:        return t->direccionViento();
    case PotenciaRole:         return m_emergenciaGlobal ? 0.0 : t->potencia();
    case PotenciaPromedioRole: return m_emergenciaGlobal ? 0.0 : t->potenciaPromedio();
    case PotenciaFisicaRole:   return m_emergenciaGlobal ? 0.0 : t->potenciaFisica();
    case RpmRole:              return m_emergenciaGlobal ? 0.0 : t->rpm();
    case TemperaturaRole:      return t->temperatura();
    case PitchRole:            return t->anguloPitch();
    case EficienciaRole:       return t->eficiencia();
    case EstadoRole:           return m_emergenciaGlobal ? "Parada" : t->estado();
    case AlertaRole:           return m_emergenciaGlobal || t->alerta();
    case TipoFalloRole:        return t->tipoFallo();
    case EnMantenimientoRole:  return t->enMantenimiento();
    case SaludRole:            return t->saludPorcentaje();
    case FechaRevisionRole:    return t->fechaUltimaRevision();
    case HorasServicioRole:    return t->horasServicio();
    case PosXRole:             return t->posX();
    case PosYRole:             return t->posY();
    default:                   return QVariant();
    }
}

QHash<int, QByteArray> ParqueEolico::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[IdRole]               = "tid";
    roles[NombreRole]           = "tname";
    roles[VelocidadRole]        = "wind";
    roles[DireccionRole]        = "windDir";
    roles[PotenciaRole]         = "power";
    roles[PotenciaPromedioRole] = "powerAvg";
    roles[PotenciaFisicaRole]   = "powerFisica";
    roles[RpmRole]              = "rpm";
    roles[TemperaturaRole]      = "temperatura";
    roles[PitchRole]            = "pitchAngle";
    roles[EficienciaRole]       = "eficienciaBetz";
    roles[EstadoRole]           = "st";
    roles[AlertaRole]           = "alerta";
    roles[TipoFalloRole]        = "tipoFallo";
    roles[EnMantenimientoRole]  = "enMantenimiento";
    roles[SaludRole]            = "salud";
    roles[FechaRevisionRole]    = "fechaRevision";
    roles[HorasServicioRole]    = "horasServicio";
    roles[PosXRole]             = "posX";
    roles[PosYRole]             = "posY";
    return roles;
}

// ============================================================
//  Propiedades calculadas
// ============================================================
double ParqueEolico::potenciaPromedio() const
{
    if (m_turbinas.isEmpty()) return 0.0;
    return m_potenciaTotal / m_turbinas.size();
}

QStringList ParqueEolico::registroEventos() const
{
    // TAREA 3c: iteración explícita para compatibilidad con Qt 6.4
    QStringList lista;
    for (const QString &s : m_eventLog) lista.append(s);
    return lista;
}

void ParqueEolico::setEmergenciaGlobal(bool valor)
{
    if (m_emergenciaGlobal == valor) return;
    m_emergenciaGlobal = valor;
    emit emergenciaGlobalChanged();
    if (!m_turbinas.isEmpty())
        emit dataChanged(createIndex(0, 0), createIndex(m_turbinas.count() - 1, 0));
    recalcularPotenciaTotal();
    registrarEvento(valor ? "⚠ CORTE DE EMERGENCIA GLOBAL ACTIVADO."
                          : "✓ Sistema reanudado desde emergencia global.");
}

// ============================================================
//  Gestión dinámica de turbinas
// ============================================================
void ParqueEolico::agregarTurbina()
{
    m_contadorIdsTurbinas++;
    int nuevoId = m_contadorIdsTurbinas;

    // Nombre automático con letra griega o genérico
    static const QStringList letras = {
        "Zeta", "Eta", "Theta", "Iota", "Kappa", "Lambda",
        "Mu", "Nu", "Xi", "Omicron", "Pi", "Rho", "Sigma", "Tau"
    };
    int idx    = (nuevoId - 6);
    QString letra = (idx >= 0 && idx < letras.size()) ? letras[idx] : ("X" + QString::number(nuevoId));
    QString nombreNuevo = "Turbina " + letra + "-" + QString::number(nuevoId).rightJustified(2, '0');

    // Posición pseudo-aleatoria en el mapa (distribuida)
    double px = 10.0 + (QRandomGenerator::global()->bounded(80));
    double py = 10.0 + (QRandomGenerator::global()->bounded(80));
    double orientacion = QRandomGenerator::global()->bounded(360);
    double vientoInicial = m_vientoMin + QRandomGenerator::global()->bounded(
                               static_cast<int>(m_vientoMax - m_vientoMin));

    // Insertar ANTES de modificar el modelo (beginInsertRows / endInsertRows)
    int nuevaFila = m_turbinas.count();
    beginInsertRows(QModelIndex(), nuevaFila, nuevaFila);

    Turbina *t = new Turbina(nuevoId, nombreNuevo, vientoInicial,
                              0.40, 5.0, orientacion, px, py, this);
    conectarTurbina(t);
    m_turbinas.append(t);

    endInsertRows();
    recalcularPotenciaTotal();
    emit modeloRestructurado();
    registrarEvento("+ Turbina añadida: " + nombreNuevo + " (ID " + QString::number(nuevoId) + ")");
}

void ParqueEolico::eliminarTurbina(int turbinaId)
{
    int idx = buscarIndicePorId(turbinaId);
    if (idx < 0) return;

    registrarEvento("- Turbina dada de baja: " + m_turbinas[idx]->nombre()
                    + " (ID " + QString::number(turbinaId) + ")");

    beginRemoveRows(QModelIndex(), idx, idx);
    Turbina *t = m_turbinas.takeAt(idx);
    t->deleteLater();   // Libera memoria limpiamente, evita fugas
    endRemoveRows();

    recalcularPotenciaTotal();
    emit modeloRestructurado();
}

// ============================================================
//  Control individual de turbinas
// ============================================================
void ParqueEolico::actualizarVelocidad(int index, double nuevaVelocidad)
{
    if (index < 0 || index >= m_turbinas.count()) return;
    m_turbinas[index]->setVelocidadViento(nuevaVelocidad);
    emitirCambioFila(index);
    recalcularPotenciaTotal();
}

double ParqueEolico::velocidadDe(int index) const
{
    if (index < 0 || index >= m_turbinas.count()) return 0.0;
    return m_turbinas.at(index)->velocidadViento();
}

void ParqueEolico::slotParadaCritica(int turbinaId)
{
    int i = buscarIndicePorId(turbinaId);
    if (i < 0) return;
    m_turbinas[i]->paradaCritica();
    emitirCambioFila(i);
    recalcularPotenciaTotal();
    registrarEvento("🛑 Parada crítica: Turbina ID " + QString::number(turbinaId));
}

void ParqueEolico::reanudarTurbina(int turbinaId)
{
    int i = buscarIndicePorId(turbinaId);
    if (i < 0) return;
    m_turbinas[i]->reanudar();
    emitirCambioFila(i);
    recalcularPotenciaTotal();
    registrarEvento("▶ Turbina reanudada: ID " + QString::number(turbinaId));
}

void ParqueEolico::activarMantenimiento(int turbinaId)
{
    int i = buscarIndicePorId(turbinaId);
    if (i < 0) return;
    m_turbinas[i]->activarMantenimiento();
    emitirCambioFila(i);
    recalcularPotenciaTotal();
    registrarEvento("🔧 Mantenimiento activado: Turbina ID " + QString::number(turbinaId));
}

void ParqueEolico::completarMantenimiento(int turbinaId)
{
    int i = buscarIndicePorId(turbinaId);
    if (i < 0) return;
    m_turbinas[i]->completarMantenimiento();
    emitirCambioFila(i);
    recalcularPotenciaTotal();
    registrarEvento("✅ Mantenimiento completado: Turbina ID " + QString::number(turbinaId)
                    + " — Salud restaurada al 100%");
}

// ============================================================
//  Simulación en tiempo real
// ============================================================
void ParqueEolico::actualizarSimulacion()
{
    if (m_emergenciaGlobal) return;

    for (int i = 0; i < m_turbinas.count(); ++i) {
        Turbina *t = m_turbinas[i];
        if (t->detenidaManualmente() || t->enMantenimiento()) continue;

        // Variación aleatoria de viento dentro del rango climático
        double deltaViento = (QRandomGenerator::global()->bounded(31) / 10.0) - 1.5;
        double deltaTemp   = (QRandomGenerator::global()->bounded(11) / 10.0) - 0.5;
        double deltaDir    = (QRandomGenerator::global()->bounded(21) / 10.0) - 1.0;

        double nuevoViento = t->velocidadViento() + deltaViento;
        nuevoViento = qBound(m_vientoMin, nuevoViento, m_vientoMax);
        t->setVelocidadViento(nuevoViento);

        double nuevaTemp = t->temperatura() + deltaTemp;
        nuevaTemp = qBound(15.0, nuevaTemp, 95.0);
        t->setTemperatura(nuevaTemp);

        t->setDireccionViento(t->direccionViento() + deltaDir);
        emitirCambioFila(i);
    }
    recalcularPotenciaTotal();
}

void ParqueEolico::verificarFallosAleatorios()
{
    if (m_emergenciaGlobal) return;

    // Probabilidad de fallo: ~10% por tick (cada 8 segundos)
    if (QRandomGenerator::global()->bounded(100) > 10) return;

    // Elegir turbina aleatoria que esté activa
    QList<int> activas;
    for (int i = 0; i < m_turbinas.count(); ++i) {
        if (!m_turbinas[i]->detenidaManualmente()
            && !m_turbinas[i]->enMantenimiento()
            && m_turbinas[i]->tipoFallo().isEmpty()) {
            activas.append(i);
        }
    }
    if (activas.isEmpty()) return;

    int idx = activas[QRandomGenerator::global()->bounded(activas.size())];
    static const QStringList tiposFallo = {
        "Sobrecalentamiento", "Vibración Excesiva", "Fallo de Sensor",
        "Desalineación de Aspas", "Sobretensión"
    };
    QString tipo = tiposFallo[QRandomGenerator::global()->bounded(tiposFallo.size())];

    m_turbinas[idx]->inyectarFallo(tipo);
    emitirCambioFila(idx);
    recalcularPotenciaTotal();

    registrarEvento("⚡ FALLO en Turbina " + m_turbinas[idx]->nombre() + ": " + tipo);
    emit falloDetectado(m_turbinas[idx]->id(), tipo);
    emit alertaSonora("fallo");
}

// ============================================================
//  Control de clima
// ============================================================
void ParqueEolico::cambiarClima(const QString &clima)
{
    m_climaActual = clima;

    if (clima == "Día Soleado") {
        m_vientoMin = 10.0;
        m_vientoMax = 50.0;
    } else if (clima == "Tormenta de Verano") {
        m_vientoMin = 60.0;
        m_vientoMax = 130.0;
    } else if (clima == "Calma Total") {
        m_vientoMin = 0.0;
        m_vientoMax = 15.0;
    }

    emit climaCambiado();
    registrarEvento("☁ Clima cambiado a: " + clima);
}

// ============================================================
//  Helpers privados
// ============================================================
void ParqueEolico::recalcularPotenciaTotal()
{
    double total = 0.0;
    if (!m_emergenciaGlobal) {
        for (const Turbina *t : m_turbinas)
            if (t->estado() != "Parada" && t->estado() != "EMERGENCIA"
                && !t->enMantenimiento())
                total += t->potencia();
    }
    if (!qFuzzyCompare(m_potenciaTotal + 1.0, total + 1.0)) {
        m_potenciaTotal = total;
        emit potenciaTotalChanged();
    }
}

void ParqueEolico::emitirCambioFila(int row)
{
    if (row < 0 || row >= m_turbinas.count()) return;
    QModelIndex idx = createIndex(row, 0);
    emit dataChanged(idx, idx);
}

int ParqueEolico::buscarIndicePorId(int turbinaId) const
{
    for (int i = 0; i < m_turbinas.count(); ++i)
        if (m_turbinas[i]->id() == turbinaId) return i;
    return -1;
}

void ParqueEolico::registrarEvento(const QString &msg)
{
    // Mantener máximo 50 eventos en el log
    if (m_eventLog.size() >= 50) m_eventLog.removeFirst();
    m_eventLog.append(QTime::currentTime().toString("HH:mm:ss") + "  " + msg);
    emit registroEventosActualizado();
}

void ParqueEolico::conectarTurbina(Turbina *t)
{
    // Reemitir señal de fallo de la turbina hacia el parque
    connect(t, &Turbina::falloOcurrido,
            this, [this](int id, const QString &tipo) {
                emit falloDetectado(id, tipo);
            });
}
