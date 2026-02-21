#!/usr/bin/env python3
"""Map tiles, decorations, UI icons, and SFX generator for Cursed Night.

Generates:
- Ground tiles (32x32, seamless) for 2 stages
- Decoration sprites (16x16 ~ 32x32) for 2 stages
- Weapon icons (16x16) for HUD
- Passive icons (16x16) for HUD
- SFX (WAV, procedural) for game events

Usage: python3 tools/generate_map_and_ui.py
"""
import os
import struct
import zlib
import math
import random

BASE_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


# ============================================================
# PNG Writer
# ============================================================

def write_png(filepath, canvas):
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
    os.makedirs(os.path.dirname(filepath) or ".", exist_ok=True)
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

    def fill(self, color):
        for y in range(self.h):
            for x in range(self.w):
                self.data[y][x] = color

    def noise_fill(self, base, variation, seed=0):
        """Fill with noisy color based on base color and variation amount."""
        rng = random.Random(seed)
        for y in range(self.h):
            for x in range(self.w):
                r = max(0, min(255, base[0] + rng.randint(-variation, variation)))
                g = max(0, min(255, base[1] + rng.randint(-variation, variation)))
                b = max(0, min(255, base[2] + rng.randint(-variation, variation)))
                self.data[y][x] = (r, g, b, base[3])

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
        outlined = Canvas(self.w, self.h)
        for y in range(self.h):
            for x in range(self.w):
                outlined.data[y][x] = self.data[y][x]
        for y in range(self.h):
            for x in range(self.w):
                if self.data[y][x][3] == 0:
                    for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                        nx, ny = x + dx, y + dy
                        if 0 <= nx < self.w and 0 <= ny < self.h:
                            if self.data[ny][nx][3] > 0:
                                outlined.data[y][x] = color
                                break
        return outlined


# ============================================================
# WAV Writer
# ============================================================

def write_wav(filepath, samples, sample_rate=22050):
    """Write 16-bit mono WAV file from float samples (-1.0 to 1.0)."""
    os.makedirs(os.path.dirname(filepath) or ".", exist_ok=True)
    num_samples = len(samples)
    data_size = num_samples * 2
    with open(filepath, "wb") as f:
        # RIFF header
        f.write(b"RIFF")
        f.write(struct.pack("<I", 36 + data_size))
        f.write(b"WAVE")
        # fmt chunk
        f.write(b"fmt ")
        f.write(struct.pack("<IHHIIHH", 16, 1, 1, sample_rate, sample_rate * 2, 2, 16))
        # data chunk
        f.write(b"data")
        f.write(struct.pack("<I", data_size))
        for s in samples:
            val = max(-1.0, min(1.0, s))
            f.write(struct.pack("<h", int(val * 32767)))


def gen_square(freq, duration, volume=0.3, sample_rate=22050):
    """Generate square wave samples."""
    n = int(sample_rate * duration)
    period = sample_rate / freq if freq > 0 else 1
    return [volume * (1.0 if (i % int(period)) < int(period / 2) else -1.0) for i in range(n)]


def gen_noise(duration, volume=0.3, sample_rate=22050):
    """Generate white noise samples."""
    rng = random.Random(42)
    n = int(sample_rate * duration)
    return [volume * (rng.random() * 2 - 1) for _ in range(n)]


def gen_sine(freq, duration, volume=0.3, sample_rate=22050):
    """Generate sine wave samples."""
    n = int(sample_rate * duration)
    return [volume * math.sin(2 * math.pi * freq * i / sample_rate) for i in range(n)]


def apply_envelope(samples, attack=0.01, decay=0.0, sustain=1.0, release=0.05, sample_rate=22050):
    """Apply ADSR envelope to samples."""
    n = len(samples)
    a_len = int(attack * sample_rate)
    r_len = int(release * sample_rate)
    result = []
    for i in range(n):
        if i < a_len:
            env = i / max(a_len, 1)
        elif i >= n - r_len:
            env = (n - i) / max(r_len, 1)
        else:
            env = sustain
        result.append(samples[i] * env)
    return result


def pitch_sweep(start_freq, end_freq, duration, volume=0.3, sample_rate=22050):
    """Generate frequency sweep."""
    n = int(sample_rate * duration)
    samples = []
    for i in range(n):
        t = i / n
        freq = start_freq + (end_freq - start_freq) * t
        samples.append(volume * math.sin(2 * math.pi * freq * i / sample_rate))
    return samples


def mix(a, b):
    """Mix two sample arrays."""
    n = max(len(a), len(b))
    result = []
    for i in range(n):
        va = a[i] if i < len(a) else 0.0
        vb = b[i] if i < len(b) else 0.0
        result.append(max(-1.0, min(1.0, va + vb)))
    return result


def concat(*arrays):
    """Concatenate sample arrays."""
    result = []
    for a in arrays:
        result.extend(a)
    return result


# ============================================================
# Color Palette (from GDD Section 3.2)
# ============================================================

# Background
DARK_PURPLE = (45, 27, 61, 255)
DARK_GREEN = (26, 58, 42, 255)
PURPLE_SHADOW = (92, 45, 110, 255)
DARK_BROWN = (61, 36, 21, 255)
MID_PURPLE = (74, 56, 96, 255)

# Accent
BRIGHT_PINK = (255, 107, 157, 255)
NEON_GREEN = (57, 255, 20, 255)
WARM_ORANGE = (255, 159, 67, 255)
CYAN_BLUE = (116, 208, 241, 255)
BRIGHT_MAGENTA = (255, 107, 214, 255)

# Object
WARM_BEIGE = (245, 222, 179, 255)
PASTEL_PINK = (255, 182, 193, 255)
DARK_RED = (139, 0, 0, 255)
GOLD = (255, 215, 0, 255)
WHITE = (255, 255, 255, 255)
BLACK = (0, 0, 0, 255)

# Tile-specific
COBBLE_BASE = (35, 22, 45, 255)
COBBLE_LIGHT = (50, 35, 60, 255)
COBBLE_DARK = (25, 15, 35, 255)
COBBLE_LINE = (20, 12, 28, 255)

DIRT_BASE = (30, 28, 22, 255)
DIRT_LIGHT = (42, 38, 30, 255)
DIRT_DARK = (20, 18, 14, 255)
DIRT_BROWN = (50, 35, 25, 255)

STONE_GRAY = (80, 75, 85, 255)
STONE_DARK = (55, 50, 60, 255)
IRON_GRAY = (70, 65, 75, 255)
IRON_DARK = (45, 40, 50, 255)
WOOD_BROWN = (90, 60, 35, 255)
WOOD_DARK = (60, 40, 25, 255)


# ============================================================
# Ground Tiles (32x32, seamless)
# ============================================================

