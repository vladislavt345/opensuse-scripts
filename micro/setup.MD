# 1. Create loopback micro -> DeepFilter
pactl load-module module-loopback \
  source=alsa_input.usb-C-Media_Electronics_Inc._USB_Advanced_Audio_Device-00.analog-stereo \
  sink=effect_input.deep_filter \
  latency_msec=20

# 2. Check loopback
pactl list modules short | grep loopback

# 3. Set default DeepFilter
pactl set-default-source effect_output.deep_filter

# 4. check list sound
pactl list sources short | grep -E "deep|USB"
