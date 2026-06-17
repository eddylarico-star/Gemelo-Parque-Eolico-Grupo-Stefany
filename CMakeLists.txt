cmake_minimum_required(VERSION 3.16)

project(ParteSantiago VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# TAREA 1 + 2: agregamos Qt6::Multimedia para audio
find_package(Qt6 REQUIRED COMPONENTS Quick Core Multimedia)

qt_standard_project_setup(REQUIRES 6.4)

qt_add_executable(appParteSantiago
    src/main.cpp
)

qt_add_qml_module(appParteSantiago
    URI ParteSantiago
    VERSION 1.0
    QML_FILES
        qml/Main.qml
        qml/MainMenu.qml
        qml/Dashboard.qml
        qml/TurbineCard.qml
        qml/WindTurbine.qml
    SOURCES
        src/turbina.h
        src/turbina.cpp
        src/parqueeolico.h
        src/parqueeolico.cpp
    RESOURCES
        assets/audio/alerta.wav
        assets/audio/soleado.mp3
        assets/audio/tormenta.mp3
        assets/audio/click.wav
)

set_target_properties(appParteSantiago PROPERTIES
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

# TAREA 1: enlazar Qt6::Multimedia
target_link_libraries(appParteSantiago
    PRIVATE Qt6::Quick Qt6::Core Qt6::Multimedia
)

install(TARGETS appParteSantiago
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