def generate_town_tile():
    """Stage 1: Dark cobblestone ground tile (32x32, seamless)."""
    c = Canvas(32, 32)
    c.noise_fill(COBBLE_BASE, 5, seed=123)

    # Stone patterns - arranged for seamless tiling
    stones = [
        (0, 0, 7, 5), (8, 0, 6, 5), (15, 0, 8, 6), (24, 0, 8, 5),
        (0, 6, 9, 5), (10, 6, 7, 6), (18, 7, 6, 5), (25, 6, 7, 5),
        (0, 12, 6, 6), (7, 13, 8, 5), (16, 13, 7, 5), (24, 12, 8, 6),
        (0, 19, 8, 5), (9, 19, 7, 6), (17, 19, 6, 5), (24, 19, 8, 5),
        (0, 25, 7, 7), (8, 25, 8, 7), (17, 25, 7, 7), (25, 25, 7, 7),
    ]

    rng = random.Random(456)
    for sx, sy, sw, sh in stones:
        lr = rng.randint(-5, 8)
        stone_col = (
            min(255, COBBLE_LIGHT[0] + lr),
            min(255, COBBLE_LIGHT[1] + lr),
            min(255, COBBLE_LIGHT[2] + lr),
            255
        )
        for dy in range(sh):
            for dx in range(sw):
                px = (sx + dx) % 32
                py = (sy + dy) % 32
                c.set(px, py, stone_col)

    # Grout lines between stones (wrap for seamless)
    for sx, sy, sw, sh in stones:
        for dx in range(sw):
            px = (sx + dx) % 32
            py_top = sy % 32
            py_bot = (sy + sh) % 32
            if rng.random() > 0.3:
                c.set(px, py_top, COBBLE_LINE)
            if rng.random() > 0.3:
                c.set(px, py_bot, COBBLE_LINE)
        for dy in range(sh):
            py = (sy + dy) % 32
            px_left = sx % 32
            px_right = (sx + sw) % 32
            if rng.random() > 0.3:
                c.set(px_left, py, COBBLE_LINE)
            if rng.random() > 0.3:
                c.set(px_right, py, COBBLE_LINE)

    # Dark spots
    for _ in range(6):
        dx = rng.randint(0, 31)
        dy = rng.randint(0, 31)
        c.set(dx, dy, COBBLE_DARK)

    # Cracks on random stones
    crack_col = (18, 10, 25, 255)
    c.draw_line(5, 2, 3, 4, crack_col)
    c.draw_line(22, 8, 24, 11, crack_col)
    c.draw_line(12, 20, 14, 22, crack_col)

    # Moss patches on edges
    moss_col = (25, 40, 20, 200)
    for mx, my in [(0, 6), (1, 6), (0, 7), (31, 19), (31, 20), (30, 20)]:
        c.set(mx, my, moss_col)

    # Subtle blood stain
    c.set(14, 10, (80, 15, 15, 180))
    c.set(15, 10, (70, 10, 10, 150))
    c.set(14, 11, (60, 10, 10, 120))

    # Small puddle
    puddle_col = (20, 18, 35, 160)
    for px, py in [(26, 14), (27, 14), (26, 15), (27, 15), (28, 15)]:
        c.set(px, py, puddle_col)

    return c


def generate_town_tile_b():
    """Stage 1 variant B: cobblestone with more wear (32x32, seamless)."""
    c = Canvas(32, 32)
    c.noise_fill(COBBLE_BASE, 7, seed=555)

    stones = [
        (0, 0, 8, 6), (9, 0, 7, 5), (17, 0, 7, 6), (25, 0, 7, 6),
        (0, 7, 6, 5), (7, 6, 8, 6), (16, 7, 8, 5), (25, 7, 7, 5),
        (0, 13, 7, 6), (8, 13, 7, 5), (16, 13, 8, 6), (25, 13, 7, 6),
        (0, 20, 8, 5), (9, 19, 6, 6), (16, 20, 8, 5), (25, 20, 7, 5),
        (0, 26, 7, 6), (8, 26, 8, 6), (17, 26, 7, 6), (25, 26, 7, 6),
    ]

    rng = random.Random(777)
    for sx, sy, sw, sh in stones:
        lr = rng.randint(-8, 5)
        stone_col = (
            max(0, min(255, COBBLE_LIGHT[0] + lr - 3)),
            max(0, min(255, COBBLE_LIGHT[1] + lr - 3)),
            max(0, min(255, COBBLE_LIGHT[2] + lr - 3)),
            255
        )
        for dy in range(sh):
            for dx in range(sw):
                c.set((sx + dx) % 32, (sy + dy) % 32, stone_col)

    for sx, sy, sw, sh in stones:
        for dx in range(sw):
            px = (sx + dx) % 32
            if rng.random() > 0.25:
                c.set(px, sy % 32, COBBLE_LINE)
            if rng.random() > 0.25:
                c.set(px, (sy + sh) % 32, COBBLE_LINE)
        for dy in range(sh):
            py = (sy + dy) % 32
            if rng.random() > 0.25:
                c.set(sx % 32, py, COBBLE_LINE)
            if rng.random() > 0.25:
                c.set((sx + sw) % 32, py, COBBLE_LINE)

    # More cracks
    crack_col = (18, 10, 25, 255)
    c.draw_line(3, 1, 6, 5, crack_col)
    c.draw_line(6, 5, 5, 8, crack_col)
    c.draw_line(20, 15, 23, 18, crack_col)
    c.draw_line(10, 25, 13, 28, crack_col)

    # Moss in grout lines
    moss_col = (25, 40, 20, 180)
    for _ in range(8):
        c.set(rng.randint(0, 31), rng.randint(0, 31), moss_col)

    # Larger puddle with reflection
    puddle_dark = (15, 12, 30, 180)
    puddle_light = (25, 22, 45, 140)
    for px, py in [(8, 10), (9, 10), (10, 10), (8, 11), (9, 11), (10, 11), (9, 12)]:
        c.set(px, py, puddle_dark)
    c.set(9, 10, puddle_light)

    return c


def generate_cemetery_tile():
    """Stage 2: Dark dirt ground tile (32x32, seamless)."""
    c = Canvas(32, 32)
    c.noise_fill(DIRT_BASE, 6, seed=789)

    rng = random.Random(101)

    # Dirt patches
    for _ in range(10):
        px = rng.randint(0, 31)
        py = rng.randint(0, 31)
        col = DIRT_LIGHT if rng.random() > 0.5 else DIRT_DARK
        c.set(px, py, col)
        for ddx, ddy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
            if rng.random() > 0.35:
                c.set((px + ddx) % 32, (py + ddy) % 32, col)

    # Small stones
    for _ in range(6):
        px = rng.randint(0, 31)
        py = rng.randint(0, 31)
        c.set(px, py, (50, 48, 55, 255))

    # Dead grass tufts
    grass_col = (35, 45, 25, 255)
    grass_dry = (45, 40, 20, 255)
    for _ in range(6):
        gx = rng.randint(0, 31)
        gy = rng.randint(0, 31)
        gc = grass_col if rng.random() > 0.5 else grass_dry
        c.set(gx, gy, gc)
        c.set((gx + 1) % 32, gy - 1 if gy > 0 else 31, gc)
        if rng.random() > 0.5:
            c.set((gx - 1) % 32, gy - 1 if gy > 0 else 31, gc)

    # Worm tracks
    worm_col = (22, 20, 16, 255)
    wx, wy = 5, 5
    for _ in range(8):
        c.set(wx % 32, wy % 32, worm_col)
        wx += rng.choice([-1, 0, 1])
        wy += rng.choice([0, 1])

    return c


def generate_cemetery_tile_b():
    """Stage 2 variant B: muddier dirt (32x32, seamless)."""
    c = Canvas(32, 32)
    c.noise_fill((25, 22, 18, 255), 8, seed=202)

    rng = random.Random(303)

    # Mud patches
    mud_col = (20, 16, 12, 255)
    mud_wet = (18, 14, 10, 220)
    for _ in range(6):
        mx = rng.randint(0, 31)
        my = rng.randint(0, 31)
        r = rng.randint(1, 3)
        for dy in range(-r, r + 1):
            for dx in range(-r, r + 1):
                if dx * dx + dy * dy <= r * r:
                    cc = mud_wet if dx * dx + dy * dy <= (r - 1) * (r - 1) else mud_col
                    c.set((mx + dx) % 32, (my + dy) % 32, cc)

    # Scattered bones
    bone_col = (160, 150, 130, 200)
    c.set(10, 8, bone_col)
    c.set(11, 8, bone_col)
    c.set(12, 8, bone_col)
    c.set(22, 20, bone_col)
    c.set(23, 20, bone_col)

    # Dead roots
    root_col = (35, 25, 18, 255)
    c.draw_line(0, 15, 5, 18, root_col)
    c.draw_line(25, 5, 31, 8, root_col)

    return c


