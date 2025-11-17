#!/bin/bash
# Complete DeepFilterNet installation for openSUSE Tumbleweed
# Real-time microphone noise suppression

set -e

echo "=== Installing DeepFilterNet for openSUSE Tumbleweed ==="
echo ""

# 1. Install system dependencies
echo "[1/7] Installing system dependencies..."
sudo zypper install -y rust cargo git pipewire pipewire-tools pipewire-pulseaudio alsa-devel

# 2. Clone repository
echo "[2/7] Cloning DeepFilterNet..."
cd ~
if [ -d "DeepFilterNet" ]; then
    echo "Repository already exists, updating..."
    cd DeepFilterNet
    git pull
else
    git clone https://github.com/Rikorose/DeepFilterNet.git
    cd DeepFilterNet
fi

# 3. Build LADSPA plugin
echo "[3/7] Building LADSPA plugin (this will take 5-10 minutes)..."
cd ~/DeepFilterNet/ladspa
cargo build --release

# 4. Install plugin
echo "[4/7] Installing LADSPA plugin..."
mkdir -p ~/.ladspa
cp ../target/release/libdeep_filter_ladspa.so ~/.ladspa/

# 5. Create PipeWire configuration
echo "[5/7] Creating PipeWire configuration..."
mkdir -p ~/.config/pipewire/pipewire.conf.d/
cat > ~/.config/pipewire/pipewire.conf.d/99-deepfilter.conf << 'EOF'
context.modules = [
  {   name = libpipewire-module-filter-chain
      args = {
          node.description = "DeepFilter Noise Cancelling"
          media.name       = "DeepFilter Noise Cancelling"
          filter.graph = {
              nodes = [
                  {
                      type   = ladspa
                      name   = deep_filter
                      plugin = "$HOME/.ladspa/libdeep_filter_ladspa.so"
                      label  = deep_filter_mono
                      control = {
                          "Attenuation Limit (dB)" = 100
                      }
                  }
              ]
          }
          audio.rate = 48000
          audio.channels = 1
          audio.position = [ MONO ]
          capture.props = {
              node.name      = "effect_input.deep_filter"
              media.class    = Audio/Sink
              audio.rate     = 48000
              audio.channels = 1
              stream.capture.sink = true
              node.passive   = true
          }
          playback.props = {
              node.name      = "effect_output.deep_filter"
              media.class    = Audio/Source
              audio.rate     = 48000
              audio.channels = 1
          }
      }
  }
]
EOF

# Replace $HOME with actual path
sed -i "s|\$HOME|$HOME|g" ~/.config/pipewire/pipewire.conf.d/99-deepfilter.conf

# 6. Restart PipeWire
echo "[6/7] Restarting PipeWire..."
systemctl --user restart pipewire pipewire-pulse wireplumber
sleep 3

# 7. Loopback setup (you need to specify YOUR microphone)
echo "[7/7] Setting up loopback..."
echo ""
echo "Available microphones:"
pactl list sources short | grep -i "input"
echo ""
echo "ATTENTION: Edit the following command to specify YOUR microphone!"
echo ""
echo "Example command for USB microphone:"
echo 'pactl load-module module-loopback source=alsa_input.usb-C-Media_Electronics_Inc._USB_Advanced_Audio_Device-00.analog-stereo sink=effect_input.deep_filter latency_msec=20'
echo ""
echo "Example command for built-in microphone:"
echo 'pactl load-module module-loopback source=alsa_input.pci-0000_36_00.6.analog-stereo sink=effect_input.deep_filter latency_msec=20'
echo ""
read -p "Enter your microphone name (e.g., alsa_input.usb-...): " MIC_NAME

if [ ! -z "$MIC_NAME" ]; then
    pactl load-module module-loopback source=$MIC_NAME sink=effect_input.deep_filter latency_msec=20
    pactl set-default-source effect_output.deep_filter
    echo ""
    echo "✓ Loopback configured!"
fi

# 8. Autostart setup
echo ""
read -p "Set up autostart on system boot? (y/n): " AUTOSTART

if [ "$AUTOSTART" = "y" ]; then
    mkdir -p ~/.config/pulse
    cat > ~/.config/pulse/default.pa << EOF
# DeepFilter loopback - autostart
.include /etc/pulse/default.pa
load-module module-loopback source=$MIC_NAME sink=effect_input.deep_filter latency_msec=20
set-default-source effect_output.deep_filter
EOF
    echo "✓ Autostart configured!"
fi

echo ""
echo "=== Installation completed! ==="
echo ""
echo "Status check:"
pactl list sources short | grep -E "deep|effect"
echo ""
echo "Recording test:"
echo "  parecord -d effect_output.deep_filter test.wav"
echo "  (speak for 5 seconds + enable noise, then Ctrl+C)"
echo "  aplay test.wav"
echo ""
echo "In soft select microphone: 'DeepFilter Noise Cancelling'"
echo ""
echo "Optional - install GUI for configuration:"
echo "  sudo zypper install qpwgraph"
echo "  qpwgraph"
echo ""
