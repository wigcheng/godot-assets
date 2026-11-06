# Motion capture data for VitChar.apply_dirs()

`mocap/<clip>/mocap.json` = `{"fps": 30, "frames": [{"yaw": rad, "legs_tracked": bool, "dirs": {joint: [x,y,z]}}]}`.
Directions are unit vectors in **character space** (X = character's left, Y up, Z toward the camera), already de-rotated by `yaw`;
apply `yaw` to the character root and the dirs to the bones. Joints: chest, head, lsh, lel, rsh, rel, lhip, lknee, rhip, rknee.

Make one from a video (host, needs `~/.venv/mocap` with mediapipe + opencv + numpy and `pose_landmarker_heavy.task`):
```sh
ffmpeg -i clip.mp4 -r 30 -an ref30.mp4
python3 tools/extract_pose.py ref30.mp4 pose_landmarker_heavy.task pose_raw.json
python3 tools/pose_to_mocap.py pose_raw.json mocap/<clip>/mocap.json
```
Limits: no limb roll (hands may face the wrong way), legs fall back to a standing pulse when out of frame, no root translation.
`dream-wings/`: 699 frames from the 23 s reference clip used by the dream-wings video (internal use only, see LICENSES.md).
