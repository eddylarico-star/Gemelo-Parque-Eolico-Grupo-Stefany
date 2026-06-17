import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia

// ============================================================
//  Dashboard.qml — Panel principal del Gemelo Digital
//  ✅ Fix navegación: onClicked usa StackView.view.pop()
//  ✅ Estética Frutiger Aero completa
//  ✅ Botones Añadir/Quitar turbina dinámica
//  ✅ Gráfico de barras en tiempo real (ecualizador glossy)
//  ✅ Control de clima con ComboBox
//  ✅ Reloj/fecha tipo Gadget Vista
//  ✅ Notificación de fallos con banner
//  ✅ [TAREA 1] Audio Qt6 Multimedia: alerta, ambiental, click
// ============================================================
Item {
    id: dashRoot

    // --- Propiedades principales ---
    property int  selectedId:  1
    readonly property bool  globalEmergency: parqueEolicoModel.emergenciaGlobal
    readonly property real  totalPower:      parqueEolicoModel.potenciaTotal

    // Historial de potencia para el gráfico (últimos 20 valores)
    property var powerHistory: [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]

    // Mensaje de fallo activo para el banner
    property string mensajeFallo: ""
    property bool   bannerVisible: false

    // Estado mute del audio ambiental
    property bool audioMuted: false

    function selectedIndex() { return dashRoot.selectedId - 1 }

    onSelectedIdChanged: windSlider.value = parqueEolicoModel.velocidadDe(dashRoot.selectedIndex())

    // ============================================================
    //  TAREA 1 — AUDIO Qt6 Multimedia
    // ============================================================

    // 1a) Sonido de alerta (se activa con onFalloDetectado)
    MediaPlayer {
        id: playerAlerta
        source: "qrc:/ParteSantiago/assets/audio/alerta.wav"
        audioOutput: AudioOutput { volume: 0.8 }
    }

    // 1b) Audio ambiental en loop (cambia según el clima)
    MediaPlayer {
        id: playerAmbiental
        source: "qrc:/ParteSantiago/assets/audio/soleado.mp3"
        loops: MediaPlayer.Infinite
        audioOutput: AudioOutput {
            id: ambientalOutput
            volume: dashRoot.audioMuted ? 0.0 : 0.12
            Behavior on volume { NumberAnimation { duration: 300 } }
        }
        Component.onCompleted: playerAmbiental.play()
    }

    // 1c) Click de botón (reproducción instantánea)
    MediaPlayer {
        id: playerClick
        source: "qrc:/ParteSantiago/assets/audio/click.wav"
        audioOutput: AudioOutput { volume: 0.6 }
    }

    function playClick() {
        playerClick.stop()
        playerClick.play()
    }

    // Conexión a señales del backend C++
    Connections {
        target: parqueEolicoModel

        // Alerta sonora + banner visual al detectar fallo
        function onFalloDetectado(turbinaId, tipo) {
            dashRoot.mensajeFallo = "⚡  FALLO DETECTADO — Turbina " + turbinaId + ": " + tipo
            dashRoot.bannerVisible = true
            bannerTimer.restart()
            // Reproducir sonido de alerta
            playerAlerta.stop()
            playerAlerta.play()
        }

        // Cambio de clima → cambiar fuente del audio ambiental
        function onClimaCambiado() {
            var clima = parqueEolicoModel.climaActual
            playerAmbiental.stop()
            if (clima === "Tormenta de Verano") {
                playerAmbiental.source = "qrc:/ParteSantiago/assets/audio/tormenta.mp3"
                ambientalOutput.volume = dashRoot.audioMuted ? 0.0 : 0.12
            } else if (clima === "Calma Total") {
                playerAmbiental.source = "qrc:/ParteSantiago/assets/audio/soleado.mp3"
                ambientalOutput.volume = dashRoot.audioMuted ? 0.0 : 0.05
            } else {
                // Día Soleado
                playerAmbiental.source = "qrc:/ParteSantiago/assets/audio/soleado.mp3"
                ambientalOutput.volume = dashRoot.audioMuted ? 0.0 : 0.12
            }
            if (!dashRoot.audioMuted)
                playerAmbiental.play()
        }
    }

    // Actualizar historial de potencia cada segundo
    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: {
            var hist = dashRoot.powerHistory.slice(1)
            hist.push(dashRoot.totalPower)
            dashRoot.powerHistory = hist
        }
    }

    // Timer para ocultar el banner de fallo
    Timer {
        id: bannerTimer
        interval: 5000
        onTriggered: dashRoot.bannerVisible = false
    }

    // ============================================================
    //  FONDO AERO (cambia según el clima)
    // ============================================================
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop {
                position: 0.0
                color: {
                    if (parqueEolicoModel.climaActual === "Tormenta de Verano") return "#556688"
                    if (parqueEolicoModel.climaActual === "Calma Total")        return "#ddeeff"
                    return "#b8ddf7"  // Día soleado
                }
                Behavior on color { ColorAnimation { duration: 800 } }
            }
            GradientStop {
                position: 1.0
                color: {
                    if (parqueEolicoModel.climaActual === "Tormenta de Verano") return "#334455"
                    if (parqueEolicoModel.climaActual === "Calma Total")        return "#eef6ff"
                    return "#9dd685"
                }
                Behavior on color { ColorAnimation { duration: 800 } }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ========================================================
        //  HEADER — Título + navegación + reloj + clima
        // ========================================================
        Rectangle {
            Layout.fillWidth: true
            height: 58
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: "#eef8ff" }
                GradientStop { position: 1.0; color: "#c8e2f8" }
            }
            border.color: "#88bbddff"; border.width: 0
            // Línea inferior brillante
            Rectangle { anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right; height: 1; color: "#aaccee" }

            RowLayout {
                anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
                spacing: 10

                // ── Botón "Volver al Menú" (FIX CRÍTICO) ──────────
                Rectangle {
                    width: 140; height: 34; radius: 17
                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop { position: 0.0; color: backHover.containsMouse ? "#ddeeff" : "#cce4f8" }
                        GradientStop { position: 1.0; color: backHover.containsMouse ? "#88bbdd" : "#7aaec8" }
                    }
                    border.color: "#aaccee"; border.width: 1.5
                    scale: backHover.pressed ? 0.95 : 1.0
                    Behavior on scale { NumberAnimation { duration: 100 } }
                    Text {
                        anchors.centerIn: parent
                        text: "◀  Volver al Menú"
                        color: "#1a3a6a"; font.pixelSize: 11; font.bold: true
                    }
                    MouseArea {
                        id: backHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        // ✅ FIX CRÍTICO: pop() navega de vuelta a MainMenu.qml
                        onClicked: {
                            dashRoot.playClick()
                            dashRoot.StackView.view.pop()
                        }
                    }
                }

                Column {
                    spacing: 1
                    Text { text: "GEMELO DIGITAL — PARQUE EÓLICO NORTE"; color: "#1a3a6a"; font.pixelSize: 12; font.bold: true; font.letterSpacing: 0.4 }
                    Text {
                        // TAREA 3b: contadorTurbinas (Q_PROPERTY reactiva) en lugar de rowCount()
                        text: "Monitoreo Industrial · " + parqueEolicoModel.contadorTurbinas + " Unidades en Red"
                        color: "#4488aa"; font.pixelSize: 9
                    }
                }

                Item { Layout.fillWidth: true }

                // ── ComboBox de clima + Botón Mute (TAREA 1) ──────
                RowLayout {
                    spacing: 6
                    Text { text: "☁"; font.pixelSize: 16; color: "#2266aa" }
                    ComboBox {
                        id: climaCombo
                        model: ["Día Soleado", "Tormenta de Verano", "Calma Total"]
                        width: 145
                        onActivated: {
                            dashRoot.playClick()
                            parqueEolicoModel.cambiarClima(currentText)
                        }
                        contentItem: Text {
                            leftPadding: 10
                            text: climaCombo.displayText
                            color: "#1a3a6a"; font.pixelSize: 11
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            radius: 10
                            gradient: Gradient {
                                orientation: Gradient.Vertical
                                GradientStop { position: 0.0; color: "#ddeeff" }
                                GradientStop { position: 1.0; color: "#aaccee" }
                            }
                            border.color: "#88bbcc"; border.width: 1
                        }
                    }

                    // TAREA 1 — Botón Mute audio ambiental
                    Rectangle {
                        width: 70; height: 28; radius: 14
                        gradient: Gradient {
                            orientation: Gradient.Vertical
                            GradientStop {
                                position: 0.0
                                color: dashRoot.audioMuted ? "#ffeecc" : "#ddeeff"
                            }
                            GradientStop {
                                position: 1.0
                                color: dashRoot.audioMuted ? "#cc8800" : "#88bbcc"
                            }
                        }
                        border.color: dashRoot.audioMuted ? "#ffaa44" : "#88bbcc"; border.width: 1.5
                        scale: muteHover.pressed ? 0.95 : (muteHover.containsMouse ? 1.04 : 1.0)
                        Behavior on scale { NumberAnimation { duration: 100 } }
                        Text {
                            anchors.centerIn: parent
                            text: dashRoot.audioMuted ? "🔇 Mute" : "🔊 On"
                            color: dashRoot.audioMuted ? "#883300" : "#1a3a6a"
                            font.pixelSize: 10; font.bold: true
                        }
                        MouseArea {
                            id: muteHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                dashRoot.audioMuted = !dashRoot.audioMuted
                                if (dashRoot.audioMuted) {
                                    playerAmbiental.pause()
                                } else {
                                    playerAmbiental.play()
                                }
                            }
                        }
                    }
                }

                // Badge SIMULACIÓN EN VIVO
                Rectangle {
                    width: 130; height: 26; radius: 13
                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop { position: 0.0; color: "#ddfff4" }
                        GradientStop { position: 1.0; color: "#aaeedd" }
                    }
                    border.color: "#44cc88"; border.width: 1
                    Row {
                        anchors.centerIn: parent; spacing: 5
                        Rectangle {
                            width: 7; height: 7; radius: 4; color: "#22cc66"
                            anchors.verticalCenter: parent.verticalCenter
                            SequentialAnimation on opacity {
                                loops: Animation.Infinite
                                NumberAnimation { to: 0.3; duration: 700 }
                                NumberAnimation { to: 1.0; duration: 700 }
                            }
                        }
                        Text { text: "SIMULACIÓN EN VIVO"; color: "#1a8855"; font.pixelSize: 9; font.bold: true }
                    }
                }

                // Reloj digital
                Rectangle {
                    width: 118; height: 38; radius: 10
                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop { position: 0.0; color: "#ddeeff" }
                        GradientStop { position: 1.0; color: "#aaccee" }
                    }
                    border.color: "#88bbcc"; border.width: 1
                    Column {
                        anchors.centerIn: parent; spacing: 0
                        Text { id: hdrClock; font.pixelSize: 14; font.bold: true; color: "#1a3a6a"; anchors.horizontalCenter: parent.horizontalCenter }
                        Text { id: hdrDate;  font.pixelSize: 8; color: "#4488aa"; anchors.horizontalCenter: parent.horizontalCenter }
                    }
                    Timer {
                        interval: 1000; running: true; repeat: true; triggeredOnStart: true
                        onTriggered: {
                            var d = new Date()
                            hdrClock.text = d.toLocaleTimeString(Qt.locale(), "HH:mm:ss")
                            hdrDate.text  = d.toLocaleDateString(Qt.locale(), "dd/MM/yyyy")
                        }
                    }
                }
            }
        }

        // ========================================================
        //  BARRA DE ESTADÍSTICAS GLOBALES (Aero)
        // ========================================================
        Rectangle {
            Layout.fillWidth: true
            height: 56
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: "#e0f0ff" }
                GradientStop { position: 1.0; color: "#c8e4f8" }
            }

            RowLayout {
                anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
                spacing: 0

                Repeater {
                    model: [
                        { label: "POTENCIA TOTAL",  value: dashRoot.totalPower.toFixed(2) + " MW",                    color: "#0066cc" },
                        { label: "UNIDADES EN RED", value: parqueEolicoModel.contadorTurbinas + " Nodos",             color: "#cc6600" },
                        { label: "PROMEDIO/TURBINA",value: (parqueEolicoModel.potenciaPromedio).toFixed(2) + " MW",   color: "#006633" },
                        { label: "ESTADO GLOBAL",   value: dashRoot.globalEmergency ? "⚠ EMERGENCIA" : "● NORMAL",  color: dashRoot.globalEmergency ? "#cc0000" : "#006633" }
                    ]
                    delegate: Item {
                        Layout.fillWidth: true
                        height: 56
                        // Separador entre stats
                        Rectangle {
                            width: 1; height: 30; color: "#aaccee"
                            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                            visible: index < 3
                        }
                        Column {
                            anchors.centerIn: parent; spacing: 3
                            Text { text: modelData.label; color: "#5588aa"; font.pixelSize: 8; font.letterSpacing: 0.3; anchors.horizontalCenter: parent.horizontalCenter }
                            Text {
                                text: modelData.value; color: modelData.color
                                font.pixelSize: 16; font.bold: true
                                anchors.horizontalCenter: parent.horizontalCenter
                                Behavior on text {}
                            }
                        }
                    }
                }
            }
        }

        // ========================================================
        //  BANNER DE FALLO (aparece y desaparece)
        // ========================================================
        Rectangle {
            Layout.fillWidth: true
            height: dashRoot.bannerVisible ? 36 : 0
            clip: true
            Behavior on height { NumberAnimation { duration: 300 } }
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "#ffeecc" }
                GradientStop { position: 0.5; color: "#ffddaa" }
                GradientStop { position: 1.0; color: "#ffeecc" }
            }
            border.color: "#ffaa44"; border.width: 1
            Text {
                anchors.centerIn: parent
                text: dashRoot.mensajeFallo
                color: "#883300"; font.pixelSize: 12; font.bold: true
            }
        }

        // ========================================================
        //  ÁREA PRINCIPAL: Grid de turbinas + gráfico
        // ========================================================
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // Grid de tarjetas de turbinas
            GridView {
                id: turbineGrid
                Layout.fillWidth:    true
                Layout.fillHeight:   true
                Layout.minimumWidth: 260   // mínimo una columna de tarjeta + margen
                Layout.margins: 12
                cellWidth:  248
                cellHeight: 228
                clip: true
                model: parqueEolicoModel

                delegate: TurbineCard {
                    width:         240
                    height:        220
                    turbineName:   model.tname
                    windSpeed:     model.wind
                    powerOutput:   model.power
                    powerFisicaW:  model.powerFisica
                    rpm:           model.rpm
                    status:        model.st
                    emergency:     dashRoot.globalEmergency
                    selected:      model.tid === dashRoot.selectedId
                    turbineId:     model.tid
                    tipoFallo:     model.tipoFallo
                    enMantenimiento: model.enMantenimiento
                    salud:         model.salud
                    fechaRevision: model.fechaRevision
                    horasServicio: model.horasServicio
                    posX:          model.posX
                    posY:          model.posY
                    temperatura:   model.temperatura
                    onCardClicked: (id) => { dashRoot.selectedId = id }
                }
            }

            // ── Panel derecho: Gráfico + Registro de eventos ──
            ColumnLayout {
                Layout.preferredWidth: 240
                Layout.minimumWidth:   240
                Layout.maximumWidth:   240
                Layout.fillHeight: true
                Layout.margins: 12
                spacing: 10

                // Gráfico de barras en tiempo real (ecualizador glossy)
                Rectangle {
                    Layout.fillWidth: true
                    height: 160; radius: 14
                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop { position: 0.0; color: "#eef8ff" }
                        GradientStop { position: 1.0; color: "#c8e0f8" }
                    }
                    border.color: "#88bbcc"; border.width: 1

                    Column {
                        anchors { top: parent.top; left: parent.left; right: parent.right; topMargin: 8; leftMargin: 8; rightMargin: 8 }
                        spacing: 4
                        Text { text: "📈 POTENCIA TOTAL EN TIEMPO REAL"; color: "#1a4a7a"; font.pixelSize: 9; font.bold: true }

                        // Barras del ecualizador
                        Row {
                            spacing: 3
                            anchors.horizontalCenter: parent.horizontalCenter

                            Repeater {
                                model: dashRoot.powerHistory
                                delegate: Rectangle {
                                    property real maxPow: 25.0
                                    property real ratio:  Math.min(modelData / maxPow, 1.0)
                                    width: 8
                                    height: 100
                                    color: "#ddeeee"
                                    radius: 4
                                    Rectangle {
                                        anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
                                        width:  parent.width
                                        height: Math.max(3, parent.height * ratio)
                                        radius: 4
                                        gradient: Gradient {
                                            orientation: Gradient.Vertical
                                            GradientStop { position: 0.0; color: ratio > 0.8 ? "#ff6644" : ratio > 0.5 ? "#ffcc00" : "#44aaff" }
                                            GradientStop { position: 0.6; color: ratio > 0.8 ? "#cc2200" : ratio > 0.5 ? "#cc8800" : "#0066cc" }
                                            GradientStop { position: 1.0; color: ratio > 0.8 ? "#881100" : ratio > 0.5 ? "#885500" : "#003388" }
                                        }
                                        Behavior on height { NumberAnimation { duration: 400 } }
                                    }
                                }
                            }
                        }
                        // Escala
                        RowLayout {
                            width: parent.width
                            Text { text: "0"; color: "#5588aa"; font.pixelSize: 8 }
                            Item { Layout.fillWidth: true }
                            Text { text: dashRoot.totalPower.toFixed(2) + " MW"; color: "#0066cc"; font.pixelSize: 8; font.bold: true }
                            Item { Layout.fillWidth: true }
                            Text { text: "25 MW"; color: "#5588aa"; font.pixelSize: 8 }
                        }
                    }
                }

                // Log de eventos
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true; radius: 14
                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop { position: 0.0; color: "#eef8ff" }
                        GradientStop { position: 1.0; color: "#c8e0f8" }
                    }
                    border.color: "#88bbcc"; border.width: 1
                    clip: true

                    ColumnLayout {
                        anchors { fill: parent; margins: 10 }
                        spacing: 6
                        Text { text: "📋 REGISTRO DE EVENTOS"; color: "#1a4a7a"; font.pixelSize: 9; font.bold: true }
                        Rectangle { Layout.fillWidth: true; height: 1; color: "#aaccee" }
                        ListView {
                            id: eventList
                            Layout.fillWidth: true; Layout.fillHeight: true
                            model: parqueEolicoModel.registroEventos
                            clip: true
                            // Auto-scroll al último
                            onCountChanged: if (count > 0) positionViewAtEnd()
                            delegate: Text {
                                width: eventList.width
                                text:  modelData
                                color: modelData.includes("FALLO") || modelData.includes("⚡") ? "#cc4400" :
                                       modelData.includes("✅") ? "#006633" : "#2a5a8a"
                                font.pixelSize: 8; wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                bottomPadding: 2
                            }
                        }
                    }
                }
            }
        }

        // ========================================================
        //  FOOTER — Controles avanzados
        // ========================================================
        Rectangle {
            Layout.fillWidth: true
            height: 100
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: "#d8ecf8" }
                GradientStop { position: 1.0; color: "#c0d8f0" }
            }
            // Línea superior
            Rectangle { anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; height: 1; color: "#aaccee" }

            RowLayout {
                anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
                spacing: 16

                // ── Output neto ───────────────────────────
                Column {
                    spacing: 2
                    Text { text: "OUTPUT NETO"; color: "#5588aa"; font.pixelSize: 8; font.letterSpacing: 0.3 }
                    Row {
                        spacing: 4
                        Text {
                            text: dashRoot.totalPower.toFixed(2)
                            color: "#0055cc"; font.pixelSize: 28; font.bold: true
                            Behavior on text {}
                        }
                        Text { text: "MW"; color: "#7799aa"; font.pixelSize: 12; anchors.bottom: parent.bottom; anchors.bottomMargin: 5 }
                    }
                }

                // ── Slider de viento de turbina seleccionada ─
                Column {
                    spacing: 4; Layout.preferredWidth: 220
                    Text { text: "CONTROL VIENTO · TURBINA 0" + dashRoot.selectedId; color: "#1a4a7a"; font.pixelSize: 9; font.bold: true }
                    RowLayout {
                        spacing: 4
                        Text { text: "0"; color: "#7799aa"; font.pixelSize: 9 }
                        Slider {
                            id: windSlider
                            from: 0; to: 100
                            Layout.preferredWidth: 150
                            Connections {
                                target: parqueEolicoModel
                                function onDataChanged() {
                                    if (!windSlider.pressed)
                                        windSlider.value = parqueEolicoModel.velocidadDe(dashRoot.selectedIndex())
                                }
                            }
                            Component.onCompleted: value = parqueEolicoModel.velocidadDe(dashRoot.selectedIndex())
                            onMoved: parqueEolicoModel.actualizarVelocidad(dashRoot.selectedIndex(), windSlider.value)
                        }
                        Text { text: "100 km/h"; color: "#7799aa"; font.pixelSize: 9 }
                    }
                    RowLayout {
                        spacing: 6
                        // Botón Parada
                        Rectangle {
                            width: 100; height: 28; radius: 14
                            gradient: Gradient {
                                orientation: Gradient.Vertical
                                GradientStop { position: 0.0; color: "#ffcccc" }
                                GradientStop { position: 1.0; color: "#cc4444" }
                            }
                            border.color: "#ff8888"; border.width: 1
                            Text { anchors.centerIn: parent; text: "🛑 Parada (T0" + dashRoot.selectedId + ")"; color: "white"; font.pixelSize: 9; font.bold: true }
                            scale: stopHover.containsMouse ? 1.05 : 1.0
                            Behavior on scale { NumberAnimation { duration: 100 } }
                            MouseArea {
                                id: stopHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    dashRoot.playClick()
                                    parqueEolicoModel.slotParadaCritica(dashRoot.selectedId)
                                }
                            }
                        }
                        // Botón Reanudar
                        Rectangle {
                            width: 90; height: 28; radius: 14
                            gradient: Gradient {
                                orientation: Gradient.Vertical
                                GradientStop { position: 0.0; color: "#ccffdd" }
                                GradientStop { position: 1.0; color: "#44aa66" }
                            }
                            border.color: "#66cc88"; border.width: 1
                            Text { anchors.centerIn: parent; text: "▶ Reanudar"; color: "white"; font.pixelSize: 9; font.bold: true }
                            scale: resumeHover.containsMouse ? 1.05 : 1.0
                            Behavior on scale { NumberAnimation { duration: 100 } }
                            MouseArea {
                                id: resumeHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    dashRoot.playClick()
                                    parqueEolicoModel.reanudarTurbina(dashRoot.selectedId)
                                }
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // ── Botones dinámicos: Añadir / Quitar turbina ─
                Column {
                    spacing: 6
                    Text { text: "GESTIÓN DINÁMICA"; color: "#1a4a7a"; font.pixelSize: 9; font.bold: true }
                    Row {
                        spacing: 8
                        // Botón AÑADIR turbina
                        Rectangle {
                            width: 130; height: 34; radius: 17
                            gradient: Gradient {
                                orientation: Gradient.Vertical
                                GradientStop { position: 0.0; color: addHover.containsMouse ? "#aaeeff" : "#88ccff" }
                                GradientStop { position: 1.0; color: addHover.containsMouse ? "#0077cc" : "#0055aa" }
                            }
                            border.color: "#44aaff"; border.width: 1.5
                            scale: addHover.pressed ? 0.95 : (addHover.containsMouse ? 1.04 : 1.0)
                            Behavior on scale { NumberAnimation { duration: 110 } }
                            Text { anchors.centerIn: parent; text: "＋ Añadir Turbina"; color: "white"; font.pixelSize: 11; font.bold: true }
                            MouseArea {
                                id: addHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    dashRoot.playClick()
                                    parqueEolicoModel.agregarTurbina()
                                }
                            }
                        }
                        // Botón QUITAR turbina seleccionada
                        Rectangle {
                            width: 130; height: 34; radius: 17
                            gradient: Gradient {
                                orientation: Gradient.Vertical
                                GradientStop { position: 0.0; color: removeHover.containsMouse ? "#ffddaa" : "#ffcc88" }
                                GradientStop { position: 1.0; color: removeHover.containsMouse ? "#cc6600" : "#aa5500" }
                            }
                            border.color: "#ffaa44"; border.width: 1.5
                            scale: removeHover.pressed ? 0.95 : (removeHover.containsMouse ? 1.04 : 1.0)
                            Behavior on scale { NumberAnimation { duration: 110 } }
                            Text { anchors.centerIn: parent; text: "✕ Dar de Baja T0" + dashRoot.selectedId; color: "white"; font.pixelSize: 11; font.bold: true }
                            MouseArea {
                                id: removeHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    dashRoot.playClick()
                                    parqueEolicoModel.eliminarTurbina(dashRoot.selectedId)
                                    // Seleccionar la turbina 1 tras eliminar
                                    if (parqueEolicoModel.contadorTurbinas > 0)
                                        dashRoot.selectedId = 1
                                }
                            }
                        }
                    }
                }

                // ── Botón Emergencia Global ─────────────────
                Rectangle {
                    width: 140; height: 50; radius: 14
                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop {
                            position: 0.0
                            color: dashRoot.globalEmergency ? "#ffeecc" : "#ffcccc"
                        }
                        GradientStop {
                            position: 1.0
                            color: dashRoot.globalEmergency ? "#cc6600" : "#cc0000"
                        }
                    }
                    border.color: dashRoot.globalEmergency ? "#ffaa44" : "#ff6666"
                    border.width: 2

                    // Parpadeo cuando hay emergencia
                    SequentialAnimation on opacity {
                        running: dashRoot.globalEmergency
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.5; duration: 500 }
                        NumberAnimation { to: 1.0; duration: 500 }
                        onRunningChanged: if (!running) parent.opacity = 1.0
                    }

                    Column {
                        anchors.centerIn: parent; spacing: 2
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: dashRoot.globalEmergency ? "▶ REANUDAR" : "⚠ EMERGENCIA"
                            color: "white"; font.pixelSize: 12; font.bold: true
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: dashRoot.globalEmergency ? "Sistema detenido" : "Corte global"
                            color: "#ffddcc"; font.pixelSize: 8
                        }
                    }
                    scale: emergHover.containsMouse ? 1.04 : 1.0
                    Behavior on scale { NumberAnimation { duration: 120 } }
                    MouseArea {
                        id: emergHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            dashRoot.playClick()
                            parqueEolicoModel.emergenciaGlobal = !parqueEolicoModel.emergenciaGlobal
                        }
                    }
                }
            }
        }
    }
}
