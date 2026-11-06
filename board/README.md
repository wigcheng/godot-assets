# Board side (B643 i.MX8MP, 10.20.70.143, user yocto)
- `play-loop.sh` + `godot-shorts-video.service`: loops `portfolio/*.mp4` (H.264 + MP3) through vpudec → waylandsink. **Never switch audio to decodebin** (hangs the board at boot).
- Stop the loop before any Godot run (`systemctl stop godot-shorts-video`), restart it after. Run Godot through `systemd-run --unit=…` so ssh drops do not kill it.
- Stills: `shots-example.sh` pattern (`--start=T --secs=T+0.6 --shot=PNG`, ≥ 0.5 s warm-up or the sky is black). Recording: `--fixed-fps 30 --write-movie x.avi`, verify frames = secs×30+1 with ffprobe; Godot may hang at exit → `systemctl stop` the unit, otherwise the next `systemd-run` fails with "already loaded".
- Publish: scp mp4, md5 both sides, test-play with the exact pipeline, `ln -sfn` into portfolio/, `sync`.
