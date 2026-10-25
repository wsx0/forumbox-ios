import math, os, shutil
from PIL import Image, ImageDraw, ImageFilter

BASE = r'D:\deepseek项目\软件破解\forum-hub\ios\Sources\AlternateIcons'
PRIMARY = r'D:\deepseek项目\软件破解\forum-hub\ios\Sources\Assets.xcassets\AppIcon.appiconset\icon-1024.png'
os.makedirs(BASE, exist_ok=True)
S = 1024


def gradient(top, bottom):
    img = Image.new('RGB', (S, S), top)
    d = ImageDraw.Draw(img)
    for y in range(S):
        t = y / (S - 1)
        color = tuple(int(top[i] * (1 - t) + bottom[i] * t) for i in range(3))
        d.line([(0, y), (S, y)], fill=color)
    return img


def ellipse(d, box, fill, outline=None, width=0):
    d.ellipse(box, fill=fill, outline=outline, width=width)


def eye(d, cx, cy, rx, ry, iris=(45, 32, 55), hi=(255, 255, 255)):
    ellipse(d, [cx - rx, cy - ry, cx + rx, cy + ry], iris)
    ellipse(d, [cx - rx * 0.42, cy - ry * 0.55, cx - rx * 0.02, cy - ry * 0.12], hi)
    ellipse(d, [cx + rx * 0.18, cy + ry * 0.20, cx + rx * 0.42, cy + ry * 0.42], (255, 255, 255, 180))


def face(img, cx, cy, r, skin=(255, 250, 248), blush=(255, 160, 185), iris=(55, 38, 65)):
    d = ImageDraw.Draw(img)
    ellipse(d, [cx - r, cy - r, cx + r, cy + r], skin)
    eye(d, cx - r * 0.38, cy - r * 0.08, r * 0.18, r * 0.24, iris)
    eye(d, cx + r * 0.38, cy - r * 0.08, r * 0.18, r * 0.24, iris)
    ellipse(d, [cx - r * 0.62, cy + r * 0.22, cx - r * 0.28, cy + r * 0.38], blush)
    ellipse(d, [cx + r * 0.28, cy + r * 0.22, cx + r * 0.62, cy + r * 0.38], blush)
    d.arc([cx - r * 0.16, cy + r * 0.16, cx + r * 0.16, cy + r * 0.40], 15, 165, fill=(80, 45, 60), width=max(4, int(r * 0.05)))


def stars(d, points, color=(255, 255, 255), size=18):
    for x, y, r in points:
        d.polygon([(x, y - r), (x + r * 0.35, y - r * 0.25), (x + r, y), (x + r * 0.35, y + r * 0.25),
                   (x, y + r), (x - r * 0.35, y + r * 0.25), (x - r, y), (x - r * 0.35, y - r * 0.25)], fill=color)


def save(img, name):
    for scale, suffix in [(3, '@3x'), (2, '@2x')]:
        size = 60 * scale
        out = img.resize((size, size), Image.LANCZOS)
        out.save(os.path.join(BASE, f'{name}{suffix}.png'), 'PNG')


# 1 Sakura
img = gradient((255, 214, 235), (255, 118, 166))
d = ImageDraw.Draw(img)
for angle in range(0, 360, 72):
    petal = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    pd = ImageDraw.Draw(petal)
    pd.ellipse([S/2 - 150, 180, S/2 + 150, 610], fill=(255, 170, 205, 255))
    pd.ellipse([S/2 - 90, 220, S/2 + 90, 560], fill=(255, 225, 238, 255))
    petal = petal.rotate(angle, center=(S/2, S/2))
    img.paste(petal, (0, 0), petal)
face(img, S/2, S/2, 160)
stars(d, [(150, 180, 22), (860, 230, 16), (200, 820, 14), (820, 800, 24)], (255, 255, 255))
save(img, 'IconSakura')