# ============================================================
# Decoration Sprites
# ============================================================

def generate_twisted_tree():
    """Twisted tree decoration (32x32)."""
    c = Canvas(32, 32)
    trunk = (55, 35, 25, 255)
    trunk_dark = (40, 25, 18, 255)
    branch = (50, 32, 22, 255)
    leaf_dead = (45, 35, 20, 255)

    # Trunk
    c.fill_rect(14, 12, 4, 18, trunk)
    c.fill_rect(13, 14, 1, 14, trunk_dark)
    c.fill_rect(18, 16, 1, 10, trunk_dark)

    # Roots
    c.set(12, 29, trunk_dark)
    c.set(11, 30, trunk_dark)
    c.set(19, 29, trunk_dark)
    c.set(20, 30, trunk_dark)

    # Branches
    c.draw_line(15, 12, 8, 5, branch)
    c.draw_line(16, 12, 24, 4, branch)
    c.draw_line(14, 16, 7, 11, branch)
    c.draw_line(17, 14, 25, 10, branch)

    # Dead leaf clusters
    for px, py in [(7, 4), (8, 5), (9, 4), (24, 3), (25, 4), (23, 4),
                   (6, 10), (7, 10), (25, 9), (26, 10)]:
        c.set(px, py, leaf_dead)

    # Eyes on trunk (creepy)
    c.set(15, 17, (200, 50, 50, 255))
    c.set(17, 17, (200, 50, 50, 255))

    return c.add_outline((20, 15, 30, 200))


def generate_broken_barrel():
    """Broken barrel decoration (16x16)."""
    c = Canvas(16, 16)
    body = WOOD_BROWN
    dark = WOOD_DARK
    band = IRON_GRAY

    # Barrel body
    c.fill_rect(3, 4, 10, 10, body)
    c.fill_rect(4, 3, 8, 1, body)
    c.fill_rect(4, 14, 8, 1, body)

    # Iron bands
    c.fill_rect(3, 6, 10, 1, band)
    c.fill_rect(3, 11, 10, 1, band)

    # Wood grain
    for y in range(4, 14):
        c.set(5, y, dark)
        c.set(9, y, dark)

    # Broken top
    c.set(6, 3, (0, 0, 0, 0))
    c.set(7, 2, body)
    c.set(8, 3, (0, 0, 0, 0))

    return c.add_outline((20, 15, 10, 200))


def generate_lamp_post():
    """Bent lamp post decoration (16x32)."""
    c = Canvas(16, 32)
    iron = IRON_GRAY
    iron_d = IRON_DARK
    glow = WARM_ORANGE

    # Post
    c.fill_rect(7, 8, 2, 22, iron)
    c.fill_rect(6, 28, 4, 2, iron_d)  # base

    # Bent top
    c.draw_line(8, 8, 10, 5, iron)
    c.draw_line(10, 5, 11, 4, iron)

    # Lamp head
    c.fill_rect(10, 2, 3, 3, iron_d)

    # Dim glow
    c.set(11, 3, glow)
    c.set(11, 5, (glow[0], glow[1], glow[2], 80))
    c.set(10, 5, (glow[0], glow[1], glow[2], 50))
    c.set(12, 5, (glow[0], glow[1], glow[2], 50))

    return c.add_outline((20, 15, 30, 180))


def generate_blood_spot():
    """Blood spot decoration (16x16)."""
    c = Canvas(16, 16)
    blood = (120, 10, 10, 180)
    blood_dark = (80, 5, 5, 150)

    c.fill_circle(8, 8, 3, blood)
    c.fill_circle(7, 7, 2, blood_dark)
    c.set(5, 6, blood)
    c.set(11, 9, blood)
    c.set(10, 5, (100, 8, 8, 100))
    c.set(6, 10, (100, 8, 8, 100))

    return c


def generate_gravestone_a():
    """Gravestone type A - rounded top (16x16)."""
    c = Canvas(16, 16)
    stone = STONE_GRAY
    dark = STONE_DARK

    # Base
    c.fill_rect(4, 7, 8, 8, stone)
    c.fill_rect(3, 14, 10, 2, dark)

    # Rounded top
    c.fill_rect(5, 5, 6, 2, stone)
    c.set(6, 4, stone)
    c.set(7, 4, stone)
    c.set(8, 4, stone)
    c.set(9, 4, stone)
    c.set(7, 3, stone)
    c.set(8, 3, stone)

    # Cross engraving
    c.set(7, 6, dark)
    c.set(8, 6, dark)
    c.set(7, 7, dark)
    c.set(8, 7, dark)
    c.set(6, 6, dark)
    c.set(9, 6, dark)
    c.set(7, 8, dark)
    c.set(8, 8, dark)

    # Crack
    c.draw_line(9, 5, 10, 9, (40, 38, 42, 255))

    return c.add_outline((25, 20, 30, 200))


def generate_gravestone_b():
    """Gravestone type B - rectangular with cross (16x16)."""
    c = Canvas(16, 16)
    stone = STONE_GRAY
    dark = STONE_DARK

    # Cross shape
    c.fill_rect(6, 3, 4, 12, stone)
    c.fill_rect(4, 5, 8, 3, stone)

    # Base
    c.fill_rect(3, 14, 10, 2, dark)

    # Shading
    c.fill_rect(7, 3, 2, 1, (90, 85, 95, 255))
    c.set(10, 6, dark)
    c.set(6, 14, dark)

    # Moss
    c.set(5, 12, (35, 50, 30, 200))
    c.set(4, 7, (35, 50, 30, 200))

    return c.add_outline((25, 20, 30, 200))


def generate_dead_tree():
    """Dead tree for cemetery (32x32)."""
    c = Canvas(32, 32)
    trunk = (45, 30, 22, 255)
    trunk_d = (30, 20, 15, 255)

    # Thick trunk
    c.fill_rect(13, 10, 6, 20, trunk)
    c.fill_rect(12, 12, 1, 16, trunk_d)
    c.fill_rect(19, 14, 1, 12, trunk_d)

    # Roots
    c.draw_line(13, 29, 9, 31, trunk_d)
    c.draw_line(18, 29, 22, 31, trunk_d)

    # Bare branches
    c.draw_line(15, 10, 6, 3, trunk)
    c.draw_line(16, 10, 25, 2, trunk)
    c.draw_line(14, 14, 4, 8, trunk)
    c.draw_line(18, 12, 27, 7, trunk)
    c.draw_line(6, 3, 3, 1, trunk_d)
    c.draw_line(25, 2, 28, 1, trunk_d)

    # Hollow
    c.fill_rect(14, 18, 3, 4, (15, 10, 8, 255))

    return c.add_outline((15, 10, 20, 180))


def generate_iron_fence():
    """Iron fence segment (16x16)."""
    c = Canvas(16, 16)
    iron = IRON_GRAY
    iron_d = IRON_DARK

    # Horizontal bars
    c.fill_rect(0, 5, 16, 1, iron_d)
    c.fill_rect(0, 12, 16, 1, iron_d)

    # Vertical bars with spear tops
    for bx in [2, 7, 12]:
        c.fill_rect(bx, 3, 2, 12, iron)
        c.set(bx, 2, iron)
        c.set(bx + 1, 2, iron)
        c.set(bx, 1, iron_d)  # spear point
        c.set(bx + 1, 1, iron_d)

    return c


