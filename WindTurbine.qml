// WindTurbine.qml — Versión Isométrica (Eddy, Semana 4)
//
// Técnica: Proyección isométrica con Canvas 2D puro, sin Qt Quick 3D.
// La función iso(x,y,z) convierte coordenadas 3D → píxeles 2D:
//   px = ox + (x - z) × cos(30°) × scale
//   py = oy - y × scale + (x + z) × sin(30°) × scale
//
// Torre: prisma con 3 caras visibles (cara luz, cara sombra, aristas).
// Góndola: caja 3D isométrica encima de la torre.
// Aspas: vector en el plano del rotor rotado θ, proyectado a iso.
//        depthFactor (1 - sin(θ)*0.35) simula perspectiva sin motor 3D.
//
// Props recibidas desde TurbineCard.qml:
//   rpm       — velocidad de rotación (real, de C++ ParqueEolico)
//   status    — "Óptimo" | "Advertencia" | "Parada"
//   emergency — bool, corte global de emergencia

import QtQuick 2.15

Item {
    id: root

    // ── Propiedades públicas (idénticas a WindTurbine original) ──────
    property real   rpm:       15.0
    property string status:    "Óptimo"
    property bool   emergency: false

    // Tamaño por defecto (TurbineCard lo sobreescribe a 100×95)
    width:  110
    height: 130

    // ── Ángulo de rotación acumulado ─────────────────────────────────
    property real _angle: 0.0

    // Forzar redibujado cuando cambian props externas
    on_AngleChanged:   turbineCanvas.requestPaint()
    onEmergencyChanged: turbineCanvas.requestPaint()
    onStatusChanged:    turbineCanvas.requestPaint()

    // ── Timer de animación (~60 fps) — idéntica lógica al original ───
    Timer {
        interval: 16
        running:  !root.emergency && root.status !== "Parada" && root.rpm > 0
        repeat:   true
        onTriggered: {
            // Misma fórmula que el WindTurbine original
            root._angle = (root._angle + (root.rpm * 0.36)) % 360
        }
    }

    // ── Canvas principal ─────────────────────────────────────────────
    Canvas {
        id: turbineCanvas
        anchors.fill: parent
        antialiasing: true

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            drawTurbine(ctx)
        }

        // ════════════════════════════════════════════════════════════
        //  PROYECCIÓN ISOMÉTRICA
        //  Sistema de coordenadas mundo: X=derecha, Y=arriba, Z=fondo
        //  Ángulo iso clásico 30°:
        //    px = ox + (x - z) * cos30 * scale
        //    py = oy - y * scale + (x + z) * sin30 * scale
        //  cos30 ≈ 0.866,  sin30 = 0.5
        // ════════════════════════════════════════════════════════════
        function iso(x, y, z) {
            var scale  = Math.min(width, height) * 0.085   // escala adaptativa al tamaño del Item
            var cos30  = 0.866
            var sin30  = 0.5
            var ox     = width  * 0.50
            var oy     = height * 0.84
            return Qt.point(
                ox + (x - z) * cos30 * scale,
                oy - y * scale + (x + z) * sin30 * scale
            )
        }

        // ── Color de estado (igual que original) ──────────────────
        function bladeColor() {
            if (root.emergency || root.status === "Parada")  return "#ff4444"
            if (root.status === "Advertencia")               return "#ffcc00"
            if (root.status === "Mantenimiento")             return "#ff9900"
            return "#44aaff"   // Aero: azul cielo brillante
        }

        function hubColor() {
            if (root.emergency || root.status === "Parada")  return "#ff4444"
            if (root.status === "Advertencia")               return "#ffcc00"
            if (root.status === "Mantenimiento")             return "#ff9900"
            return "#0099ee"   // Aero: azul brillante
        }

        // ══════════════════════════════════════════════════════════
        //  DIBUJO PRINCIPAL
        // ══════════════════════════════════════════════════════════
        function drawTurbine(ctx) {
            drawShadow(ctx)
            drawTower(ctx)
            drawNacelle(ctx)
            drawBlades(ctx)
            drawHub(ctx)
            drawRpmLabel(ctx)
        }

        // ── Sombra elíptica en la base (igual que original) ───────
        function drawShadow(ctx) {
            var base = iso(0, 0, 0)
            ctx.beginPath()
            ctx.ellipse(base.x, base.y + 2, 10, 4, 0, 0, Math.PI * 2)
            ctx.fillStyle = "#12122a"
            ctx.fill()
        }

        // ── Torre: prisma isométrico con 2 caras visibles ─────────
        // Dimensiones: tw=semi-ancho, td=semi-profundidad, th=altura
        function drawTower(ctx) {
            var tw = 0.22
            var td = 0.22
            var th = 5.5

            // Vértices base y tapa
            var b0 = iso( tw, 0,   -td)   // esquina derecha-frontal
            var b1 = iso( tw, 0,    td)   // esquina derecha-trasera
            var b2 = iso(-tw, 0,    td)   // esquina izquierda-trasera
            var t0 = iso( tw, th,  -td)
            var t1 = iso( tw, th,   td)
            var t2 = iso(-tw, th,   td)

            // Cara derecha (iluminada)
            ctx.beginPath()
            ctx.moveTo(b0.x, b0.y)
            ctx.lineTo(b1.x, b1.y)
            ctx.lineTo(t1.x, t1.y)
            ctx.lineTo(t0.x, t0.y)
            ctx.closePath()
            ctx.fillStyle = "#4a4a6a"
            ctx.fill()

            // Cara izquierda (sombra)
            ctx.beginPath()
            ctx.moveTo(b1.x, b1.y)
            ctx.lineTo(b2.x, b2.y)
            ctx.lineTo(t2.x, t2.y)
            ctx.lineTo(t1.x, t1.y)
            ctx.closePath()
            ctx.fillStyle = "#2e2e4e"
            ctx.fill()

            // Aristas de contorno
            ctx.strokeStyle = "#1e1e3a"
            ctx.lineWidth   = 0.6
            ctx.beginPath()
            ctx.moveTo(b0.x, b0.y); ctx.lineTo(t0.x, t0.y)
            ctx.moveTo(b1.x, b1.y); ctx.lineTo(t1.x, t1.y)
            ctx.moveTo(b2.x, b2.y); ctx.lineTo(t2.x, t2.y)
            ctx.stroke()
        }

        // ── Góndola: caja 3D isométrica encima de la torre ────────
        function drawNacelle(ctx) {
            var th = 5.5    // tope de la torre
            var gx = 0.50   // semi-ancho
            var gy = 0.22   // semi-alto
            var gz = 0.22   // semi-profundidad

            var f0 = iso( gx, th,       -gz)
            var f1 = iso( gx, th,        gz)
            var f2 = iso(-gx, th,        gz)
            var c0 = iso( gx, th + gy*2, -gz)
            var c1 = iso( gx, th + gy*2,  gz)
            var c2 = iso(-gx, th + gy*2,  gz)
            var c3 = iso(-gx, th + gy*2, -gz)

            // Techo
            ctx.beginPath()
            ctx.moveTo(c0.x, c0.y); ctx.lineTo(c1.x, c1.y)
            ctx.lineTo(c2.x, c2.y); ctx.lineTo(c3.x, c3.y)
            ctx.closePath()
            ctx.fillStyle = "#555577"
            ctx.fill()

            // Cara lateral derecha
            ctx.beginPath()
            ctx.moveTo(f0.x, f0.y); ctx.lineTo(f1.x, f1.y)
            ctx.lineTo(c1.x, c1.y); ctx.lineTo(c0.x, c0.y)
            ctx.closePath()
            ctx.fillStyle = "#606088"
            ctx.fill()

            // Cara frontal izquierda
            ctx.beginPath()
            ctx.moveTo(f1.x, f1.y); ctx.lineTo(f2.x, f2.y)
            ctx.lineTo(c2.x, c2.y); ctx.lineTo(c1.x, c1.y)
            ctx.closePath()
            ctx.fillStyle = "#404060"
            ctx.fill()

            // Aristas
            ctx.strokeStyle = "#2a2a50"
            ctx.lineWidth   = 0.5
            ctx.beginPath()
            ctx.moveTo(c0.x, c0.y); ctx.lineTo(c1.x, c1.y)
            ctx.lineTo(c2.x, c2.y); ctx.lineTo(c3.x, c3.y); ctx.closePath()
            ctx.moveTo(f0.x, f0.y); ctx.lineTo(c0.x, c0.y)
            ctx.moveTo(f1.x, f1.y); ctx.lineTo(c1.x, c1.y)
            ctx.moveTo(f2.x, f2.y); ctx.lineTo(c2.x, c2.y)
            ctx.stroke()
        }

        // ═══════════════════════════════════════════════════════════
        //  ASPAS CON PROYECCIÓN ROTACIONAL ISOMÉTRICA
        //
        //  El eje de rotación del rotor es el eje X del mundo (viento).
        //  Una aspa a ángulo θ en el plano del rotor tiene:
        //    componente vertical (Y iso) = R * cos(θ)
        //    componente profundidad (Z iso) = R * sin(θ)
        //
        //  depthFactor = 1.0 - sin(θ)*0.35  →  aspa hacia cámara
        //  (sin(θ)<0): más gruesa y brillante; alejándose: más delgada
        //  y oscura. Es perspectiva falsa pero visualmente convincente.
        // ═══════════════════════════════════════════════════════════
        function drawBlades(ctx) {
            var th    = 5.94                           // altura del hub
            var R     = 2.9                            // longitud del aspa
            var baseA = root._angle * Math.PI / 180.0  // ángulo actual en radianes
            var bc    = bladeColor()
            var alpha = root.emergency ? 0.35 : 0.88

            for (var i = 0; i < 3; i++) {
                var theta = baseA + i * (2 * Math.PI / 3)

                var rx = Math.cos(theta)   // componente Y (vertical)
                var rz = Math.sin(theta)   // componente Z (profundidad)

                // Puntos clave del aspa
                var hubPt  = iso(0, th, 0)
                var rootPt = iso(0, th + 0.35 * rx, 0.35 * rz)
                var tipPt  = iso(0, th + R * rx,    R * rz)

                // Factor de profundidad para perspectiva falsa
                var depthFactor = 1.0 - rz * 0.35
                var lw = Math.max(0.8, depthFactor * 2.8)

                // Vector perpendicular para el grosor del perfil
                var dx  = tipPt.x - rootPt.x
                var dy  = tipPt.y - rootPt.y
                var len = Math.sqrt(dx*dx + dy*dy) || 1
                var nx  =  dy / len * lw
                var ny  = -dx / len * lw

                ctx.save()
                ctx.globalAlpha = alpha * Math.max(0.5, depthFactor)

                // Perfil aerodinámico como polígono
                ctx.beginPath()
                ctx.moveTo(hubPt.x,              hubPt.y)
                ctx.lineTo(rootPt.x + nx * 1.1,  rootPt.y + ny * 1.1)
                ctx.lineTo(tipPt.x  + nx * 0.15, tipPt.y  + ny * 0.15)
                ctx.lineTo(tipPt.x  - nx * 0.15, tipPt.y  - ny * 0.15)
                ctx.lineTo(rootPt.x - nx * 1.1,  rootPt.y - ny * 1.1)
                ctx.closePath()

                // Gradiente raíz → punta
                var grad = ctx.createLinearGradient(hubPt.x, hubPt.y, tipPt.x, tipPt.y)
                grad.addColorStop(0, bc)
                grad.addColorStop(1, "rgba(100,140,160,0.5)")
                ctx.fillStyle   = grad
                ctx.strokeStyle = "#00000033"
                ctx.lineWidth   = 0.4
                ctx.fill()
                ctx.stroke()

                ctx.restore()
            }
        }

        // ── Hub central ────────────────────────────────────────────
        function drawHub(ctx) {
            var th  = 5.94
            var hub = iso(0, th, 0)

            // Buje exterior
            ctx.beginPath()
            ctx.arc(hub.x, hub.y, 5, 0, Math.PI * 2)
            ctx.fillStyle = "#1e1e2f"
            ctx.fill()

            // Indicador LED de estado (igual que original)
            ctx.beginPath()
            ctx.arc(hub.x, hub.y, 2.5, 0, Math.PI * 2)
            ctx.fillStyle = hubColor()
            ctx.fill()
        }

        // ── Etiqueta RPM (idéntica al original) ───────────────────
        function drawRpmLabel(ctx) {
            ctx.fillStyle = root.emergency || root.status === "Parada"
                            ? "#ff4444" : "#aaaacc"
            ctx.font      = "bold 8px sans-serif"
            ctx.textAlign = "center"
            var label = root.emergency || root.status === "Parada"
                        ? "0 RPM (Frenado)"
                        : Math.round(root.rpm) + " RPM"
            ctx.fillText(label, width * 0.5, height * 0.97)
        }
    }
}
