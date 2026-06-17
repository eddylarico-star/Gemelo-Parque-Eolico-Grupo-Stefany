import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

//  MainMenu.qml — Pantalla de bienvenida
//  Estética: Frutiger Aero (gradientes cielo-verde, vidrio,
//  brillo, bordes luminosos, tipografía clara).
Item {
    id: root

    // Fondo degradado Aero: azul cielo → verde césped
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0;  color: "#b8ddf7" }   // azul cielo claro
            GradientStop { position: 0.45; color: "#7ec8e3" }   // azul medio
            GradientStop { position: 0.75; color: "#9dd685" }   // verde suave
            GradientStop { position: 1.0;  color: "#6abf5e" }   // verde césped
        }
    }

    // Destellos de luz difusa (efecto Aero)
    Rectangle {
        x: -80; y: -80
        width: 350; height: 350
        radius: 175
        color: "white"
        opacity: 0.18
    }
    Rectangle {
        anchors.right: parent.right; anchors.rightMargin: -60
        y: parent.height * 0.5
        width: 280; height: 280
        radius: 140
        color: "#00aaff"
        opacity: 0.10
    }

    // Panel central "Aero Glass"
    Rectangle {
        anchors.centerIn: parent
        width:  380
        height: 520
        radius: 22
        color:  "transparent"

        // Efecto cristal: fondo semitransparente blanco con borde brillante
        Rectangle {
            anchors.fill: parent
            radius: 22
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: "#ccffffff" }  // blanco 80% opaco arriba
                GradientStop { position: 1.0; color: "#88e8f4ff" }  // celeste translúcido abajo
            }
            border.color: "#aaffffff"
            border.width: 2
        }

        // Brillo superior (highlight de cristal)
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 2
            width:  parent.width * 0.65
            height: 30
            radius: 15
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: "#eeffffff" }
                GradientStop { position: 1.0; color: "#00ffffff" }
            }
        }

        ColumnLayout {
            anchors { fill: parent; margins: 36 }
            spacing: 0

            // Logo animado del aerogenerador
            Canvas {
                id: logoCanvas
                Layout.alignment: Qt.AlignHCenter
                width: 110
                height: 110
                Layout.bottomMargin: 8

                property real angle: 0

                NumberAnimation on angle {
                    from: 0; to: 360
                    duration: 3000
                    loops: Animation.Infinite
                    running: true
                }
                onAngleChanged: requestPaint()

                onPaint: {
                    var ctx = getContext("2d")
                    var cx = width / 2
                    var cy = height / 2 + 10
                    var bL = 38
                    ctx.clearRect(0, 0, width, height)

                    // Sombra suave del logo
                    ctx.shadowColor = "rgba(0,100,180,0.25)"
                    ctx.shadowBlur  = 12

                    // Torre (tronco)
                    ctx.beginPath()
                    ctx.moveTo(cx - 5, cy + 38)
                    ctx.lineTo(cx + 5, cy + 38)
                    ctx.lineTo(cx + 3, cy)
                    ctx.lineTo(cx - 3, cy)
                    ctx.closePath()
                    var towerGrad = ctx.createLinearGradient(cx - 5, 0, cx + 5, 0)
                    towerGrad.addColorStop(0, "#ffffff")
                    towerGrad.addColorStop(1, "#8bcce8")
                    ctx.fillStyle = towerGrad
                    ctx.fill()

                    // 3 aspas rotatorias
                    ctx.shadowBlur = 8
                    ctx.shadowColor = "rgba(0,160,255,0.4)"
                    for (var i = 0; i < 3; i++) {
                        var a = (i * (2 * Math.PI / 3)) + (angle * Math.PI / 180)
                        ctx.save()
                        ctx.translate(cx, cy)
                        ctx.rotate(a)
                        var grad = ctx.createLinearGradient(0, 0, 0, -bL)
                        grad.addColorStop(0, "rgba(0,180,255,0.9)")
                        grad.addColorStop(1, "rgba(255,255,255,0.6)")
                        ctx.beginPath()
                        ctx.moveTo(0, 0)
                        ctx.bezierCurveTo(6, -10, 4, -(bL * 0.7), 0, -bL)
                        ctx.bezierCurveTo(-4, -(bL * 0.7), -6, -10, 0, 0)
                        ctx.closePath()
                        ctx.fillStyle = grad
                        ctx.fill()
                        ctx.restore()
                    }

                    // Hub central
                    ctx.shadowBlur = 0
                    var hubGrad = ctx.createRadialGradient(cx - 2, cy - 2, 2, cx, cy, 9)
                    hubGrad.addColorStop(0, "#ffffff")
                    hubGrad.addColorStop(1, "#0088cc")
                    ctx.beginPath()
                    ctx.arc(cx, cy, 9, 0, Math.PI * 2)
                    ctx.fillStyle = hubGrad
                    ctx.fill()
                }
            }

            // Título principal
            Text {
                text: "Parque Eólico Norte"
                color: "#1a4a7a"
                font.pixelSize: 26
                font.bold: true
                font.letterSpacing: 0.5
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 4
                style: Text.Raised
                styleColor: "#99ffffff"
            }

            // Subtítulo
            Text {
                text: "Sistema de Monitoreo · Gemelo Digital"
                color: "#3a7aaa"
                font.pixelSize: 12
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 4
            }

            // Separador brillante
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 14
                Layout.bottomMargin: 14
                width: 200; height: 1
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.5; color: "#88aaccff" }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            // Infobadges Aero
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 12
                Layout.bottomMargin: 18

                Repeater {
                    model: [
                        { icon: "⚡", val: "5 Turbinas" },
                        { icon: "🌬", val: "En Vivo" },
                        { icon: "📊", val: "POO C++" }
                    ]
                    delegate: Rectangle {
                        width: 82; height: 40; radius: 10
                        gradient: Gradient {
                            orientation: Gradient.Vertical
                            GradientStop { position: 0.0; color: "#ddf0ff" }
                            GradientStop { position: 1.0; color: "#aad8f8" }
                        }
                        border.color: "#88bbddff"; border.width: 1
                        Column {
                            anchors.centerIn: parent
                            spacing: 0
                            Text { text: modelData.icon; font.pixelSize: 13; anchors.horizontalCenter: parent.horizontalCenter }
                            Text { text: modelData.val; color: "#1a4a7a"; font.pixelSize: 9; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
                        }
                    }
                }
            }

            // Botón principal "Aero 3D"
            Rectangle {
                id: btnDashboard
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 230
                Layout.preferredHeight: 50
                radius: 25
                // Gradiente 3D: claro arriba, azul vibrante abajo
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0;  color: btnArea.containsMouse ? "#88ddff" : "#55ccff" }
                    GradientStop { position: 0.45; color: btnArea.containsMouse ? "#0099ee" : "#0077cc" }
                    GradientStop { position: 1.0;  color: btnArea.containsMouse ? "#005599" : "#004488" }
                }
                border.color: "#aaeeff"; border.width: 2
                scale: btnArea.pressed ? 0.96 : (btnArea.containsMouse ? 1.04 : 1.0)
                Behavior on scale { NumberAnimation { duration: 120 } }

                // Brillo interno del botón
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 4
                    width:  parent.width * 0.6
                    height: 14
                    radius: 7
                    color:  "#55ffffff"
                }

                Text {
                    anchors.centerIn: parent
                    text: "▶  Ingresar al Dashboard"
                    color: "white"
                    font.pixelSize: 14
                    font.bold: true
                    style: Text.Raised
                    styleColor: "#44000033"
                }

                MouseArea {
                    id: btnArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.StackView.view.push("Dashboard.qml")
                }
            }

            // Créditos
            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 18
                text: "Programación II · Dr. Dennis Barrios · MEC2-1"
                color: "#4a7aaa"
                font.pixelSize: 10
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 2
                text: "Ingeniería Mecatrónica · UCSP"
                color: "#6a9aaa"
                font.pixelSize: 9
            }
        }
    }

    // Reloj digital tipo Gadget Windows Vista (esquina inferior derecha)
    Rectangle {
        anchors { bottom: parent.bottom; right: parent.right; margins: 16 }
        width: 150; height: 44; radius: 12
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: "#ccffffff" }
            GradientStop { position: 1.0; color: "#88aaccff" }
        }
        border.color: "#aaffffff"; border.width: 1

        Column {
            anchors.centerIn: parent
            spacing: 1
            Text {
                id: clockText
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: 18; font.bold: true
                color: "#1a3a6a"
                style: Text.Raised; styleColor: "#66ffffff"
            }
            Text {
                id: dateText
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: 9; color: "#3a6a9a"
            }
        }
        Timer {
            interval: 1000; running: true; repeat: true; triggeredOnStart: true
            onTriggered: {
                var d = new Date()
                clockText.text = d.toLocaleTimeString(Qt.locale(), "HH:mm:ss")
                dateText.text  = d.toLocaleDateString(Qt.locale(), "ddd, dd MMM yyyy")
            }
        }
    }
}
