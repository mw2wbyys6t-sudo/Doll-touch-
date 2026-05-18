#!/usr/bin/env python3
"""
星空愛莉 (Hoshizora Airi) App Icon Generator v7
BANG DREAM / IDOL GAME STYLE:
- Character fills 75%+ of frame (close-up portrait)
- High saturation, vivid colors
- Clear dark outline (cel-shading style)
- Dynamic angle + energetic composition
- Starburst/sparkle effects
- Clean background with brand color gradient
"""
from PIL import Image, ImageDraw, ImageFilter
import math
import random
import os

OUTPUT_DIR = '/workspace/ohos_airi'

# ======== VIVID PALETTE (High saturation for idol game feel) ========
C = {
    # Hair: rich brown with vivid pink-purple tips
    'hair_main':       (85, 58, 42),    # Saturated deep brown
    'hair_mid':        (110, 78, 55),    # Medium brown
    'hair_light':      (150, 110, 85),   # Highlight brown
    'hair_tip_pink':   (245, 160, 185),  # Vivid pink tip
    'hair_tip_lavender':(200, 155, 220), # Vivid lavender tip
    
    # Eyes: BRIGHT violet (signature color, POP!)
    'eye_outer':       (140, 90, 230),   # Bright violet
    'eye_main':        (175, 120, 245),  # Vibrant violet
    'eye_inner':       (210, 170, 255),  # Light violet
    'eye_highlight':   (255, 255, 255),
    'pupil':           (45, 25, 80),     # Deep purple-black
    
    # Skin: warm and lively
    'skin_base':       (255, 242, 228),
    'skin_shadow':     (240, 218, 198),
    'skin_highlight':  (255, 252, 245),
    'blush':           (255, 165, 180),  # Vivid blush pink
    'mouth':           (235, 95, 115),   # Coral red mouth
    
    # Bow: vivid pink-magenta
    'bow_main':        (245, 130, 190),
    'bow_light':       (255, 195, 225),
    'bow_center':      (215, 95, 165),
    
    # Outline color (crucial for anime look!)
    'outline':         (50, 35, 30),     # Dark brown outline
    'outline_thin':    (80, 60, 50),
    
    # Background: vibrant indigo-to-purple gradient (brand color)
    'bg_top':          (65, 35, 100),    # Rich indigo
    'bg_bottom':       (35, 15, 60),     # Deep purple
    'bg_accent':       (100, 60, 160),   # Accent glow
    
    # Sparkles/stars
    'sparkle_white':   (255, 255, 255),
    'sparkle_pink':    (255, 200, 230),
    'sparkle_violet':  (200, 170, 255),
}

def lerp(c1, c2, t):
    t = max(0, min(1, t))
    return tuple(int(a + (b - a) * t) for a, b in zip(c1, c2))

def draw_outline_ellipse(draw, cx, cy, rx, ry, fill_color, outline_w=3):
    """Draw ellipse with dark outline (cel-shading effect)"""
    # Outline first (slightly larger)
    draw.ellipse([cx-rx-outline_w, cy-ry-outline_w,
                  cx+rx+outline_w, cy+ry+outline_w],
                 fill=C['outline'])
    # Fill on top
    draw.ellipse([cx-rx, cy-ry, cx+rx, cy+ry], fill=fill_color)

