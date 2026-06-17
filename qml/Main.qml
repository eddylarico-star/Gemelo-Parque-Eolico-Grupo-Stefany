import QtQuick //rectangulos, textos, imagenes
import QtQuick.Controls

Window {
    width:   1100
    height:  700
    visible: true
    title:   "Gemelo Digital — Parque Eólico Norte"
    color:   "#d4eaf7"   // Frutiger Aero: fondo celeste claro base

    StackView {
        id: mainStack
        anchors.fill: parent
        initialItem: "MainMenu.qml"
    }
}
