#!/usr/bin/env python3
"""Pixel art sprite generator for Cursed Night.

Generates all game sprites as PNG files following the GDD art style:
"Blood-stained Storybook" - dark and eerie yet cute.

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
# Color Palette - "Blood-stained Storybook"
# ============================================================

T = (0, 0, 0, 0)

# Darks
OUTLINE_DARK = (25, 15, 30, 255)
SHADOW_BLACK = (20, 12, 28, 255)

# Skin tones
SKIN_LIGHT = (248, 228, 195, 255)
SKIN_MID = (235, 205, 165, 255)
SKIN_SHADOW = (200, 170, 130, 255)
SKIN_DARK = (170, 135, 100, 255)

# Rosie's palette
HAIR_PINK = (255, 155, 175, 255)
HAIR_PINK_HI = (255, 195, 205, 255)
HAIR_PINK_SH = (195, 105, 125, 255)
HAIR_PINK_DARK = (155, 70, 90, 255)
DRESS_RED = (175, 55, 65, 255)
DRESS_RED_HI = (210, 80, 90, 255)
DRESS_RED_SH = (135, 35, 45, 255)
APRON_WHITE = (240, 235, 225, 255)
APRON_SHADOW = (210, 200, 190, 255)
RIBBON_PINK = (255, 130, 155, 255)
SHOE_BROWN = (65, 40, 30, 255)

# Fritz's palette
COAT_DARK = (45, 32, 55, 255)
COAT_MID = (65, 48, 80, 255)
COAT_HI = (88, 68, 108, 255)
COAT_LIGHT = (105, 85, 125, 255)
HAIR_GRAY = (185, 180, 175, 255)
HAIR_GRAY_HI = (210, 205, 200, 255)
HAIR_GRAY_SH = (145, 140, 135, 255)
GLASSES_FRAME = (70, 60, 50, 255)
GLASSES_LENS = (175, 195, 215, 255)
GLASSES_HI = (210, 225, 240, 255)
GOLD_BUTTON = (230, 190, 50, 255)
GOLD_DARK = (180, 145, 30, 255)

# Eye colors
EYE_WHITE = (255, 255, 255, 255)
EYE_DARK = (35, 25, 45, 255)
EYE_RED = (200, 40, 40, 255)
BLUSH = (255, 140, 140, 100)

# Flower enemy
PETAL_RED = (215, 65, 85, 255)
PETAL_PINK = (255, 135, 155, 255)
PETAL_DARK = (170, 40, 60, 255)
STEM_GREEN = (55, 130, 60, 255)
STEM_DARK = (35, 90, 40, 255)
LEAF_GREEN = (75, 170, 80, 255)
TOOTH_WHITE = (245, 240, 235, 255)
TOOTH_SHADOW = (210, 200, 190, 255)
GUM_RED = (180, 50, 60, 255)

# Shadow cat
SHADOW_BODY = (40, 28, 55, 255)
SHADOW_MID = (55, 40, 72, 255)
SHADOW_LIGHT = (70, 55, 90, 255)
CAT_EYE_GREEN = (60, 255, 30, 255)
CAT_EYE_DARK = (30, 180, 15, 255)

# Spider doll
DOLL_BODY = (205, 175, 145, 255)
DOLL_SHADOW = (175, 140, 110, 255)
DOLL_DARK = (140, 105, 75, 255)
STITCH_BROWN = (110, 75, 50, 255)
BUTTON_EYE = (30, 20, 20, 255)
THREAD_RED = (180, 50, 60, 255)

# Candle ghost
GHOST_WHITE = (225, 220, 240, 200)
GHOST_BLUE = (195, 190, 220, 180)
GHOST_SHADOW = (165, 155, 190, 160)
GHOST_DARK = (130, 120, 160, 140)
FLAME_CORE = (255, 245, 130, 255)
FLAME_MID = (255, 185, 65, 255)
FLAME_OUTER = (255, 125, 45, 255)
FLAME_TIP = (255, 90, 30, 255)
CANDLE_WAX = (240, 235, 220, 255)
CANDLE_SHADOW = (210, 200, 185, 255)

# Twisted bread
BREAD_GOLD = (225, 180, 85, 255)
BREAD_CRUST = (175, 125, 55, 255)
BREAD_SHADOW = (140, 95, 40, 255)
BREAD_HI = (245, 210, 130, 255)
BREAD_DARK = (100, 65, 30, 255)
BREAD_TOOTH = (240, 235, 225, 255)

# Bookworm
BOOK_COVER = (130, 40, 40, 255)
BOOK_SPINE = (90, 25, 25, 255)
BOOK_PAGE = (240, 235, 220, 255)
BOOK_SHADOW = (210, 200, 185, 255)
WORM_GREEN = (80, 160, 70, 255)
WORM_DARK = (50, 110, 45, 255)
WORM_HI = (120, 200, 100, 255)

# Mirror ghost
MIRROR_BODY = (180, 220, 240, 160)
MIRROR_SHINE = (225, 245, 255, 210)
MIRROR_CRACK = (100, 160, 190, 190)
MIRROR_DARK = (130, 170, 200, 140)
MIRROR_EDGE = (90, 140, 175, 180)

# Root hand
ROOT_BROWN = (95, 65, 40, 255)
ROOT_DARK = (65, 42, 28, 255)
ROOT_LIGHT = (125, 90, 55, 255)
ROOT_GREEN = (70, 95, 48, 255)
DIRT_BROWN = (105, 80, 55, 255)
DIRT_DARK = (75, 55, 35, 255)
NAIL_GRAY = (170, 160, 150, 255)

# Gems
GEM_BLUE = (80, 140, 255, 255)
GEM_BLUE_HI = (150, 200, 255, 255)
GEM_BLUE_SH = (45, 90, 190, 255)
GEM_GREEN = (80, 220, 100, 255)
GEM_GREEN_HI = (150, 255, 170, 255)
GEM_GREEN_SH = (45, 160, 60, 255)
GEM_RED = (255, 80, 80, 255)
GEM_RED_HI = (255, 160, 160, 255)
GEM_RED_SH = (190, 45, 45, 255)

# Drops
MAGNET_BLUE = (60, 120, 220, 255)
MAGNET_HI = (110, 170, 255, 255)
MAGNET_DARK = (35, 80, 165, 255)
BELL_YELLOW = (240, 215, 65, 255)
BELL_DARK = (200, 175, 45, 255)
BELL_HI = (255, 240, 130, 255)
CHEST_BROWN = (145, 95, 45, 255)
CHEST_DARK = (105, 65, 30, 255)
CHEST_GOLD = (225, 185, 55, 255)
CHEST_HI = (255, 225, 110, 255)

# Boss Grimholt
THRONE_PURPLE = (95, 48, 115, 255)
THRONE_DARK = (60, 30, 78, 255)
THRONE_HI = (125, 70, 148, 255)
GRIM_SKIN = (200, 182, 162, 255)
GRIM_SKIN_SH = (165, 145, 125, 255)
CROWN_GOLD = (255, 220, 55, 255)
CROWN_GEM = (200, 40, 40, 255)
CAPE_DARK = (30, 20, 45, 255)
CAPE_MID = (50, 35, 70, 255)
CAPE_HI = (72, 55, 95, 255)

# Boss Witch Messenger
CROW_BLACK = (28, 22, 38, 255)
CROW_DARK = (38, 30, 50, 255)
CROW_MID = (50, 40, 65, 255)
CROW_BEAK = (85, 65, 35, 255)
CROW_BEAK_HI = (115, 90, 50, 255)
POISON_GREEN = (45, 185, 65, 200)
POISON_DARK = (30, 125, 42, 180)

# Weapon projectiles
SILVER = (200, 200, 215, 255)
SILVER_HI = (235, 235, 248, 255)
SILVER_DARK = (150, 150, 168, 255)
DARK_RED = (140, 10, 10, 255)
BRIGHT_MAGENTA = (255, 110, 220, 255)
NEON_GREEN = (60, 255, 25, 255)

# Misc
WHITE = (255, 255, 255, 255)
BRIGHT_YELLOW = (255, 220, 55, 255)
PASTEL_PINK = (255, 185, 198, 255)
LIGHT_SKY = (120, 210, 245, 255)
DARK_BROWN = (60, 38, 22, 255)
MAUVE = (95, 48, 115, 255)


# ============================================================
# Helpers
# ============================================================

def darken(color, factor=0.7):
    r, g, b, a = color
    return (int(r * factor), int(g * factor), int(b * factor), a)


def lighten(color, factor=1.3):
    r, g, b, a = color
    return (min(int(r * factor), 255), min(int(g * factor), 255),
            min(int(b * factor), 255), a)


def add_aura(canvas, color, radius=1):
    """Add glowing aura around non-transparent pixels."""
    aura = []
    for y in range(canvas.h):
        for x in range(canvas.w):
            if canvas.data[y][x][3] == 0:
                found = False
                for dy in range(-radius, radius + 1):
                    for dx in range(-radius, radius + 1):
                        if dx == 0 and dy == 0:
                            continue
                        nx, ny = x + dx, y + dy
                        if 0 <= nx < canvas.w and 0 <= ny < canvas.h:
                            if canvas.data[ny][nx][3] > 0:
                                aura.append((x, y))
                                found = True
                                break
                    if found:
                        break
    r, g, b, a = color
    for x, y in aura:
        canvas.set(x, y, (r, g, b, a // 2))


# ============================================================
# Character Sprites (24x24 sprite sheets, 2 frames = 48x24)
# ============================================================

def make_rosie():
    """Rosie - flower shop daughter, 24x24 x2 frame sprite sheet."""
    sheet = Canvas(48, 24)
    # Frame 1: standing
    pal1 = {
        ".": T,
        "O": OUTLINE_DARK,
        # Hair
        "H": HAIR_PINK, "h": HAIR_PINK_HI, "s": HAIR_PINK_SH, "d": HAIR_PINK_DARK,
        # Face
        "S": SKIN_LIGHT, "k": SKIN_MID, "m": SKIN_SHADOW,
        "E": EYE_DARK, "W": EYE_WHITE, "B": BLUSH,
        # Dress
        "R": DRESS_RED, "r": DRESS_RED_SH, "q": DRESS_RED_HI,
        # Apron
        "A": APRON_WHITE, "a": APRON_SHADOW,
        # Other
        "P": RIBBON_PINK, "L": SHOE_BROWN,
    }
    sheet.from_grid(
        "......hHHHHh...................................................\n"
        ".....hHHPPHHh..................................................\n"
        "....sHHHHHHHHs.................................................\n"
        "....HHHHHHHHHH.................................................\n"
        "....HsSkkkSsH.................................................\n"
        "....HkWEkEWkH.................................................\n"
        ".....kSkBBkSk.................................................\n"
        "......SkmmkS...................................................\n"
        "......qRRRRq..................................................\n"
        ".....qRRAAARq.................................................\n"
        "....kRRAAAAARk................................................\n"
        "....kRRAAAAARk................................................\n"
        ".....RRaAaARR.................................................\n"
        ".....rRAAAARr.................................................\n"
        ".....rRaAaARr.................................................\n"
        "......RAAAAR..................................................\n"
        "......rRRRRr..................................................\n"
        ".......rRRr...................................................\n"
        ".......kR.Rk..................................................\n"
        ".......kR.Rk..................................................\n"
        "......kk..kk..................................................\n"
        "......LL..LL..................................................\n"
        "......LL..LL..................................................\n"
        ".........................", pal1)
    # Frame 2: slight bob (1px down shift on body, hair sway)
    f2_pal = dict(pal1)
    f2 = Canvas(24, 24)
    f2.from_grid(
        ".......hHHHh............\n"
        "......hHPPHHh...........\n"
        ".....sHHHHHHHs..........\n"
        ".....HHHHHHHHHs.........\n"
        ".....HsSkkkSsH.........\n"
        ".....HkWEkEWkH.........\n"
        "......kSkBBkSk.........\n"
        ".......SkmmkS..........\n"
        ".......qRRRRq..........\n"
        "......qRRAAARq.........\n"
        ".....kRRAAAAARk........\n"
        ".....kRRAAAAARk........\n"
        "......RRaAaARR.........\n"
        "......rRAAAARr.........\n"
        "......rRaAaARr.........\n"
        ".......RAAAAR..........\n"
        ".......rRRRRr..........\n"
        "........rRRr...........\n"
        ".......kR..Rk..........\n"
        ".......kR..Rk..........\n"
        "......kk...kk..........\n"
        "......LL...LL..........\n"
        "......LL...LL..........\n"
        "........................", f2_pal)
    sheet.blit(f2, 24, 0)
    sheet.add_outline(OUTLINE_DARK)
    return sheet


def make_fritz():
    """Fritz - clocktower keeper, 24x24 x2 frame sprite sheet."""
    sheet = Canvas(48, 24)
    pal = {
        ".": T,
        "O": OUTLINE_DARK,
        # Hair
        "G": HAIR_GRAY, "g": HAIR_GRAY_SH, "i": HAIR_GRAY_HI,
        # Face
        "S": SKIN_LIGHT, "k": SKIN_MID, "m": SKIN_SHADOW,
        "E": EYE_DARK, "W": EYE_WHITE,
        # Glasses
        "F": GLASSES_FRAME, "L": GLASSES_LENS, "l": GLASSES_HI,
        # Coat
        "C": COAT_DARK, "c": COAT_MID, "q": COAT_HI, "p": COAT_LIGHT,
        # Other
        "B": GOLD_BUTTON, "b": GOLD_DARK,
        "K": SHOE_BROWN,
    }
    sheet.from_grid(
        ".......iGGGi..............................................\n"
        "......iGGGGGi.............................................\n"
        "......gGGGGGg.............................................\n"
        ".......gGGGg..............................................\n"
        ".......SSkSSS.............................................\n"
        "......FlEkElF.............................................\n"
        "......FSkkkSF.............................................\n"
        ".......SkmkS..............................................\n"
        ".......pCCCCp.............................................\n"
        "......pCCCCCCp............................................\n"
        ".....kCCCBCCCk...........................................\n"
        ".....kCCCbCCCk...........................................\n"
        "......cCCCCCCc...........................................\n"
        "......cCCCCCCc...........................................\n"
        "......cCCCCCCc...........................................\n"
        ".......CCCCCC............................................\n"
        ".......cCCCCc............................................\n"
        "........cCCc.............................................\n"
        ".......kC..Ck............................................\n"
        ".......kC..Ck............................................\n"
        "......kk...kk............................................\n"
        "......KK...KK............................................\n"
        "......KK...KK............................................\n"
        ".........................", pal)
    # Frame 2
    f2 = Canvas(24, 24)
    f2.from_grid(
        "........iGGi............\n"
        ".......iGGGGi..........\n"
        ".......gGGGGGg.........\n"
        "........gGGGg..........\n"
        "........SSkSS..........\n"
        ".......FlEkElF.........\n"
        ".......FSkkkSF.........\n"
        "........SkmkS..........\n"
        "........pCCCp..........\n"
        ".......pCCCCCp.........\n"
        "......kCCCBCCCk........\n"
        "......kCCCbCCCk........\n"
        ".......cCCCCCCc........\n"
        ".......cCCCCCCc........\n"
        ".......cCCCCCCc........\n"
        "........CCCCCC.........\n"
        "........cCCCCc.........\n"
        ".........cCCc..........\n"
        "........kC..Ck.........\n"
        "........kC..Ck.........\n"
        ".......kk...kk.........\n"
        ".......KK...KK.........\n"
        ".......KK...KK.........\n"
        "........................", pal)
    sheet.blit(f2, 24, 0)
    sheet.add_outline(OUTLINE_DARK)
    return sheet


# ============================================================
# Enemy Sprites
# ============================================================

def make_tooth_flower():
    """Tooth flower - carnivorous flower with teeth, 16x16."""
    c = Canvas(16, 16)
    pal = {
        ".": T,
        "R": PETAL_RED, "P": PETAL_PINK, "D": PETAL_DARK,
        "G": STEM_GREEN, "g": STEM_DARK, "L": LEAF_GREEN,
        "W": TOOTH_WHITE, "w": TOOTH_SHADOW,
        "M": GUM_RED, "E": EYE_DARK, "Y": (255, 255, 100, 255),
    }
    c.from_grid(
        "....DPRD........\n"
        "...DRRRRP.......\n"
        "..PRRRRRRD......\n"
        "..RRMWWMRR......\n"
        "..RWEYYEWRP.....\n"
        "..PMMWWMMP......\n"
        "...RWWWWR.......\n"
        "....DRRRD.......\n"
        ".....gGg........\n"
        "....LgGgL.......\n"
        "...L.gGg.L......\n"
        ".....gGg........\n"
        "....gG.Gg.......\n"
        "...gG...Gg......\n"
        "..gG.....Gg.....\n"
        "................", pal)
    c.add_outline(OUTLINE_DARK)
    return c


def make_shadow_cat():
    """Shadow cat - eerie dark cat with glowing eyes, 16x16."""
    c = Canvas(16, 16)
    pal = {
        ".": T,
        "S": SHADOW_BODY, "M": SHADOW_MID, "L": SHADOW_LIGHT,
        "G": CAT_EYE_GREEN, "g": CAT_EYE_DARK,
        "N": (18, 10, 25, 255),  # nose
        "W": (220, 210, 230, 200),  # whisker
    }
    c.from_grid(
        "..SM....MS......\n"
        "..SSM..MSS......\n"
        "..SSSMMSS.......\n"
        "..SLSLLSLS......\n"
        "..SGS..SGS......\n"
        "..SgS..SgS......\n"
        "..SSSNNSS.......\n"
        "W.SSMMMSS.W.....\n"
        "..MSSSSSM.......\n"
        "..MSSSSSSM......\n"
        "..SSSSSSSS......\n"
        "..SSLSSLSS......\n"
        "..SS.SS.SS......\n"
        "..NN.NN.NN......\n"
        "..........SM....\n"
        "...........SM...", pal)
    c.add_outline(OUTLINE_DARK)
    return c


def make_spider_doll():
    """Spider doll - stitched doll with spider legs, 16x16."""
    c = Canvas(16, 16)
    pal = {
        ".": T,
        "B": DOLL_BODY, "D": DOLL_SHADOW, "K": DOLL_DARK,
        "S": STITCH_BROWN, "E": BUTTON_EYE,
        "R": THREAD_RED, "P": PASTEL_PINK,
        "L": (85, 55, 38, 255),  # legs
    }
    c.from_grid(
        "................\n"
        ".....BBBBB......\n"
        "....BBBBBBB.....\n"
        "....BBEBBEBD....\n"
        "....BBBSBBB.....\n"
        "....BBRPRBBD....\n"
        ".L..BBBBBBB..L..\n"
        "L.L.BSBSBSB.L.L\n"
        "..L..BDBDB..L...\n"
        "..L..BBBBB..L...\n"
        ".L...BSBSB...L..\n"
        "L....BD.DB....L.\n"
        ".....LL.LL......\n"
        ".....KK.KK......\n"
        "................\n"
        "................", pal)
    c.add_outline(OUTLINE_DARK)
    return c


def make_candle_ghost():
    """Candle ghost - floating spirit carrying a candle, 16x16."""
    c = Canvas(16, 16)
    pal = {
        ".": T,
        "Y": FLAME_CORE, "O": FLAME_MID, "F": FLAME_OUTER, "T": FLAME_TIP,
        "W": CANDLE_WAX, "w": CANDLE_SHADOW,
        "G": GHOST_WHITE, "g": GHOST_BLUE, "D": GHOST_SHADOW,
        "E": (65, 55, 85, 200),  # ghost eyes
    }
    c.from_grid(
        "......YY........\n"
        ".....YYOO.......\n"
        ".....YOOF.......\n"
        "......Ww........\n"
        "......Ww........\n"
        ".....GGGG.......\n"
        "....GGGGGG......\n"
        "...GGGGGGGg.....\n"
        "...GEGg.GEG.....\n"
        "...GGGgGGGG.....\n"
        "...gGDGGDGg.....\n"
        "....GGGGGG......\n"
        "....gGDDGg......\n"
        "...Gg.GG.gG.....\n"
        "..Gg..GG..gG....\n"
        "................", pal)
    c.add_outline(OUTLINE_DARK)
    return c


def make_twisted_bread():
    """Twisted bread - possessed bread with teeth, 16x16."""
    c = Canvas(16, 16)
    pal = {
        ".": T,
        "G": BREAD_GOLD, "C": BREAD_CRUST, "S": BREAD_SHADOW,
        "H": BREAD_HI, "D": BREAD_DARK,
        "W": BREAD_TOOTH, "E": EYE_DARK, "R": (180, 50, 50, 255),
    }
    c.from_grid(
        "................\n"
        ".....CCCC.......\n"
        "....CHGGGC......\n"
        "...CHGGGGGC.....\n"
        "...CGGGGGGGC....\n"
        "...CGEGCGEGC....\n"
        "...CGGGGGGGC....\n"
        "...CRWDWDWRC....\n"
        "...CWDWDWDWC....\n"
        "....CWDWDWCS....\n"
        "....CGGGGGSS....\n"
        ".....CGGGSS.....\n"
        "......CSSS......\n"
        "......DSS.......\n"
        "................\n"
        "................", pal)
    c.add_outline(OUTLINE_DARK)
    return c


def make_bookworm():
    """Bookworm - living book with tentacle pages, 16x16."""
    c = Canvas(16, 16)
    pal = {
        ".": T,
        "C": BOOK_COVER, "S": BOOK_SPINE, "P": BOOK_PAGE, "p": BOOK_SHADOW,
        "E": EYE_DARK, "G": CAT_EYE_GREEN,
        "W": WORM_GREEN, "w": WORM_DARK, "h": WORM_HI,
    }
    c.from_grid(
        "................\n"
        "..C.......C.....\n"
        "..CP.....PC.....\n"
        "..CPP...PPC.....\n"
        "..CPPP.PPPC.....\n"
        "..CPPPSPPPSC....\n"
        "..CPGPSPGPC.....\n"
        "..CPPPSPPPSC....\n"
        "..CPPPSPPPSC....\n"
        "..CPPPSPPPpC....\n"
        "...CPPSPPpC.....\n"
        "....CPSPC.......\n"
        ".....CSC........\n"
        ".W..........W...\n"
        "..wW......Ww....\n"
        "...wh....hw.....", pal)
    c.add_outline(OUTLINE_DARK)
    return c


def make_mirror_ghost():
    """Mirror ghost - broken mirror spirit, 24x24."""
    c = Canvas(24, 24)
    # Mirror body
    c.fill_ellipse(12, 11, 8, 7, MIRROR_BODY)
    c.fill_ellipse(12, 10, 6, 5, MIRROR_SHINE)
    # Cracks
    c.draw_line(8, 6, 16, 14, MIRROR_CRACK)
    c.draw_line(14, 5, 9, 15, MIRROR_CRACK)
    c.draw_line(6, 10, 18, 10, MIRROR_CRACK)
    # Edge details
    c.draw_line(5, 7, 5, 14, MIRROR_EDGE)
    c.draw_line(19, 7, 19, 14, MIRROR_EDGE)
    # Eyes
    c.set(10, 9, (65, 55, 85, 210))
    c.set(11, 9, (65, 55, 85, 210))
    c.set(14, 9, (65, 55, 85, 210))
    c.set(15, 9, (65, 55, 85, 210))
    # Mouth
    c.set(11, 12, MIRROR_DARK)
    c.set(12, 12, MIRROR_DARK)
    c.set(13, 12, MIRROR_DARK)
    # Shards trailing below
    c.fill_rect(4, 17, 3, 3, MIRROR_BODY)
    c.set(5, 17, MIRROR_SHINE)
    c.fill_rect(17, 17, 3, 3, MIRROR_BODY)
    c.set(18, 17, MIRROR_SHINE)
    c.fill_rect(9, 19, 2, 3, MIRROR_BODY)
    c.fill_rect(14, 20, 2, 2, MIRROR_BODY)
    c.set(10, 19, MIRROR_SHINE)
    c.add_outline(LIGHT_SKY)
    return c


def make_root_hand():
    """Root hand - earth-bound grasping roots, 16x16."""
    c = Canvas(16, 16)
    pal = {
        ".": T,
        "R": ROOT_BROWN, "D": ROOT_DARK, "L": ROOT_LIGHT,
        "G": ROOT_GREEN, "I": DIRT_BROWN, "i": DIRT_DARK,
        "N": NAIL_GRAY, "n": (140, 130, 120, 255),
    }
    c.from_grid(
        "................\n"
        ".....RN.RN......\n"
        "....RRn.RRn.....\n"
        "....RR.RRR......\n"
        "...LRRRRRL......\n"
        "...RRDRRDRL.....\n"
        "....RRRRRR......\n"
        "....DRRRRRD.....\n"
        ".....RRRR.......\n"
        "......RR........\n"
        ".....GRRG.......\n"
        ".....DGGI.......\n"
        "....iIIIIi......\n"
        "..iIIIIIIIi.....\n"
        ".iIIIIIIIIi.....\n"
        "IIIIIIIIIIII....", pal)
    c.add_outline(OUTLINE_DARK)
    return c


# ============================================================
# Elite Sprites (24x24)
# ============================================================

def _make_elite(base_func):
    """Create an elite version: place in 24x24 canvas with magenta aura."""
    base = base_func()
    c = Canvas(24, 24)
    ox = (24 - base.w) // 2
    oy = (24 - base.h) // 2
    c.blit(base, ox, oy)
    add_aura(c, BRIGHT_MAGENTA, radius=2)
    c.add_outline(BRIGHT_MAGENTA)
    return c


def make_elite_tooth_flower():
    return _make_elite(make_tooth_flower)


def make_elite_spider_doll():
    return _make_elite(make_spider_doll)


def make_elite_candle_ghost():
    return _make_elite(make_candle_ghost)


# ============================================================
# XP Gem Sprites (8x8) with facets
# ============================================================

def _make_gem(base, highlight, shadow):
    c = Canvas(8, 8)
    pal = {".": T, "b": base, "h": highlight, "d": shadow,
           "s": darken(shadow, 0.8)}
    c.from_grid(
        "...hh...\n"
        "..hhbh..\n"
        ".hhbbbh.\n"
        "hbbbbddh\n"
        "hbbdddh.\n"
        ".hbddsh.\n"
        "..hdsh..\n"
        "...hh...", pal)
    return c


def make_gem_small():
    return _make_gem(GEM_BLUE, GEM_BLUE_HI, GEM_BLUE_SH)


def make_gem_medium():
    return _make_gem(GEM_GREEN, GEM_GREEN_HI, GEM_GREEN_SH)


def make_gem_large():
    return _make_gem(GEM_RED, GEM_RED_HI, GEM_RED_SH)


# ============================================================
# Map Drop Sprites (8x8)
# ============================================================

def make_heal_bread():
    c = Canvas(8, 8)
    pal = {".": T, "g": BREAD_GOLD, "c": BREAD_CRUST, "h": BREAD_HI, "s": BREAD_SHADOW}
    c.from_grid(
        "..hgg...\n"
        ".hggggh.\n"
        "gggggggc\n"
        "gggggggc\n"
        "cggggccs\n"
        ".cccccss\n"
        "..ssss..\n"
        "........", pal)
    return c


def make_magnet_charm():
    c = Canvas(8, 8)
    pal = {".": T, "b": MAGNET_BLUE, "h": MAGNET_HI, "d": MAGNET_DARK}
    c.from_grid(
        ".hh..hh.\n"
        ".bb..bb.\n"
        ".bd..db.\n"
        ".bbbbbb.\n"
        "..bhhb..\n"
        "..dbbd..\n"
        "...bb...\n"
        "........", pal)
    return c


def make_purify_bell():
    c = Canvas(8, 8)
    pal = {".": T, "y": BELL_YELLOW, "d": BELL_DARK, "h": BELL_HI, "k": DARK_BROWN}
    c.from_grid(
        "...hh...\n"
        "..hyyh..\n"
        ".yyyyyy.\n"
        ".yyyyyy.\n"
        "dyyyyyyd\n"
        "ddyyyydd\n"
        "..dkkd..\n"
        "...kk...", pal)
    return c


def make_gold_pouch():
    c = Canvas(8, 8)
    pal = {".": T, "g": CROWN_GOLD, "d": GOLD_DARK, "h": BRIGHT_YELLOW, "b": BREAD_CRUST}
    c.from_grid(
        "..bhb...\n"
        ".bggb...\n"
        ".gghgg..\n"
        "ggggggg.\n"
        "ggghggg.\n"
        ".gdddg..\n"
        "..ddd...\n"
        "........", pal)
    return c


def make_treasure_chest():
    c = Canvas(16, 16)
    pal = {".": T, "b": CHEST_BROWN, "d": CHEST_DARK, "g": CHEST_GOLD,
           "h": CHEST_HI, "k": (55, 32, 14, 255)}
    c.from_grid(
        "................\n"
        "....gggggg......\n"
        "...gghhhggg.....\n"
        "..ggbbbbdggg....\n"
        "..gbbbbbbddg....\n"
        "..gbbbgbbddg....\n"
        "..gddddddddg...\n"
        "..gbbbbbbbbdg...\n"
        "..gbbhgggbbdg...\n"
        "..gbbhghgbbdg...\n"
        "..gbbhgggbbdg...\n"
        "..gbbbbbbbbdg...\n"
        "..gddddddddg...\n"
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
    pal = {".": T, "p": MAUVE, "w": BOOK_PAGE, "d": THRONE_DARK, "g": CROWN_GOLD}
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
    pal = {".": T, "p": PASTEL_PINK, "h": (255, 220, 232, 255), "d": (200, 142, 162, 255)}
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
    pal = {".": T, "g": CROWN_GOLD, "d": GOLD_DARK, "h": BRIGHT_YELLOW}
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
           "h": (182, 142, 72, 255)}
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
# Boss: Lord Grimholt (64x64)
# ============================================================

def make_boss_grimholt():
    """Lord Grimholt - enthroned spider-lord with crown and cape."""
    c = Canvas(64, 64)

    # Throne back
    c.fill_rect(20, 5, 24, 30, THRONE_PURPLE)
    c.fill_rect(22, 3, 20, 4, THRONE_HI)
    # Throne decorative top
    c.fill_rect(20, 3, 3, 3, CROWN_GOLD)
    c.fill_rect(41, 3, 3, 3, CROWN_GOLD)
    c.fill_rect(30, 2, 4, 3, CROWN_GOLD)
    c.set(31, 1, BRIGHT_YELLOW)
    c.set(32, 1, BRIGHT_YELLOW)

    # Human torso
    c.fill_ellipse(32, 22, 8, 6, GRIM_SKIN)
    c.fill_ellipse(32, 22, 6, 4, GRIM_SKIN_SH)
    # Face
    c.fill_ellipse(32, 16, 7, 6, GRIM_SKIN)
    # Shading on face
    c.fill_ellipse(32, 17, 5, 4, GRIM_SKIN_SH)
    # Eyes - red and glowing
    c.fill_rect(28, 14, 3, 2, EYE_WHITE)
    c.fill_rect(33, 14, 3, 2, EYE_WHITE)
    c.set(29, 14, EYE_RED)
    c.set(30, 14, EYE_RED)
    c.set(34, 14, EYE_RED)
    c.set(35, 14, EYE_RED)
    # Wide grin with teeth
    for x in range(26, 39):
        c.set(x, 19, DARK_RED)
    for x in range(27, 38):
        c.set(x, 20, (42, 12, 22, 255))
    for x in range(27, 38, 2):
        c.set(x, 19, WHITE)

    # Crown
    c.fill_rect(26, 9, 12, 3, CROWN_GOLD)
    for x in range(27, 37, 3):
        c.set(x, 8, CROWN_GOLD)
        c.set(x, 7, BRIGHT_YELLOW)
    # Crown gems
    c.set(28, 10, CROWN_GEM)
    c.set(32, 10, CROWN_GEM)
    c.set(36, 10, CROWN_GEM)

    # Arms on armrests
    c.fill_rect(16, 20, 5, 3, GRIM_SKIN)
    c.fill_rect(17, 21, 3, 2, GRIM_SKIN_SH)
    c.fill_rect(43, 20, 5, 3, GRIM_SKIN)
    c.fill_rect(44, 21, 3, 2, GRIM_SKIN_SH)

    # Cape / robe
    c.fill_rect(22, 24, 20, 12, CAPE_MID)
    c.fill_rect(24, 30, 16, 8, CAPE_DARK)
    c.fill_rect(23, 26, 2, 8, CAPE_HI)
    c.fill_rect(39, 26, 2, 8, CAPE_HI)

    # Throne seat
    c.fill_rect(16, 30, 32, 6, THRONE_DARK)
    c.fill_rect(18, 28, 28, 3, THRONE_PURPLE)
    # Throne seat highlights
    c.fill_rect(19, 28, 2, 1, THRONE_HI)
    c.fill_rect(43, 28, 2, 1, THRONE_HI)

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
    # Leg joint highlights
    for jx, jy in [(5, 45), (8, 50), (59, 45), (56, 50)]:
        c.fill_circle(jx, jy, 1, leg_joint)
    # Leg tips
    for tx, ty in [(2, 55), (6, 58), (62, 55), (58, 58)]:
        c.set(tx, ty, THRONE_HI)

    # Throne front legs
    c.fill_rect(20, 36, 4, 20, THRONE_DARK)
    c.fill_rect(40, 36, 4, 20, THRONE_DARK)
    c.fill_rect(21, 36, 2, 20, THRONE_PURPLE)
    c.fill_rect(41, 36, 2, 20, THRONE_PURPLE)
    c.fill_rect(20, 54, 5, 3, THRONE_PURPLE)
    c.fill_rect(39, 54, 5, 3, THRONE_PURPLE)
    # Claw feet
    c.fill_rect(19, 56, 2, 2, THRONE_HI)
    c.fill_rect(44, 56, 2, 2, THRONE_HI)

    c.add_outline(darken(THRONE_DARK, 0.5))
    return c


def make_boss_witch_messenger():
    """Witch's Herald - 96x96, crow-headed humanoid with flowing cape."""
    c = Canvas(96, 96)

    # Cape (wide, flowing, with shading)
    for y in range(35, 85):
        spread = int((y - 35) * 0.7)
        left = 30 - spread
        right = 66 + spread
        for x in range(max(left, 0), min(right, 96)):
            # Shading: darker at edges, lighter in center
            dist_from_center = abs(x - 48) / max(abs(right - left) / 2.0, 1.0)
            if dist_from_center > 0.8:
                shade = CAPE_DARK
            elif dist_from_center > 0.5:
                shade = CAPE_MID
            elif (x + y) % 7 == 0:
                shade = CAPE_HI
            else:
                shade = CAPE_MID
            c.set(x, y, shade)

    # Body
    c.fill_ellipse(48, 50, 12, 18, CAPE_MID)
    c.fill_ellipse(48, 50, 10, 16, CAPE_DARK)
    # Center detail
    c.fill_rect(46, 40, 4, 25, CAPE_HI)

    # Hands reaching from cape (left side)
    c.fill_rect(15, 55, 4, 3, GRIM_SKIN_SH)
    c.fill_rect(12, 54, 3, 2, GRIM_SKIN)
    c.fill_rect(10, 53, 2, 1, GRIM_SKIN)
    c.fill_rect(13, 60, 4, 3, GRIM_SKIN_SH)
    c.fill_rect(10, 59, 3, 2, GRIM_SKIN)
    # Right side
    c.fill_rect(77, 55, 4, 3, GRIM_SKIN_SH)
    c.fill_rect(81, 54, 3, 2, GRIM_SKIN)
    c.fill_rect(84, 53, 2, 1, GRIM_SKIN)
    c.fill_rect(79, 60, 4, 3, GRIM_SKIN_SH)
    c.fill_rect(83, 59, 3, 2, GRIM_SKIN)

    # Crow head
    c.fill_ellipse(48, 25, 12, 10, CROW_BLACK)
    c.fill_ellipse(48, 25, 10, 8, CROW_DARK)
    # Head highlight
    c.fill_ellipse(46, 22, 4, 3, CROW_MID)
    # Beak
    c.fill_rect(46, 32, 5, 2, CROW_BEAK)
    c.fill_rect(44, 34, 9, 2, CROW_BEAK)
    c.fill_rect(45, 34, 7, 1, CROW_BEAK_HI)
    c.fill_rect(46, 36, 5, 1, darken(CROW_BEAK))
    # Eyes (glowing red, larger)
    c.fill_rect(42, 23, 3, 3, EYE_RED)
    c.fill_rect(51, 23, 3, 3, EYE_RED)
    c.set(43, 24, WHITE)
    c.set(52, 24, WHITE)
    # Eye glow aura
    for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
        c.set(42 + dx, 23 + dy, (200, 40, 40, 80))
        c.set(54 + dx, 23 + dy, (200, 40, 40, 80))

    # Feather tufts
    for fx in [38, 42, 54, 58]:
        c.draw_line(fx, 18, fx + (1 if fx < 48 else -1), 14, CROW_BLACK)
        c.set(fx, 15, CROW_MID)

    # Taloned feet
    for foot_x in [38, 55]:
        c.fill_rect(foot_x, 82, 4, 3, darken(CROW_BLACK))
        c.set(foot_x - 1, 84, CROW_BEAK)
        c.set(foot_x + 4, 84, CROW_BEAK)
        c.set(foot_x + 1, 85, CROW_BEAK)
        c.set(foot_x + 2, 85, CROW_BEAK)

    # More hands from cape bottom
    for hx in [25, 35, 60, 70]:
        c.fill_rect(hx, 78, 3, 4, GRIM_SKIN_SH)
        c.set(hx, 82, GRIM_SKIN)
        c.set(hx + 2, 82, GRIM_SKIN)

    # Dark aura particles (more numerous)
    for ax, ay in [(20, 40), (75, 38), (18, 70), (78, 72),
                   (30, 80), (65, 82), (15, 50), (82, 48),
                   (25, 65), (72, 68)]:
        c.set(ax, ay, (42, 22, 62, 110))
        c.set(ax + 1, ay, (32, 16, 52, 85))
        c.set(ax, ay + 1, (32, 16, 52, 65))

    c.add_outline(darken(CAPE_DARK, 0.5))
    return c


# ============================================================
# Death Particle (4x4)
# ============================================================

def make_death_particle():
    c = Canvas(4, 4)
    pal = {".": T, "W": WHITE, "P": HAIR_PINK}
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
        # Characters (24x24 sprite sheets, 2 frames = 48x24)
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
