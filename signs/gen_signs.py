#!/usr/bin/env python3
"""Taiwan street signboards as PNGs (Noto Sans CJK TC). Emissive textures for city.gd.
   python3 gen_signs.py   -> signs/v_NN.png (256x1024 vertical), signs/h_NN.png (1024x256 horizontal)"""
from PIL import Image, ImageDraw, ImageFont
import os
F = "/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc"
if not os.path.exists(F):
    import subprocess
    F = subprocess.check_output(["fc-match", "-f", "%{file}", "Noto Sans CJK TC:bold"]).decode()
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "out")
os.makedirs(OUT, exist_ok=True)
Y, R, W, B, G, K = (255, 214, 0), (214, 30, 30), (250, 250, 245), (20, 70, 180), (20, 140, 70), (25, 25, 25)
# (text, background, foreground)  -- vertical signs hang off the facade like the reference shot
V = [("燒啤酒", Y, K), ("生鮮食品", W, R), ("道地茶藝", G, W), ("黑膠唱片", K, Y), ("永和豆漿", W, B),
     ("鹹酥雞", R, W), ("牛肉麵", Y, R), ("藥局", W, G), ("當鋪", B, W), ("機車行", K, W),
     ("威強電 IEI", B, W), ("彩券", R, Y), ("按摩", Y, K), ("麵線", W, R), ("檳榔", G, Y), ("卡拉OK", K, R)]
H = [("GTO 生鮮超市", W, B), ("燒 啤 酒", Y, K), ("i.MX95 SMARC", K, W), ("24H 便利商店", G, W),
     ("古典吉他 樂器行", W, K), ("GC7000UL 車行", R, W), ("道地茶藝 茶", G, Y), ("台灣夜市", K, Y)]
def draw(text, bg, fg, size, vertical, name):
    im = Image.new("RGB", size, bg)
    d = ImageDraw.Draw(im)
    pad = 28
    d.rectangle([pad // 2, pad // 2, size[0] - pad // 2, size[1] - pad // 2], outline=fg, width=6)
    if vertical:
        n = len(text)
        fs = min(int((size[1] - 2 * pad) / n * 0.86), size[0] - 2 * pad)
        f = ImageFont.truetype(F, fs)
        step = (size[1] - 2 * pad) / n
        for i, ch in enumerate(text):
            bb = d.textbbox((0, 0), ch, font=f)
            x = (size[0] - (bb[2] - bb[0])) / 2 - bb[0]
            y = pad + i * step + (step - (bb[3] - bb[1])) / 2 - bb[1]
            d.text((x, y), ch, font=f, fill=fg)
    else:
        fs = size[1] - 2 * pad
        f = ImageFont.truetype(F, fs)
        while d.textbbox((0, 0), text, font=f)[2] > size[0] - 2 * pad:
            fs -= 4; f = ImageFont.truetype(F, fs)
        bb = d.textbbox((0, 0), text, font=f)
        d.text(((size[0] - (bb[2] - bb[0])) / 2 - bb[0], (size[1] - (bb[3] - bb[1])) / 2 - bb[1]), text, font=f, fill=fg)
    im.save(os.path.join(OUT, name), optimize=True)
for i, (t, bg, fg) in enumerate(V): draw(t, bg, fg, (256, 1024), True, "v_%02d.png" % i)
for i, (t, bg, fg) in enumerate(H): draw(t, bg, fg, (1024, 256), False, "h_%02d.png" % i)
print("signs:", len(V), "vertical,", len(H), "horizontal, font", F)