def draw_starburst(draw, cx, cy, outer_r, inner_r, rays, rotation, color, alpha=200):
    """Draw starburst/ray effect"""
    pts = []
    for i in range(rays * 2):
        angle = math.pi / rays * i + rotation - math.pi/2
        r = outer_r if i % 2 == 0 else inner_r
        pts.append((cx + r * math.cos(angle), cy + r * math.sin(angle)))
    
    overlay = Image.new('RGBA', draw._image.size, (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    od.polygon(pts, fill=(*color, alpha))
    return overlay

def generate_icon(size=1024, seed=88888):
    random.seed(seed)
    s = size
    sc = s / 1024
    
    img = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    
    # ======== BACKGROUND: Vibrant diagonal gradient ========
    bg_layers = 50
    for i in range(bg_layers):
        t = i / bg_layers
        
        # Diagonal gradient from top-left to bottom-right
        grad_color = lerp(C['bg_top'], C['bg_bottom'], t)
        
        # Offset creates diagonal feel
        offset_x = int(s * 0.1 * (1-t))
        offset_y = int(s * 0.08 * t)
        
        r = int(s * 0.56 * (1 - t*0.3))
        
        bg_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
        bd = ImageDraw.Draw(bg_ov)
        bd.ellipse([s//2-r+offset_x, s//2-r-offset_y,
                   s//2+r+offset_x, s//2+r-offset_y], 
                  fill=(*grad_color, 255))
        img = Image.alpha_composite(img, bg_ov)
    
    # Accent glow spot (top-right area)
    accent_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    ad = ImageDraw.Draw(accent_ov)
    ad.ellipse([int(s*0.62), int(s*0.02), int(s*0.98), int(s*0.38)],
              fill=(*C['bg_accent'], 60))
    accent_ov = accent_ov.filter(ImageFilter.GaussianBlur(radius=int(s*0.08)))
    img = Image.alpha_composite(img, accent_ov)
    d = ImageDraw.Draw(img)
    
    # ======== SPARKLE EFFECTS (BanG Dream style!) ========
    # Large 4-point sparkles at key positions
    sparkle_positions = [
        (s*0.12, s*0.10, 18*sc, 0.3),    # Top left
        (s*0.88, s*0.14, 14*sc, 0.8),    # Top right  
        (s*0.06, s*0.52, 11*sc, 1.5),    # Left mid
        (s*0.92, s*0.68, 13*sc, 2.1),    # Right lower
        (s*0.18, s*0.88, 9*sc, 0.5),     # Bottom left
        (s*0.82, s*0.94, 8*sc, 1.2),     # Bottom right
    ]
    
    for sx, sy, sr, rot in sparkle_positions:
        sb = draw_starburst(d, sx, sy, sr, sr*0.25, 4, rot, C['sparkle_white'], 220)
        img = Image.alpha_composite(img, sb.filter(ImageFilter.GaussianBlur(radius=int(1*sc))))
        d = ImageDraw.Draw(img)
    
    # Small diamond sparkles scattered
    for _ in range(20):
        dx = random.randint(int(s*0.03), int(s*0.97))
        dy = random.randint(int(s*0.03), int(s*0.97))
        ds = random.uniform(3, 7) * sc
        dr = random.uniform(0, math.pi*2)
        
        colors = [C['sparkle_white'], C['sparkle_pink'], C['sparkle_violet']]
        sc_color = random.choice(colors)
        
        sp = draw_starburst(d, dx, dy, ds, ds*0.3, 4, dr, sc_color, random.randint(150, 230))
        img = Image.alpha_composite(img, sp.filter(ImageFilter.GaussianBlur(radius=max(1, int(ds*0.3)))))
        d = ImageDraw.Draw(img)
    
    # Tiny dot sparkles
    for _ in range(40):
        dx = random.randint(int(s*0.02), int(s*0.98))
        dy = random.randint(int(s*0.02), int(s*0.98))
        dd = random.uniform(1.5, 3.5) * sc
        
        dot_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
        dd_raw = ImageDraw.Draw(dot_ov)
        dd_raw.ellipse([dx-dd, dy-dd, dx+dd, dy+dd], 
                      fill=(255, 255, 255, random.randint(120, 220)))
        img = Image.alpha_composite(img, dot_ov)
    
    d = ImageDraw.Draw(img)
    
    # ======== CHARACTER: LARGE CLOSE-UP (75% of frame!) ========
    # Face position - slightly off-center for dynamic feel
    face_cx = int(s * 0.48)  # Slightly left
    face_cy = int(s * 0.52)
    
    # Face is BIG - this is an idol game icon!
    face_rx = int(s * 0.34)   # Very wide
    face_ry = int(s * 0.38)   # Very tall
    
    # ======== HAIR BACK LAYER (with outline!) ========
    hair_back_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    hbd = ImageDraw.Draw(hair_back_ov)
    
    # Hair shape - large, flowing, organic
    hb_pts = []
    hb_n = 2.5  # Superellipse exponent (soft square-ish)
    hb_steps = 72
    hb_w = face_rx * 1.55
    hb_h = face_ry * 1.85
    
    for i in range(hb_steps):
        angle = 2 * math.pi * i / hb_steps
        cos_a = math.cos(angle)
        sin_a = math.sin(angle)
        
        rx_val = hb_w * (abs(cos_a) ** (2/hb_n)) * (1 if cos_a >= 0 else -1)
        ry_val = hb_h * (abs(sin_a) ** (2/hb_n)) * (1 if sin_a >= 0 else -1)
        
        px = face_cx + rx_val
        py = face_cy + ry_val * 0.82  # Hair sits higher
        hb_pts.append((px, py))
    
    # Draw hair with outline
    hbd.polygon(hb_pts, fill=C['outline'])  # Outline layer
    hbd.polygon([(p[0]-2*sc, p[1]) for p in hb_pts], fill=C['hair_main'])
    
    hair_back_ov = hair_back_ov.filter(ImageFilter.GaussianBlur(radius=int(1.5*sc)))
    img = Image.alpha_composite(img, hair_back_ov)
    d = ImageDraw.Draw(img)
    
    # Hair shading (darker at edges - cel-shading!)
    shade_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shade_ov)
    sd.polygon([(p[0]+8*sc, p[1]+6*sc) for p in hb_pts], fill=(*C['hair_mid'], 80))
    shade_ov = shade_ov.filter(ImageFilter.GaussianBlur(radius=int(12*sc)))
    img = Image.alpha_composite(img, shade_ov)
    d = ImageDraw.Draw(img)
    
    # Side hair locks (left - long flowing with PINK tips!)
    for li in range(4):
        lx = face_cx - face_rx*(0.78 + li*0.12)
        ly_top = face_cy - face_ry*(0.22 + li*0.06)
        ly_bot = face_cy + face_ry*(0.92 + li*0.08)
        lw = (16 + li*5) * sc
        
        lock_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
        ld = ImageDraw.Draw(lock_ov)
        
        lock_pts = [
            (lx - lw, ly_top),
            (lx + lw*0.4, ly_top + (ly_bot-ly_top)*0.2),
            (lx + lw*0.55, ly_bot),
            (lx - lw*0.8, ly_bot - (ly_bot-ly_top)*0.15),
        ]
        
        # Outline
        ld.polygon(lock_pts, fill=C['outline'])
        # Fill (offset inward)
        ld.polygon([(p[0]-2*sc, p[1]) for p in lock_pts], fill=C['hair_main'])
        
        # Pink/lavender tip (VIVID!)
        tip_color = lerp(C['hair_tip_pink'], C['hair_tip_lavender'], li*0.25)
        tip_y_thresh = ly_top + (ly_bot-ly_top)*0.55
        tip_pts = [(p[0]-2*sc, max(p[1], tip_y_thresh)) for p in lock_pts]
        ld.polygon(tip_pts, fill=tip_color)
        
        lock_ov = lock_ov.filter(ImageFilter.GaussianBlur(radius=int(1.5*sc)))
        img = Image.alpha_composite(img, lock_ov)
    
    d = ImageDraw.Draw(img)
    
    # Right side hair (shorter)
    for li in range(2):
        lx = face_cx + face_rx*(0.86 + li*0.1)
        ly_top = face_cy - face_ry*0.15
        ly_bot = face_cy + face_ry*(0.48 + li*0.07)
        lw = (14 + li*4) * sc
        
        lock_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
        ld = ImageDraw.Draw(lock_ov)
        lock_pts = [
            (lx - lw*0.5, ly_top),
            (lx + lw, ly_top + (ly_bot-ly_top)*0.22),
            (lx + lw*0.65, ly_bot),
            (lx - lw*0.35, ly_bot - (ly_bot-ly_top)*0.08),
        ]
        ld.polygon(lock_pts, fill=C['outline'])
        ld.polygon([(p[0]-1.5*sc, p[1]) for p in lock_pts], 
                  fill=C['hair_mid'] if li==0 else C['hair_main'])
        lock_ov = lock_ov.filter(ImageFilter.GaussianBlur(radius=int(1.2*sc)))
        img = Image.alpha_composite(img, lock_ov)
    
    d = ImageDraw.Draw(img)
    
    # ======== FACE SHAPE (with outline!) ========
    face_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    fd = ImageDraw.Draw(face_ov)
    
    # Face outline (slightly larger)
    fd.ellipse([face_cx-face_rx-3*sc, face_cy-face_ry-3*sc,
               face_cx+face_rx+3*sc, face_cy+face_ry+3*sc],
              fill=C['outline'])
    # Face base
    fd.ellipse([face_cx-face_rx, face_cy-face_ry,
               face_cx+face_rx, face_cy+face_ry],
              fill=C['skin_base'])
    
    face_ov = face_ov.filter(ImageFilter.GaussianBlur(radius=int(1.5*sc)))
    img = Image.alpha_composite(img, face_ov)
    d = ImageDraw.Draw(img)
    
    # Face shadow (bottom-right, cel-shaded)
    shadow_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    shd = ImageDraw.Draw(shadow_ov)
    shd.ellipse([face_cx-face_rx*0.7, face_cy+face_ry*0.1,
                face_cx+face_rx*1.05, face_cy+face_ry*1.08],
               fill=(*C['skin_shadow'], 140))
    shadow_ov = shadow_ov.filter(ImageFilter.GaussianBlur(radius=int(8*sc)))
    img = Image.alpha_composite(img, shadow_ov)
    
    # Face highlight (top-left)
    hl_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    hld = ImageDraw.Draw(hl_ov)
    hld.ellipse([face_cx-face_rx*0.75, face_cy-face_ry*0.75,
                face_cx+face_rx*0.25, face_cy+face_ry*0.15],
               fill=(*C['skin_highlight'], 70))
    hl_ov = hl_ov.filter(ImageFilter.GaussianBlur(radius=int(15*sc)))
    img = Image.alpha_composite(img, hl_ov)
    d = ImageDraw.Draw(img)
    
    # ======== EYES: THE STAR OF THE SHOW (BIG, BRIGHT, OUTLINED!) ========
    eye_spacing = face_rx * 0.48
    eye_size = face_ry * 0.28  # VERY large eyes!
    eye_y = face_cy - face_ry * 0.02
    
    for side in [-1, 1]:
        ex = face_cx + eye_spacing * side
        ey = eye_y
        es = eye_size * (1 + random.uniform(-0.02, 0.02))
        
        # Eye white (outlined!)
        ew_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
        ewd = ImageDraw.Draw(ew_ov)
        ewd.ellipse([ex-es*1.2, ey-es*1.0, ex+es*1.2, ey+es*1.0], 
                   fill=C['outline'])
        ewd.ellipse([ex-es*1.15, ey-es*0.95, ex+es*1.15, ey+es*0.95], 
                   fill=(250, 248, 245))
        ew_ov = ew_ov.filter(ImageFilter.GaussianBlur(radius=int(1.2*sc)))
        img = Image.alpha_composite(img, ew_ov)
        
        # Iris layers (VIOLET GRADIENT - the signature!)
        iris_r = es * 0.74
        
        # Outer iris ring (dark violet, outlined feel)
        ir_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
        ird = ImageDraw.Draw(ir_ov)
        ird.ellipse([ex-iris_r, ey-iris_r, ex+iris_r, ey+iris_r], fill=C['eye_outer'])
        ir_ov = ir_ov.filter(ImageFilter.GaussianBlur(radius=int(0.8*sc)))
        img = Image.alpha_composite(img, ir_ov)
        
        # Mid iris (brighter violet)
        ir2_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
        ir2d = ImageDraw.Draw(ir2_ov)
        ir2d.ellipse([ex-iris_r*0.82, ey-iris_r*0.82,
                    ex+iris_r*0.82, ey+iris_r*0.82], fill=C['eye_main'])
        ir2_ov = ir2_ov.filter(ImageFilter.GaussianBlur(radius=int(0.6*sc)))
        img = Image.alpha_composite(img, ir2_ov)
        
        # Inner iris (light violet)
        ir3_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
        ir3d = ImageDraw.Draw(ir3_ov)
        ir3d.ellipse([ex-iris_r*0.54, ey-iris_r*0.54,
                    ex+iris_r*0.54, ey+iris_r*0.54], fill=C['eye_inner'])
        ir3_ov = ir3_ov.filter(ImageFilter.GaussianBlur(radius=int(0.5*sc)))
        img = Image.alpha_composite(img, ir3_ov)
        
        d = ImageDraw.Draw(img)
        
        # Pupil
        pupil_r = iris_r * 0.28
        po_x = pupil_r * 0.1 * side
        po_y = pupil_r * 0.06
        
        p_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
        pd = ImageDraw.Draw(p_ov)
        pd.ellipse([ex+po_x-pupil_r, ey+po_y-pupil_r,
                   ex+po_x+pupil_r, ey+po_y+pupil_r], fill=C['pupil'])
        img = Image.alpha_composite(img, p_ov)
        
        d = ImageDraw.Draw(img)
        
        # HIGHLIGHTS (make eyes SPARKLE!)
        # Main big highlight (top-left)
        h1r = es * 0.26
        h1_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
        h1d = ImageDraw.Draw(h1_ov)
        h1d.ellipse([ex-es*0.32-h1r, ey-es*0.36-h1r,
                   ex-es*0.32+h1r, ey-es*0.36+h1r], fill=C['eye_highlight'])
        img = Image.alpha_composite(img, h1_ov)
        
        # Secondary highlight (bottom-right)
        h2r = es * 0.12
        h2_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
        h2d = ImageDraw.Draw(h2_ov)
        h2d.ellipse([ex+es*0.18-h2r, ey+es*0.26-h2r,
                   ex+es*0.18+h2r, ey+es*0.26+h2r], fill=C['eye_highlight'])
        img = Image.alpha_composite(img, h2_ov)
        
        # Tiny sparkle in eye
        h3r = es * 0.06
        h3_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
        h3d = ImageDraw.Draw(h3_ov)
        h3d.ellipse([ex-es*0.04-h3r, ey+es*0.40-h3r,
                   ex-es*0.04+h3r, ey+es*0.40+h3r], fill=(255, 255, 255, 230))
        img = Image.alpha_composite(img, h3_ov)
        
        d = ImageDraw.Draw(img)
        
        # Upper eyelid line (thick, dark - anime style!)
        lid_pts = []
        lid_base = ey - es*0.96
        for i in range(28):
            t = i / 27
            lx = ex - es*1.15 + es*2.3 * t
            ly = lid_base + math.sin(t*math.pi) * (-es*0.17)
            lid_pts.append((lx, ly))
        
        lid_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
        ldd = ImageDraw.Draw(lid_ov)
        ldd.line(lid_pts, fill=C['outline_thin'], width=max(2, int(3*sc)), joint='curve')
        img = Image.alpha_composite(img, lid_ov)
        d = ImageDraw.Draw(img)
        
        # Lower lashes (few, distinct)
        for la_i in range(4):
            la_t = 0.1 + la_i * 0.25
            la_x = ex - es*0.76 + es*1.52 * la_t
            la_y = ey + es*0.88
            la_len = (2.5 + random.random()*2) * sc
            
            la_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
            lad = ImageDraw.Draw(la_ov)
            la_ang = math.radians(-10 + la_i*6 + random.uniform(-3,3))
            lad.line([(la_x, la_y),
                     (la_x + la_len*math.cos(la_ang),
                      la_y + la_len*math.sin(la_ang))],
                   fill=C['outline_thin'], width=max(1, int(1.5*sc)))
            img = Image.alpha_composite(img, la_ov)
    
    d = ImageDraw.Draw(img)
    
    # ======== EYEBROWS (thick, expressive) ========
    brow_y = eye_y - eye_size * 1.28
    for bs in [-1, 1]:
        bx = face_cx + eye_spacing * 0.86 * bs
        by = brow_y
        bw = eye_size * 0.9
        bh = eye_size * 0.19
        
        brow_pts = []
        for i in range(26):
            t = i / 25
            px = bx - bw*bs + bw*2*t*bs
            py = by + math.sin(t*math.pi)*(-bh)
            brow_pts.append((px, py))
        
        brow_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
        bwd = ImageDraw.Draw(brow_ov)
        bwd.line(brow_pts, fill=C['hair_main'], width=max(2, int(3*sc)), joint='curve')
        brow_ov = brow_ov.filter(ImageFilter.GaussianBlur(radius=int(0.8*sc)))
        img = Image.alpha_composite(img, brow_ov)
    
    d = ImageDraw.Draw(img)
    
    # ======== NOSE (minimal) ========
    nose_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    nd = ImageDraw.Draw(nose_ov)
    nd.ellipse([face_cx-2.5*sc, face_cy+face_ry*0.11-1.5*sc,
              face_cx+2.5*sc, face_cy+face_ry*0.11+2.5*sc],
             fill=(*C['skin_shadow'], 130))
    nose_ov = nose_ov.filter(ImageFilter.GaussianBlur(radius=int(2*sc)))
    img = Image.alpha_composite(img, nose_ov)
    d = ImageDraw.Draw(img)
    
    # ======== BLUSH (VIVID ovals!) ========
    bl_y = face_cy + face_ry * 0.24
    bl_xo = face_rx * 0.38
    
    for bl_s in [-1, 1]:
        blx = face_cx + bl_xo * bl_s
        bly = bl_y
        blr = face_ry * 0.16
        
        bl_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
        bld = ImageDraw.Draw(bl_ov)
        bld.ellipse([blx-blr*1.2, bly-blr*0.8, blx+blr*1.2, bly+blr*0.8],
                   fill=(*C['blush'], 150))
        bl_ov = bl_ov.filter(ImageFilter.GaussianBlur(radius=int(6*sc)))
        img = Image.alpha_composite(img, bl_ov)
    
    d = ImageDraw.Draw(img)
    
    # ======== MOUTH: Happy smile ========
    mx = face_cx
    my = face_cy + face_ry * 0.46
    mw = face_rx * 0.16
    md = face_ry * 0.04
    
    smile_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    smd = ImageDraw.Draw(smile_ov)
    
    smile_pts = []
    for i in range(22):
        t = i / 21
        sx = mx - mw + mw*2*t
        sy = my + math.sin(t*math.pi)*md
        smile_pts.append((sx, sy))
    
    smd.line(smile_pts, fill=C['mouth'], width=max(2, int(2.5*sc)), joint='curve')
    smile_ov = smile_ov.filter(ImageFilter.GaussianBlur(radius=int(0.8*sc)))
    img = Image.alpha_composite(img, smile_ov)
    d = ImageDraw.Draw(img)
    
    # ======== BANGS/Front Hair (outlined!) ========
    bang_base = face_cy - face_ry * 0.58
    
    bang_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    bd = ImageDraw.Draw(bang_ov)
    
    bang_pts = [
        (face_cx + face_rx*1.05, bang_base - face_ry*0.30),
        (face_cx + face_rx*0.55, bang_base - face_ry*0.20),
        (face_cx + face_rx*0.05, bang_base - face_ry*0.10),
        (face_cx - face_rx*0.28, bang_base + face_ry*0.08),
        (face_cx - face_rx*0.50, bang_base + face_ry*0.22),
        (face_cx - face_rx*0.35, bang_base + face_ry*0.36),
        (face_cx + face_rx*0.05, bang_base + face_ry*0.26),
        (face_cx + face_rx*0.45, bang_base + face_ry*0.12),
        (face_cx + face_rx*0.85, bang_base - face_ry*0.0),
    ]
    
    # Outline
    bd.polygon(bang_pts, fill=C['outline'])
    # Fill
    bd.polygon([(p[0]-2*sc, p[1]) for p in bang_pts], fill=C['hair_main'])
    # Highlight
    bd.polygon(bang_pts[:6], fill=(*C['hair_light'], 70))
    
    bang_ov = bang_ov.filter(ImageFilter.GaussianBlur(radius=int(1.5*sc)))
    img = Image.alpha_composite(img, bang_ov)
    d = ImageDraw.Draw(img)
    
    # Individual bang strands
    for si in range(4):
        sx = face_cx - face_rx*0.25 + si*face_rx*0.23
        sy_top = bang_base - face_ry*0.15
        sy_bot = face_cy - face_ry*0.06 + si*face_ry*0.065
        sw = (8 + si*2.5) * sc
        
        str_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
        std = ImageDraw.Draw(str_ov)
        sp = [
            (sx - sw, sy_top),
            (sx + sw*0.3, sy_top + (sy_bot-sy_top)*0.28),
            (sx + sw*0.48, sy_bot),
            (sx - sw*0.5, sy_bot - (sy_bot-sy_top)*0.16),
        ]
        std.polygon(sp, fill=C['outline'])
        std.polygon([(p[0]-1.5*sc, p[1]) for p in sp], 
                  fill=C['hair_main'] if si%2==0 else C['hair_mid'])
        str_ov = str_ov.filter(ImageFilter.GaussianBlur(radius=int(1.2*sc)))
        img = Image.alpha_composite(img, str_ov)
    
    d = ImageDraw.Draw(img)
    
    # ======== BUTTERFLY BOW (right side, VIVID!) ========
    bcx = face_cx + face_rx * 0.98
    bcy = face_cy - face_ry * 0.20
    bsz = face_rx * 0.32
    
    # Left wing (larger)
    lw_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    lwd = ImageDraw.Draw(lw_ov)
    
    wl_pts = []
    for i in range(26):
        t = i / 25
        ang = math.radians(-66 + t*132)
        r = bsz * (0.92 if t<0.4 else (0.86 - 0.36*abs(t-0.5)))
        wx = bcx - bsz*0.16 + r*math.cos(ang)
        wy = bcy + r*math.sin(ang)*0.62
        wl_pts.append((wx, wy))
    
    lwd.polygon(wl_pts, fill=C['outline'])
    lwd.polygon([(p[0]-1.5*sc, p[1]) for p in wl_pts], fill=C['bow_main'])
    lwd.polygon(wl_pts[:14], fill=(*C['bow_light'], 90))
    
    lw_ov = lw_ov.filter(ImageFilter.GaussianBlur(radius=int(2*sc)))
    img = Image.alpha_composite(img, lw_ov)
    d = ImageDraw.Draw(img)
    
    # Right wing (smaller)
    rw_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    rwd = ImageDraw.Draw(rw_ov)
    
    wr_pts = []
    for i in range(20):
        t = i / 19
        ang = math.radians(34 + t*92)
        r = bsz*0.6 * (0.86 if t<0.5 else 0.66)
        wx = bcx + bsz*0.1 + r*math.cos(ang)
        wy = bcy + r*math.sin(ang)*0.52
        wr_pts.append((wx, wy))
    
    rwd.polygon(wr_pts, fill=C['outline'])
    rwd.polygon([(p[0]-1.2*sc, p[1]) for p in wr_pts], fill=C['bow_main'])
    
    rw_ov = rw_ov.filter(ImageFilter.GaussianBlur(radius=int(1.8*sc)))
    img = Image.alpha_composite(img, rw_ov)
    d = ImageDraw.Draw(img)
    
    # Knot
    kn_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    knd = ImageDraw.Draw(kn_ov)
    knd.ellipse([bcx-bsz*0.13, bcy-bsz*0.10,
              bcx+bsz*0.13, bcy+bsz*0.10], fill=C['bow_center'])
    kn_ov = kn_ov.filter(ImageFilter.GaussianBlur(radius=int(1.5*sc)))
    img = Image.alpha_composite(img, kn_ov)
    d = ImageDraw.Draw(img)
    
    # Ribbon tails
    for ti in range(2):
        tx = bcx + (-1 if ti==0 else 1)*bsz*0.12
        ty_top = bcy + bsz*0.08
        ty_bot = bcy + bsz*0.48
        tw = bsz*0.10
        
        tl_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
        tld = ImageDraw.Draw(tl_ov)
        tp = [
            (tx - tw, ty_top),
            (tx + tw*0.45, ty_top + (ty_bot-ty_top)*0.36),
            (tx + tw*0.26, ty_bot),
            (tx - tw*0.55, ty_bot - (ty_bot-ty_top)*0.16),
        ]
        tld.polygon(tp, fill=C['bow_light'])
        tl_ov = tl_ov.filter(ImageFilter.GaussianBlur(radius=int(1.5*sc)))
        img = Image.alpha_composite(img, tl_ov)
    
    d = ImageDraw.Draw(img)
    
    # ======== SUBTLE FACE OUTLINE (overall) ========
    # Light outline around entire face to separate from hair
    out_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    od = ImageDraw.Draw(out_ov)
    od.ellipse([face_cx-face_rx+2*sc, face_cy-face_ry+2*sc,
               face_cx+face_rx-2*sc, face_cy+face_ry-2*sc],
              outline=(*C['outline'], 60), width=max(2, int(3*sc)))
    out_ov = out_ov.filter(ImageFilter.GaussianBlur(radius=int(2*sc)))
    img = Image.alpha_composite(img, out_ov)
    
    # Convert to RGB
    final = Image.new('RGB', (s, s), C['bg_bottom'])
    final.paste(img, (0, 0), img if img.mode == 'RGBA' else None)
    
    return final


if __name__ == '__main__':
    print("Generating v7 icon (BanG Dream / Idol Game Style)...")
    
    sizes = [1024, 512, 192, 96, 72, 48]
    
    for sz in sizes:
        print(f"  Generating {sz}x{sz}...", end=' ', flush=True)
        icon = generate_icon(size=sz, seed=88888)
        
        filename = f'{OUTPUT_DIR}/game_icon_v7_{sz}.png'
        icon.save(filename, 'PNG')
        
        fsize = os.path.getsize(filename) if os.path.exists(filename) else 0
        print(f"✓ {filename} ({fsize:,} bytes)")
    
    print("\n✓ Done! v7 icons generated (Idol Game Style).")
