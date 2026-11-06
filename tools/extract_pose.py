#!/usr/bin/env python3
"""ref30.mp4 -> pose_raw.json: per frame 33 world landmarks [x,y,z,visibility] (MediaPipe PoseLandmarker heavy, VIDEO mode)."""
import json, sys, cv2, numpy as np
import mediapipe as mp
from mediapipe.tasks import python as mpp
from mediapipe.tasks.python import vision
src, model, out = sys.argv[1:4]
opts = vision.PoseLandmarkerOptions(base_options=mpp.BaseOptions(model_asset_path=model),
    running_mode=vision.RunningMode.VIDEO, num_poses=1, min_pose_detection_confidence=0.5,
    min_tracking_confidence=0.5, output_segmentation_masks=False)
cap = cv2.VideoCapture(src); fps = cap.get(cv2.CAP_PROP_FPS)
frames = []; i = 0
with vision.PoseLandmarker.create_from_options(opts) as lm:
    while True:
        ok, bgr = cap.read()
        if not ok: break
        img = mp.Image(image_format=mp.ImageFormat.SRGB, data=cv2.cvtColor(bgr, cv2.COLOR_BGR2RGB))
        res = lm.detect_for_video(img, int(i * 1000 / fps))
        if res.pose_world_landmarks:
            w = res.pose_world_landmarks[0]; n = res.pose_landmarks[0]
            frames.append([[p.x, p.y, p.z, q.visibility] for p, q in zip(w, n)])
        else:
            frames.append(None)
        i += 1
        if i % 100 == 0: print("frame", i, flush=True)
json.dump({"fps": fps, "frames": frames}, open(out, "w"))
print("done", i, "frames,", sum(f is None for f in frames), "without pose")