def generate_skull():
    """Small skull decoration (8x8)."""
    c = Canvas(8, 8)
    bone = (200, 190, 180, 255)
    dark = (80, 70, 65, 255)

    # Skull shape
    c.fill_rect(2, 1, 4, 4, bone)
    c.set(1, 2, bone)
    c.set(1, 3, bone)
    c.set(6, 2, bone)
    c.set(6, 3, bone)

    # Eye sockets
    c.set(3, 2, dark)
    c.set(5, 2, dark)

    # Jaw
    c.fill_rect(3, 5, 3, 1, bone)
    c.set(3, 6, dark)
    c.set(4, 6, bone)
    c.set(5, 6, dark)

    return c.add_outline((30, 25, 35, 200))


def generate_well():
    """Old broken well decoration (16x16) for town stage."""
    c = Canvas(16, 16)
    stone = STONE_GRAY
    dark = STONE_DARK
    water = (20, 25, 50, 200)
    wood = WOOD_BROWN

    # Stone ring
    c.fill_rect(3, 6, 10, 8, stone)
    c.fill_rect(4, 5, 8, 1, stone)
    c.fill_rect(4, 14, 8, 2, dark)
    # Interior (dark water)
    c.fill_rect(5, 7, 6, 6, water)
    c.set(6, 8, (25, 30, 60, 180))
    # Wooden frame posts
    c.fill_rect(4, 1, 2, 5, wood)
    c.fill_rect(10, 1, 2, 5, wood)
    # Crossbar
    c.fill_rect(4, 1, 8, 1, wood)
    # Rope
    c.set(8, 2, (120, 100, 70, 255))
    c.set(8, 3, (120, 100, 70, 255))
    c.set(8, 4, (120, 100, 70, 255))

    return c.add_outline((20, 15, 30, 200))


def generate_cart():
    """Overturned cart decoration (32x16) for town stage."""
    c = Canvas(32, 16)
    wood = WOOD_BROWN
    wood_d = WOOD_DARK
    wheel = IRON_GRAY
    wheel_d = IRON_DARK

    # Cart body (tilted)
    c.fill_rect(4, 4, 20, 8, wood)
    c.fill_rect(3, 5, 1, 6, wood_d)
    c.fill_rect(24, 5, 1, 6, wood_d)
    # Planks
    for px in [8, 14, 20]:
        for py in range(4, 12):
            c.set(px, py, wood_d)
    # Wheel
    c.fill_circle(27, 10, 3, wheel)
    c.fill_circle(27, 10, 1, wheel_d)
    # Broken wheel spokes
    c.draw_line(27, 7, 27, 13, wheel_d)
    c.draw_line(24, 10, 30, 10, wheel_d)
    # Scattered goods
    c.fill_rect(1, 12, 3, 2, (150, 120, 80, 200))

    return c.add_outline((20, 15, 10, 180))


def generate_mushroom_cluster():
    """Glowing mushroom cluster (16x16) for cemetery stage."""
    c = Canvas(16, 16)
    stem = (60, 50, 45, 255)
    cap1 = (100, 40, 120, 255)
    cap2 = (80, 50, 110, 255)
    glow = (140, 80, 160, 180)

    # Large mushroom
    c.fill_rect(6, 8, 2, 5, stem)
    c.fill_rect(4, 6, 6, 3, cap1)
    c.fill_rect(5, 5, 4, 1, cap1)
    c.set(5, 7, glow)
    c.set(8, 7, glow)

    # Small mushroom
    c.fill_rect(10, 10, 2, 4, stem)
    c.fill_rect(9, 8, 4, 3, cap2)
    c.set(10, 9, glow)

    # Tiny mushroom
    c.set(3, 12, stem)
    c.fill_rect(2, 11, 3, 1, cap2)

    # Glow spots on ground
    c.set(5, 13, (100, 60, 120, 60))
    c.set(7, 14, (100, 60, 120, 40))
    c.set(11, 14, (80, 50, 100, 50))

    return c.add_outline((20, 15, 30, 160))


def generate_broken_coffin():
    """Broken coffin emerging from ground (16x16) for cemetery."""
    c = Canvas(16, 16)
    wood = (70, 45, 30, 255)
    wood_d = (45, 30, 20, 255)
    dirt = DIRT_BASE
    bone = (180, 170, 155, 220)

    # Ground line
    c.fill_rect(0, 12, 16, 4, dirt)
    # Coffin (angled, partially buried)
    c.fill_rect(4, 4, 8, 9, wood)
    c.fill_rect(3, 5, 1, 7, wood_d)
    c.fill_rect(12, 5, 1, 7, wood_d)
    # Lid (broken, tilted)
    c.fill_rect(5, 3, 6, 2, wood)
    c.set(11, 3, (0, 0, 0, 0))
    c.set(10, 2, wood)
    # Cross on lid
    c.set(7, 4, wood_d)
    c.set(8, 4, wood_d)
    c.set(7, 3, wood_d)
    # Arm bone sticking out
    c.set(6, 6, bone)
    c.set(5, 7, bone)
    c.set(4, 7, bone)
    # Dirt mound around base
    c.set(2, 12, (35, 32, 26, 255))
    c.set(13, 12, (35, 32, 26, 255))

    return c.add_outline((15, 10, 20, 180))


# ============================================================
# Weapon Icons (16x16)
# ============================================================

def generate_weapon_icon_scissors():
    c = Canvas(16, 16)
    metal = (200, 200, 210, 255)
    handle = (180, 50, 50, 255)
    # Blades
    c.draw_line(3, 3, 8, 8, metal)
    c.draw_line(12, 3, 7, 8, metal)
    c.draw_line(4, 3, 9, 8, metal)
    c.draw_line(11, 3, 6, 8, metal)
    # Pivot
    c.fill_circle(8, 8, 1, (150, 150, 160, 255))
    # Handles
    c.draw_line(6, 9, 3, 13, handle)
    c.draw_line(9, 9, 12, 13, handle)
    c.fill_circle(3, 13, 1, handle)
    c.fill_circle(12, 13, 1, handle)
    return c.add_outline(BLACK)


def generate_weapon_icon_bible():
    c = Canvas(16, 16)
    cover = (100, 50, 130, 255)
    page = (220, 210, 190, 255)
    # Book cover
    c.fill_rect(3, 2, 10, 12, cover)
    # Pages
    c.fill_rect(4, 3, 8, 10, page)
    # Spine
    c.fill_rect(3, 2, 1, 12, (70, 35, 90, 255))
    # Cross on cover
    c.fill_rect(7, 4, 2, 6, GOLD)
    c.fill_rect(5, 6, 6, 2, GOLD)
    return c.add_outline(BLACK)


def generate_weapon_icon_candle():
    c = Canvas(16, 16)
    wax = WARM_BEIGE
    flame_out = WARM_ORANGE
    flame_in = (255, 230, 100, 255)
    # Candle body
    c.fill_rect(6, 6, 4, 8, wax)
    c.fill_rect(5, 13, 6, 2, (180, 160, 130, 255))
    # Wick
    c.set(8, 5, (60, 50, 40, 255))
    # Flame
    c.fill_rect(7, 2, 2, 3, flame_out)
    c.set(7, 1, flame_out)
    c.set(8, 1, flame_out)
    c.set(7, 3, flame_in)
    c.set(8, 3, flame_in)
    return c.add_outline(BLACK)


