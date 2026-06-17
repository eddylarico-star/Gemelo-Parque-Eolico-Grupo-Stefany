#include "turbina.h"
#include <cmath>
#include <QDate>

// ============================================================
//  Constructor
// ============================================================
Turbina::Turbina(int id, const QString &nombre,
                 double velocidadInicialKmh, double eficienciaInicial,
                 double potenciaMaximaMW, double orientacionGrados,
                 double posX, double posY,
                 QObject *parent)
    : QObject(parent),
      m_id(id),
      m_nombre(nombre),
      m_orientacionTurbina(orientacionGrados),
      m_potenciaMaximaMW(potenciaMaximaMW),
      m_radioRotorM(50.0),                          // rotor de 50 m de radio (real ~3 MW)
      m_areaRotor(M_PI * 50.0 * 50.0),             // π * 50² ≈ 7854 m²
      m_velocidadVientoKmh(velocidadInicialKmh),
      m_direccionViento(0.0),
      m_potencia(0.0),
      m_potenciaFisicaW(0.0),
      m_temperatura(25.0),
      m_anguloPitch(0.0),
      m_eficiencia(eficienciaInicial),
      m_rpm(0.0),
      m_estado("Óptimo"),
      m_alerta(false),
      m_detenidaManualmente(false),
      m_tipoFallo(""),
      m_enMantenimiento(false),
      m_saludPorcentaje(100.0),
      m_fechaUltimaRevision(QDate::currentDate().addDays(-id * 15).toString("dd/MM/yyyy")),
      m_horasServicio(1200 + id * 340),
      m_posX(posX),
      m_posY(posY)
{
    m_historialPotencia.fill(0.0, MAX_HISTORIAL);
    recalcularTodo();
}

// ============================================================
//  FÍSICA REAL: P = 0.5 * rho * A * v³ * Cp
//  rho = 1.225 kg/m³ (densidad del aire a nivel del mar, 15°C)
//  A   = π * r²  (área barrida por el rotor)
//  v   = velocidad del viento en m/s
//  Cp  = coeficiente de potencia (eficiencia, ≤ límite Betz 0.593)
// ============================================================
double Turbina::calcularPotenciaFisicaW() const
{
    double v_ms = m_velocidadVientoKmh / 3.6;   // km/h → m/s

    if (v_ms < (V_ARRANQUE_KMH / 3.6)) return 0.0;
    if (v_ms > (VIENTO_CORTE_KMH / 3.6)) return 0.0;
    if (m_enMantenimiento || m_detenidaManualmente) return 0.0;

    double Cp = m_eficiencia;
    if (Cp > LIMITE_BETZ) Cp = LIMITE_BETZ;

    // Factor por desalineación de la turbina respecto al viento
    double diff = std::fabs(m_direccionViento - m_orientacionTurbina);
    if (diff > 180.0) diff = 360.0 - diff;
    double factorDir = std::cos(diff * M_PI / 180.0);
    if (factorDir < 0.0) factorDir = 0.0;
    Cp *= factorDir;

    // Factor por ángulo de pitch (0° = máxima captación)
    double factorPitch = std::cos(m_anguloPitch * M_PI / 180.0);
    if (factorPitch < 0.0) factorPitch = 0.0;
    Cp *= factorPitch;

    // Fórmula exacta de potencia del viento
    double P_W = 0.5 * RHO_AIRE * m_areaRotor * std::pow(v_ms, 3.0) * Cp;

    // Límite físico del generador
    double P_max_W = m_potenciaMaximaMW * 1.0e6;
    if (P_W > P_max_W) P_W = P_max_W;

    // Reducción por temperatura excesiva (>60°C degrada los imanes)
    if (m_temperatura > 60.0) {
        double factor = 1.0 - (m_temperatura - 60.0) / 80.0;
        if (factor < 0.6) factor = 0.6;
        P_W *= factor;
    }

    // Reducción proporcional a la salud de la turbina
    P_W *= (m_saludPorcentaje / 100.0);

    return P_W;
}

double Turbina::calcularPotenciaTeorica() const
{
    // Convierte la potencia física (W) a MW para el modelo
    return calcularPotenciaFisicaW() / 1.0e6;
}

double Turbina::calcularRPM() const
{
    const double v    = m_velocidadVientoKmh / 3.6;
    const double V_A  = V_ARRANQUE_KMH / 3.6;
    const double V_MR = V_MAX_RPM_KMH  / 3.6;

    if (v < V_A || m_enMantenimiento || m_detenidaManualmente) return 0.0;

    double rpm = (v > V_MR) ? RPM_MAX : (v - V_A) / (V_MR - V_A) * RPM_MAX;
    rpm *= (1.0 - m_anguloPitch / 90.0);
    rpm *= (m_saludPorcentaje / 100.0);
    return (rpm < 0.0) ? 0.0 : rpm;
}

void Turbina::actualizarHistorial(double potencia)
{
    if (!m_historialPotencia.isEmpty())
        m_historialPotencia.removeFirst();
    m_historialPotencia.append(potencia);
    m_horasServicio++;  // incrementa horas de servicio con cada tick
}

double Turbina::potenciaPromedio() const
{
    if (m_historialPotencia.isEmpty()) return 0.0;
    double suma = 0.0;
    for (double p : m_historialPotencia) suma += p;
    return suma / m_historialPotencia.size();
}

