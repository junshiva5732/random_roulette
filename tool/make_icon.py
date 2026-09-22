"""앱 아이콘 생성 스크립트. 실행: python tool/make_icon.py
assets/icon/icon.png (1024x1024, 배경 포함) 과
assets/icon/icon_fg.png (Android adaptive 전경, 투명 배경) 을 만든다."""
import math
import os

from PIL import Image, ImageDraw, ImageFilter

SIZE = 1024
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "icon")
os.makedirs(OUT, exist_ok=True)

# 배경: 앱 시드색(#7B3FE4) 계열 보라 그라데이션. 룰렛 조각은 클래식 테마 8색.
TOP = (150, 92, 240)
BOTTOM = (86, 38, 170)
SLICES = [(229, 57, 53), (30, 136, 229), (253, 216, 53), (67, 160, 71),
          (251, 140, 0), (142, 36, 170), (0, 172, 193), (216, 27, 96)]
RIM = (255, 255, 255)
HUB = (255, 255, 255)
HUB_DOT = (123, 63, 228)
POINTER = (40, 24, 70)


def gradient_bg(size):
    img = Image.new("RGB", (size, size))
    px = img.load()
    for y in range(size):
        t = y / (size - 1)
        for x in range(size):
            k = t * 0.7 + (x / (size - 1)) * 0.3
            px[x, y] = tuple(int(TOP[i] + (BOTTOM[i] - TOP[i]) * k) for i in range(3))
    return img


def draw_symbol(layer, scale=1.0):
    """가운데 룰렛 판 + 위쪽 포인터. layer 는 RGBA. 4배 크기로 그려서 축소(안티앨리어싱)."""
    ss = 4
    big = Image.new("RGBA", (SIZE * ss, SIZE * ss), (0, 0, 0, 0))
    d = ImageDraw.Draw(big)
    s = SIZE * ss * scale
    cx = cy = SIZE * ss / 2
    # 룰렛이 약간 아래로: 포인터 자리를 위에 남긴다
    cy += s * 0.03
    r = s * 0.34

    # 그림자
    sh = Image.new("RGBA", big.size, (0, 0, 0, 0))
    ImageDraw.Draw(sh).ellipse([cx - r - s * 0.02, cy - r + s * 0.02, cx + r + s * 0.02, cy + r + s * 0.06],
                               fill=(20, 0, 60, 130))
    sh = sh.filter(ImageFilter.GaussianBlur(s * 0.025))
    big.alpha_composite(sh)

    # 림
    rim = s * 0.03
    d.ellipse([cx - r - rim, cy - r - rim, cx + r + rim, cy + r + rim], fill=RIM + (255,))
    # 조각 (12시부터 시계 방향). PIL 은 3시 = 0°, 시계 방향 증가.
    n = len(SLICES)
    sweep = 360 / n
    for i, col in enumerate(SLICES):
        a0 = -90 + i * sweep
        d.pieslice([cx - r, cy - r, cx + r, cy + r], a0, a0 + sweep, fill=col + (255,))
    # 조각 사이 흰 선
    for i in range(n):
        a = math.radians(-90 + i * sweep)
        d.line([cx, cy, cx + r * math.cos(a), cy + r * math.sin(a)], fill=(255, 255, 255, 200), width=int(s * 0.008))
    # 허브
    hr = r * 0.2
    d.ellipse([cx - hr - s * 0.008, cy - hr - s * 0.008, cx + hr + s * 0.008, cy + hr + s * 0.008], fill=RIM + (255,))
    d.ellipse([cx - hr, cy - hr, cx + hr, cy + hr], fill=HUB + (255,))
    dr = r * 0.07
    d.ellipse([cx - dr, cy - dr, cx + dr, cy + dr], fill=HUB_DOT + (255,))

    # 포인터: 12시 위에서 아래를 향하는 물방울
    pw = s * 0.09
    ph = s * 0.13
    top = cy - r - rim - ph * 0.55
    tip = (cx, cy - r + ph * 0.25)
    pr = pw / 2
    pc = (cx, top + pr)
    pointer = Image.new("RGBA", big.size, (0, 0, 0, 0))
    pd = ImageDraw.Draw(pointer)
    pd.ellipse([pc[0] - pr, pc[1] - pr, pc[0] + pr, pc[1] + pr], fill=POINTER + (255,))
    pd.polygon([(pc[0] - pr * 0.98, pc[1] + pr * 0.2), (pc[0] + pr * 0.98, pc[1] + pr * 0.2), tip], fill=POINTER + (255,))
    pd.ellipse([pc[0] - pr * 0.38, pc[1] - pr * 0.38, pc[0] + pr * 0.38, pc[1] + pr * 0.38], fill=(255, 255, 255, 255))
    psh = pointer.filter(ImageFilter.GaussianBlur(s * 0.012))
    psh_dark = Image.new("RGBA", big.size, (0, 0, 0, 0))
    psh_dark.paste((0, 0, 0, 120), (0, int(s * 0.01)), psh)
    big.alpha_composite(psh_dark)
    big.alpha_composite(pointer)

    layer.alpha_composite(big.resize((SIZE, SIZE), Image.LANCZOS))


# 1) 풀 아이콘 (iOS / 스토어용, 불투명)
bg = gradient_bg(SIZE).convert("RGBA")
sym = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
draw_symbol(sym)
bg.alpha_composite(sym)
bg.convert("RGB").save(os.path.join(OUT, "icon.png"))

# 2) Adaptive 전경 (Android): 배경 없이 룰렛만. flutter_launcher_icons 가 16% 인셋을 넣는다.
fg = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
draw_symbol(fg, scale=1.15)
fg.save(os.path.join(OUT, "icon_fg.png"))

print("written:", os.path.abspath(OUT))
