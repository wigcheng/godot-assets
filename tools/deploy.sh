#!/bin/sh
# Copy a Godot project folder to the board (symlinks into godot-assets are expanded with tar -h).
# usage: BOARD_IP=<ip> BOARD_PASS=<password> tools/deploy.sh <project-dir>   -> /home/yocto/godot/<basename>/
# (no password in the repo: export BOARD_PASS, or set up ssh keys and leave it empty)
set -e
P=${1:?project dir}; IP=${BOARD_IP:?set BOARD_IP}; N=$(basename "$P")
SSH="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=ERROR"
[ -n "$BOARD_PASS" ] && SSH="sshpass -p $BOARD_PASS $SSH"
tar chf - -C "$(dirname "$P")" --exclude='*.avi' --exclude='*.mp4' --exclude='*.png.import' --exclude='*/upstream' --exclude='*/out' --exclude='*/.git' "$N" | \
  $SSH yocto@$IP "cd /home/yocto/godot && tar xf - && du -sh $N"
