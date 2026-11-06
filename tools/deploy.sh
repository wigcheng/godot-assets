#!/bin/sh
# Copy a Godot project folder to the board (symlinks into godot-assets are expanded with tar -h).
# usage: tools/deploy.sh <project-dir> [board-ip]   -> /home/yocto/godot/<basename>/
set -e
P=${1:?project dir}; IP=${2:-10.20.70.143}; N=$(basename "$P")
tar chf - -C "$(dirname "$P")" --exclude='*.avi' --exclude='*.mp4' --exclude='*.png.import' --exclude='*/upstream' --exclude='*/out' --exclude='*/.git' "$N" | \
  sshpass -p 1234 ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=ERROR yocto@$IP "cd /home/yocto/godot && tar xf - && du -sh $N"