def generate_weapon_icon_bouquet():
    c = Canvas(16, 16)
    stem = (60, 120, 40, 255)
    petal1 = PASTEL_PINK
    petal2 = (200, 100, 150, 255)
    petal3 = (255, 150, 100, 255)
    # Stems
    c.draw_line(7, 8, 5, 14, stem)
    c.draw_line(8, 8, 8, 14, stem)
    c.draw_line(8, 8, 10, 14, stem)
    # Flowers
    c.fill_circle(6, 4, 2, petal1)
    c.fill_circle(10, 4, 2, petal2)
    c.fill_circle(8, 3, 2, petal3)
    c.fill_circle(7, 6, 2, petal2)
    c.fill_circle(9, 6, 2, petal1)
    # Centers
    c.set(6, 4, GOLD)
    c.set(10, 4, GOLD)
    c.set(8, 3, GOLD)
    return c.add_outline(BLACK)


def generate_weapon_icon_needle():
    c = Canvas(16, 16)
    metal = (200, 200, 210, 255)
    tip = (230, 230, 240, 255)
    # Needle body
    c.draw_line(8, 1, 8, 12, metal)
    c.draw_line(7, 2, 7, 11, metal)
    # Sharp tip
    c.set(8, 0, tip)
    c.set(7, 1, tip)
    # Eye
    c.set(7, 13, (60, 50, 70, 255))
    c.set(8, 13, (60, 50, 70, 255))
    # Thread
    c.draw_line(8, 13, 11, 14, BRIGHT_PINK)
    c.set(12, 14, BRIGHT_PINK)
    return c.add_outline(BLACK)


def generate_weapon_icon_gear():
    c = Canvas(16, 16)
    metal = GOLD
    dark = (180, 150, 0, 255)
    # Gear body
    c.fill_circle(8, 8, 4, metal)
    c.fill_circle(8, 8, 2, dark)
    c.fill_circle(8, 8, 1, (100, 80, 0, 255))
    # Teeth
    for angle_i in range(8):
        angle = angle_i * math.pi / 4
        tx = int(8 + 5.5 * math.cos(angle))
        ty = int(8 + 5.5 * math.sin(angle))
        c.set(tx, ty, metal)
    return c.add_outline(BLACK)


def generate_weapon_icon_mirror():
    c = Canvas(16, 16)
    frame = IRON_GRAY
    glass = CYAN_BLUE
    # Frame
    c.fill_circle(8, 7, 5, frame)
    # Glass
    c.fill_circle(8, 7, 3, glass)
    # Shine
    c.set(7, 5, WHITE)
    c.set(6, 6, (200, 230, 255, 255))
    # Handle
    c.fill_rect(7, 12, 2, 3, frame)
    # Crack
    c.draw_line(8, 5, 10, 9, (50, 45, 55, 255))
    return c.add_outline(BLACK)


def generate_weapon_icon_broom():
    c = Canvas(16, 16)
    handle = WOOD_BROWN
    bristle = (160, 130, 80, 255)
    bristle_d = (120, 100, 60, 255)
    # Handle
    c.draw_line(3, 2, 10, 9, handle)
    c.draw_line(4, 2, 11, 9, handle)
    # Bristles
    for by in range(10, 15):
        c.fill_rect(9, by, 5, 1, bristle)
    c.set(10, 14, bristle_d)
    c.set(12, 14, bristle_d)
    c.fill_rect(9, 10, 1, 5, bristle_d)
    return c.add_outline(BLACK)


# ============================================================
# Passive Icons (16x16)
# ============================================================

def generate_passive_icon_apron():
    """Thick apron (HP)."""
    c = Canvas(16, 16)
    cloth = (200, 180, 160, 255)
    dark = (160, 140, 120, 255)
    strap = (140, 100, 80, 255)
    # Body
    c.fill_rect(4, 5, 8, 9, cloth)
    c.fill_rect(5, 4, 6, 1, cloth)
    # Straps
    c.draw_line(5, 4, 3, 1, strap)
    c.draw_line(10, 4, 12, 1, strap)
    # Pocket
    c.fill_rect(6, 9, 4, 3, dark)
    # Cross (healing symbol)
    c.set(7, 10, (200, 50, 50, 255))
    c.set(8, 10, (200, 50, 50, 255))
    c.set(7, 9, (200, 50, 50, 255))
    c.set(8, 9, (200, 50, 50, 255))
    return c.add_outline(BLACK)


def generate_passive_icon_shoe():
    """Running shoe (Speed)."""
    c = Canvas(16, 16)
    shoe = (180, 80, 50, 255)
    sole = (60, 40, 30, 255)
    lace = WHITE
    # Sole
    c.fill_rect(2, 11, 12, 2, sole)
    # Body
    c.fill_rect(2, 7, 10, 4, shoe)
    c.fill_rect(11, 8, 2, 3, shoe)
    c.set(13, 9, shoe)
    # Top curve
    c.fill_rect(3, 6, 6, 1, shoe)
    # Laces
    c.set(5, 7, lace)
    c.set(7, 7, lace)
    # Speed lines
    c.set(0, 8, (255, 200, 100, 150))
    c.set(0, 10, (255, 200, 100, 150))
    c.set(1, 9, (255, 200, 100, 100))
    return c.add_outline(BLACK)


def generate_passive_icon_clock():
    """Broken clock (Cooldown)."""
    c = Canvas(16, 16)
    frame = GOLD
    face = (220, 215, 200, 255)
    hand = (40, 35, 30, 255)
    # Frame circle
    c.fill_circle(8, 8, 6, frame)
    c.fill_circle(8, 8, 5, face)
    # Hands
    c.draw_line(8, 8, 8, 4, hand)
    c.draw_line(8, 8, 11, 7, hand)
    # Center
    c.set(8, 8, (60, 50, 40, 255))
    # Crack
    c.draw_line(10, 3, 12, 6, (100, 90, 80, 255))
    # 12 marker
    c.set(8, 3, hand)
    return c.add_outline(BLACK)


def generate_passive_icon_necklace():
    """Cursed necklace (Damage)."""
    c = Canvas(16, 16)
    chain = GOLD
    gem = BRIGHT_PINK
    # Chain arc
    for i in range(8):
        angle = math.pi + math.pi * i / 7
        x = int(8 + 5 * math.cos(angle))
        y = int(5 + 4 * math.sin(angle))
        c.set(x, y, chain)
    # Pendant
    c.fill_rect(7, 9, 3, 3, (180, 150, 0, 255))
    c.set(8, 10, gem)
    # Sparkle
    c.set(9, 9, WHITE)
    return c.add_outline(BLACK)


def generate_passive_icon_magnifier():
    """Magnifying glass (Range)."""
    c = Canvas(16, 16)
    frame = (180, 150, 100, 255)
    glass = (180, 220, 255, 180)
    handle = WOOD_BROWN
    # Glass
    c.fill_circle(7, 6, 4, glass)
    c.fill_circle(7, 6, 5, frame)
    c.fill_circle(7, 6, 4, glass)
    # Shine
    c.set(5, 4, WHITE)
    c.set(6, 4, (220, 240, 255, 200))
    # Handle
    c.draw_line(10, 9, 13, 13, handle)
    c.draw_line(11, 9, 14, 13, handle)
    return c.add_outline(BLACK)