# 2 Cat
img = gradient((206, 191, 255), (94, 75, 188))
d = ImageDraw.Draw(img)
d.polygon([(250, 390), (300, 160), (470, 330)], fill=(46, 36, 82))
d.polygon([(774, 390), (724, 160), (554, 330)], fill=(46, 36, 82))
d.polygon([(280, 360), (315, 215), (420, 320)], fill=(255, 170, 205))
d.polygon([(744, 360), (709, 215), (604, 320)], fill=(255, 170, 205))
d.rounded_rectangle([240, 300, 784, 820], radius=240, fill=(58, 44, 100))
face(img, S/2, 590, 190, skin=(255, 246, 250), iris=(255, 200, 110))
d = ImageDraw.Draw(img)
for y in (690, 740):
    d.line([(320, y), (450, y + 20)], fill=(255, 255, 255, 180), width=8)
    d.line([(704, y), (574, y + 20)], fill=(255, 255, 255, 180), width=8)
stars(d, [(170, 250, 18), (850, 180, 22), (800, 860, 15), (180, 840, 20)])
save(img, 'IconCat')

# 3 Moon
img = gradient((24, 38, 92), (8, 10, 28))
d = ImageDraw.Draw(img)
ellipse(d, [230, 180, 800, 750], (255, 224, 130))
ellipse(d, [330, 110, 900, 680], (20, 30, 75))
face(img, 520, 520, 165, skin=(255, 239, 198), iris=(70, 55, 80))
stars(d, [(170, 180, 20), (840, 240, 24), (220, 820, 16), (810, 800, 20), (700, 130, 12)])
save(img, 'IconMoon')

# 4 Star
img = gradient((150, 235, 255), (45, 100, 240))
d = ImageDraw.Draw(img)
cx, cy, outer, inner = S/2, S/2, 390, 170
pts = []
for i in range(10):
    r = outer if i % 2 == 0 else inner
    a = -math.pi / 2 + i * math.pi / 5
    pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
d.polygon(pts, fill=(255, 220, 90), outline=(255, 248, 190), width=10)
face(img, cx, cy + 20, 180, skin=(255, 246, 205), iris=(80, 55, 95))
stars(d, [(180, 190, 22), (840, 210, 18), (180, 830, 18), (830, 820, 22)], (255, 255, 255))
save(img, 'IconStar')

# 5 Cyber
img = gradient((8, 14, 28), (3, 5, 12))
d = ImageDraw.Draw(img)
for x in range(0, S, 64):
    d.line([(x, 0), (x, S)], fill=(18, 45, 70), width=2)
for y in range(0, S, 64):
    d.line([(0, y), (S, y)], fill=(18, 45, 70), width=2)
d.rounded_rectangle([180, 330, 844, 700], radius=180, fill=(10, 22, 36), outline=(0, 238, 255), width=14)
d.rounded_rectangle([230, 390, 794, 560], radius=80, fill=(0, 220, 245))
d.polygon([(280, 475), (440, 445), (440, 515)], fill=(255, 45, 160))
d.polygon([(744, 475), (584, 445), (584, 515)], fill=(255, 45, 160))
d.line([(330, 620), (690, 620)], fill=(255, 45, 160), width=12)
for i in range(8):
    x = 120 + i * 110
    d.line([(x, 820), (x + 50, 780)], fill=(0, 238, 255), width=6)
stars(d, [(150, 180, 18), (860, 200, 16), (170, 850, 20)], (255, 80, 180))
save(img, 'IconCyber')

# 6 Bunny
img = gradient((255, 246, 220), (255, 180, 205))
d = ImageDraw.Draw(img)
d.rounded_rectangle([300, 120, 455, 560], radius=78, fill=(255, 252, 250))
d.rounded_rectangle([569, 120, 724, 560], radius=78, fill=(255, 252, 250))
d.rounded_rectangle([330, 170, 425, 520], radius=48, fill=(255, 190, 210))
d.rounded_rectangle([599, 170, 694, 520], radius=48, fill=(255, 190, 210))
face(img, S/2, 600, 240, skin=(255, 253, 250), iris=(90, 60, 90))
d = ImageDraw.Draw(img)
ellipse(d, [470, 590, 554, 640], (255, 170, 195))
stars(d, [(170, 230, 20), (850, 250, 18), (180, 820, 16)], (255, 255, 255))
save(img, 'IconBunny')

