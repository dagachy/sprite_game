"""Sprite Fusion 갤러리 스타일(1px 어두운 외곽선, 3단 램프 음영, 치비 캐릭터, 발광 눈)을 참고한
v5 「새벽 레일: 환생 열차」 예상 화면. 에셋은 전부 이 스크립트에서 새로 그린다."""
import random, math
from PIL import Image, ImageDraw, ImageFont, ImageFilter

OUT = __import__('os').path.join(__import__('os').path.dirname(__import__('os').path.abspath(__file__)), '..', 'v2_sf_style') + '/'
LW, LH, S = 180, 320, 3
W, H = LW * S, LH * S
FONT = "/System/Library/Fonts/AppleSDGothicNeo.ttc"
OUTLINE = (22, 16, 30, 255)

def f(size, bold=True):
    return ImageFont.truetype(FONT, size, index=6 if bold else 0)

# ---------- 스프라이트 파이프라인: 키 그리드 -> 램프 음영 -> 외곽선 ----------
RAMP = {
    "h": ((28, 30, 56), (46, 52, 92), (78, 90, 140)),        # 머리(남색)
    "s": ((196, 128, 104), (236, 176, 140), (252, 214, 180)),  # 피부
    "e": ((30, 22, 40),) * 3,
    "m": ((170, 100, 90),) * 3,
    "c": ((30, 64, 120), (52, 104, 176), (104, 168, 228)),     # 승무원 코트
    "b": ((90, 56, 30), (140, 92, 48), (190, 140, 80)),
    "g": ((170, 120, 30), (230, 180, 60), (255, 236, 140)),    # 금
    "p": ((34, 34, 50), (54, 56, 76), (84, 88, 110)),
    "k": ((50, 34, 30), (80, 56, 44), (110, 80, 60)),
    "w": ((150, 160, 186), (210, 220, 240), (255, 255, 255)),  # 강철
    "d": ((14, 10, 28), (34, 26, 60), (66, 52, 108)),          # 그늘
    "y": ((200, 190, 255), (230, 224, 255), (255, 255, 255)),  # 그늘 눈
    "f": ((70, 34, 28), (108, 54, 40), (140, 78, 54)),         # 불꽃 계열 몸(저채도)
    "o": ((255, 150, 30), (255, 196, 60), (255, 240, 150)),    # 고채도 눈
    "r": ((70, 50, 50), (110, 84, 76), (150, 120, 104)),       # 뿔
    "t": ((78, 84, 104), (112, 120, 142), (150, 160, 182)),    # 석재
    "u": ((52, 56, 74),) * 3,                                  # 줄눈
    "x": ((96, 60, 34), (140, 90, 50), (180, 126, 72)),        # 목재
    "i": ((70, 74, 90), (110, 116, 134), (160, 166, 184)),     # 철
    "R": ((150, 30, 50), (220, 60, 80), (255, 130, 140)),      # 하트
    "L": ((220, 150, 40), (255, 210, 90), (255, 248, 190)),    # 등불 빛
}

def grid_from_rows(rows, w=None):
    w = w or max(len(r) for r in rows)
    out = []
    for r in rows:
        pad = (w - len(r)) // 2
        out.append(list("." * pad + r + "." * (w - len(r) - pad)))
    return out

def render(grid):
    h, w = len(grid), len(grid[0])
    im = Image.new("RGBA", (w + 2, h + 2), (0, 0, 0, 0))
    P = im.load()
    def k(x, y):
        return grid[y][x] if 0 <= x < w and 0 <= y < h else "."
    for y in range(h):
        for x in range(w):
            c = grid[y][x]
            if c == ".": continue
            dk, md, lt = RAMP[c]
            if k(x, y - 1) != c or k(x - 1, y) != c and k(x, y - 1) != c:
                col = lt
            elif k(x, y + 1) != c or k(x + 1, y) != c:
                col = dk
            else:
                col = md
            P[x + 1, y + 1] = col + (255,)
    # 외곽선
    base = im.copy(); B = base.load()
    for y in range(h + 2):
        for x in range(w + 2):
            if B[x, y][3]: continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                xx, yy = x + dx, y + dy
                if 0 <= xx < w + 2 and 0 <= yy < h + 2 and B[xx, yy][3] and B[xx, yy][:3] != OUTLINE[:3]:
                    P[x, y] = OUTLINE; break
    return im

