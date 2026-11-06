#!/usr/bin/env python3
"""1024x1024 labelled UV test texture (TL/TR/BL/BR quadrants + grid). Put it on a mesh to see which UV set / orientation the GPU uses."""
from PIL import Image, ImageDraw, ImageFont
import sys
im = Image.new("RGB", (1024, 1024), (200, 200, 200)); d = ImageDraw.Draw(im)
for i, (x, y) in enumerate([(0, 0), (512, 0), (0, 512), (512, 512)]):
    d.rectangle([x, y, x + 511, y + 511], fill=[(230, 60, 60), (60, 180, 60), (60, 90, 230), (230, 200, 40)][i])
for v in range(0, 1024, 64):
    d.line([(v, 0), (v, 1023)], fill=(0, 0, 0), width=2); d.line([(0, v), (1023, v)], fill=(0, 0, 0), width=2)
f = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 120)
for t, (x, y) in zip(["TL", "TR", "BL", "BR"], [(150, 180), (660, 180), (150, 690), (660, 690)]): d.text((x, y), t, font=f, fill=(0, 0, 0))
im.save(sys.argv[1] if len(sys.argv) > 1 else "uvgrid.png")
