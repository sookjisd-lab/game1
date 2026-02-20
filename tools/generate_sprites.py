#!/usr/bin/env python3
"""Pixel art sprite generator for Cursed Night (저주받은 밤).

Generates all game sprites as PNG files following the GDD art style:
"피 묻은 동화책" (Blood-stained Storybook).

Usage: python3 tools/generate_sprites.py
"""
import os
import struct
import zlib
import math


# ============================================================
# PNG Writer
# ============================================================

def write_png(filepath, canvas):
    """Write a Canvas to a PNG file."""
    w, h = canvas.w, canvas.h
    raw = b""
    for row in canvas.data:
        raw += b"\x00"
        for r, g, b, a in row:
            raw += struct.pack("BBBB", r, g, b, a)
    compressed = zlib.compress(raw, 9)

    def chunk(ctype, cdata):
        c = ctype + cdata
        crc = struct.pack(">I", zlib.crc32(c) & 0xFFFFFFFF)
        return struct.pack(">I", len(cdata)) + c + crc

    sig = b"\x89PNG\r\n\x1a\n"
    ihdr = struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)
    png = sig + chunk(b"IHDR", ihdr) + chunk(b"IDAT", compressed) + chunk(b"IEND", b"")

    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    with open(filepath, "wb") as f:
        f.write(png)


# ============================================================
# Canvas
# ============================================================

class Canvas:
    def __init__(self, w, h):
        self.w = w
        self.h = h
        self.data = [[(0, 0, 0, 0)] * w for _ in range(h)]

    def set(self, x, y, color):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.data[int(y)][int(x)] = color

    def get(self, x, y):
        if 0 <= x < self.w and 0 <= y < self.h:
            return self.data[int(y)][int(x)]
        return (0, 0, 0, 0)

    def fill_rect(self, x, y, w, h, color):
        for dy in range(h):
            for dx in range(w):
                self.set(x + dx, y + dy, color)

    def fill_circle(self, cx, cy, r, color):
        for y in range(-r, r + 1):
            for x in range(-r, r + 1):
                if x * x + y * y <= r * r:
                    self.set(cx + x, cy + y, color)

    def fill_ellipse(self, cx, cy, rx, ry, color):
        for y in range(-ry, ry + 1):
            for x in range(-rx, rx + 1):
                fx = x / max(rx, 0.1)
                fy = y / max(ry, 0.1)
                if fx * fx + fy * fy <= 1.0:
                    self.set(cx + x, cy + y, color)

    def draw_line(self, x0, y0, x1, y1, color):
        dx = abs(x1 - x0)
        dy = -abs(y1 - y0)
        sx = 1 if x0 < x1 else -1
        sy = 1 if y0 < y1 else -1
        err = dx + dy
        while True:
            self.set(x0, y0, color)
            if x0 == x1 and y0 == y1:
                break
            e2 = 2 * err
            if e2 >= dy:
                err += dy
                x0 += sx
            if e2 <= dx:
                err += dx
                y0 += sy

    def add_outline(self, color):
        outline = []
        for y in range(self.h):
            for x in range(self.w):
                if self.data[y][x][3] == 0:
                    for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                        nx, ny = x + dx, y + dy
                        if 0 <= nx < self.w and 0 <= ny < self.h:
                            if self.data[ny][nx][3] > 0:
                                outline.append((x, y))
                                break
        for x, y in outline:
            self.set(x, y, color)

    def from_grid(self, grid, palette):
        rows = grid.strip().split("\n")
        for y, row in enumerate(rows):
            for x, ch in enumerate(row):
                if ch in palette:
                    self.set(x, y, palette[ch])
        return self

    def copy(self):
        c = Canvas(self.w, self.h)
        for y in range(self.h):
            for x in range(self.w):
                c.data[y][x] = self.data[y][x]
        return c

    def scale(self, factor):
        c = Canvas(self.w * factor, self.h * factor)
        for y in range(self.h):
            for x in range(self.w):
                color = self.data[y][x]
                for dy in range(factor):
                    for dx in range(factor):
                        c.set(x * factor + dx, y * factor + dy, color)
        return c

    def blit(self, other, ox, oy):
        for y in range(other.h):
            for x in range(other.w):
                color = other.data[y][x]
                if color[3] > 0:
                    self.set(ox + x, oy + y, color)


# ============================================================
# GDD Color Palette (Section 3.2)
# ============================================================

T = (0, 0, 0, 0)

# Background
DARK_PURPLE = (45, 27, 61, 255)
DARK_GREEN = (26, 58, 42, 255)
MAUVE = (92, 45, 110, 255)
DARK_BROWN = (61, 36, 21, 255)
MID_PURPLE = (74, 56, 96, 255)

# Accents
BRIGHT_PINK = (255, 107, 157, 255)
NEON_GREEN = (57, 255, 20, 255)
LIGHT_ORANGE = (255, 159, 67, 255)
LIGHT_SKY = (116, 208, 241, 255)
BRIGHT_MAGENTA = (255, 107, 214, 255)

# Character/Object
WARM_BEIGE = (245, 222, 179, 255)
PASTEL_PINK = (255, 182, 193, 255)
DARK_RED = (139, 0, 0, 255)
BRIGHT_YELLOW = (255, 215, 0, 255)
WHITE = (255, 255, 255, 255)