def generate_passive_icon_brooch():
    """Magnet brooch (Magnet range)."""
    c = Canvas(16, 16)
    red = (200, 50, 50, 255)
    blue = (50, 80, 200, 255)
    metal = (180, 180, 190, 255)
    # U-shape magnet
    c.fill_rect(3, 3, 3, 10, red)
    c.fill_rect(10, 3, 3, 10, blue)
    c.fill_rect(3, 10, 10, 3, metal)
    # Tips
    c.fill_rect(3, 3, 3, 2, (220, 70, 70, 255))
    c.fill_rect(10, 3, 3, 2, (70, 100, 220, 255))
    # Field lines
    c.set(6, 2, (200, 200, 255, 100))
    c.set(9, 2, (200, 200, 255, 100))
    return c.add_outline(BLACK)


def generate_passive_icon_diary():
    """Old diary (XP)."""
    c = Canvas(16, 16)
    cover = (120, 80, 50, 255)
    page = (220, 210, 190, 255)
    # Cover
    c.fill_rect(3, 2, 10, 12, cover)
    # Spine
    c.fill_rect(3, 2, 2, 12, (80, 55, 35, 255))
    # Pages
    c.fill_rect(5, 3, 7, 10, page)
    # Text lines
    for ty in [5, 7, 9, 11]:
        c.fill_rect(6, ty, 5, 1, (150, 140, 120, 255))
    # Bookmark
    c.fill_rect(11, 1, 1, 3, BRIGHT_PINK)
    return c.add_outline(BLACK)


def generate_passive_icon_coin():
    """Lucky coin (Crit)."""
    c = Canvas(16, 16)
    gold = GOLD
    dark_gold = (200, 170, 0, 255)
    # Coin body
    c.fill_circle(8, 8, 5, gold)
    c.fill_circle(8, 8, 4, dark_gold)
    c.fill_circle(8, 8, 3, gold)
    # Star/luck symbol
    c.set(8, 6, WHITE)
    c.set(7, 7, WHITE)
    c.set(9, 7, WHITE)
    c.set(8, 8, WHITE)
    c.set(7, 9, WHITE)
    c.set(9, 9, WHITE)
    c.set(8, 10, WHITE)
    # Shine
    c.set(6, 5, (255, 255, 200, 200))
    return c.add_outline(BLACK)


def generate_passive_icon_herb():
    """Regen herb (HP Regen)."""
    c = Canvas(16, 16)
    stem = (60, 120, 40, 255)
    leaf = (80, 180, 60, 255)
    leaf_d = (50, 130, 40, 255)
    # Stem
    c.draw_line(8, 6, 8, 14, stem)
    # Leaves
    c.fill_rect(5, 5, 3, 2, leaf)
    c.fill_rect(9, 7, 3, 2, leaf)
    c.fill_rect(4, 3, 4, 2, leaf)
    c.fill_rect(9, 4, 3, 2, leaf)
    c.set(5, 5, leaf_d)
    c.set(10, 7, leaf_d)
    # Sparkle (healing)
    c.set(7, 2, (100, 255, 150, 200))
    c.set(10, 3, (100, 255, 150, 150))
    return c.add_outline(BLACK)


def generate_passive_icon_cloak():
    """Ghost cloak (Dodge)."""
    c = Canvas(16, 16)
    cloak = (80, 60, 120, 255)
    cloak_l = (100, 80, 150, 255)
    # Cloak body
    c.fill_rect(4, 3, 8, 11, cloak)
    c.fill_rect(3, 5, 1, 8, cloak)
    c.fill_rect(12, 5, 1, 8, cloak)
    # Hood
    c.fill_rect(5, 2, 6, 2, cloak)
    c.fill_rect(6, 1, 4, 1, cloak_l)
    # Face shadow
    c.fill_rect(6, 3, 4, 2, (30, 20, 40, 255))
    # Eyes
    c.set(7, 4, (200, 200, 255, 200))
    c.set(9, 4, (200, 200, 255, 200))
    # Bottom wave
    c.set(4, 14, (0, 0, 0, 0))
    c.set(7, 14, (0, 0, 0, 0))
    c.set(11, 14, (0, 0, 0, 0))
    # Ghost-like transparency at bottom
    for x in range(4, 12):
        px = c.get(x, 13)
        if px[3] > 0:
            c.set(x, 13, (px[0], px[1], px[2], 180))
    return c.add_outline((30, 20, 50, 180))


# ============================================================
# SFX Generation
# ============================================================

def generate_vignette():
    """Vignette overlay (320x180) - dark edges, transparent center."""
    w, h = 320, 180
    c = Canvas(w, h)
    cx, cy = w / 2.0, h / 2.0
    max_dist = math.sqrt(cx * cx + cy * cy)

    for y in range(h):
        for x in range(w):
            dx = (x - cx) / cx
            dy = (y - cy) / cy
            dist = math.sqrt(dx * dx + dy * dy)
            # Smooth vignette curve: ramp from 0.3 to 1.0
            t = max(0.0, min(1.0, (dist - 0.3) / 0.7))
            t = t * t  # quadratic falloff
            alpha = int(t * 255)
            c.set(x, y, (0, 0, 0, alpha))
    return c


def generate_player_glow():
    """Soft radial glow (64x64) for player ambient light."""
    size = 64
    c = Canvas(size, size)
    center = size / 2.0
    radius = size / 2.0

    for y in range(size):
        for x in range(size):
            dx = x - center
            dy = y - center
            dist = math.sqrt(dx * dx + dy * dy)
            if dist >= radius:
                continue
            t = 1.0 - (dist / radius)
            t = t * t  # quadratic falloff
            alpha = int(t * 255)
            c.set(x, y, (255, 255, 255, alpha))
    return c


