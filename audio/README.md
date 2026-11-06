# Audio generators (numpy, copyright-free)
`python3 gen_dream_audio.py out.wav` (23.04 s, 128 BPM) · `python3 gen_city_audio.py out.wav` (20.04 s). Event times are computed from the
scene scripts' constants, never by ear. Board playback needs **MP3**: `-c:a libmp3lame -b:a 192k -ar 48000`; target −16 LUFS (`loudnorm`).