# Extended palette
OUTLINE = (160, 140, 120, 255)
PETAL_RED = (220, 70, 90, 255)
PETAL_PINK = (255, 140, 160, 255)
STEM_GREEN = (50, 140, 60, 255)
LEAF_GREEN = (70, 180, 80, 255)
SHADOW_BODY = (35, 25, 50, 255)
SHADOW_DARK = (20, 12, 30, 255)
DOLL_BODY = (200, 170, 140, 255)
DOLL_STITCH = (120, 80, 60, 255)
DOLL_LEG = (80, 50, 35, 255)
GHOST_BODY = (220, 215, 235, 200)
GHOST_DARK = (180, 170, 200, 180)
FLAME_CORE = (255, 240, 120, 255)
FLAME_MID = (255, 180, 60, 255)
FLAME_OUTER = (255, 120, 40, 255)
BREAD_GOLD = (220, 175, 80, 255)
BREAD_CRUST = (170, 120, 50, 255)
BREAD_SHADOW = (140, 90, 40, 255)
BOOK_PAGE = (240, 235, 220, 255)
BOOK_COVER = (130, 40, 40, 255)
BOOK_SPINE = (90, 25, 25, 255)
MIRROR_BODY = (180, 220, 240, 150)
MIRROR_SHINE = (220, 240, 255, 200)
MIRROR_CRACK = (100, 160, 190, 180)
ROOT_BROWN = (90, 60, 35, 255)
ROOT_DARK = (60, 40, 25, 255)
ROOT_GREEN = (70, 90, 45, 255)
DIRT = (100, 75, 50, 255)
GEM_BLUE = (80, 140, 255, 255)
GEM_BLUE_HI = (140, 190, 255, 255)
GEM_GREEN = (80, 220, 100, 255)
GEM_GREEN_HI = (140, 255, 160, 255)
GEM_RED = (255, 80, 80, 255)
GEM_RED_HI = (255, 150, 150, 255)
GOLD = (255, 215, 0, 255)
GOLD_DARK = (200, 160, 0, 255)
GOLD_HI = (255, 240, 120, 255)
SILVER = (200, 200, 210, 255)
SILVER_HI = (230, 230, 240, 255)
SILVER_DARK = (150, 150, 165, 255)
SKIN = (245, 222, 179, 255)
SKIN_SHADOW = (210, 180, 145, 255)
HAIR_PINK = (255, 150, 170, 255)
HAIR_PINK_HI = (255, 190, 200, 255)
HAIR_PINK_SH = (200, 110, 130, 255)
DRESS_RED = (180, 60, 70, 255)
DRESS_RED_SH = (140, 40, 50, 255)
APRON_WHITE = (240, 235, 225, 255)
APRON_SHADOW = (200, 195, 185, 255)
COAT_DARK = (50, 35, 60, 255)
COAT_MID = (70, 50, 85, 255)
COAT_HI = (90, 70, 110, 255)
GLASSES = (180, 200, 220, 255)
GLASSES_FRAME = (80, 70, 60, 255)
HAIR_GRAY = (180, 175, 170, 255)
HAIR_GRAY_SH = (140, 135, 130, 255)
THRONE_PURPLE = (92, 45, 110, 255)
THRONE_DARK = (60, 30, 75, 255)
THRONE_HI = (120, 65, 140, 255)
GRIM_SKIN = (200, 180, 160, 255)
GRIM_SKIN_SH = (160, 140, 120, 255)
CAPE_DARK = (30, 20, 45, 255)
CAPE_MID = (50, 35, 70, 255)
CROW_BLACK = (25, 20, 35, 255)
CROW_BEAK = (80, 60, 30, 255)
MAGNET_BLUE = (60, 120, 220, 255)
MAGNET_HI = (100, 160, 255, 255)
BELL_YELLOW = (240, 210, 60, 255)
BELL_DARK = (200, 170, 40, 255)
CHEST_BROWN = (140, 90, 40, 255)
CHEST_DARK = (100, 60, 25, 255)
CHEST_GOLD = (220, 180, 50, 255)
POISON_GREEN = (40, 180, 60, 200)
POISON_DARK = (30, 120, 40, 180)
EYE_RED = (200, 40, 40, 255)


# ============================================================
# Helper Functions
# ============================================================

