#!/usr/bin/env bash

set -e

echo "🚀 Atualizando sistema..."
sudo apt update && sudo apt upgrade -y

echo "📦 Instalando pacotes básicos..."
sudo apt install -y --no-install-recommends \
    xorg \
    xinit \
    retroarch \
    cpufrequtils \
    alsa-utils \
    unzip \
    curl

echo "⚡ Configurando CPU em modo performance..."
echo 'GOVERNOR="performance"' | sudo tee /etc/default/cpufrequtils
sudo systemctl disable ondemand || true
sudo systemctl enable cpufrequtils || true

echo "🧹 Desativando serviços desnecessários..."
sudo systemctl disable bluetooth || true
sudo systemctl disable avahi-daemon || true
sudo systemctl disable triggerhappy || true
sudo systemctl disable ModemManager || true

echo "🎮 Configurando RetroArch..."
mkdir -p ~/.config/retroarch

cat > ~/.config/retroarch/retroarch.cfg <<EOF
video_driver = "gl"
audio_driver = "alsa"
menu_driver = "ozone"
video_fullscreen = "true"
video_vsync = "true"
EOF

echo "🖥️ Configurando auto start do X..."
cat > ~/.xinitrc <<EOF
retroarch
EOF

echo "🔁 Configurando auto login no tty1..."
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d/

sudo bash -c 'cat > /etc/systemd/system/getty@tty1.service.d/override.conf <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin '$USER' --noclear %I \$TERM
EOF'

echo "⚙️ Configurando boot direto no RetroArch..."
if ! grep -q "startx" ~/.bashrc; then
cat >> ~/.bashrc <<'EOF'

# AUTO START X
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
  startx
fi
EOF
fi

echo "🔊 Configurando áudio..."
amixer set Master unmute || true
amixer set Master 100% || true

echo "✅ Instalação concluída!"
echo "🔁 Reinicie com: sudo reboot"