# 7 Matcha
img = gradient((226, 249, 210), (80, 175, 125))
d = ImageDraw.Draw(img)
d.ellipse([180, 210, 820, 850], fill=(58, 140, 90))
d.ellipse([250, 270, 770, 790], fill=(120, 205, 155))
d.line([(500, 780), (540, 400)], fill=(40, 100, 65), width=22)
d.line([(520, 500), (330, 380)], fill=(40, 100, 65), width=16)
d.line([(530, 460), (720, 340)], fill=(40, 100, 65), width=16)
face(img, S/2, 560, 170, skin=(245, 255, 240), iris=(45, 100, 65))
save(img, 'IconMatcha')

# 8 Peach
img = gradient((255, 226, 190), (255, 140, 140))
d = ImageDraw.Draw(img)
d.ellipse([210, 300, 610, 800], fill=(255, 180, 155))
d.ellipse([420, 300, 820, 800], fill=(255, 155, 140))
d.ellipse([280, 420, 500, 720], fill=(255, 210, 180))
d.polygon([(500, 330), (520, 180), (700, 230), (600, 350)], fill=(80, 170, 105))
face(img, S/2, 620, 170, skin=(255, 236, 225), iris=(100, 55, 65))
stars(d, [(170, 220, 18), (850, 260, 20), (180, 820, 16)], (255, 255, 255))
save(img, 'IconPeach')

# 9 Ocean
img = gradient((180, 240, 255), (25, 100, 210))
d = ImageDraw.Draw(img)
for base, color in [(650, (120, 220, 255)), (730, (70, 180, 245)), (810, (40, 140, 220))]:
    pts = [(0, base)]
    for x in range(0, S + 80, 80):
        pts.append((x, base - 40 * math.sin(x / 120)))
    pts += [(S, S), (0, S)]
    d.polygon(pts, fill=color)
d.ellipse([360, 300, 700, 560], fill=(255, 190, 90))
d.polygon([(700, 430), (840, 350), (840, 510)], fill=(255, 170, 70))
eye(d, 480, 390, 22, 28, (70, 45, 40))
eye(d, 590, 390, 22, 28, (70, 45, 40))
d.arc([500, 420, 590, 500], 15, 165, fill=(100, 55, 50), width=8)
for i in range(5):
    ellipse(d, [740 + i * 25, 210 - i * 18, 780 + i * 25, 250 - i * 18], (255, 255, 255, 180))
stars(d, [(180, 180, 20), (850, 820, 18)], (255, 255, 255))
save(img, 'IconOcean')

# 10 Pixel heart
img = gradient((48, 28, 78), (12, 7, 24))
d = ImageDraw.Draw(img)
pixel = 44
grid = [
    "0011001100",
    "0111111110",
    "1111111111",
    "1111111111",
    "0111111110",
    "0011111100",
    "0001111000",
    "0000110000",
    "0000000000",
]
start_x = S/2 - len(grid[0]) * pixel / 2
start_y = S/2 - len(grid) * pixel / 2 + 20
for row, line in enumerate(grid):
    for col, ch in enumerate(line):
        if ch == '1':
            x = start_x + col * pixel
            y = start_y + row * pixel
            shade = (255, 100, 170) if row < 4 else (230, 70, 145)
            d.rectangle([x + 2, y + 2, x + pixel - 2, y + pixel - 2], fill=shade)
stars(d, [(180, 190, 18), (840, 220, 20), (190, 830, 16), (830, 810, 22)], (120, 240, 255))
save(img, 'IconPixel')

# Default preview from existing primary
primary = Image.open(PRIMARY).convert('RGB')
for scale, suffix in [(3, '@3x'), (2, '@2x')]:
    size = 60 * scale
    primary.resize((size, size), Image.LANCZOS).save(os.path.join(BASE, f'IconDefault{suffix}.png'), 'PNG')

print('generated', len([f for f in os.listdir(BASE) if f.endswith('.png')]), 'files')
