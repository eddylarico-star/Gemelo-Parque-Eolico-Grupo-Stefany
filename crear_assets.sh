#!/usr/bin/env bash
# =============================================================
#  crear_assets.sh — Genera archivos de audio de marcador de
#  posición para el proyecto Gemelo Digital de Parque Eólico.
#
#  INSTRUCCIONES DE USO:
#  1. Ejecuta este script UNA VEZ desde la raíz del proyecto:
#       chmod +x crear_assets.sh
#       ./crear_assets.sh
#  2. Para usar audio real, reemplaza los archivos generados en
#       assets/audio/
#     con tus propios archivos WAV/MP3 de los mismos nombres:
#       alerta.wav   — sonido de alerta (0.5–2 s, pitido corto)
#       soleado.mp3  — ambiente día soleado (loop, 30–60 s)
#       tormenta.mp3 — ambiente tormenta (loop, 30–60 s)
#       click.wav    — click de botón (< 0.2 s)
#
#  NOTA: Los archivos vacíos permiten que el proyecto compile.
#  El audio simplemente no sonará hasta reemplazar con archivos reales.
# =============================================================

AUDIO_DIR="assets/audio"

echo "=== Creando directorio de assets de audio... ==="
mkdir -p "$AUDIO_DIR"

ARCHIVOS=("alerta.wav" "soleado.mp3" "tormenta.mp3" "click.wav")

# Intentar con ffmpeg si está disponible
if command -v ffmpeg &>/dev/null; then
    echo "ffmpeg detectado — generando tonos de marcador de posición..."

    # alerta.wav — tono de alerta (880 Hz, 0.5 s)
    ffmpeg -y -f lavfi \
        -i "sine=frequency=880:duration=0.5" \
        -ar 44100 -ac 1 \
        "$AUDIO_DIR/alerta.wav" 2>/dev/null \
        && echo "  ✔ alerta.wav" || echo "  ✘ alerta.wav (se usará archivo vacío)"

    # click.wav — click corto (1200 Hz, 0.05 s)
    ffmpeg -y -f lavfi \
        -i "sine=frequency=1200:duration=0.05" \
        -ar 44100 -ac 1 \
        "$AUDIO_DIR/click.wav" 2>/dev/null \
        && echo "  ✔ click.wav" || echo "  ✘ click.wav (se usará archivo vacío)"

    # soleado.mp3 — silencio de 5 s como marcador de posición
    ffmpeg -y -f lavfi \
        -i "aevalsrc=0:d=5" \
        -ar 44100 -ac 2 \
        "$AUDIO_DIR/soleado.mp3" 2>/dev/null \
        && echo "  ✔ soleado.mp3" || echo "  ✘ soleado.mp3 (se usará archivo vacío)"

    # tormenta.mp3 — ruido blanco suave de 5 s como marcador
    ffmpeg -y -f lavfi \
        -i "aevalsrc=0.02*random(0):d=5" \
        -ar 44100 -ac 2 \
        "$AUDIO_DIR/tormenta.mp3" 2>/dev/null \
        && echo "  ✔ tormenta.mp3" || echo "  ✘ tormenta.mp3 (se usará archivo vacío)"

else
    echo "ffmpeg NO encontrado — creando archivos vacíos de marcador..."
    for f in "${ARCHIVOS[@]}"; do
        if [ ! -f "$AUDIO_DIR/$f" ]; then
            touch "$AUDIO_DIR/$f"
            echo "  ✔ $AUDIO_DIR/$f (vacío)"
        else
            echo "  — $AUDIO_DIR/$f ya existe, no se sobreescribe"
        fi
    done
    echo ""
    echo "AVISO: Para instalar ffmpeg y generar tonos reales:"
    echo "  Ubuntu/Debian : sudo apt install ffmpeg"
    echo "  macOS (brew)  : brew install ffmpeg"
    echo "  Windows       : https://ffmpeg.org/download.html"
fi

echo ""
echo "=== Assets listos en: $AUDIO_DIR ==="
echo ""
echo "Para reemplazar con audio real, copia tus archivos aquí:"
for f in "${ARCHIVOS[@]}"; do
    echo "  $AUDIO_DIR/$f"
done
echo ""
echo "Luego re-compila el proyecto:"
echo "  cmake -B build && cmake --build build"
