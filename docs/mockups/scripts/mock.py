"""v5 제안서 기준 예상 모바일 화면 목업 (픽셀아트 느낌, 1080x1920 기준을 540x960으로 축소)."""
import random
from PIL import Image, ImageDraw, ImageFont

OUT = __import__('os').path.join(__import__('os').path.dirname(__import__('os').path.abspath(__file__)), '..', 'v1_simple') + '/'
LW, LH, S = 135, 240, 4          # 로직 픽셀 해상도 x4 = 540x960
W, H = LW * S, LH * S
FONT = "/System/Library/Fonts/AppleSDGothicNeo.ttc"

def f(size, bold=True):
    try:
        return ImageFont.truetype(FONT, size, index=6 if bold else 0)
    except Exception:
        return ImageFont.truetype(FONT, size)

# 챕터1 폐역 지하: 회청 석재 팔레트
C = dict(
    bg0=(28, 33, 46), bg1=(38, 45, 61), bg2=(52, 61, 80), stone=(78, 90, 112), stone_hi=(112, 126, 150),
    rail=(120, 108, 92), tie=(64, 52, 44), wall=(20, 23, 33), wall_hi=(60, 68, 88),
    haz=(96, 40, 70), haz_hi=(170, 60, 110),
    shadow=(18, 14, 30), shadow_hi=(70, 56, 110), mark_l=(250, 240, 170),
    flame=(92, 52, 40), flame_hi=(130, 70, 50), eye=(255, 170, 40), mark_f=(255, 110, 60),
    p_hair=(40, 36, 52), p_skin=(240, 200, 160), p_coat=(60, 110, 170), p_coat_hi=(110, 170, 220), sword=(230, 235, 250),
    slash=(200, 235, 255), gem=(90, 230, 200), ebullet=(255, 120, 70), lamp=(255, 220, 140),
)

def px(d, x, y, c, w=1, h=1):
    d.rectangle([x, y, x + w - 1, y + h - 1], fill=c)

