#!/bin/sh
# dream_vit stills at 5 / 15 / 20.5 s (same frames as the puppet versions); waits for any running probe
cd /home/yocto/godot
true
systemctl stop godot-shorts-video
rm -f dv-shots.done
for s in 5 15 20.5; do
  timeout 420 env GODOT_SILENCE_ROOT_WARNING=1 XDG_RUNTIME_DIR=/run/user/0 WAYLAND_DISPLAY=wayland-0 XDG_DATA_HOME=/home/yocto/godot/userdata XDG_CACHE_HOME=/home/yocto/godot/userdata ./Godot_v4.7.2-stable_linux.arm64 --path vit res://dream_vit.tscn --display-driver wayland --rendering-driver vulkan --resolution 1920x1080 -- --start=$s --secs=$(echo "$s + 0.6" | bc) --shot=/home/yocto/godot/dv-$s.png > dv-shot-$s.log 2>&1
  echo "shot $s rc=$?" >> dv-shots.done
done
systemctl start godot-shorts-video
echo ALLDONE >> dv-shots.done