# 주인공 여울(검사) 16x18
HERO = grid_from_rows([
    "hhhhhhhh", "hhhhhhhhhh", "hhhhhhhhhhhh", "hhsssssssshh", "hsseesseessh",
    "hssssssssssh", "hssssmmssssh", "ccccsscccc", "cccccccccccc", "scccggcccccs",
    "sccbbbbbbccs", "cccccccccc", "cccccccccc", "pppp..pppp", "pppp..pppp", "kkkk..kkkk",
], 16)
for y in range(2, 12): HERO[y][15] = "w"
HERO[12][15] = "g"; HERO[12][14] = "g"; HERO[13][15] = "b"
HERO_SP = render(HERO)

SHADOW_SP = render(grid_from_rows([
    "dddd", "dddddddd", "dddddddddd", "ddyyddyydd", "dddddddddd",
    "dddddddddddd", "dddddddddddd", "dd..dd..dd"], 12))
FLAME_SP = render(grid_from_rows([
    "r......r", "rr....rr", "rffffffr", "ffffffffff", "ffooffoof f".replace(" ", ""),
    "ffffffffff", "ffffmmffff", "ffffffff", "fff..fff"], 12))

def elite():
    g = [["."] * 22 for _ in range(22)]
    for y in range(22):
        for x in range(22):
            dx, dy = x - 11, y - 10
            d = math.hypot(dx, dy)
            if d < 7.5: g[y][x] = "f"
            if math.hypot(dx, dy + 1) < 3.6: g[y][x] = "y"
            if math.hypot(dx, dy + 1) < 1.8: g[y][x] = "o"
    for a in range(8):
        ang = a * math.pi / 4 + 0.3
        for t in range(8, 11):
            x, y = int(11 + math.cos(ang) * t), int(10 + math.sin(ang) * t + (t - 8))
            if 0 <= x < 22 and 0 <= y < 22: g[y][x] = "r"
    return render(g)
ELITE_SP = elite()

