#!/bin/sh
# Loop every film in the portfolio folder in name order: H.264 on the VPU, MP3 audio to PulseAudio (HDMI).
# Films must be H.264 + MP3. Do not switch the audio branch to decodebin: on this board it hung the whole system twice (2026-11-05).
D=/home/yocto/godot/portfolio
while true; do
	for F in "$D"/*.mp4; do
		[ -e "$F" ] || { sleep 5; continue; }
		gst-launch-1.0 -q filesrc location="$F" ! qtdemux name=d \
			d.video_0 ! queue ! h264parse ! vpudec ! waylandsink fullscreen=true \
			d.audio_0 ! queue ! mpegaudioparse ! mpg123audiodec ! audioconvert ! audioresample ! pulsesink
	done
done
