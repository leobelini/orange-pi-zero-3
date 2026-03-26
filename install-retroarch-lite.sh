#!/usr/bin/env bash

set -e

echo "🚀 Atualizando sistema..."
sudo apt update && sudo apt upgrade -y

echo "🎮 Instalando RetroArch..."
sudo apt install -y retroarch alsa-utils

echo "⚡ Configurando CPU em performance..."
sudo apt install -y linux-cpupower || true
sudo cpupower frequency-set -g performance 2>/dev/null || true
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null || true

# persistir no boot
if [ ! -f /etc/rc.local ]; then
sudo bash -c 'cat > /etc/rc.local <<EOF
#!/bin/bash
exit 0
EOF'
sudo chmod +x /etc/rc.local
fi

sudo sed -i '/^exit 0/i echo performance > /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor' /etc/rc.local

echo "🧹 Removendo XFCE e desktop..."
sudo apt purge -y \
    xfce4* \
    lightdm \
    x11-common \
    xfwm4 \
    xfdesktop4 \
    xfce4-panel \
    thunar \
    xfce4-session || true

sudo apt autoremove -y --purge

echo "🧼 Limpando possíveis restos..."
sudo apt clean

echo "🎮 Configurando RetroArch..."
mkdir -p ~/.config/retroarch

cat > ~/.config/retroarch/retroarch.cfg <<EOF
video_driver = "kmsdrm"
audio_driver = "alsa"
video_fullscreen = "true"
video_vsync = "true"
menu_driver = "ozone"
EOF

echo "🔊 Configurando áudio..."
amixer set Master unmute 2>/dev/null || true
amixer set Master 100% 2>/dev/null || true

echo "🔁 Configurando auto login..."
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d/

sudo bash -c "cat > /etc/systemd/system/getty@tty1.service.d/override.conf <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $USER --noclear %I \$TERM
EOF"

echo "⚙️ Configurando boot direto no RetroArch..."

if ! grep -q "retroarch" ~/.bashrc; then
cat >> ~/.bashrc <<'EOF'

# AUTO START RETROARCH
if [ "$(tty)" = "/dev/tty1" ]; then
  retroarch
fi
EOF
fi

echo "🧪 Ajustando driver automaticamente..."

if ls /dev/dri >/dev/null 2>&1; then
    sed -i 's/video_driver = .*/video_driver = "kmsdrm"/' ~/.config/retroarch/retroarch.cfg
else
    sed -i 's/video_driver = .*/video_driver = "fbdev"/' ~/.config/retroarch/retroarch.cfg
fi

echo "🧹 Desativando serviços desnecessários..."
sudo systemctl disable bluetooth 2>/dev/null || true
sudo systemctl disable avahi-daemon 2>/dev/null || true
sudo systemctl disable lightdm 2>/dev/null || true

echo "✅ Tudo pronto!"
echo "👉 Reinicie com: sudo reboot"