def add_aura(canvas, color, radius=1):
    """Add glowing aura around non-transparent pixels."""
    aura = []
    for y in range(canvas.h):
        for x in range(canvas.w):
            if canvas.data[y][x][3] == 0:
                for dy in range(-radius, radius + 1):
                    for dx in range(-radius, radius + 1):
                        if dx == 0 and dy == 0:
                            continue
                        nx, ny = x + dx, y + dy
                        if 0 <= nx < canvas.w and 0 <= ny < canvas.h:
                            if canvas.data[ny][nx][3] > 0:
                                aura.append((x, y))
                                break
                    else:
                        continue
                    break
    r, g, b, a = color
    for x, y in aura:
        canvas.set(x, y, (r, g, b, a // 2))


def darken(color, factor=0.7):
    r, g, b, a = color
    return (int(r * factor), int(g * factor), int(b * factor), a)


def lighten(color, factor=1.3):
    r, g, b, a = color
    return (min(int(r * factor), 255), min(int(g * factor), 255),
            min(int(b * factor), 255), a)


# ============================================================
# XP Gem Sprites (8x8)
# ============================================================

def _make_gem(base, highlight):
    c = Canvas(8, 8)
    pal = {".": T, "b": base, "h": highlight, "d": darken(base)}
    c.from_grid(
        "...hh...\n"
        "..hbbh..\n"
        ".hbbbbh.\n"
        "hbbbbbdh\n"
        "hbbbddh.\n"
        ".hbbdh..\n"
        "..hdh...\n"
        "...h....", pal)
    return c

def make_gem_small(): return _make_gem(GEM_BLUE, GEM_BLUE_HI)
def make_gem_medium(): return _make_gem(GEM_GREEN, GEM_GREEN_HI)
def make_gem_large(): return _make_gem(GEM_RED, GEM_RED_HI)


# ============================================================
# Map Drop Sprites (8x8 ~ 16x16)
# ============================================================

def make_heal_bread():
    c = Canvas(8, 8)
    pal = {".": T, "g": BREAD_GOLD, "c": BREAD_CRUST, "h": GOLD_HI, "s": BREAD_SHADOW}
    c.from_grid(
        "..hgg...\n"
        ".ggggg..\n"
        "ggggggc.\n"
        "gggggcc.\n"
        "cgggccs.\n"
        ".ccccs..\n"
        "..sss...\n"
        "........", pal)
    return c

def make_magnet_charm():
    c = Canvas(8, 8)
    pal = {".": T, "b": MAGNET_BLUE, "h": MAGNET_HI}
    c.from_grid(
        ".hh..hh.\n"
        ".bb..bb.\n"
        ".bb..bb.\n"
        ".bbbbbb.\n"
        "..bbbb..\n"
        "..hbbh..\n"
        "...bb...\n"
        "........", pal)
    return c

def make_purify_bell():
    c = Canvas(8, 8)
    pal = {".": T, "y": BELL_YELLOW, "d": BELL_DARK, "h": GOLD_HI, "k": DARK_BROWN}
    c.from_grid(
        "...hh...\n"
        "..yyyy..\n"
        ".yyyyyy.\n"
        ".yyyyyy.\n"
        "dyyyyyyd\n"
        "ddyyyydd\n"
        "..dkkd..\n"
        "...kk...", pal)
    return c

def make_gold_pouch():
    c = Canvas(8, 8)
    pal = {".": T, "g": GOLD, "d": GOLD_DARK, "h": GOLD_HI, "b": BREAD_CRUST}
    c.from_grid(
        "..bhb...\n"
        ".bggb...\n"
        ".ggggg..\n"
        "ggghggg.\n"
        "ggggggg.\n"
        ".gdddg..\n"
        "..ddd...\n"
        "........", pal)
    return c

def make_treasure_chest():
    c = Canvas(16, 16)
    pal = {".": T, "b": CHEST_BROWN, "d": CHEST_DARK, "g": CHEST_GOLD,
           "h": GOLD_HI, "k": (60, 35, 15, 255)}
    c.from_grid(
        "................\n"
        "....gggggg......\n"
        "...gghhhhgg.....\n"
        "..gghbbbdhgg....\n"
        "..gbbbbbbbdg....\n"
        "..gbbbgbbddg....\n"
        "..gddddddddg...\n"
        "..gbbbbbbbbbg...\n"
        "..gbbbgggbbbg...\n"
        "..gbbbghgbbbg...\n"
        "..gbbbgggbbbg...\n"
        "..gbbbbbbbbbg...\n"
        "..gdddddddddg..\n"
        "..kkkkkkkkkkk...\n"
        "................\n"
        "................", pal)
    return c


# ============================================================
# Weapon Projectile Sprites
# ============================================================

def make_proj_scissors():
    c = Canvas(10, 10)
    pal = {".": T, "s": SILVER, "h": SILVER_HI, "d": SILVER_DARK, "r": DARK_RED}
    c.from_grid(
        "..........\n"
        "..h....h..\n"
        "..sh..hs..\n"
        "...shhs...\n"
        "....rr....\n"
        "....rr....\n"
        "...sdds...\n"
        "..sd..ds..\n"
        "..d....d..\n"
        "..........", pal)
    return c

def make_proj_bible():
    c = Canvas(10, 10)
    pal = {".": T, "p": MAUVE, "w": BOOK_PAGE, "d": THRONE_DARK, "g": GOLD}
    c.from_grid(
        "..........\n"
        "..dppppd..\n"
        ".dppggppd.\n"
        ".dpwwwwpd.\n"
        ".dpwwwwpd.\n"
        ".dpwwwwpd.\n"
        ".dpwwwwpd.\n"
        ".dppppppd.\n"
        "..dddddd..\n"
        "..........", pal)
    return c

def make_proj_candle():
    c = Canvas(8, 8)
    pal = {".": T, "y": FLAME_CORE, "o": FLAME_MID, "r": FLAME_OUTER}
    c.from_grid(
        "...yy...\n"
        "..yyyy..\n"
        ".yyyooo.\n"
        ".yyoooo.\n"
        "..oooo..\n"
        "..orrr..\n"
        "...rr...\n"
        "........", pal)
    return c

def make_proj_bouquet():
    c = Canvas(10, 10)
    pal = {".": T, "g": POISON_GREEN, "d": POISON_DARK, "n": NEON_GREEN}
    c.from_grid(
        "..........\n"
        "...ngn....\n"
        "..nggggn..\n"
        ".nggddggn.\n"
        ".ggddddgg.\n"
        ".nggddggn.\n"
        "..nggggn..\n"
        "...ngn....\n"
        "..........\n"
        "..........", pal)
    return c

def make_proj_needle():
    c = Canvas(6, 12)
    pal = {".": T, "p": PASTEL_PINK, "h": (255, 220, 230, 255), "d": (200, 140, 160, 255)}
    c.from_grid(
        "..hh..\n"
        "..pp..\n"
        "..pp..\n"
        "..pp..\n"
        "..pp..\n"
        "..pp..\n"
        "..pp..\n"
        "..pp..\n"
        "..pp..\n"
        ".dpd..\n"
        ".ddd..\n"
        "......", pal)
    return c

def make_proj_gear():
    c = Canvas(12, 12)
    pal = {".": T, "g": GOLD, "d": GOLD_DARK, "h": GOLD_HI}
    c.from_grid(
        "....hh......\n"
        "...hggh.....\n"
        ".hhgddghh...\n"
        ".ggddddgg...\n"
        "hgdd..ddgh..\n"
        "hgdd..ddgh..\n"
        ".ggddddgg...\n"
        ".hhgddghh...\n"
        "...hggh.....\n"
        "....hh......\n"
        "............\n"
        "............", pal)
    return c

def make_proj_mirror():
    c = Canvas(8, 8)
    pal = {".": T, "m": MIRROR_BODY, "s": MIRROR_SHINE, "c": MIRROR_CRACK}
    c.from_grid(
        "..smm...\n"
        ".smmmc..\n"
        "smmmmc..\n"
        "mmmcmm..\n"
        "mmcmmm..\n"
        ".mmmm...\n"
        "..mm....\n"
        "........", pal)
    return c

def make_proj_broom():
    c = Canvas(16, 8)
    pal = {".": T, "b": BREAD_CRUST, "d": DARK_BROWN, "s": STEM_GREEN,
           "h": (180, 140, 70, 255)}
    c.from_grid(
        "..bbbb..........\n"
        ".bbbbbb.........\n"
        "hbbdbdbb........\n"
        "hbbdbbdbbddddddd\n"
        "hbbdbdbbddddddd.\n"
        ".bbdbbb.........\n"
        "..bbbb..........\n"
        "................", pal)
    return c


# ============================================================
# Enemy Sprites (16x16)
# ============================================================

def make_tooth_flower():
    c = Canvas(16, 16)
    pal = {".": T, "R": PETAL_RED, "P": PETAL_PINK, "G": STEM_GREEN,
           "L": LEAF_GREEN, "W": WHITE, "D": (40, 10, 20, 255),
           "E": (30, 5, 10, 255)}
    c.from_grid(
        "................\n"
        ".....PPPP.......\n"
        "....PRRRRP......\n"
        "...PRRRRRRP.....\n"
        "...PREP.PERP....\n"
        "...RRDDDDRR.....\n"
        "...RRWDWDRR.....\n"
        "....RDDDDR......\n"
        "....PRRRRP......\n"
        ".....PRRP.......\n"
        "......GG........\n"
        ".....LGGL.......\n"
        "......GG........\n"
        ".....GG.GG......\n"
        ".....G...G......\n"
        "................", pal)
    c.add_outline(OUTLINE)
    return c

def make_shadow_cat():
    c = Canvas(16, 16)
    pal = {".": T, "S": SHADOW_BODY, "D": SHADOW_DARK, "G": NEON_GREEN,
           "W": WHITE, "N": (15, 8, 20, 255)}
    c.from_grid(
        "................\n"
        "..SS......SS....\n"
        "..SSS....SSS....\n"
        "..SDSS..SSDS....\n"
        "..SGSS..SSGS....\n"
        "..SSSSSSSSSS....\n"
        "..SSSSSSSSSS....\n"
        "...SSSSSSSS.....\n"
        "...DNSSSSND.....\n"
        "...SSSSSSSS.....\n"
        "...SSSSSSSS.....\n"
        "...SS.SS.SS.....\n"
        "...SS.SS.SS.....\n"
        "...NN.NN.NN.....\n"
        "............S...\n"
        ".............S..", pal)
    c.add_outline(OUTLINE)
    return c

def make_spider_doll():
    c = Canvas(16, 16)
    pal = {".": T, "B": DOLL_BODY, "S": DOLL_STITCH, "L": DOLL_LEG,
           "E": (30, 20, 20, 255), "W": WHITE, "P": PASTEL_PINK}
    c.from_grid(
        "................\n"
        ".....BBBBB......\n"
        "....BBBBBBB.....\n"
        "....BBEBBEB.....\n"
        "....BBBSBBB.....\n"
        "....BBBPBBB.....\n"
        ".L..BBBBBBB..L..\n"
        "L.L.BSBSBSB.L.L\n"
        "..L..BBBBB..L...\n"
        "..L..BBBBB..L...\n"
        ".L...BSBSB...L..\n"
        "L....BB.BB....L.\n"
        ".....LL.LL......\n"
        ".....LL.LL......\n"
        "................\n"
        "................", pal)
    c.add_outline(OUTLINE)
    return c

def make_candle_ghost():
    c = Canvas(16, 16)
    pal = {".": T, "G": GHOST_BODY, "D": GHOST_DARK, "Y": FLAME_CORE,
           "O": FLAME_MID, "R": FLAME_OUTER, "E": (60, 50, 80, 200)}
    c.from_grid(
        "......YY........\n"
        ".....YYYY.......\n"
        ".....YOOO.......\n"
        "......OO........\n"
        ".....GGGG.......\n"
        "....GGGGGG......\n"
        "...GGGGGGGG.....\n"
        "...GEGG.GEG.....\n"
        "...GGGGGGGG.....\n"
        "...GDGGGGDG.....\n"
        "....GGGGGG......\n"
        "....GDGGDG......\n"
        "...GG.GG.GG.....\n"
        "..GG..GG..GG....\n"
        "..G...GG...G....\n"
        "................", pal)
    c.add_outline(OUTLINE)
    return c

def make_twisted_bread():
    c = Canvas(16, 16)
    pal = {".": T, "G": BREAD_GOLD, "C": BREAD_CRUST, "S": BREAD_SHADOW,
           "W": WHITE, "D": (40, 20, 10, 255), "E": (30, 10, 5, 255)}
    c.from_grid(
        "................\n"
        "................\n"
        ".....CCCC.......\n"
        "....CGGGGGC.....\n"
        "...CGGGGGGGC....\n"
        "...CGEGGEGC.....\n"
        "...CGGGGGGGC....\n"
        "...CGDDDDDGC....\n"
        "...CWDWDWDWC....\n"
        "....CDDDDDSC....\n"
        "....CGGGGGSSC...\n"
        ".....CGGGSS.....\n"
        "......CSSS......\n"
        "................\n"
        "................\n"
        "................", pal)
    c.add_outline(OUTLINE)
    return c

def make_bookworm():
    c = Canvas(16, 16)
    pal = {".": T, "W": BOOK_PAGE, "C": BOOK_COVER, "S": BOOK_SPINE,
           "E": (40, 20, 20, 255), "G": NEON_GREEN}
    c.from_grid(
        "................\n"
        "..C.......C.....\n"
        "..CW.....WC.....\n"
        "..CWW...WWC.....\n"
        "..CWWW.WWWC.....\n"
        "..CWWWSWWWC.....\n"
        "..CWEWSWEWC.....\n"
        "..CWWWSWWWC.....\n"
        "..CWWWSWWWC.....\n"
        "..CWWWSWWWC.....\n"
        "...CWWSWWC......\n"
        "....CWSWC.......\n"
        ".....CSC........\n"
        "................\n"
        "................\n"
        "................", pal)
    c.add_outline(OUTLINE)
    return c

def make_mirror_ghost():
    """24x24 mirror ghost - semi-transparent with sky blue outline."""
    c = Canvas(24, 24)
    # Irregular broken mirror shape
    c.fill_ellipse(12, 10, 8, 7, MIRROR_BODY)
    c.fill_ellipse(12, 10, 6, 5, MIRROR_SHINE)
    # Crack lines
    c.draw_line(8, 6, 16, 14, MIRROR_CRACK)
    c.draw_line(14, 5, 10, 15, MIRROR_CRACK)
    c.draw_line(6, 10, 18, 10, MIRROR_CRACK)
    # Eyes
    c.set(10, 9, (60, 50, 80, 200))
    c.set(14, 9, (60, 50, 80, 200))
    # Trailing shards
    c.fill_rect(4, 16, 3, 3, MIRROR_BODY)
    c.fill_rect(17, 16, 3, 3, MIRROR_BODY)
    c.fill_rect(9, 18, 2, 3, MIRROR_BODY)
    c.fill_rect(14, 19, 2, 2, MIRROR_BODY)
    # Sky blue outline (GDD: #74D0F1)
    c.add_outline(LIGHT_SKY)
    return c

def make_root_hand():
    c = Canvas(16, 16)
    pal = {".": T, "R": ROOT_BROWN, "D": ROOT_DARK, "G": ROOT_GREEN,
           "I": DIRT, "N": (50, 30, 15, 255)}
    c.from_grid(
        "................\n"
        ".....R..R.......\n"
        "....RR..RR......\n"
        "....RR.RRR......\n"
        "...RRRRRRR......\n"
        "...RRDRRDR......\n"
        "....RRRRRR......\n"
        "....RRRRRR......\n"
        ".....RRRR.......\n"
        "......RR........\n"
        ".....GRRG.......\n"
        ".....DGGD.......\n"
        "....DIIID.......\n"
        "..DIIIIIIID.....\n"
        ".DIIIIIIIID.....\n"
        "IIIIIIIIIIIII...", pal)
    c.add_outline(OUTLINE)
    return c


# ============================================================
# Elite Sprites (24x24) - Scaled enemies + magenta aura
# ============================================================

def _make_elite(base_func, name):
    """Create an elite version: scale up base sprite + add magenta aura."""
    base = base_func()
    # Create 24x24 canvas, place scaled sprite centered
    c = Canvas(24, 24)
    # Scale base 16x16 to ~20x20 by 1.25x (approximate by redrawing)
    # Simple approach: blit original at center offset, then add aura
    ox = (24 - base.w) // 2
    oy = (24 - base.h) // 2
    # First draw slightly larger version by duplicating edge pixels
    for y in range(base.h):
        for x in range(base.w):
            color = base.get(x, y)
            if color[3] > 0:
                c.set(ox + x, oy + y, color)
                # Expand slightly
                if x == 0 and color[3] > 0:
                    c.set(ox - 1, oy + y, color)
                if x == base.w - 1 and color[3] > 0:
                    c.set(ox + x + 1, oy + y, color)
                if y == 0 and color[3] > 0:
                    c.set(ox + x, oy - 1, color)
                if y == base.h - 1 and color[3] > 0:
                    c.set(ox + x, oy + y + 1, color)
    # Remove old outline, add magenta aura + outline
    add_aura(c, BRIGHT_MAGENTA, radius=2)
    c.add_outline(BRIGHT_MAGENTA)
    return c

def make_elite_tooth_flower():
    return _make_elite(make_tooth_flower, "elite_tooth_flower")

def make_elite_spider_doll():
    return _make_elite(make_spider_doll, "elite_spider_doll")

def make_elite_candle_ghost():
    return _make_elite(make_candle_ghost, "elite_candle_ghost")


# ============================================================
# Character Sprites (32x32)
# ============================================================

def make_rosie():
    c = Canvas(32, 32)
    pal = {
        ".": T,
        "H": HAIR_PINK, "h": HAIR_PINK_HI, "s": HAIR_PINK_SH,
        "S": SKIN, "k": SKIN_SHADOW,
        "W": WHITE, "E": (40, 30, 50, 255),
        "R": DRESS_RED, "r": DRESS_RED_SH,
        "A": APRON_WHITE, "a": APRON_SHADOW,
        "L": SILVER, "l": SILVER_DARK,
        "B": (30, 20, 15, 255),  # shoes
        "P": PASTEL_PINK,  # ribbon
    }
    c.from_grid(
        "................................\n"
        "................................\n"
        ".........hHHHHHHh...............\n"
        "........hHHHHHHHHh..............\n"
        ".......hHHHPPHHHHh.............\n"
        ".......HHHHHHHHHHHH............\n"
        ".......HHHHHHHHHHHh............\n"
        ".......HsSSSSSSsHH.............\n"
        ".......HSSESSESsH..............\n"
        "........SSSSSSSS...............\n"
        "........SSkPPkSS...............\n"
        ".........SSSSSS................\n"
        "..........kSSk.................\n"
        ".........RRRRRR................\n"
        "........RRAAAARR...............\n"
        ".......SRRAAAARRS...............\n"
        ".......SRRAAAARRSL..............\n"
        ".......SRRAAAARRSL..............\n"
        "........RRAAAARR.ll............\n"
        "........rRAAAARr...............\n"
        "........rRAAAARr...............\n"
        ".........RaaaaR................\n"
        ".........RRRRRR................\n"
        ".........rRRRRr................\n"
        ".........rR..Rr................\n"
        "..........R..R.................\n"
        "..........R..R.................\n"
        ".........kk..kk................\n"
        ".........BB..BB................\n"
        "................................\n"
        "................................\n"
        "................................", pal)
    c.add_outline(darken(HAIR_PINK_SH, 0.6))
    return c

def make_fritz():
    c = Canvas(32, 32)
    pal = {
        ".": T,
        "G": HAIR_GRAY, "g": HAIR_GRAY_SH,
        "S": SKIN, "k": SKIN_SHADOW,
        "W": WHITE, "E": (40, 30, 50, 255),
        "F": GLASSES_FRAME, "L": GLASSES,
        "C": COAT_DARK, "c": COAT_MID, "q": COAT_HI,
        "O": GOLD, "o": GOLD_DARK,
        "B": (30, 20, 15, 255),
    }
    c.from_grid(
        "................................\n"
        "................................\n"
        "..........GGGGG.................\n"
        ".........GGGGGGGg...............\n"
        ".........GGGGGGGg...............\n"
        ".........gGGGGGg................\n"
        "..........SSSSSS...............\n"
        ".........FLESSELF..............\n"
        ".........FSSSSSF...............\n"
        "..........SSSSSS...............\n"
        "..........SkkkkS...............\n"
        "..........SkSSks................\n"
        "...........SSSS................\n"
        "..........qCCCCq...............\n"
        ".........qCCCCCCq..............\n"
        "........SqCCCCCCqS.............\n"
        "........SCCCCCCCCs..............\n"
        "........SCCCOCCCC...............\n"
        ".........CCCoCCCC...............\n"
        ".........cCCCCCCc...............\n"
        ".........cCCCCCCc...............\n"
        ".........cCCCCCCc...............\n"
        "..........CCCCCC................\n"
        "..........CCCCCC................\n"
        "..........CC..CC................\n"
        "..........CC..CC................\n"
        "..........CC..CC................\n"
        ".........kk...kk...............\n"
        ".........BB...BB...............\n"
        "................................\n"
        "................................\n"
        "................................", pal)
    c.add_outline(darken(COAT_DARK, 0.6))
    return c


# ============================================================
# Boss Sprites (64x64, 96x96) - Procedural
# ============================================================

def make_boss_grimholt():
    """Lord Grimholt - 64x64. Throne with spider legs, human upper body."""
    c = Canvas(64, 64)

    # Throne back
    c.fill_rect(20, 5, 24, 30, THRONE_PURPLE)
    c.fill_rect(22, 3, 20, 4, THRONE_HI)
    # Throne ornaments
    c.fill_rect(20, 3, 3, 3, GOLD)
    c.fill_rect(41, 3, 3, 3, GOLD)
    c.fill_rect(30, 2, 4, 3, GOLD)

    # Human torso
    c.fill_ellipse(32, 22, 8, 6, GRIM_SKIN)
    c.fill_ellipse(32, 22, 6, 4, GRIM_SKIN_SH)
    # Face
    c.fill_ellipse(32, 16, 7, 6, GRIM_SKIN)
    # Eyes
    c.fill_rect(28, 14, 3, 2, WHITE)
    c.fill_rect(33, 14, 3, 2, WHITE)
    c.set(29, 14, EYE_RED)
    c.set(34, 14, EYE_RED)
    # Wide grin (extends to ears)
    for x in range(26, 39):
        c.set(x, 19, DARK_RED)
    for x in range(27, 38):
        c.set(x, 20, (40, 10, 20, 255))
    # Teeth in grin
    for x in range(27, 38, 2):
        c.set(x, 19, WHITE)
    # Crown
    c.fill_rect(26, 9, 12, 3, GOLD)
    for x in range(27, 37, 3):
        c.set(x, 8, GOLD)
        c.set(x, 7, BRIGHT_YELLOW)

    # Arms on throne
    c.fill_rect(16, 20, 5, 3, GRIM_SKIN)
    c.fill_rect(43, 20, 5, 3, GRIM_SKIN)

    # Throne seat
    c.fill_rect(16, 30, 32, 6, THRONE_DARK)
    c.fill_rect(18, 28, 28, 3, THRONE_PURPLE)

    # Spider legs (4 pairs)
    leg_color = THRONE_DARK
    leg_joint = THRONE_HI
    # Left legs
    c.draw_line(18, 35, 5, 45, leg_color)
    c.draw_line(5, 45, 2, 55, leg_color)
    c.draw_line(20, 37, 8, 50, leg_color)
    c.draw_line(8, 50, 6, 58, leg_color)
    # Right legs
    c.draw_line(46, 35, 59, 45, leg_color)
    c.draw_line(59, 45, 62, 55, leg_color)
    c.draw_line(44, 37, 56, 50, leg_color)
    c.draw_line(56, 50, 58, 58, leg_color)
    # Leg joints
    for jx, jy in [(5, 45), (8, 50), (59, 45), (56, 50)]:
        c.fill_circle(jx, jy, 1, leg_joint)

    # Throne legs (front)
    c.fill_rect(20, 36, 4, 20, THRONE_DARK)
    c.fill_rect(40, 36, 4, 20, THRONE_DARK)
    c.fill_rect(20, 54, 5, 3, THRONE_PURPLE)
    c.fill_rect(39, 54, 5, 3, THRONE_PURPLE)

    # Robe/cloth
    c.fill_rect(22, 24, 20, 12, CAPE_MID)
    c.fill_rect(24, 30, 16, 8, CAPE_DARK)

    c.add_outline(darken(THRONE_DARK, 0.5))
    return c

def make_boss_witch_messenger():
    """Witch's Herald - 96x96. Crow-headed humanoid with cape."""
    c = Canvas(96, 96)

    # Cape (wide, flowing)
    for y in range(35, 85):
        spread = int((y - 35) * 0.7)
        left = 30 - spread
        right = 66 + spread
        for x in range(max(left, 0), min(right, 96)):
            shade = CAPE_DARK if (x + y) % 5 == 0 else CAPE_MID
            c.set(x, y, shade)

    # Body
    c.fill_ellipse(48, 50, 12, 18, CAPE_MID)
    c.fill_ellipse(48, 50, 10, 16, CAPE_DARK)

    # Reaching hands from cape (left)
    c.fill_rect(15, 55, 4, 3, GRIM_SKIN_SH)
    c.fill_rect(12, 54, 3, 2, GRIM_SKIN)
    c.fill_rect(10, 53, 2, 1, GRIM_SKIN)
    c.fill_rect(13, 60, 4, 3, GRIM_SKIN_SH)
    c.fill_rect(10, 59, 3, 2, GRIM_SKIN)
    # Reaching hands from cape (right)
    c.fill_rect(77, 55, 4, 3, GRIM_SKIN_SH)
    c.fill_rect(81, 54, 3, 2, GRIM_SKIN)
    c.fill_rect(84, 53, 2, 1, GRIM_SKIN)
    c.fill_rect(79, 60, 4, 3, GRIM_SKIN_SH)
    c.fill_rect(83, 59, 3, 2, GRIM_SKIN)

    # Crow head
    c.fill_ellipse(48, 25, 12, 10, CROW_BLACK)
    c.fill_ellipse(48, 25, 10, 8, darken(CROW_BLACK, 0.8))
    # Beak
    c.fill_rect(46, 32, 5, 2, CROW_BEAK)
    c.fill_rect(44, 34, 9, 2, CROW_BEAK)
    c.fill_rect(46, 36, 5, 1, darken(CROW_BEAK))
    # Eyes (glowing red)
    c.fill_rect(42, 23, 3, 3, EYE_RED)
    c.fill_rect(51, 23, 3, 3, EYE_RED)
    c.set(43, 24, WHITE)
    c.set(52, 24, WHITE)
    # Eye glow
    c.set(41, 23, (200, 40, 40, 120))
    c.set(55, 23, (200, 40, 40, 120))

    # Feather tufts on head
    for fx in [38, 42, 54, 58]:
        c.draw_line(fx, 18, fx + (1 if fx < 48 else -1), 14, CROW_BLACK)

    # Taloned feet
    for foot_x in [38, 55]:
        c.fill_rect(foot_x, 82, 4, 3, darken(CROW_BLACK))
        c.set(foot_x - 1, 84, CROW_BEAK)
        c.set(foot_x + 4, 84, CROW_BEAK)
        c.set(foot_x + 1, 85, CROW_BEAK)
        c.set(foot_x + 2, 85, CROW_BEAK)

    # More hands reaching from cape bottom
    for hx in [25, 35, 60, 70]:
        c.fill_rect(hx, 78, 3, 4, GRIM_SKIN_SH)
        c.set(hx, 82, GRIM_SKIN)
        c.set(hx + 2, 82, GRIM_SKIN)

    # Dark aura particles
    for ax, ay in [(20, 40), (75, 38), (18, 70), (78, 72), (30, 80), (65, 82)]:
        c.set(ax, ay, (40, 20, 60, 100))
        c.set(ax + 1, ay, (30, 15, 50, 80))

    c.add_outline(darken(CAPE_DARK, 0.5))
    return c


# ============================================================
# Death Particle (4x4)
# ============================================================

def make_death_particle():
    c = Canvas(4, 4)
    pal = {".": T, "W": WHITE, "P": BRIGHT_PINK}
    c.from_grid(
        ".WW.\n"
        "WPWW\n"
        "WWPW\n"
        ".WW.", pal)
    return c


# ============================================================
# Main
# ============================================================

def main():
    base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    assets = os.path.join(base, "assets")

    sprites = {
        # Characters (32x32)
        "characters/rosie.png": make_rosie(),
        "characters/fritz.png": make_fritz(),

        # Enemies (16x16)
        "enemies/tooth_flower.png": make_tooth_flower(),
        "enemies/shadow_cat.png": make_shadow_cat(),
        "enemies/spider_doll.png": make_spider_doll(),
        "enemies/candle_ghost.png": make_candle_ghost(),
        "enemies/twisted_bread.png": make_twisted_bread(),
        "enemies/bookworm.png": make_bookworm(),
        "enemies/root_hand.png": make_root_hand(),
        "enemies/mirror_ghost.png": make_mirror_ghost(),

        # Elites (24x24)
        "elites/elite_tooth_flower.png": make_elite_tooth_flower(),
        "elites/elite_spider_doll.png": make_elite_spider_doll(),
        "elites/elite_candle_ghost.png": make_elite_candle_ghost(),

        # Bosses
        "bosses/boss_grimholt.png": make_boss_grimholt(),
        "bosses/boss_witch_messenger.png": make_boss_witch_messenger(),

        # XP Gems (8x8)
        "drops/xp_gem_small.png": make_gem_small(),
        "drops/xp_gem_medium.png": make_gem_medium(),
        "drops/xp_gem_large.png": make_gem_large(),

        # Map Drops
        "drops/heal_bread.png": make_heal_bread(),
        "drops/magnet_charm.png": make_magnet_charm(),
        "drops/purify_bell.png": make_purify_bell(),
        "drops/gold_pouch.png": make_gold_pouch(),
        "drops/treasure_chest.png": make_treasure_chest(),

        # Weapon Projectiles
        "weapons/proj_scissors.png": make_proj_scissors(),
        "weapons/proj_bible.png": make_proj_bible(),
        "weapons/proj_candle.png": make_proj_candle(),
        "weapons/proj_bouquet.png": make_proj_bouquet(),
        "weapons/proj_needle.png": make_proj_needle(),
        "weapons/proj_gear.png": make_proj_gear(),
        "weapons/proj_mirror.png": make_proj_mirror(),
        "weapons/proj_broom.png": make_proj_broom(),

        # Particles
        "particles/death_particle.png": make_death_particle(),
    }

    count = 0
    for path, canvas in sprites.items():
        full_path = os.path.join(assets, path)
        write_png(full_path, canvas)
        count += 1
        print(f"  [{count}/{len(sprites)}] {path} ({canvas.w}x{canvas.h})")

    print(f"\nGenerated {count} sprites in {assets}/")


if __name__ == "__main__":
    main()