def draw_world(seed=3, enemies=True):
    random.seed(seed)
    im = Image.new("RGB", (LW, LH), C["bg0"])
    d = ImageDraw.Draw(im)
    # 바닥 석판 타일 8px
    for ty in range(0, LH, 8):
        for tx in range(0, LW, 8):
            c = C["bg1"] if (tx // 8 + ty // 8) % 2 == 0 else C["bg2"]
            px(d, tx, ty, c, 8, 8)
            if random.random() < 0.15:
                px(d, tx + random.randint(1, 6), ty + random.randint(1, 6), C["stone"])
    # 좌우 벽
    for y in range(0, LH, 8):
        px(d, 0, y, C["wall"], 14, 8); px(d, 13, y, C["wall_hi"], 1, 8)
        px(d, LW - 14, y, C["wall"], 14, 8); px(d, LW - 14, y, C["wall_hi"], 1, 8)
        if y % 32 == 0:  # 벽 램프
            px(d, 6, y + 3, C["lamp"], 2, 2); px(d, LW - 8, y + 3, C["lamp"], 2, 2)
    # 세로 레일 (중앙)
    for y in range(0, LH, 4):
        px(d, 52, y, C["tie"], 31, 2)
    px(d, 57, 0, C["rail"], 2, LH); px(d, 76, 0, C["rail"], 2, LH)
    # 위험 바닥 (구역: 우측 중단)
    for y in range(92, 116, 4):
        for x in range(88, 118, 4):
            px(d, x, y, C["haz"] if (x + y) % 8 else C["haz_hi"], 4, 4)
    # 엄폐 기둥
    for (cx, cy) in [(28, 60), (100, 150), (34, 170), (96, 40)]:
        px(d, cx, cy, C["stone"], 10, 12); px(d, cx, cy, C["stone_hi"], 10, 2); px(d, cx, cy + 12, C["wall"], 10, 2)
    # 병목 벽
    px(d, 14, 128, C["wall"], 26, 8); px(d, 14, 128, C["wall_hi"], 26, 1)
    px(d, 95, 196, C["wall"], 26, 8); px(d, 95, 196, C["wall_hi"], 26, 1)
    if enemies:
        # 경험치 보석
        for _ in range(14):
            x, y = random.randint(20, 112), random.randint(120, 220)
            px(d, x, y, C["gem"], 2, 2)
        # 그늘 계열(빛 약점): 둥근 실루엣 + 위 1px 노란 마크
        for (x, y) in [(40, 30), (48, 24), (60, 36), (70, 22), (82, 30), (30, 90), (44, 100), (64, 70), (78, 80), (90, 66)]:
            px(d, x + 1, y, C["shadow"], 6, 1); px(d, x, y + 1, C["shadow"], 8, 6); px(d, x + 1, y + 7, C["shadow"], 2, 1); px(d, x + 5, y + 7, C["shadow"], 2, 1)
            px(d, x + 2, y + 3, C["shadow_hi"], 1, 1); px(d, x + 5, y + 3, C["shadow_hi"], 1, 1)
            px(d, x + 3, y - 2, C["mark_l"], 2, 1)
        # 불꽃 계열: 각진 실루엣 + 뿔, 고채도 눈, 위 1px 주황 마크
        for (x, y) in [(22, 44), (100, 86), (58, 52), (108, 118)]:
            px(d, x, y + 1, C["flame"], 9, 7); px(d, x, y - 1, C["flame_hi"], 2, 2); px(d, x + 7, y - 1, C["flame_hi"], 2, 2)
            px(d, x + 2, y + 3, C["eye"]); px(d, x + 6, y + 3, C["eye"])
            px(d, x + 4, y - 3, C["mark_f"], 1, 1)
        # 적 탄
        for (x, y) in [(70, 110), (64, 118), (52, 104), (86, 124), (40, 116)]:
            px(d, x, y, C["ebullet"], 2, 2)
    return im

def draw_player(d, x, y):
    px(d, x + 2, y, C["p_hair"], 5, 3); px(d, x + 2, y + 2, C["p_skin"], 5, 3)
    px(d, x + 1, y + 5, C["p_coat"], 7, 6); px(d, x + 2, y + 5, C["p_coat_hi"], 1, 5)
    px(d, x + 2, y + 11, C["p_hair"], 2, 2); px(d, x + 5, y + 11, C["p_hair"], 2, 2)
    px(d, x + 8, y + 2, C["sword"], 1, 8)

def up(im):
    return im.resize((W, H), Image.NEAREST).convert("RGBA")

def overlay():
    o = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    return o, ImageDraw.Draw(o)

def text(d, xy, s, size, fill=(240, 240, 245), bold=True, anchor="la", stroke=2):
    d.text(xy, s, font=f(size, bold), fill=fill, anchor=anchor, stroke_width=stroke, stroke_fill=(10, 10, 18))

def panel(d, box, fill=(16, 18, 28, 220), outline=(120, 130, 160, 255), r=10, w=3):
    d.rounded_rectangle(box, r, fill=fill, outline=outline, width=w)


ICONS = {
 "sword": ["......XX",".....XXX","....XXX.","X..XXX..",".XXXX...","..XX....",".X.XX...","X...X..."],
 "star":  ["...X....","...X....",".X.X.X..","..XXX...","XXXXXXX.","..XXX...",".X.X.X..","...X...."],
 "gem":   ["...XX...","..XXXX..",".XXXXXX.","XXXXXXXX",".XXXXXX.","..XXXX..","...XX...","........"],
 "heart": [".XX..XX.","XXXXXXXX","XXXXXXXX","XXXXXXXX",".XXXXXX.","..XXXX..","...XX...","........"],
 "lamp":  ["..XXXX..","...XX...","..XXXX..",".XXXXXX.",".XX..XX.",".XXXXXX.","..XXXX..","...XX..."],
 "relic": ["X.XX.X..","XXXXXX..",".XXXX...",".XXXX...",".XXXX...","XXXXXX..","XXXXXX..","........"],
 "skull": [".XXXXX..","XXXXXXX.","X..X..X.","XXXXXXX.",".XXXXX..",".X.X.X..","........","........"],
 "sun":   ["X..X..X.",".X.X.X..","..XXX...","XXXXXXX.","..XXX...",".X.X.X..","X..X..X.","........"],
 "reroll":["..XXXX..",".X....X.","X......X","X....XXX","X.....X.",".X......","..XXXX..","........"],
}
def icon(d, kind, cx, cy, sc, col):
    g = ICONS[kind]; n = 8
    x0, y0 = cx - n * sc // 2, cy - n * sc // 2
    for j, row in enumerate(g):
        for i, ch in enumerate(row):
            if ch == "X":
                d.rectangle([x0 + i * sc, y0 + j * sc, x0 + (i + 1) * sc - 1, y0 + (j + 1) * sc - 1], fill=col)

def status_bar(d):
    text(d, (24, 10), "9:41", 18, stroke=0)
    text(d, (W - 24, 10), "87%", 16, anchor="ra", stroke=0)
    for k in range(3):
        d.rectangle([W - 110 + k * 8, 22 - k * 4, W - 105 + k * 8, 26], fill=(240, 240, 245))

def hud(d):
    status_bar(d)
    # 상단: 층 이름 + 진행 바 (A/B/C/보스)
    panel(d, (16, 40, W - 16, 120))
    text(d, (32, 50), "폐역 지하 · 3층", 22)
    text(d, (W - 32, 50), "03:12", 22, fill=(255, 230, 160), anchor="ra")
    bx0, bx1, by = 32, W - 32, 92
    segs = [("A", 0.33), ("B", 0.62), ("C", 0.85), ("보스", 1.0)]
    d.rounded_rectangle((bx0, by, bx1, by + 14), 6, fill=(40, 44, 60))
    prog = 0.43
    d.rounded_rectangle((bx0, by, bx0 + (bx1 - bx0) * prog, by + 14), 6, fill=(120, 190, 255))
    prev = 0
    for lab, end in segs:
        xm = bx0 + (bx1 - bx0) * (prev + end) / 2
        xe = bx0 + (bx1 - bx0) * end
        if end < 1: d.line((xe, by - 3, xe, by + 17), fill=(230, 230, 240), width=2)
        text(d, (xm, by + 7), lab, 13, anchor="mm", stroke=2)
        prev = end
    # 체력 / 경험치
    d.rounded_rectangle((16, 130, 250, 146), 5, fill=(40, 20, 26), outline=(10, 10, 18), width=2)
    d.rounded_rectangle((18, 132, 18 + 230 * 0.72, 144), 4, fill=(230, 70, 80))
    text(d, (258, 128), "HP 72", 15)
    text(d, (W - 16, 128), "Lv 9", 18, fill=(150, 240, 220), anchor="ra")
    d.rectangle((0, 152, W, 158), fill=(20, 30, 36))
    d.rectangle((0, 152, W * 0.58, 158), fill=(90, 230, 200))
    # 무기 4 + 패시브 4 + 유물 1 슬롯 (좌측 세로)
    icons = ["sword", "star", "", "", "gem", "heart", "", ""]
    cols = [(120, 180, 255), (255, 200, 80), None, None, (180, 140, 255), (255, 120, 130), None, None]
    for i, (ic, cc) in enumerate(zip(icons, cols)):
        x = 16 + (i % 4) * 36
        y = 168 + (i // 4) * 36
        d.rounded_rectangle((x, y, x + 30, y + 30), 5, fill=(16, 18, 28, 200), outline=(90, 100, 130), width=2)
        if ic:
            icon(d, ic, x + 15, y + 15, 3, cc)
        if i in (0, 1, 4):
            text(d, (x + 28, y + 30), str({0: 3, 1: 1, 4: 2}[i]), 11, anchor="rd", stroke=2)
    # 유물 슬롯 (금테)
    d.rounded_rectangle((W - 56, 168, W - 16, 208), 6, fill=(30, 24, 10, 220), outline=(230, 190, 90), width=3)
    icon(d, "relic", W - 34, 188, 3, (255, 215, 120))
    text(d, (W - 36, 214), "유물", 11, anchor="ma")
    # 일시정지
    d.rounded_rectangle((W - 56, 240, W - 16, 276), 6, fill=(16, 18, 28, 200), outline=(90, 100, 130), width=2)
    text(d, (W - 36, 258), "II", 16, anchor="mm")

def screen_play():
    im = draw_world()
    d = ImageDraw.Draw(im)
    draw_player(d, 62, 178)
    base = up(im)
    o, od = overlay()
    # 검사 근접 호 이펙트 (전방 반원)
    cx, cy = 66 * S, 180 * S
    for r, a in [(92, 180), (80, 120)]:
        od.arc((cx - r, cy - r, cx + r, cy + r), 200, 340, fill=(200, 235, 255, a), width=10)
    # 엄폐 뒤 보너스 표시 없음(검사) / 피해 숫자
    for (x, y, s) in [(190, 300, "38"), (260, 330, "41"), (330, 280, "!약점 112")]:
        text(od, (x, y), s, 18 if s[0] != "!" else 20, fill=(255, 250, 200) if s[0] != "!" else (255, 230, 90))
    hud(od)
    # 구역 전환 자막
    panel(od, (110, 430, W - 110, 486), fill=(8, 8, 14, 170), outline=(200, 210, 240, 120), w=2)
    text(od, (W // 2, 458), "구역 B · 보급 광장 접근", 22, anchor="mm")
    # 하단 드래그 패드 (상대 드래그)
    od.ellipse((W // 2 - 70, H - 190, W // 2 + 70, H - 50), outline=(255, 255, 255, 70), width=3)
    od.ellipse((W // 2 - 10, H - 145, W // 2 + 40, H - 95), fill=(255, 255, 255, 90))
    text(od, (W // 2, H - 30), "아무 곳이나 끌어서 이동 · 공격은 자동", 14, fill=(220, 220, 230), anchor="mm", stroke=2)
    # 감속 표시(손 떼면 0.5배)
    text(od, (16, H - 30), "손 떼면 감속 x0.5", 13, fill=(170, 200, 255), anchor="lm")
    return Image.alpha_composite(base, o)

def card(d, box, tag, tagc, icon, iconc, name, lv, desc, weak=None):
    x0, y0, x1, y1 = box
    panel(d, box, fill=(22, 24, 38, 245), outline=tagc + (255,), r=12, w=4)
    d.rounded_rectangle((x0 + 14, y0 + 14, x0 + 84, y0 + 84), 8, fill=(40, 44, 64), outline=(10, 10, 18), width=2)
    globals()["icon"](d, icon, x0 + 49, y0 + 49, 6, iconc)
    d.rounded_rectangle((x1 - 92, y0 + 14, x1 - 14, y0 + 40), 6, fill=tagc + (255,))
    text(d, (x1 - 53, y0 + 27), tag, 14, fill=(15, 15, 20), anchor="mm", stroke=0)
    text(d, (x0 + 100, y0 + 22), name, 22)
    text(d, (x0 + 100, y0 + 54), lv, 15, fill=(180, 230, 255))
    text(d, (x0 + 100, y0 + 82), desc, 14, fill=(210, 210, 220), bold=False, stroke=1)
    if weak:
        d.rounded_rectangle((x0 + 14, y1 - 30, x0 + 150, y1 - 8), 5, fill=(70, 60, 20), outline=(255, 220, 90), width=2)
        globals()["icon"](d, "sun", x0 + 30, y1 - 19, 2, (255, 230, 120))
        text(d, (x0 + 90, y1 - 19), weak, 12, fill=(255, 230, 120), anchor="mm", stroke=0)

def screen_levelup():
    im = draw_world(seed=5)
    d = ImageDraw.Draw(im)
    draw_player(d, 62, 178)
    base = up(im)
    dim = Image.new("RGBA", (W, H), (6, 6, 12, 175))
    base = Image.alpha_composite(base, dim)
    o, od = overlay()
    status_bar(od)
    text(od, (W // 2, 150), "레벨 업!", 40, fill=(150, 240, 220), anchor="mm", stroke=3)
    text(od, (W // 2, 196), "하나를 고르세요 (3택)", 18, fill=(220, 220, 230), anchor="mm")
    card(od, (30, 240, W - 30, 400), "강화", (120, 190, 255), "sword", (200, 230, 255),
         "근접 호", "Lv 3 → 4", "베기 범위 +20%, 넉백 강화", None)
    card(od, (30, 420, W - 30, 580), "신규", (150, 240, 160), "lamp", (255, 240, 150),
         "새벽 등불", "새 무기 · Lv 1", "주변에 빛 파동. 그늘 계열에 강함", "약점 원소: 빛")
    card(od, (30, 600, W - 30, 760), "무작위", (230, 170, 255), "heart", (255, 130, 150),
         "강철 심장", "패시브 · Lv 1", "최대 체력 +15%  → 진화 재료", None)
    # 리롤: 무료 2 + 광고 1
    panel(od, (30, 790, 260, 846), fill=(30, 34, 52, 240), outline=(140, 150, 180, 255), r=10, w=3)
    icon(od, "reroll", 62, 818, 3, (230, 230, 240)); text(od, (155, 818), "다시 뽑기 (무료 2)", 17, anchor="mm")
    panel(od, (280, 790, W - 30, 846), fill=(30, 34, 52, 240), outline=(140, 150, 180, 255), r=10, w=3)
    text(od, (W - 30 - (W - 310) / 2, 818), "▶ 광고 보고 1회", 17, anchor="mm")
    text(od, (W // 2, 900), "진화 조건: 근접 호 Lv5 + 방어 패시브", 14, fill=(255, 215, 120), anchor="mm")
    return Image.alpha_composite(base, o)

def screen_result():
    im = Image.new("RGB", (LW, LH), (14, 16, 30))
    d = ImageDraw.Draw(im)
    # 승강장 + 시계탑 실루엣 + 새벽 전 하늘
    for y in range(0, 120):
        t = y / 120
        px(d, 0, y, (int(14 + 30 * t), int(16 + 20 * t), int(40 + 30 * t)), LW, 1)
    random.seed(9)
    for _ in range(30):
        px(d, random.randint(0, LW - 1), random.randint(0, 90), (200, 200, 230))
    px(d, 56, 30, (30, 30, 48), 22, 90); px(d, 60, 22, (30, 30, 48), 14, 8); px(d, 64, 16, (30, 30, 48), 6, 6)
    d.ellipse((60, 40, 74, 54), fill=(230, 210, 150)); px(d, 66, 43, (40, 30, 30), 2, 5); px(d, 67, 47, (40, 30, 30), 4, 1)
    px(d, 0, 120, (50, 56, 74), LW, 6); px(d, 0, 126, (34, 38, 52), LW, LH - 126)
    for x in range(0, LW, 6):
        px(d, x, 150, (64, 52, 44), 3, 30)
    px(d, 0, 155, C["rail"], LW, 2); px(d, 0, 172, C["rail"], LW, 2)
    draw_player(d, 62, 106)
    base = up(im)
    o, od = overlay()
    status_bar(od)
    text(od, (W // 2, 60), "[종소리]", 15, fill=(200, 200, 220), anchor="mm")
    text(od, (W // 2, 96), "종이 울린다. 승강장에서 다시 눈을 뜬다.", 18, anchor="mm")
    panel(od, (30, 520, W - 30, 880), fill=(14, 16, 28, 235), outline=(200, 180, 120, 255), r=14, w=3)
    text(od, (W // 2, 552), "환생 · 폐역 지하 3층 구역 C에서 쓰러짐", 17, fill=(230, 200, 150), anchor="mm")
    text(od, (W // 2, 586), "스테이터스 상승", 26, fill=(255, 230, 140), anchor="mm")
    rows = [("힘", "+3"), ("속도", "+1"), ("처치", "412")]
    for i, (k, v) in enumerate(rows):
        y = 626 + i * 40
        text(od, (80, y), k, 20, bold=False)
        text(od, (W - 80, y), v, 22, fill=(150, 240, 220), anchor="ra")
        od.line((80, y + 32, W - 80, y + 32), fill=(60, 64, 90), width=1)
    od.rounded_rectangle((60, 752, W - 60, 790), 8, fill=(40, 30, 60), outline=(180, 150, 255), width=2)
    text(od, (W // 2, 771), "각인 +18 (60% 보존) · 새긴 만큼 남는다", 16, fill=(220, 200, 255), anchor="mm")
    text(od, (W // 2, 812), "재료 4/6 · 코인 +230", 15, fill=(210, 210, 220), anchor="mm", bold=False)
    panel(od, (60, 832, 262, 872), fill=(50, 90, 150, 255), outline=(150, 200, 255, 255), r=10, w=2)
    text(od, (161, 852), "다시 출격", 18, anchor="mm")
    panel(od, (278, 832, W - 60, 872), fill=(40, 44, 64, 255), outline=(140, 150, 180, 255), r=10, w=2)
    text(od, (W - 60 - (W - 338) / 2, 852), "승강장으로", 18, anchor="mm")
    text(od, (W // 2, 920), "다음 판 시작 시 「전생 기억」 무료 3택 1회", 14, fill=(255, 215, 120), anchor="mm")
    return Image.alpha_composite(base, o)

def frame(img, title):
    pad, top = 24, 70
    fr = Image.new("RGBA", (W + pad * 2, H + pad * 2 + top), (0, 0, 0, 0))
    d = ImageDraw.Draw(fr)
    d.rounded_rectangle((0, top, fr.width - 1, fr.height - 1), 48, fill=(18, 18, 22))
    mask = Image.new("L", (W, H), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, W - 1, H - 1), 30, fill=255)
    fr.paste(img, (pad, top + pad), mask)
    d.text((fr.width // 2, 30), title, font=f(26), fill=(30, 30, 40), anchor="mm")
    return fr

screens = [(screen_play(), "① 판 안 플레이 (구역 A)"), (screen_levelup(), "② 레벨업 3택"), (screen_result(), "③ 환생 결과 화면")]
frames = []
for i, (img, t) in enumerate(screens):
    img.convert("RGB").save(OUT + f"screen_{i + 1}.png")
    frames.append(frame(img, t))
gap = 40
sheet = Image.new("RGB", (sum(fr.width for fr in frames) + gap * 4, frames[0].height + 100), (236, 236, 240))
x = gap
for fr in frames:
    sheet.paste(fr, (x, 20), fr)
    x += fr.width + gap
ImageDraw.Draw(sheet).text((sheet.width // 2, sheet.height - 40),
    "새벽 레일: 환생 열차 (가제) — v5 제안서 기준 예상 화면 목업 · 챕터 1 「폐역 지하」 회청 석재 팔레트 · 실제 에셋 아님",
    font=f(20, False), fill=(80, 80, 90), anchor="mm")
sheet.save(OUT + "mockup_sheet.png")
print("ok", sheet.size)