def generate_sfx():
    """Generate all game sound effects."""
    sfx_dir = os.path.join(BASE_DIR, "assets", "audio", "sfx")

    # Enemy hit
    s = apply_envelope(gen_square(300, 0.06, 0.4), attack=0.005, release=0.02)
    write_wav(os.path.join(sfx_dir, "enemy_hit.wav"), s)

    # Enemy death
    s = apply_envelope(pitch_sweep(400, 100, 0.15, 0.35), attack=0.005, release=0.05)
    write_wav(os.path.join(sfx_dir, "enemy_death.wav"), s)

    # Player hit
    s = apply_envelope(gen_square(200, 0.1, 0.4), attack=0.005, release=0.03)
    s2 = apply_envelope(gen_noise(0.05, 0.15), attack=0.005, release=0.02)
    write_wav(os.path.join(sfx_dir, "player_hit.wav"), mix(s, s2))

    # Level up
    notes = [523, 659, 784, 1047]  # C5, E5, G5, C6
    parts = []
    for note in notes:
        parts.append(apply_envelope(gen_sine(note, 0.15, 0.3), release=0.05))
    s = concat(*parts)
    write_wav(os.path.join(sfx_dir, "level_up.wav"), s)

    # XP gem pickup
    s = apply_envelope(pitch_sweep(800, 1200, 0.08, 0.25), attack=0.005, release=0.03)
    write_wav(os.path.join(sfx_dir, "gem_pickup.wav"), s)

    # Item pickup
    s = apply_envelope(gen_sine(880, 0.08, 0.3), attack=0.005, release=0.03)
    s2 = apply_envelope(gen_sine(1100, 0.06, 0.2), attack=0.01, release=0.02)
    write_wav(os.path.join(sfx_dir, "item_pickup.wav"), concat(s, s2))

    # UI select
    s = apply_envelope(gen_square(600, 0.05, 0.2), attack=0.005, release=0.02)
    write_wav(os.path.join(sfx_dir, "ui_select.wav"), s)

    # UI confirm
    s = apply_envelope(gen_sine(800, 0.06, 0.25), attack=0.005, release=0.02)
    s2 = apply_envelope(gen_sine(1000, 0.06, 0.2), attack=0.005, release=0.02)
    write_wav(os.path.join(sfx_dir, "ui_confirm.wav"), concat(s, s2))

    # Boss warning
    s1 = apply_envelope(gen_square(150, 0.3, 0.4), attack=0.01, release=0.1)
    s2 = apply_envelope(gen_noise(0.3, 0.15), attack=0.01, release=0.1)
    write_wav(os.path.join(sfx_dir, "boss_warning.wav"), mix(s1, s2))

    # Boss death
    s1 = apply_envelope(pitch_sweep(200, 50, 0.5, 0.4), attack=0.01, release=0.15)
    s2 = apply_envelope(gen_noise(0.5, 0.2), attack=0.01, release=0.15)
    write_wav(os.path.join(sfx_dir, "boss_death.wav"), mix(s1, s2))

    # Weapon: slash
    s = apply_envelope(pitch_sweep(600, 200, 0.08, 0.3), attack=0.005, release=0.03)
    n = apply_envelope(gen_noise(0.06, 0.15), attack=0.005, release=0.02)
    write_wav(os.path.join(sfx_dir, "weapon_slash.wav"), mix(s, n))

    # Weapon: fire
    s = apply_envelope(pitch_sweep(300, 150, 0.12, 0.25), attack=0.005, release=0.04)
    n = apply_envelope(gen_noise(0.12, 0.2), attack=0.01, release=0.04)
    write_wav(os.path.join(sfx_dir, "weapon_fire.wav"), mix(s, n))

    # Weapon: magic
    s = apply_envelope(pitch_sweep(500, 800, 0.1, 0.25), attack=0.005, release=0.04)
    write_wav(os.path.join(sfx_dir, "weapon_magic.wav"), s)

    # Heal
    notes = [659, 784, 880]  # E5, G5, A5
    parts = []
    for note in notes:
        parts.append(apply_envelope(gen_sine(note, 0.12, 0.2), release=0.04))
    write_wav(os.path.join(sfx_dir, "heal.wav"), concat(*parts))

    # Chest open
    s1 = apply_envelope(gen_noise(0.05, 0.2), attack=0.005, release=0.02)
    s2 = apply_envelope(gen_sine(600, 0.1, 0.3), attack=0.01, release=0.04)
    s3 = apply_envelope(gen_sine(900, 0.1, 0.2), attack=0.01, release=0.04)
    write_wav(os.path.join(sfx_dir, "chest_open.wav"), concat(s1, mix(s2, s3)))

    # Revive
    notes = [440, 554, 659, 880]  # A4, C#5, E5, A5
    parts = []
    for note in notes:
        parts.append(apply_envelope(gen_sine(note, 0.2, 0.25), release=0.06))
    write_wav(os.path.join(sfx_dir, "revive.wav"), concat(*parts))

    # Thunder (for Stage 2 lightning)
    s = apply_envelope(gen_noise(0.4, 0.5), attack=0.005, sustain=0.6, release=0.2)
    s2 = apply_envelope(gen_square(60, 0.3, 0.2), attack=0.01, release=0.15)
    write_wav(os.path.join(sfx_dir, "thunder.wav"), mix(s, s2))

    # Game over
    notes = [392, 349, 330, 262]  # G4, F4, E4, C4 - descending
    parts = []
    for note in notes:
        parts.append(apply_envelope(gen_sine(note, 0.25, 0.3), release=0.08))
    write_wav(os.path.join(sfx_dir, "game_over.wav"), concat(*parts))

    # Victory
    notes = [523, 659, 784, 1047, 1319]  # C5, E5, G5, C6, E6 - ascending
    parts = []
    for note in notes:
        parts.append(apply_envelope(gen_sine(note, 0.18, 0.3), release=0.05))
    write_wav(os.path.join(sfx_dir, "victory.wav"), concat(*parts))


# ============================================================
# BGM Generation (simple ambient loops)
# ============================================================

def generate_bgm():
    """Generate simple ambient BGM loops."""
    bgm_dir = os.path.join(BASE_DIR, "assets", "audio", "bgm")
    sr = 22050

    # Stage 1: Dark music box melody
    def music_box_melody():
        # Simple pentatonic melody notes (in Hz) with pauses
        melody = [
            (523, 0.4), (0, 0.1), (659, 0.3), (0, 0.1),
            (587, 0.4), (0, 0.1), (523, 0.3), (0, 0.2),
            (440, 0.5), (0, 0.1), (523, 0.3), (0, 0.1),
            (587, 0.4), (0, 0.3),
            (523, 0.4), (0, 0.1), (440, 0.3), (0, 0.1),
            (392, 0.5), (0, 0.1), (440, 0.3), (0, 0.1),
            (523, 0.6), (0, 0.5),
        ]
        samples = []
        for freq, dur in melody:
            if freq == 0:
                samples.extend([0.0] * int(sr * dur))
            else:
                note = apply_envelope(gen_sine(freq, dur, 0.15), attack=0.01, release=0.05, sample_rate=sr)
                # Add slight detuned harmonics for music box feel
                h2 = apply_envelope(gen_sine(freq * 2, dur, 0.05), attack=0.01, release=0.05, sample_rate=sr)
                h3 = apply_envelope(gen_sine(freq * 3, dur, 0.02), attack=0.01, release=0.05, sample_rate=sr)
                mixed = mix(mix(note, h2), h3)
                samples.extend(mixed)
        return samples

    # Repeat melody 4 times for ~30s loop
    mel = music_box_melody()
    stage1_bgm = mel * 4
    # Add subtle low drone
    drone = gen_sine(110, len(stage1_bgm) / sr, 0.03, sr)
    stage1_bgm = mix(stage1_bgm, drone[:len(stage1_bgm)])
    write_wav(os.path.join(bgm_dir, "stage1_town.wav"), stage1_bgm, sr)

    # Stage 2: Darker ambient
    def cemetery_ambient():
        melody = [
            (330, 0.5), (0, 0.3), (294, 0.4), (0, 0.2),
            (262, 0.6), (0, 0.3), (247, 0.4), (0, 0.2),
            (220, 0.8), (0, 0.5),
            (247, 0.4), (0, 0.2), (262, 0.5), (0, 0.3),
            (220, 0.7), (0, 0.8),
        ]
        samples = []
        for freq, dur in melody:
            if freq == 0:
                samples.extend([0.0] * int(sr * dur))
            else:
                note = apply_envelope(gen_sine(freq, dur, 0.1), attack=0.02, release=0.08, sample_rate=sr)
                samples.extend(note)
        return samples

    mel = cemetery_ambient()
    stage2_bgm = mel * 4
    # Add wind noise
    wind = apply_envelope(gen_noise(len(stage2_bgm) / sr, 0.04, sr), attack=0.5, sustain=0.8, release=0.5, sample_rate=sr)
    stage2_bgm = mix(stage2_bgm, wind[:len(stage2_bgm)])
    write_wav(os.path.join(bgm_dir, "stage2_cemetery.wav"), stage2_bgm, sr)

    # Title: Calm then eerie
    title_calm = music_box_melody()
    # Make "corrupted" version - detune slightly
    corrupted = []
    for freq, dur in [
        (520, 0.4), (0, 0.1), (655, 0.3), (0, 0.1),
        (590, 0.4), (0, 0.1), (518, 0.3), (0, 0.2),
        (435, 0.5), (0, 0.1), (520, 0.3), (0, 0.1),
        (590, 0.4), (0, 0.3),
    ]:
        if freq == 0:
            corrupted.extend([0.0] * int(sr * dur))
        else:
            note = apply_envelope(gen_sine(freq, dur, 0.12), attack=0.02, release=0.08, sample_rate=sr)
            corrupted.extend(note)
    title_bgm = title_calm + corrupted * 2 + title_calm
    write_wav(os.path.join(bgm_dir, "title.wav"), title_bgm, sr)

    # Boss 1: Intense
    def boss1_theme():
        pattern = [
            (220, 0.15), (0, 0.05), (220, 0.15), (0, 0.05),
            (262, 0.15), (0, 0.05), (294, 0.15), (0, 0.05),
            (330, 0.3), (0, 0.1),
            (294, 0.15), (0, 0.05), (262, 0.15), (0, 0.05),
            (220, 0.3), (0, 0.2),
        ]
        samples = []
        for freq, dur in pattern:
            if freq == 0:
                samples.extend([0.0] * int(sr * dur))
            else:
                note = apply_envelope(gen_square(freq, dur, 0.2), attack=0.005, release=0.03, sample_rate=sr)
                bass = apply_envelope(gen_sine(freq / 2, dur, 0.1), attack=0.005, release=0.03, sample_rate=sr)
                samples.extend(mix(note, bass))
        return samples

    boss1 = boss1_theme() * 6
    write_wav(os.path.join(bgm_dir, "boss_grimholt.wav"), boss1, sr)

    # Boss 2: More ominous
    def boss2_theme():
        pattern = [
            (196, 0.2), (0, 0.05), (233, 0.15), (0, 0.05),
            (262, 0.2), (0, 0.05), (294, 0.15), (0, 0.1),
            (349, 0.3), (0, 0.1), (330, 0.2), (0, 0.05),
            (294, 0.15), (0, 0.05), (262, 0.3), (0, 0.3),
        ]
        samples = []
        for freq, dur in pattern:
            if freq == 0:
                samples.extend([0.0] * int(sr * dur))
            else:
                note = apply_envelope(gen_square(freq, dur, 0.18), attack=0.005, release=0.03, sample_rate=sr)
                sub = apply_envelope(gen_sine(freq / 3, dur, 0.12), attack=0.005, release=0.05, sample_rate=sr)
                samples.extend(mix(note, sub))
        return samples

    boss2 = boss2_theme() * 6
    noise_bg = apply_envelope(gen_noise(len(boss2) / sr, 0.02, sr), attack=0.5, sustain=0.8, release=0.5, sample_rate=sr)
    boss2 = mix(boss2, noise_bg[:len(boss2)])
    write_wav(os.path.join(bgm_dir, "boss_witch.wav"), boss2, sr)