void Turbina::actualizarEstadoYPitchAutomatico()
{
    if (m_enMantenimiento) {
        m_anguloPitch = 90.0;
        m_estado      = "Mantenimiento";
        return;
    }
    if (m_detenidaManualmente) {
        m_anguloPitch = 90.0;
        m_estado      = "Parada";
        return;
    }
    if (!m_tipoFallo.isEmpty()) {
        m_anguloPitch = 90.0;
        m_estado      = "EMERGENCIA";
        return;
    }
    if (m_velocidadVientoKmh <= 0.0) {
        m_anguloPitch = 90.0;
        m_estado      = "Parada";
    } else if (m_velocidadVientoKmh >= VIENTO_ADVERTENCIA_KMH) {
        m_anguloPitch = 90.0;
        m_estado      = (m_velocidadVientoKmh >= VIENTO_CORTE_KMH) ? "Parada" : "Advertencia";
    } else {
        m_anguloPitch = 0.0;
        m_estado      = "Óptimo";
    }
}

void Turbina::recalcularTodo()
{
    actualizarEstadoYPitchAutomatico();

    m_potenciaFisicaW = calcularPotenciaFisicaW();
    double nuevaPotencia = calcularPotenciaTeorica();
    if (m_estado == "Parada" || m_estado == "EMERGENCIA" || m_enMantenimiento)
        nuevaPotencia = 0.0;

    if (!qFuzzyCompare(nuevaPotencia + 1.0, m_potencia + 1.0)) {
        m_potencia = nuevaPotencia;
        actualizarHistorial(m_potencia);
    }

    m_rpm = (m_estado == "Parada" || m_estado == "EMERGENCIA" || m_enMantenimiento)
            ? 0.0 : calcularRPM();

    evaluarAlertas();
    emit datosActualizados();
}

// ============================================================
//  Setters públicos
// ============================================================
void Turbina::setVelocidadViento(double valueKmh)
{
    if (valueKmh < 0.0)   valueKmh = 0.0;
    if (valueKmh > 180.0) valueKmh = 180.0;
    if (qFuzzyCompare(m_velocidadVientoKmh + 1.0, valueKmh + 1.0)) return;
    m_velocidadVientoKmh = valueKmh;
    recalcularTodo();
}

void Turbina::setDireccionViento(double valueGrados)
{
    while (valueGrados < 0.0)    valueGrados += 360.0;
    while (valueGrados >= 360.0) valueGrados -= 360.0;
    if (qFuzzyCompare(m_direccionViento + 1.0, valueGrados + 1.0)) return;
    m_direccionViento = valueGrados;
    recalcularTodo();
}

void Turbina::setTemperatura(double value)
{
    if (qFuzzyCompare(m_temperatura + 1.0, value + 1.0)) return;
    m_temperatura = value;
    recalcularTodo();
}

void Turbina::setAnguloPitch(double value)
{
    if (value < 0.0)  value = 0.0;
    if (value > 90.0) value = 90.0;
    if (qFuzzyCompare(m_anguloPitch + 1.0, value + 1.0)) return;
    m_anguloPitch = value;
    recalcularTodo();
}

void Turbina::setEficiencia(double value)
{
    if (value < 0.0)         value = 0.0;
    if (value > LIMITE_BETZ) value = LIMITE_BETZ;
    if (qFuzzyCompare(m_eficiencia + 1.0, value + 1.0)) return;
    m_eficiencia = value;
    recalcularTodo();
}

// ============================================================
//  Control operativo
// ============================================================
void Turbina::paradaCritica()
{
    m_detenidaManualmente = true;
    m_velocidadVientoKmh  = 0.0;
    m_potencia            = 0.0;
    m_potenciaFisicaW     = 0.0;
    m_rpm                 = 0.0;
    m_anguloPitch         = 90.0;
    m_estado              = "Parada";
    m_alerta = false;
    emit alertaCambiada();
    emit datosActualizados();
}

void Turbina::reanudar()
{
    m_detenidaManualmente = false;
    m_tipoFallo.clear();
    m_enMantenimiento = false;
    // Restaura salud gradualmente al reanudar
    if (m_saludPorcentaje < 50.0) m_saludPorcentaje = 50.0;
    emit estadoMantenimientoCambiado();
    recalcularTodo();
}

void Turbina::activarMantenimiento()
{
    m_enMantenimiento = true;
    m_potencia        = 0.0;
    m_rpm             = 0.0;
    m_anguloPitch     = 90.0;
    m_estado          = "Mantenimiento";
    m_tipoFallo.clear();
    m_alerta = false;
    emit estadoMantenimientoCambiado();
    emit alertaCambiada();
    emit datosActualizados();
}

void Turbina::completarMantenimiento()
{
    m_enMantenimiento       = false;
    m_detenidaManualmente   = false;
    m_tipoFallo.clear();
    m_saludPorcentaje       = 100.0;  // Restaura salud completa
    m_fechaUltimaRevision   = QDate::currentDate().toString("dd/MM/yyyy");
    emit estadoMantenimientoCambiado();
    recalcularTodo();
}

void Turbina::inyectarFallo(const QString &tipo)
{
    if (m_enMantenimiento || m_detenidaManualmente) return;

    m_tipoFallo = tipo;
    m_alerta    = true;

    // Degradar salud por el fallo
    m_saludPorcentaje -= 15.0;
    if (m_saludPorcentaje < 5.0) m_saludPorcentaje = 5.0;

    emit falloOcurrido(m_id, tipo);
    emit alertaCambiada();
    recalcularTodo();
}

void Turbina::evaluarAlertas()
{
    bool nueva = false;
    if (!m_tipoFallo.isEmpty())                    nueva = true;
    if (m_velocidadVientoKmh > VIENTO_ADVERTENCIA_KMH) nueva = true;
    if (m_temperatura > 85.0)                      nueva = true;
    if (m_potencia > m_potenciaMaximaMW * 0.95)    nueva = true;
    if (m_saludPorcentaje < 30.0)                  nueva = true;

    if (nueva != m_alerta) {
        m_alerta = nueva;
        emit alertaCambiada();
    }
}