def pillar():
    rows = []
    for y in range(26):
        r = ""
        for x in range(14):
            if y in (6, 12, 18, 24) or (x == (4 if (y // 6) % 2 else 10) and y % 6 != 0): r += "u"
            else: r += "t"
        rows.append(r)
    g = grid_from_rows(rows, 14)
    return render(g)
PILLAR_SP = pillar()

CHEST_SP = render(grid_from_rows([
    "xxxxxxxxxxxx", "xxxxxxxxxxxxxx", "iiiiiiiiiiiiii", "xxxxxxxxxxxxxx", "xxxxxggxxxxxxx",
    "iiiiiggiiiiiii", "xxxxxxxxxxxxxx", "xxxxxxxxxxxxxx", "iiiiiiiiiiiiii"], 14))
GEM_SP = render(grid_from_rows(["yy", "yyyy", "yyyy", "yy"], 4))
LAMP_SP = render(grid_from_rows(["LL", "LLLL", "LLLL", "LL", "ii", "ii", "ii", "iiii"], 4))

ICON = {
    "sword": render(grid_from_rows(["......ww", ".....www", "....www.", "...www..", "g.www...", ".gww....", "..gg....", ".b.gg...", "b.......".rstrip(".")], 8)),
    "lamp": render(grid_from_rows(["ii", "iiii", "LLLL", "LLLLLL", "LLLLLL", "LLLL", "iiii", "ii"], 8)),
    "heart": render(grid_from_rows(["RR..RR", "RRRRRRRR", "RRRRRRRR", "RRRRRRRR", "RRRRRR", "RRRR", "RR"], 8)),
    "star": render(grid_from_rows(["g", "g", "g.ggg.g".replace(".", "g")[:0] + "ggg", "ggggggg", "ggggg", "gg.gg", "g...g"], 8)),
    "gem": render(grid_from_rows(["yy", "yyyy", "yyyyyy", "yyyyyyyy", "yyyyyy", "yyyy", "yy"], 8)),
    "relic": render(grid_from_rows(["g.gg.g", "gggggg", "gggg", "gggg", "gggg", "gggggg", "gggggggg"], 8)),
    "sun": render(grid_from_rows(["L..L..L", ".LLLLL.", "LLLLLLL", ".LLLLL.", "L..L..L"], 7)),
}

def paste(dst, sp, x, y):
    dst.alpha_composite(sp, (int(x), int(y)))

# ---------- 타일 ----------
def floor_tile(seed, hazard=False):
    rnd = random.Random(seed)
    t = Image.new("RGBA", (16, 16)); P = t.load()
    if hazard:
        base, hi, dk = (64, 30, 70), (96, 48, 104), (40, 18, 46)
    else:
        v = rnd.randint(-6, 6)
        base, hi, dk = (62 + v, 70 + v, 92 + v), (86 + v, 96 + v, 120 + v), (40, 45, 62)
    for y in range(16):
        for x in range(16):
            c = base
            if x == 0 or y == 0: c = hi
            if x == 15 or y == 15: c = dk
            P[x, y] = c + (255,)
    for _ in range(rnd.randint(2, 5)):
        x, y = rnd.randint(2, 13), rnd.randint(2, 13)
        P[x, y] = (dk if rnd.random() < .6 else hi) + (255,)
    if rnd.random() < 0.35 and not hazard:  # 균열
        x, y = rnd.randint(3, 10), rnd.randint(3, 10)
        for i in range(5):
            P[x + i, y + (i % 2)] = dk + (255,)
    if hazard:  # 빛나는 저주 균열
        x = rnd.randint(2, 12)
        for y in range(2, 14):
            x = max(1, min(14, x + rnd.choice((-1, 0, 1))))
            P[x, y] = (230, 90, 200, 255)
            if rnd.random() < .5: P[min(15, x + 1), y] = (160, 60, 150, 255)
    return t

def wall_tile(y_idx):
    t = Image.new("RGBA", (16, 16), (24, 26, 40, 255)); d = ImageDraw.Draw(t)
    off = 0 if y_idx % 2 == 0 else 8
    for row in range(2):
        yy = row * 8
        for bx in range(-8, 24, 16):
            x0 = bx + (off if row == 0 else (off + 8) % 16)
            d.rectangle([x0 + 1, yy + 1, x0 + 14, yy + 6], fill=(44, 48, 68))
            d.line([x0 + 1, yy + 1, x0 + 14, yy + 1], fill=(66, 72, 98))
            d.line([x0 + 1, yy + 6, x0 + 14, yy + 6], fill=(32, 34, 50))
    return t

def draw_world(seed=3, with_enemies=True):
    rnd = random.Random(seed)
    im = Image.new("RGBA", (LW, LH), (18, 20, 30, 255))
    for ty in range(0, LH, 16):
        for tx in range(0, LW, 16):
            haz = 112 <= tx < 160 and 112 <= ty < 144
            im.alpha_composite(floor_tile(rnd.randint(0, 99999), haz), (tx, ty))
    for ty in range(0, LH, 16):
        im.alpha_composite(wall_tile(ty // 16), (0, ty)); im.alpha_composite(wall_tile(ty // 16 + 1), (LW - 16, ty))
    d = ImageDraw.Draw(im)
    d.line([16, 0, 16, LH], fill=(10, 10, 18)); d.line([LW - 17, 0, LW - 17, LH], fill=(10, 10, 18))
    # 레일: 침목 + 강철 레일
    for y in range(-2, LH, 8):
        d.rectangle([70, y, 110, y + 3], fill=(80, 54, 36)); d.line([70, y, 110, y], fill=(120, 84, 54)); d.line([70, y + 3, 110, y + 3], fill=(44, 30, 22))
    for rx in (76, 102):
        d.rectangle([rx, 0, rx + 2, LH], fill=(110, 116, 134)); d.line([rx, 0, rx, LH], fill=(190, 196, 214)); d.line([rx + 2, 0, rx + 2, LH], fill=(50, 54, 66))
    # 병목 벽
    for (x0, y0, w) in [(16, 176, 40), (124, 268, 40)]:
        for xx in range(x0, x0 + w, 16):
            im.alpha_composite(wall_tile(1).crop((0, 0, min(16, x0 + w - xx), 16)), (xx, y0))
        d.line([x0, y0, x0 + w - 1, y0], fill=(96, 104, 136)); d.line([x0, y0 + 16, x0 + w - 1, y0 + 16], fill=(10, 10, 18))
    for (x, y) in [(34, 74), (132, 200), (40, 214), (126, 42)]:
        paste(im, PILLAR_SP, x, y)
    for y in (30, 110, 190, 270):  # 벽 등불
        paste(im, LAMP_SP, 5, y); paste(im, LAMP_SP, LW - 11, y)
    paste(im, CHEST_SP, 22, 132)  # 보물방 알코브
    if with_enemies:
        for _ in range(16):
            paste(im, GEM_SP, rnd.randint(24, 150), rnd.randint(150, 300))
        for (x, y) in [(52, 28), (64, 18), (82, 34), (96, 20), (112, 30), (40, 112), (60, 124), (88, 92), (104, 104), (122, 86), (70, 150), (96, 140)]:
            paste(im, SHADOW_SP, x, y)
            d.rectangle([x + 6, y - 2, x + 7, y - 1], fill=(255, 240, 160))  # 계열 마크
        for (x, y) in [(28, 52), (138, 112), (76, 62), (146, 150), (116, 156)]:
            paste(im, FLAME_SP, x, y)
            d.rectangle([x + 6, y - 3, x + 7, y - 2], fill=(255, 120, 60))
        paste(im, ELITE_SP, 118, 52)
        for (x, y) in [(92, 182), (84, 190), (70, 176), (112, 196), (56, 190), (128, 178)]:
            d.rectangle([x, y, x + 2, y + 2], fill=(255, 130, 70)); d.point((x + 1, y + 1), fill=(255, 240, 180))
    return im

def lighting(img, lights):
    """저해상도 월드에 어둠 + 등불 빛을 얹는다."""
    dark = Image.new("RGBA", img.size, (6, 6, 20, 120))
    mask = Image.new("L", img.size, 255); md = ImageDraw.Draw(mask)
    for (x, y, r) in lights:
        for i in range(r, 0, -2):
            md.ellipse([x - i, y - i, x + i, y + i], fill=int(255 * (i / r) ** 1.4))
    dark.putalpha(Image.eval(mask, lambda v: v * 120 // 255))
    out = Image.alpha_composite(img, dark)
    glow = Image.new("RGBA", img.size, (0, 0, 0, 0)); gd = ImageDraw.Draw(glow)
    for (x, y, r) in lights[:-1]:
        gd.ellipse([x - r // 3, y - r // 3, x + r // 3, y + r // 3], fill=(255, 200, 120, 28))
    return Image.alpha_composite(out, glow.filter(ImageFilter.GaussianBlur(4)))

def up(im):
    return im.resize((W, H), Image.NEAREST).convert("RGBA")

# ---------- UI ----------
def text(d, xy, s, size, fill=(240, 240, 245), bold=True, anchor="la", stroke=2):
    d.text(xy, s, font=f(size, bold), fill=fill, anchor=anchor, stroke_width=stroke, stroke_fill=(10, 10, 18))

def panel(d, box, fill=(16, 18, 28, 225), outline=(120, 130, 160, 255), r=4, w=3):
    x0, y0, x1, y1 = box  # 픽셀 UI: 모서리 각진 이중 테두리
    d.rectangle(box, fill=fill, outline=(10, 10, 18, 255), width=w)
    d.rectangle((x0 + w, y0 + w, x1 - w, y1 - w), outline=outline, width=2)

def big_icon(d_img, name, cx, cy, scale):
    sp = ICON[name]; sp = sp.resize((sp.width * scale, sp.height * scale), Image.NEAREST)
    d_img.alpha_composite(sp, (int(cx - sp.width / 2), int(cy - sp.height / 2)))

def status_bar(d):
    text(d, (24, 10), "9:41", 18, stroke=0)
    text(d, (W - 24, 10), "87%", 16, anchor="ra", stroke=0)
    for k in range(3):
        d.rectangle([W - 110 + k * 8, 22 - k * 4, W - 105 + k * 8, 26], fill=(240, 240, 245))

def hud(o, d):
    status_bar(d)
    panel(d, (16, 40, W - 16, 120))
    text(d, (32, 52), "폐역 지하 · 3층", 22)
    text(d, (W - 32, 52), "02:24", 22, fill=(255, 230, 160), anchor="ra")
    bx0, bx1, by = 32, W - 32, 92
    segs = [("A", 0.33), ("B", 0.62), ("C", 0.85), ("보스", 1.0)]
    d.rectangle((bx0, by, bx1, by + 14), fill=(40, 44, 60), outline=(10, 10, 18), width=2)
    d.rectangle((bx0 + 2, by + 2, bx0 + (bx1 - bx0) * 0.31, by + 12), fill=(120, 190, 255))
    d.rectangle((bx0 + 2, by + 2, bx0 + (bx1 - bx0) * 0.31, by + 4), fill=(190, 230, 255))
    prev = 0
    for lab, end in segs:
        xm = bx0 + (bx1 - bx0) * (prev + end) / 2; xe = bx0 + (bx1 - bx0) * end
        if end < 1: d.rectangle((xe - 1, by - 3, xe + 1, by + 17), fill=(230, 230, 240))
        text(d, (xm, by + 7), lab, 13, anchor="mm", stroke=2); prev = end
    d.rectangle((16, 130, 250, 148), fill=(40, 20, 26), outline=(10, 10, 18), width=2)
    d.rectangle((19, 133, 19 + 228 * 0.72, 145), fill=(220, 60, 76)); d.rectangle((19, 133, 19 + 228 * 0.72, 136), fill=(255, 130, 140))
    text(d, (258, 129), "HP 72", 15)
    text(d, (W - 16, 129), "Lv 9", 18, fill=(150, 240, 220), anchor="ra")
    d.rectangle((0, 154, W, 161), fill=(14, 22, 28)); d.rectangle((0, 155, W * 0.58, 160), fill=(90, 230, 200))
    slots = ["sword", "star", None, None, "gem", "heart", None, None]
    for i, ic in enumerate(slots):
        x = 16 + (i % 4) * 38; y = 170 + (i // 4) * 38
        panel(d, (x, y, x + 34, y + 34), fill=(16, 18, 28, 210), outline=(80, 90, 120, 255), w=2)
        if ic:
            big_icon(o, ic, x + 17, y + 17, 2)
            text(d, (x + 31, y + 33), {0: "3", 1: "1", 4: "2", 5: "1"}[i], 11, anchor="rd")
    panel(d, (W - 58, 170, W - 16, 212), fill=(30, 24, 10, 225), outline=(230, 190, 90, 255), w=2)
    big_icon(o, "relic", W - 37, 191, 2); text(d, (W - 37, 218), "유물", 11, anchor="ma")
    panel(d, (W - 58, 244, W - 16, 282), fill=(16, 18, 28, 210), outline=(80, 90, 120, 255), w=2)
    text(d, (W - 37, 263), "II", 16, anchor="mm")

def screen_play():
    world = draw_world()
    paste(world, HERO_SP, 82, 236)
    world = lighting(world, [(8, 33, 40), (172, 33, 40), (8, 113, 40), (172, 113, 40), (8, 193, 40), (172, 193, 40), (8, 273, 40), (172, 273, 40), (90, 246, 70)])
    base = up(world)
    o = Image.new("RGBA", (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(o)
    # 근접 호 (픽셀 호)
    arc = Image.new("RGBA", (LW, LH), (0, 0, 0, 0)); ad = ImageDraw.Draw(arc)
    ad.arc((60, 214, 124, 262), 200, 340, fill=(220, 245, 255, 230), width=3)
    ad.arc((63, 217, 121, 259), 210, 330, fill=(120, 200, 255, 180), width=2)
    o.alpha_composite(up(arc))
    for (x, y, s, c) in [(210, 380, "38", (255, 250, 210)), (300, 420, "41", (255, 250, 210)), (360, 330, "약점! 112", (255, 230, 90))]:
        text(d, (x, y), s, 20, fill=c)
    hud(o, d)
    panel(d, (100, 440, W - 100, 492), fill=(8, 8, 14, 190), outline=(200, 210, 240, 160), w=2)
    text(d, (W // 2, 466), "구역 A · 무너진 승강장", 21, anchor="mm")
    d.ellipse((W // 2 - 70, H - 186, W // 2 + 70, H - 50), outline=(255, 255, 255, 70), width=3)
    d.ellipse((W // 2 - 4, H - 140, W // 2 + 44, H - 92), fill=(255, 255, 255, 90))
    text(d, (W // 2, H - 28), "아무 곳이나 끌어서 이동 · 공격은 자동", 14, anchor="mm")
    text(d, (16, H - 28), "손 떼면 x0.5", 13, fill=(170, 200, 255), anchor="lm")
    return Image.alpha_composite(base, o)

def card(o, d, box, tag, tagc, icon, name, lv, desc, weak=None):
    x0, y0, x1, y1 = box
    panel(d, box, fill=(22, 24, 38, 245), outline=tagc + (255,), w=3)
    panel(d, (x0 + 16, y0 + 16, x0 + 92, y0 + 92), fill=(40, 44, 64, 255), outline=(70, 76, 100, 255), w=2)
    big_icon(o, icon, x0 + 54, y0 + 54, 6)
    d.rectangle((x1 - 96, y0 + 16, x1 - 16, y0 + 42), fill=tagc + (255,), outline=(10, 10, 18), width=2)
    text(d, (x1 - 56, y0 + 29), tag, 14, fill=(15, 15, 20), anchor="mm", stroke=0)
    text(d, (x0 + 108, y0 + 22), name, 22)
    text(d, (x0 + 108, y0 + 54), lv, 15, fill=(180, 230, 255))
    text(d, (x0 + 108, y0 + 82), desc, 14, fill=(210, 210, 220), bold=False, stroke=1)
    if weak:
        d.rectangle((x0 + 16, y1 - 34, x0 + 170, y1 - 10), fill=(70, 60, 20), outline=(255, 220, 90), width=2)
        big_icon(o, "sun", x0 + 32, y1 - 22, 2)
        text(d, (x0 + 100, y1 - 22), weak, 12, fill=(255, 230, 120), anchor="mm", stroke=0)

def screen_levelup():
    world = draw_world(seed=5)
    paste(world, HERO_SP, 82, 236)
    base = up(world)
    base = Image.alpha_composite(base, Image.new("RGBA", (W, H), (6, 6, 12, 185)))
    o = Image.new("RGBA", (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(o)
    status_bar(d)
    text(d, (W // 2, 140), "레벨 업!", 42, fill=(150, 240, 220), anchor="mm", stroke=3)
    text(d, (W // 2, 188), "하나를 고르세요", 18, fill=(220, 220, 230), anchor="mm")
    card(o, d, (26, 226, W - 26, 392), "강화", (120, 190, 255), "sword", "근접 호", "Lv 3 → 4", "베기 범위 +20%, 넉백 강화")
    card(o, d, (26, 410, W - 26, 576), "신규", (150, 240, 160), "lamp", "새벽 등불", "새 무기 · Lv 1", "주변에 빛 파동. 그늘 계열에 강함", "약점 원소: 빛")
    card(o, d, (26, 594, W - 26, 760), "무작위", (230, 170, 255), "heart", "강철 심장", "패시브 · Lv 1", "최대 체력 +15% · 진화 재료")
    panel(d, (26, 786, 262, 844), fill=(30, 34, 52, 240), outline=(140, 150, 180, 255))
    text(d, (144, 815), "다시 뽑기 (무료 2)", 17, anchor="mm")
    panel(d, (278, 786, W - 26, 844), fill=(30, 34, 52, 240), outline=(140, 150, 180, 255))
    text(d, (W - 26 - (W - 304) / 2, 815), "▶ 광고 보고 1회", 17, anchor="mm")
    text(d, (W // 2, 896), "진화 조건: 근접 호 Lv5 + 방어 패시브", 14, fill=(255, 215, 120), anchor="mm")
    return Image.alpha_composite(base, o)

def screen_result():
    im = Image.new("RGBA", (LW, LH), (14, 16, 30, 255)); d = ImageDraw.Draw(im)
    for y in range(0, 170):
        t = y / 170
        d.line([0, y, LW, y], fill=(int(16 + 46 * t), int(16 + 26 * t), int(40 + 40 * t)))
    rnd = random.Random(9)
    for _ in range(40):
        d.point((rnd.randint(0, LW - 1), rnd.randint(0, 120)), fill=(210, 210, 240))
    # 시계탑(벽돌 타일 + 시계)
    for ty in range(40, 176, 16):
        for tx in range(66, 114, 16):
            im.alpha_composite(wall_tile(ty // 16), (tx, ty))
    d.rectangle([62, 34, 117, 40], fill=(60, 66, 92)); d.polygon([(66, 34), (90, 8), (114, 34)], fill=(40, 44, 66), outline=(22, 16, 30))
    d.ellipse([76, 50, 104, 78], fill=(236, 214, 150), outline=(22, 16, 30), width=2)
    d.line([90, 64, 90, 54], fill=(40, 30, 30), width=2); d.line([90, 64, 98, 64], fill=(40, 30, 30), width=2)
    paste(im, LAMP_SP, 88, 82)
    # 승강장
    for tx in range(0, LW, 16):
        im.alpha_composite(floor_tile(tx), (tx, 176))
    d.rectangle([0, 176, LW, 178], fill=(240, 210, 90))
    for y in (200, 216):
        pass
    for x in range(-2, LW, 8):
        d.rectangle([x, 196, x + 4, 222], fill=(80, 54, 36)); d.line([x, 196, x, 222], fill=(120, 84, 54))
    for ry in (202, 214):
        d.rectangle([0, ry, LW, ry + 2], fill=(110, 116, 134)); d.line([0, ry, LW, ry], fill=(190, 196, 214))
    d.rectangle([0, 224, LW, LH], fill=(20, 22, 34))
    paste(im, HERO_SP, 82, 158 - 2)
    im = lighting(im, [(90, 64, 50), (90, 166, 50)])
    base = up(im)
    o = Image.new("RGBA", (W, H), (0, 0, 0, 0)); dd = ImageDraw.Draw(o)
    status_bar(dd)
    text(dd, (W // 2, 410), "[종소리]", 15, fill=(200, 200, 220), anchor="mm")
    text(dd, (W // 2, 440), "종이 울린다. 승강장에서 다시 눈을 뜬다.", 18, anchor="mm")
    panel(dd, (26, 520, W - 26, 890), fill=(14, 16, 28, 240), outline=(200, 180, 120, 255))
    text(dd, (W // 2, 552), "환생 · 폐역 지하 3층 구역 C에서 쓰러짐", 17, fill=(230, 200, 150), anchor="mm")
    text(dd, (W // 2, 588), "스테이터스 상승", 26, fill=(255, 230, 140), anchor="mm")
    for i, (k, v) in enumerate([("힘", "+3"), ("속도", "+1"), ("처치", "412")]):
        y = 626 + i * 40
        text(dd, (70, y), k, 20, bold=False); text(dd, (W - 70, y), v, 22, fill=(150, 240, 220), anchor="ra")
        dd.line((70, y + 32, W - 70, y + 32), fill=(60, 64, 90), width=2)
    dd.rectangle((56, 752, W - 56, 790), fill=(40, 30, 60), outline=(180, 150, 255), width=2)
    text(dd, (W // 2, 771), "각인 +18 (60% 보존) · 새긴 만큼 남는다", 16, fill=(220, 200, 255), anchor="mm")
    big_icon(o, "gem", 200, 812, 2)
    text(dd, (W // 2 + 10, 812), "재료 4/6 · 코인 +230", 15, fill=(210, 210, 220), anchor="mm", bold=False)
    panel(dd, (56, 832, 262, 878), fill=(50, 90, 150, 255), outline=(150, 200, 255, 255))
    text(dd, (159, 855), "다시 출격", 18, anchor="mm")
    panel(dd, (278, 832, W - 56, 878), fill=(40, 44, 64, 255), outline=(140, 150, 180, 255))
    text(dd, (W - 56 - (W - 334) / 2, 855), "승강장으로", 18, anchor="mm")
    text(dd, (W // 2, 924), "다음 판 시작 시 「전생 기억」 무료 3택 1회", 14, fill=(255, 215, 120), anchor="mm")
    return Image.alpha_composite(base, o)

def frame(img, title):
    pad, top = 24, 70
    fr = Image.new("RGBA", (W + pad * 2, H + pad * 2 + top), (0, 0, 0, 0)); d = ImageDraw.Draw(fr)
    d.rounded_rectangle((0, top, fr.width - 1, fr.height - 1), 48, fill=(18, 18, 22))
    mask = Image.new("L", (W, H), 0); ImageDraw.Draw(mask).rounded_rectangle((0, 0, W - 1, H - 1), 30, fill=255)
    fr.paste(img, (pad, top + pad), mask)
    d.text((fr.width // 2, 30), title, font=f(26), fill=(30, 30, 40), anchor="mm")
    return fr

def asset_sheet():
    items = [(HERO_SP, "여울(검사)"), (SHADOW_SP, "그늘 계열"), (FLAME_SP, "불꽃 계열"), (ELITE_SP, "정예: 불씨 눈"),
             (PILLAR_SP, "엄폐 기둥"), (CHEST_SP, "보물 상자"), (floor_tile(7), "석판 바닥"), (floor_tile(8, True), "위험 바닥")]
    sc = 6; cw = 170
    sh = Image.new("RGBA", (cw * len(items), 260), (236, 236, 240, 255)); d = ImageDraw.Draw(sh)
    for i, (sp, nm) in enumerate(items):
        r = sp.resize((sp.width * sc, sp.height * sc), Image.NEAREST)
        sh.alpha_composite(r, (i * cw + (cw - r.width) // 2, 20 + (180 - r.height) // 2))
        d.text((i * cw + cw // 2, 230), nm, font=f(18), fill=(40, 40, 50), anchor="mm")
    return sh

screens = [(screen_play(), "① 판 안 플레이 (구역 A)"), (screen_levelup(), "② 레벨업 3택"), (screen_result(), "③ 환생 결과 화면")]
frames = []
for i, (img, t) in enumerate(screens):
    img.convert("RGB").save(OUT + f"sf_screen_{i + 1}.png"); frames.append(frame(img, t))
gap = 40
sheet_w = sum(fr.width for fr in frames) + gap * 4
assets = asset_sheet()
sheet = Image.new("RGB", (sheet_w, frames[0].height + assets.height + 120), (236, 236, 240))
x = gap
for fr in frames:
    sheet.paste(fr, (x, 20), fr); x += fr.width + gap
sheet.paste(assets, ((sheet_w - assets.width) // 2, frames[0].height + 40), assets)
ImageDraw.Draw(sheet).text((sheet_w // 2, sheet.height - 36),
    "새벽 레일: 환생 열차 (가제) — Sprite Fusion 갤러리 스타일 참고 예상 화면 · 1px 어두운 외곽선 + 3단 램프 음영 · 에셋은 새로 그림(갤러리 이미지 미사용)",
    font=f(20, False), fill=(80, 80, 90), anchor="mm")
sheet.save(OUT + "sf_mockup_sheet.png"); assets.save(OUT + "sf_assets.png")
print("ok", sheet.size)
