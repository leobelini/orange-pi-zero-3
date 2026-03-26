#!/usr/bin/env bash

set -e

echo "🚀 Atualizando sistema..."
sudo apt update && sudo apt upgrade -y

echo "📦 Instalando pacotes básicos..."
sudo apt install -y --no-install-recommends \
    xorg \
    xinit \
    retroarch \
    alsa-utils \
    unzip \
    curl \
    linux-cpupower || true

echo "⚡ Configurando CPU em modo performance..."

# tenta via cpupower
sudo cpupower frequency-set -g performance 2>/dev/null || true

# fallback universal (funciona sempre)
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null || true

# garantir no boot via rc.local
if [ ! -f /etc/rc.local ]; then
sudo bash -c 'cat > /etc/rc.local <<EOF
#!/bin/bash
exit 0
EOF'
sudo chmod +x /etc/rc.local
fi

# adiciona antes do exit 0
sudo sed -i '/^exit 0/i echo performance > /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor' /etc/rc.local

echo "🧹 Desativando serviços desnecessários..."
sudo systemctl disable bluetooth 2>/dev/null || true
sudo systemctl disable avahi-daemon 2>/dev/null || true
sudo systemctl disable triggerhappy 2>/dev/null || true
sudo systemctl disable ModemManager 2>/dev/null || true

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

sudo bash -c "cat > /etc/systemd/system/getty@tty1.service.d/override.conf <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $USER --noclear %I \$TERM
EOF"

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
amixer set Master unmute 2>/dev/null || true
amixer set Master 100% 2>/dev/null || true

echo "🧪 Testando driver gráfico..."
# tenta kmsdrm automaticamente se existir
if ls /dev/dri >/dev/null 2>&1; then
    sed -i 's/video_driver = .*/video_driver = "kmsdrm"/' ~/.config/retroarch/retroarch.cfg
else
    sed -i 's/video_driver = .*/video_driver = "fbdev"/' ~/.config/retroarch/retroarch.cfg
fi

echo "✅ Instalação concluída!"
echo "👉 Reinicie com: sudo reboot"