# ============================================================
# Main
# ============================================================

def main():
    random.seed(42)

    # Ground tiles
    print("Generating ground tiles...")
    tile_dir = os.path.join(BASE_DIR, "assets", "tilesets")
    write_png(os.path.join(tile_dir, "town_ground.png"), generate_town_tile())
    write_png(os.path.join(tile_dir, "town_ground_b.png"), generate_town_tile_b())
    write_png(os.path.join(tile_dir, "cemetery_ground.png"), generate_cemetery_tile())
    write_png(os.path.join(tile_dir, "cemetery_ground_b.png"), generate_cemetery_tile_b())

    # Decorations - Stage 1
    print("Generating decorations...")
    deco_dir = os.path.join(BASE_DIR, "assets", "decorations")
    write_png(os.path.join(deco_dir, "twisted_tree.png"), generate_twisted_tree())
    write_png(os.path.join(deco_dir, "broken_barrel.png"), generate_broken_barrel())
    write_png(os.path.join(deco_dir, "lamp_post.png"), generate_lamp_post())
    write_png(os.path.join(deco_dir, "blood_spot.png"), generate_blood_spot())
    write_png(os.path.join(deco_dir, "well.png"), generate_well())
    write_png(os.path.join(deco_dir, "cart.png"), generate_cart())

    # Decorations - Stage 2
    write_png(os.path.join(deco_dir, "gravestone_a.png"), generate_gravestone_a())
    write_png(os.path.join(deco_dir, "gravestone_b.png"), generate_gravestone_b())
    write_png(os.path.join(deco_dir, "dead_tree.png"), generate_dead_tree())
    write_png(os.path.join(deco_dir, "iron_fence.png"), generate_iron_fence())
    write_png(os.path.join(deco_dir, "skull.png"), generate_skull())
    write_png(os.path.join(deco_dir, "mushroom_cluster.png"), generate_mushroom_cluster())
    write_png(os.path.join(deco_dir, "broken_coffin.png"), generate_broken_coffin())

    # Weapon icons
    print("Generating weapon icons...")
    icon_dir = os.path.join(BASE_DIR, "assets", "icons")
    write_png(os.path.join(icon_dir, "weapon_scissors.png"), generate_weapon_icon_scissors())
    write_png(os.path.join(icon_dir, "weapon_bible.png"), generate_weapon_icon_bible())
    write_png(os.path.join(icon_dir, "weapon_candle.png"), generate_weapon_icon_candle())
    write_png(os.path.join(icon_dir, "weapon_bouquet.png"), generate_weapon_icon_bouquet())
    write_png(os.path.join(icon_dir, "weapon_needle.png"), generate_weapon_icon_needle())
    write_png(os.path.join(icon_dir, "weapon_gear.png"), generate_weapon_icon_gear())
    write_png(os.path.join(icon_dir, "weapon_mirror.png"), generate_weapon_icon_mirror())
    write_png(os.path.join(icon_dir, "weapon_broom.png"), generate_weapon_icon_broom())

    # Passive icons
    print("Generating passive icons...")
    write_png(os.path.join(icon_dir, "passive_apron.png"), generate_passive_icon_apron())
    write_png(os.path.join(icon_dir, "passive_shoe.png"), generate_passive_icon_shoe())
    write_png(os.path.join(icon_dir, "passive_clock.png"), generate_passive_icon_clock())
    write_png(os.path.join(icon_dir, "passive_necklace.png"), generate_passive_icon_necklace())
    write_png(os.path.join(icon_dir, "passive_magnifier.png"), generate_passive_icon_magnifier())
    write_png(os.path.join(icon_dir, "passive_brooch.png"), generate_passive_icon_brooch())
    write_png(os.path.join(icon_dir, "passive_diary.png"), generate_passive_icon_diary())
    write_png(os.path.join(icon_dir, "passive_coin.png"), generate_passive_icon_coin())
    write_png(os.path.join(icon_dir, "passive_herb.png"), generate_passive_icon_herb())
    write_png(os.path.join(icon_dir, "passive_cloak.png"), generate_passive_icon_cloak())

    # Effect textures
    print("Generating effect textures...")
    fx_dir = os.path.join(BASE_DIR, "assets", "fx")
    write_png(os.path.join(fx_dir, "vignette.png"), generate_vignette())
    write_png(os.path.join(fx_dir, "player_glow.png"), generate_player_glow())

    # SFX
    print("Generating SFX...")
    generate_sfx()

    # BGM
    print("Generating BGM...")
    generate_bgm()

    print("Done! Generated:")
    print("  - 4 ground tiles (32x32, 2 per stage)")
    print("  - 13 decoration sprites")
    print("  - 8 weapon icons (16x16)")
    print("  - 10 passive icons (16x16)")
    print("  - 19 SFX files")
    print("  - 5 BGM tracks")


if __name__ == "__main__":
    main()
