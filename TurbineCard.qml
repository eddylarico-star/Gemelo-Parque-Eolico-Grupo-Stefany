import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

// ============================================================
//  TurbineCard.qml — Tarjeta de aerogenerador
//  Estética Frutiger Aero: vidrio, esquinas redondeadas,
//  borde luminoso, hover 3D.
//  Incluye Popup de detalle con mini-mapa cartesiano.
// ============================================================
Rectangle {
    id: root

    // --- Propiedades de datos ---
    property string turbineName:     "Turbina 01"
    property real   windSpeed:       0.0
    property real   powerOutput:     0.0
    property real   powerFisicaW:    0.0     // Potencia física real en Watts
    property real   rpm:             0.0
    property string status:          "Óptimo"
    property bool   emergency:       false
    property bool   selected:        false
    property int    turbineId:       1
    property string tipoFallo:       ""
    property bool   enMantenimiento: false
    property real   salud:           100.0
    property string fechaRevision:   ""
    property int    horasServicio:   0
    property real   posX:            50.0
    property real   posY:            50.0
    property real   temperatura:     25.0

    signal cardClicked(int id)

    // --- Colores según estado ---
    readonly property color _accentColor: {
        if (emergency || tipoFallo !== "")  return "#ff4444"
        if (enMantenimiento)                return "#ff9900"
        if (status === "Parada")            return "#ff4444"
        if (status === "Advertencia")       return "#ffcc00"
        if (selected)                       return "#00aaff"
        return "#44cc88"
    }
    readonly property string _estadoLabel: {
        if (emergency || tipoFallo !== "")  return "⚠ " + (tipoFallo !== "" ? tipoFallo.toUpperCase() : "EMERGENCIA")
        if (enMantenimiento)                return "🔧 MANTENIMIENTO"
        if (status === "Parada")            return "◼ DETENIDA"
        if (status === "Advertencia")       return "⚡ ADVERTENCIA"
        return "● ÓPTIMO"
    }

    // Animación de parpadeo en emergencia
    SequentialAnimation on opacity {
        running: (emergency || tipoFallo !== "") && !enMantenimiento
        loops:   Animation.Infinite
        NumberAnimation { to: 0.6; duration: 400 }
        NumberAnimation { to: 1.0; duration: 400 }
        onRunningChanged: if (!running) root.opacity = 1.0
    }

    // --- Geometría ---
    width:  238
    height: 218
    radius: 15

    // Fondo Aero Glass
    gradient: Gradient {
        orientation: Gradient.Vertical
        GradientStop { position: 0.0; color: selected ? "#ddf2ff" : (cardHover.containsMouse ? "#e8f6ff" : "#eef8ff") }
        GradientStop { position: 0.5; color: selected ? "#bbdff8" : "#d8eef8" }
        GradientStop { position: 1.0; color: selected ? "#99ccea" : "#c4e0f0" }
    }
    border.color: _accentColor
    border.width: selected ? 2.5 : 1.5

    // Glow externo en selección/alerta
    layer.enabled: selected || emergency || tipoFallo !== ""

    // Brillo superior (highlight de cristal)
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 3
        width:  parent.width * 0.6
        height: 16; radius: 8
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: "#bbffffff" }
            GradientStop { position: 1.0; color: "#00ffffff" }
        }
    }

    // Efecto de hover (volumen 3D)
    scale: cardHover.containsMouse ? 1.04 : 1.0
    z:     cardHover.containsMouse ? 1 : 0
    Behavior on scale { NumberAnimation { duration: 150 } }
    Behavior on border.color { ColorAnimation { duration: 200 } }

    MouseArea {
        id: cardHover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape:  Qt.PointingHandCursor
        onClicked: {
            root.cardClicked(root.turbineId)
            detailPopup.open()
        }
    }

    ColumnLayout {
        anchors { fill: parent; margins: 12 }
        spacing: 5

        // Fila: nombre + badge de estado
        RowLayout {
            Text {
                text:  root.turbineName.toUpperCase()
                color: root.selected ? "#003366" : "#1a4a6a"
                font.pixelSize: 10; font.bold: true; font.letterSpacing: 0.4
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            Rectangle {
                width:  statusBadge.implicitWidth + 14; height: 18; radius: 9
                color:  Qt.rgba(root._accentColor.r, root._accentColor.g, root._accentColor.b, 0.18)
                border.color: root._accentColor; border.width: 1
                Text {
                    id: statusBadge
                    anchors.centerIn: parent
                    text:  root._estadoLabel
                    color: root._accentColor
                    font.pixelSize: 8; font.bold: true
                }
            }
        }

        // Barra de salud
        RowLayout {
            spacing: 4
            Text { text: "SALUD"; color: "#5588aa"; font.pixelSize: 8 }
            Rectangle {
                Layout.fillWidth: true; height: 5; radius: 3
                color: "#cce0ee"
                Rectangle {
                    width:  parent.width * (root.salud / 100.0)
                    height: parent.height; radius: 3
                    color: root.salud > 60 ? "#44cc88" : root.salud > 30 ? "#ffcc00" : "#ff4444"
                    Behavior on width { NumberAnimation { duration: 400 } }
                }
            }
            Text { text: root.salud.toFixed(0) + "%"; color: "#3a6a9a"; font.pixelSize: 8; font.bold: true }
        }

        // Aerogenerador visual (WindTurbine)
        WindTurbine {
            Layout.alignment: Qt.AlignHCenter
            width: 96; height: 88
            rpm:       root.rpm
            status:    root.status
            emergency: root.emergency || root.tipoFallo !== ""
        }

        // Datos numéricos: VIENTO / POTENCIA / RPM
        RowLayout {
            spacing: 5; Layout.fillWidth: true

            Repeater {
                model: [
                    { label: "VIENTO",   value: root.windSpeed.toFixed(1) + "\nkm/h",    color: "#0088cc" },
                    { label: "POTENCIA", value: (root.emergency ? "0.00" : root.powerOutput.toFixed(2)) + "\nMW", color: "#e8840a" },
                    { label: "RPM",      value: (root.emergency ? "0.0" : root.rpm.toFixed(1)),                   color: "#3aaa66" }
                ]
                delegate: Rectangle {
                    Layout.fillWidth: true; height: 42; radius: 8
                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop { position: 0.0; color: "#ddeeff" }
                        GradientStop { position: 1.0; color: "#bbddf0" }
                    }
                    border.color: "#aaccee"; border.width: 1
                    Column {
                        anchors.centerIn: parent; spacing: 1
                        Text { text: modelData.label; color: "#5588aa"; font.pixelSize: 7; anchors.horizontalCenter: parent.horizontalCenter }
                        Text { text: modelData.value; color: modelData.color; font.pixelSize: 11; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter; horizontalAlignment: Text.AlignHCenter }
                    }
                }
            }
        }

        // Física real: muestra Potencia en kW (fórmula P=0.5*rho*A*v³*Cp)
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "⚡ P física = " + (root.powerFisicaW / 1000.0).toFixed(1) + " kW  (ρ·A·v³·Cp)"
            color: "#1a5a8a"; font.pixelSize: 8
            font.italic: true
        }
    }

    // ============================================================
    //  POPUP DE DETALLE (Aero Glass flotante)
    // ============================================================
    Popup {
        id: detailPopup
        modal: true
        focus: true
        width: 420; height: 380
        // Centrado sobre la ventana completa mediante el overlay de Qt Quick Controls 2
        parent: Overlay.overlay
        x: Overlay.overlay ? Math.round((Overlay.overlay.width  - width)  / 2) : 50
        y: Overlay.overlay ? Math.round((Overlay.overlay.height - height) / 2) : 50
        padding: 0

        // Fondo Aero Glass del popup
        background: Rectangle {
            radius: 18
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: "#eef8ff" }
                GradientStop { position: 1.0; color: "#c8e8f8" }
            }
            border.color: "#88bbddff"; border.width: 2

            // Brillo superior
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 4; width: parent.width * 0.55; height: 18; radius: 9
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0; color: "#aaffffff" }
                    GradientStop { position: 1.0; color: "#00ffffff" }
                }
            }
        }

        contentItem: ColumnLayout {
            anchors { fill: parent; margins: 18 }
            spacing: 8

            // Título del popup
            RowLayout {
                Text {
                    text: "🔍  " + root.turbineName
                    color: "#1a3a6a"; font.pixelSize: 15; font.bold: true
                    Layout.fillWidth: true
                }
                Rectangle {
                    width: 26; height: 26; radius: 13
                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop { position: 0.0; color: "#88ccee" }
                        GradientStop { position: 1.0; color: "#4488aa" }
                    }
                    border.color: "#aaccee"; border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: "✕"; color: "white"; font.pixelSize: 11; font.bold: true
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: detailPopup.close()
                    }
                }
            }

            // Separador
            Rectangle { Layout.fillWidth: true; height: 1; color: "#aaccee" }

            RowLayout {
                Layout.fillWidth: true; spacing: 12

                // --- Datos técnicos e historial ---
                ColumnLayout {
                    spacing: 5; Layout.preferredWidth: 190

                    Text { text: "DATOS TÉCNICOS"; color: "#4488aa"; font.pixelSize: 9; font.bold: true; font.letterSpacing: 0.5 }

                    Repeater {
                        model: [
                            { label: "Estado actual",    value: root._estadoLabel },
                            { label: "Temperatura",      value: root.temperatura.toFixed(1) + " °C" },
                            { label: "Ángulo Pitch",     value: (root.powerOutput > 0 ? "0°" : "90°") + "  (auto)" },
                            { label: "Salud",            value: root.salud.toFixed(1) + "%" },
                            { label: "Potencia física",  value: (root.powerFisicaW / 1000.0).toFixed(2) + " kW" },
                            { label: "Horas servicio",   value: root.horasServicio.toString() + " h" },
                            { label: "Última revisión",  value: root.fechaRevision },
                            { label: "Posición X/Y",     value: "(" + root.posX.toFixed(0) + ", " + root.posY.toFixed(0) + ")" }
                        ]
                        delegate: RowLayout {
                            spacing: 4
                            Text { text: modelData.label + ":"; color: "#5588aa"; font.pixelSize: 9; Layout.preferredWidth: 95 }
                            Text { text: modelData.value;       color: "#1a3a6a"; font.pixelSize: 9; font.bold: true }
                        }
                    }

                    // Botones de mantenimiento
                    Rectangle { Layout.fillWidth: true; height: 1; color: "#aaccee"; Layout.topMargin: 4 }
                    Text { text: "CONTROL"; color: "#4488aa"; font.pixelSize: 9; font.bold: true }
                    RowLayout {
                        spacing: 6
                        // Botón "Mantenimiento"
                        Rectangle {
                            width: 86; height: 28; radius: 14
                            gradient: Gradient {
                                orientation: Gradient.Vertical
                                GradientStop { position: 0.0; color: "#ffdd88" }
                                GradientStop { position: 1.0; color: "#cc8800" }
                            }
                            border.color: "#ffbb44"; border.width: 1
                            Text { anchors.centerIn: parent; text: "🔧 Mantto."; color: "white"; font.pixelSize: 9; font.bold: true }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: { parqueEolicoModel.activarMantenimiento(root.turbineId); detailPopup.close() }
                            }
                        }
                        // Botón "Completar"
                        Rectangle {
                            width: 86; height: 28; radius: 14
                            gradient: Gradient {
                                orientation: Gradient.Vertical
                                GradientStop { position: 0.0; color: "#88ddaa" }
                                GradientStop { position: 1.0; color: "#228855" }
                            }
                            border.color: "#44bb77"; border.width: 1
                            Text { anchors.centerIn: parent; text: "✅ Listo"; color: "white"; font.pixelSize: 9; font.bold: true }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: { parqueEolicoModel.completarMantenimiento(root.turbineId); detailPopup.close() }
                            }
                        }
                    }
                }

                // --- Mini-Mapa cartesiano ---
                ColumnLayout {
                    spacing: 4; Layout.preferredWidth: 165

                    Text { text: "MINI-MAPA DEL PARQUE"; color: "#4488aa"; font.pixelSize: 9; font.bold: true; font.letterSpacing: 0.5 }

                    Rectangle {
                        width: 158; height: 158; radius: 8
                        gradient: Gradient {
                            orientation: Gradient.Vertical
                            GradientStop { position: 0.0; color: "#e8f8ee" }
                            GradientStop { position: 1.0; color: "#c8e8d8" }
                        }
                        border.color: "#88bbaa"; border.width: 1
                        clip: true

                        // Líneas de cuadrícula
                        Repeater {
                            model: 5
                            delegate: Rectangle {
                                x: (index + 1) * (158 / 6); y: 0; width: 1; height: 158
                                color: "#88aabbcc"; opacity: 0.5
                            }
                        }
                        Repeater {
                            model: 5
                            delegate: Rectangle {
                                x: 0; y: (index + 1) * (158 / 6); width: 158; height: 1
                                color: "#88aabbcc"; opacity: 0.5
                            }
                        }

                        // Etiquetas de ejes
                        Text { x: 2;   y: 2;   text: "N"; color: "#5588aa"; font.pixelSize: 7 }
                        Text { x: 148; y: 2;   text: "E"; color: "#5588aa"; font.pixelSize: 7 }
                        Text { x: 2;   y: 148; text: "S"; color: "#5588aa"; font.pixelSize: 7 }

                        // Todas las turbinas en el mapa
                        Repeater {
                            model: parqueEolicoModel
                            delegate: Rectangle {
                                property real mx: model.posX * 1.42  // escalar 0-100 → 0-142
                                property real my: model.posY * 1.42
                                x: mx - 5; y: my - 5
                                width: 10; height: 10; radius: 5
                                color: model.tid === root.turbineId
                                       ? "#ff5500"
                                       : (model.st === "Óptimo" ? "#22cc66" : "#ffcc00")
                                border.color: "white"; border.width: 1
                                // Etiqueta
                                Text {
                                    anchors { bottom: parent.top; horizontalCenter: parent.horizontalCenter }
                                    text: "T" + model.tid
                                    color: model.tid === root.turbineId ? "#ff5500" : "#336655"
                                    font.pixelSize: 7; font.bold: true
                                }
                            }
                        }
                    }

                    Text {
                        text: "● Esta turbina  ○ Otras"
                        color: "#5588aa"; font.pixelSize: 8
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
        }
    }
}
