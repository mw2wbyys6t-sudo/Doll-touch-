#!/usr/bin/env python3
"""
星空愛莉 (Hoshizora Airi) App Icon Generator v6
BALANCED APPROACH: Organic shapes + soft rendering + anime proportions
Key fix: LESS jitter, MORE blur, BETTER curves
"""
from PIL import Image, ImageDraw, ImageFilter
import math
import random
import os

OUTPUT_DIR = '/workspace/ohos_airi'

C = {
    'hair_main':       (78, 55, 40),
    'hair_mid':        (95, 68, 50),
    'hair_light':      (130, 95, 75),
    'hair_tip_pink':   (220, 150, 170),
    'hair_tip_lavender':(180, 140, 200),
    'eye_outer':       (120, 80, 200),
    'eye_main':        (155, 100, 220),
    'eye_inner':       (190, 140, 235),
    'eye_highlight':   (255, 255, 255),
    'pupil':           (35, 20, 60),
    'skin_light':      (255, 248, 240),
    'skin_main':       (250, 235, 222),
    'skin_shadow':     (230, 210, 195),
    'blush':           (245, 180, 190),
    'mouth':           (220, 100, 120),
    'bow_main':        (230, 130, 180),
    'bow_light':       (250, 180, 210),
    'bow_center':      (200, 100, 160),
    'bg_center':       (45, 25, 65),
    'bg_edge':         (18, 8, 30),
}

def lerp(c1, c2, t):
    t = max(0, min(1, t))
    return tuple(int(a + (b - a) * t) for a, b in zip(c1, c2))

def draw_soft_ellipse(draw, cx, cy, rx, ry, fill_color, blur_radius=0):
    """Draw ellipse with optional blur for softness"""
    if isinstance(fill_color[0], int):
        draw.ellipse([cx-rx, cy-ry, cx+rx, cy+ry], fill=fill_color)
    else:
        # RGBA color
        temp = Image.new('RGBA', draw._image.size, (0,0,0,0))
        td = ImageDraw.Draw(temp)
        td.ellipse([cx-rx, cy-ry, cx+rx, cy+ry], fill=fill_color)
        if blur_radius > 0:
            temp = temp.filter(ImageFilter.GaussianBlur(radius=blur_radius))
        return temp
    return None

def generate_icon(size=1024, seed=88888):
    random.seed(seed)
    s = size
    sc = s / 1024  # scale factor
    
    img = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    
    # ======== BACKGROUND: Soft radial gradient ========
    for i in range(40, 0, -1):
        t = i / 40
        r = int(s * 0.52 * t)
        color = lerp(C['bg_center'], C['bg_edge'], 1-t)
        alpha = int(255 * (1 - (1-t)**1.8))
        
        overlay = Image.new('RGBA', (s, s), (0, 0, 0, 0))
        d = ImageDraw.Draw(overlay)
        d.ellipse([s//2-r, s//2-r, s//2+r, s//2+r], fill=(*color, alpha))
        overlay = overlay.filter(ImageFilter.GaussianBlur(radius=max(1, int(s*0.02))))
        img = Image.alpha_composite(img, overlay)
    
    # Off-center purple glow (break symmetry subtly)
    glow_overlay = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow_overlay)
    glow_cx = int(s * 0.58)
    glow_cy = int(s * 0.42)
    gd.ellipse([glow_cx-int(s*0.15), glow_cy-int(s*0.12), 
                glow_cx+int(s*0.15), glow_cy+int(s*0.12)], 
               fill=(150, 90, 210, 45))
    glow_overlay = glow_overlay.filter(ImageFilter.GaussianBlur(radius=int(s*0.08)))
    img = Image.alpha_composite(img, glow_overlay)
    
    # ======== STARS: Varied sizes, organic placement ========
    star_data = [
        (0.17, 0.14, 14, 4), (0.79, 0.21, 10, 4), (0.11, 0.56, 7, 5),
        (0.87, 0.63, 11, 4), (0.24, 0.83, 8, 5), (0.73, 0.86, 6, 4),
        (0.44, 0.07, 7, 4), (0.91, 0.36, 5, 5), (0.09, 0.37, 6, 4),
    ]
    
    for sx, sy, sr, pts in star_data:
        sx = int(s * sx + random.uniform(-8, 8))
        sy = int(s * sy + random.uniform(-8, 8))
        sr = int(sr * sc * random.uniform(0.9, 1.1))
        
        angles = []
        rot = random.uniform(0, math.pi)
        for i in range(pts * 2):
            angle = math.pi / pts * i + rot - math.pi/2
            r = sr if i % 2 == 0 else sr * 0.38
            angles.append((sx + r*math.cos(angle), sy + r*math.sin(angle)))
        
        d = ImageDraw.Draw(img)
        d.polygon(angles, fill=(255, 255, 255, random.randint(200, 255)))
    
    # Sparkle dots
    for _ in range(35):
        dx = random.randint(int(s*0.04), int(s*0.96))
        dy = random.randint(int(s*0.04), int(s*0.96))
        ds = random.uniform(1.5, 3) * sc
        
        dot_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
        dd = ImageDraw.Draw(dot_ov)
        dd.ellipse([dx-ds, dy-ds, dx+ds, dy+ds], fill=(255, 255, 255, random.randint(100, 200)))
        dot_ov = dot_ov.filter(ImageFilter.GaussianBlur(radius=max(1, int(ds))))
        img = Image.alpha_composite(img, dot_ov)
    
    # ======== CHARACTER FACE ========
    face_cx = s // 2 + int(random.uniform(-5, 3) * sc)  # Slight asymmetry
    face_cy = int(s * 0.52)
    face_rx = int(s * 0.27)  
    face_ry = int(s * 0.31)
    
    # Face shadow layer (larger, darker, blurred)
    shadow_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow_ov)
    sd.ellipse([face_cx-face_rx-10*sc, face_cy-face_ry-12*sc,
               face_cx+face_rx+10*sc, face_cy+face_ry+12*sc], 
              fill=C['skin_shadow'])
    shadow_ov = shadow_ov.filter(ImageFilter.GaussianBlur(radius=int(12*sc)))
    img = Image.alpha_composite(img, shadow_ov)
    
    # Main face (soft edges via blur)
    face_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    fd = ImageDraw.Draw(face_ov)
    fd.ellipse([face_cx-face_rx, face_cy-face_ry,
               face_cx+face_rx, face_cy+face_ry], 
              fill=C['skin_main'])
    face_ov = face_ov.filter(ImageFilter.GaussianBlur(radius=int(2*sc)))
    img = Image.alpha_composite(img, face_ov)
    
    # Face highlight (top-left lighting)
    hl_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    hld = ImageDraw.Draw(hl_ov)
    hld.ellipse([face_cx-face_rx*0.7, face_cy-face_ry*0.7,
                face_cx+face_rx*0.3, face_cy+face_ry*0.2],
               fill=(*C['skin_light'], 55))
    hl_ov = hl_ov.filter(ImageFilter.GaussianBlur(radius=int(18*sc)))
    img = Image.alpha_composite(img, hl_ov)
    
    d = ImageDraw.Draw(img)
    
    # ======== HAIR BACK LAYER ========
    hair_back_w = face_rx * 1.6
    hair_back_h = face_ry * 1.9
    
    # Hair back (large organic shape)
    hair_back_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    hbd = ImageDraw.Draw(hair_back_ov)
    
    # Use superellipse-like shape with slight asymmetry
    hb_pts = []
    hb_steps = 80
    for i in range(hb_steps):
        angle = 2 * math.pi * i / hb_steps
        
        # Superellipse formula with noise
        cos_a = math.cos(angle)
        sin_a = math.sin(angle)
        
        n = 2.3  # Superellipse exponent (between circle and square)
        r_x = hair_back_w * (abs(cos_a) ** (2/n)) * (1 if cos_a >= 0 else -1)
        r_y = hair_back_h * (abs(sin_a) ** (2/n)) * (1 if sin_a >= 0 else -1)
        
        px = face_cx + r_x + random.uniform(-2, 2)*sc
        py = face_cy + r_y * 0.85 + random.uniform(-2, 2)*sc  # Slightly higher center
        hb_pts.append((px, py))
    
    hbd.polygon(hb_pts, fill=C['hair_main'])
    hair_back_ov = hair_back_ov.filter(ImageFilter.GaussianBlur(radius=int(3*sc)))
    img = Image.alpha_composite(img, hair_back_ov)
    d = ImageDraw.Draw(img)
    
    # Hair shading layers
    for shade_i in range(3):
        shade_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
        shd = ImageDraw.Draw(shade_ov)
        
        sh_pts = [(p[0] - shade_i*6*sc, p[1] + shade_i*4*sc) for p in hb_pts]
        shd.polygon(sh_pts, fill=(*C['hair_mid'], 30 - shade_i*8))
        shade_ov = shade_ov.filter(ImageFilter.GaussianBlur(radius=int((10 + shade_i*5)*sc)))
        img = Image.alpha_composite(img, shade_ov)
    
    d = ImageDraw.Draw(img)
    
    # Side hair locks (left side - flowing down with pink tips)
    for lock_idx in range(3):
        lock_x = face_cx - face_rx*(0.82 + lock_idx*0.13)
        lock_top = face_cy - face_ry*(0.28 + lock_idx*0.08)
        lock_bot = face_cy + face_ry*(0.88 + lock_idx*0.1)
        lock_w = (14 + lock_idx*5) * sc
        
        lock_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
        ld = ImageDraw.Draw(lock_ov)
        
        # Tapered lock shape
        lock_pts = [
            (lock_x - lock_w, lock_top),
            (lock_x + lock_w*0.4, lock_top + (lock_bot-lock_top)*0.22),
            (lock_x + lock_w*0.55, lock_bot),
            (lock_x - lock_w*0.75, lock_bot - (lock_bot-lock_top)*0.18),
        ]
        ld.polygon(lock_pts, fill=C['hair_main'])
        
        # Pink/lavender tip gradient
        tip_color = lerp(C['hair_tip_pink'], C['hair_tip_lavender'], lock_idx * 0.33)
        tip_pts = [(p[0], max(p[1], lock_top + (lock_bot-lock_top)*0.58)) for p in lock_pts]
        ld.polygon(tip_pts, fill=(*tip_color, 90))
        
        lock_ov = lock_ov.filter(ImageFilter.GaussianBlur(radius=int(4*sc)))
        img = Image.alpha_composite(img, lock_ov)
    
    d = ImageDraw.Draw(img)
    
    # Right side hair (shorter)
    for lock_idx in range(2):
        lock_x = face_cx + face_rx*(0.88 + lock_idx*0.1)
        lock_top = face_cy - face_ry*0.18
        lock_bot = face_cy + face_ry*(0.48 + lock_idx*0.08)
        lock_w = (12 + lock_idx*4) * sc
        
        lock_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
        ld = ImageDraw.Draw(lock_ov)
        lock_pts = [
            (lock_x - lock_w*0.5, lock_top),
            (lock_x + lock_w, lock_top + (lock_bot-lock_top)*0.25),
            (lock_x + lock_w*0.65, lock_bot),
            (lock_x - lock_w*0.35, lock_bot - (lock_bot-lock_top)*0.1),
        ]
        ld.polygon(lock_pts, fill=C['hair_mid'] if lock_idx == 0 else C['hair_main'])
        lock_ov = lock_ov.filter(ImageFilter.GaussianBlur(radius=int(3*sc)))
        img = Image.alpha_composite(img, lock_ov)
    
    d = ImageDraw.Draw(img)
    
    # ======== EYES: Signature violet eyes (CRITICAL!) ========
    eye_spacing = face_rx * 0.50
    eye_size = face_ry * 0.24  # Large anime eyes!
    eye_y = face_cy - face_ry * 0.03
    
    for eye_side in [-1, 1]:
        ex = face_cx + eye_spacing * eye_side
        ey = eye_y + random.uniform(-2, 2) * sc * eye_side
        es = eye_size * (1 + random.uniform(-0.02, 0.02))
        
        # Eye white (warm white, not pure)
        ew_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
        ewd = ImageDraw.Draw(ew_ov)
        ewd.ellipse([ex-es*1.18, ey-es*0.98, ex+es*1.18, ey+es*0.98], 
                   fill=(252, 250, 247))
        ew_ov = ew_ov.filter(ImageFilter.GaussianBlur(radius=int(2*sc)))
        img = Image.alpha_composite(img, ew_ov)
        
        # Iris layers (violet gradient!)
        iris_r = es * 0.76
        
        # Outer iris (dark violet)
        ir_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
        ird = ImageDraw.Draw(ir_ov)
        ird.ellipse([ex-iris_r, ey-iris_r, ex+iris_r, ey+iris_r], fill=C['eye_outer'])
        ir_ov = ir_ov.filter(ImageFilter.GaussianBlur(radius=int(1.5*sc)))
        img = Image.alpha_composite(img, ir_ov)
        
        # Mid iris (bright violet)
        ir2_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
        ir2d = ImageDraw.Draw(ir2_ov)
        ir2d.ellipse([ex-iris_r*0.84, ey-iris_r*0.84, 
                    ex+iris_r*0.84, ey+iris_r*0.84], fill=C['eye_main'])
        ir2_ov = ir2_ov.filter(ImageFilter.GaussianBlur(radius=int(1*sc)))
        img = Image.alpha_composite(img, ir2_ov)
        
        # Inner iris (light violet)
        ir3_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
        ir3d = ImageDraw.Draw(ir3_ov)
        ir3d.ellipse([ex-iris_r*0.56, ey-iris_r*0.56,
                    ex+iris_r*0.56, ey+iris_r*0.56], fill=C['eye_inner'])
        ir3_ov = ir3_ov.filter(ImageFilter.GaussianBlur(radius=int(0.8*sc)))
        img = Image.alpha_composite(img, ir3_ov)
        
        d = ImageDraw.Draw(img)
        
        # Pupil
        pupil_r = iris_r * 0.30
        pupil_off_x = pupil_r * 0.12 * eye_side
        pupil_off_y = pupil_r * 0.08
        
        p_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
        pd = ImageDraw.Draw(p_ov)
        pd.ellipse([ex+pupil_off_x-pupil_r, ey+pupil_off_y-pupil_r,
                   ex+pupil_off_x+pupil_r, ey+pupil_off_y+pupil_r], fill=C['pupil'])
        p_ov = p_ov.filter(ImageFilter.GaussianBlur(radius=int(0.5*sc)))
        img = Image.alpha_composite(img, p_ov)
        
        d = ImageDraw.Draw(img)
        
        # HIGHLIGHTS (make eyes sparkle!)
        # Main large highlight (top-left)
        hl1_r = es * 0.24
        h1_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
        h1d = ImageDraw.Draw(h1_ov)
        h1d.ellipse([ex-es*0.30-hl1_r, ey-es*0.34-hl1_r,
                   ex-es*0.30+hl1_r, ey-es*0.34+hl1_r], fill=C['eye_highlight'])
        h1_ov = h1_ov.filter(ImageFilter.GaussianBlur(radius=int(1*sc)))
        img = Image.alpha_composite(img, h1_ov)
        
        # Secondary highlight (bottom-right)
        hl2_r = es * 0.11
        h2_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
        h2d = ImageDraw.Draw(h2_ov)
        h2d.ellipse([ex+es*0.16-hl2_r, ey+es*0.24-hl2_r,
                   ex+es*0.16+hl2_r, ey+es*0.24+hl2_r], fill=C['eye_highlight'])
        h2_ov = h2_ov.filter(ImageFilter.GaussianBlur(radius=int(0.5*sc)))
        img = Image.alpha_composite(img, h2_ov)
        
        # Tiny third highlight (adds life)
        if random.random() > 0.3:
            hl3_r = es * 0.06
            h3_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
            h3d = ImageDraw.Draw(h3_ov)
            h3d.ellipse([ex-es*0.05-hl3_r, ey+es*0.38-hl3_r,
                       ex-es*0.05+hl3_r, ey+es*0.38+hl3_r], fill=(255, 255, 255, 220))
            img = Image.alpha_composite(img, h3_ov)
        
        d = ImageDraw.Draw(img)
        
        # Upper eyelid line (soft curve)
        lid_pts = []
        lid_y_base = ey - es*0.92
        for i in range(30):
            t = i / 29
            lx = ex - es*1.12 + es*2.24 * t
            ly = lid_y_base + math.sin(t * math.pi) * (-es*0.16)
            lid_pts.append((lx, ly))
        
        if len(lid_pts) >= 2:
            lid_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
            ldd = ImageDraw.Draw(lid_ov)
            ldd.line(lid_pts, fill=(60, 35, 90), width=max(1, int(2.5*sc)), joint='curve')
            lid_ov = lid_ov.filter(ImageFilter.GaussianBlur(radius=int(0.8*sc)))
            img = Image.alpha_composite(img, lid_ov)
        
        d = ImageDraw.Draw(img)
        
        # Lower lashes (subtle)
        for lash_i in range(4):
            lash_t = 0.12 + lash_i * 0.24
            lash_x = ex - es*0.78 + es*1.56 * lash_t
            lash_y = ey + es*0.86
            lash_len = (2 + random.random() * 2.5) * sc
            
            lash_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
            lashd = ImageDraw.Draw(lash_ov)
            lash_angle = math.radians(-12 + lash_i * 7 + random.uniform(-4, 4))
            lashd.line([(lash_x, lash_y), 
                      (lash_x + lash_len*math.cos(lash_angle), 
                       lash_y + lash_len*math.sin(lash_angle))],
                     fill=(70, 40, 100), width=max(1, int(1.3*sc)))
            img = Image.alpha_composite(img, lash_ov)
    
    d = ImageDraw.Draw(img)
    
    # ======== EYEBROWS ========
    brow_y = eye_y - eye_size * 1.32
    for brow_side in [-1, 1]:
        bx = face_cx + eye_spacing * 0.88 * brow_side
        by = brow_y
        brow_w = eye_size * 0.88
        brow_h = eye_size * 0.17
        
        brow_pts = []
        for i in range(25):
            t = i / 24
            px = bx - brow_w * brow_side + brow_w * 2 * t * brow_side
            py = by + math.sin(t * math.pi) * (-brow_h)
            brow_pts.append((px, py))
        
        brow_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
        bd = ImageDraw.Draw(brow_ov)
        bd.line(brow_pts, fill=C['hair_main'], width=max(1, int(2.6*sc)), joint='curve')
        brow_ov = brow_ov.filter(ImageFilter.GaussianBlur(radius=int(1*sc)))
        img = Image.alpha_composite(img, brow_ov)
    
    d = ImageDraw.Draw(img)
    
    # ======== NOSE (minimal) ========
    nose_x = face_cx
    nose_y = face_cy + face_ry * 0.12
    nose_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    nd = ImageDraw.Draw(nose_ov)
    nd.ellipse([nose_x-2*sc, nose_y-1.5*sc, nose_x+2*sc, nose_y+2.5*sc], 
              fill=(*C['skin_shadow'], 120))
    nose_ov = nose_ov.filter(ImageFilter.GaussianBlur(radius=int(2*sc)))
    img = Image.alpha_composite(img, nose_ov)
    
    d = ImageDraw.Draw(img)
    
    # ======== BLUSH ========
    blush_y = face_cy + face_ry * 0.26
    blush_x_off = face_rx * 0.40
    
    for bl_side in [-1, 1]:
        blx = face_cx + blush_x_off * bl_side
        bly = blush_y
        blr = face_ry * 0.15
        
        for bl_l in range(4):
            bl_alpha = 32 - bl_l * 7
            bl_scale = 1 + bl_l * 0.28
            
            bl_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
            bld = ImageDraw.Draw(bl_ov)
            bld.ellipse([blx-blr*bl_scale, bly-blr*bl_scale*0.72,
                       blx+blr*bl_scale, bly+blr*bl_scale*0.72],
                      fill=(*C['blush'], bl_alpha))
            bl_ov = bl_ov.filter(ImageFilter.GaussianBlur(radius=int((6 + bl_l*2)*sc)))
            img = Image.alpha_composite(img, bl_ov)
    
    d = ImageDraw.Draw(img)
    
    # ======== MOUTH: Gentle smile ========
    mouth_x = face_cx
    mouth_y = face_cy + face_ry * 0.47
    mouth_w = face_rx * 0.17
    smile_d = face_ry * 0.038
    
    smile_pts = []
    for i in range(22):
        t = i / 21
        sx = mouth_x - mouth_w + mouth_w * 2 * t
        sy = mouth_y + math.sin(t * math.pi) * smile_d
        smile_pts.append((sx, sy))
    
    mouth_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    md = ImageDraw.Draw(mouth_ov)
    md.line(smile_pts, fill=C['mouth'], width=max(1, int(2*sc)), joint='curve')
    mouth_ov = mouth_ov.filter(ImageFilter.GaussianBlur(radius=int(0.8*sc)))
    img = Image.alpha_composite(img, mouth_ov)
    
    # Lip tint
    lip_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    lipd = ImageDraw.Draw(lip_ov)
    lipd.ellipse([mouth_x-mouth_w*0.42, mouth_y+smile_d*0.3-mouth_w*0.15,
                mouth_x+mouth_w*0.42, mouth_y+smile_d*0.3+mouth_w*0.15],
               fill=(*C['mouth'], 35))
    lip_ov = lip_ov.filter(ImageFilter.GaussianBlur(radius=int(3*sc)))
    img = Image.alpha_composite(img, lip_ov)
    
    d = ImageDraw.Draw(img)
    
    # ======== BANGS/Front Hair ========
    bang_base_y = face_cy - face_ry * 0.62
    
    # Main bang shape
    bang_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    bd = ImageDraw.Draw(bang_ov)
    
    bang_pts = [
        (face_cx + face_rx*1.08, bang_base_y - face_ry*0.32),
        (face_cx + face_rx*0.58, bang_base_y - face_ry*0.22),
        (face_cx + face_rx*0.08, bang_base_y - face_ry*0.12),
        (face_cx - face_rx*0.32, bang_base_y + face_ry*0.06),
        (face_cx - face_rx*0.55, bang_base_y + face_ry*0.20),
        (face_cx - face_rx*0.38, bang_base_y + face_ry*0.34),
        (face_cx + face_rx*0.02, bang_base_y + face_ry*0.24),
        (face_cx + face_rx*0.48, bang_base_y + face_ry*0.10),
        (face_cx + face_rx*0.88, bang_base_y - face_ry*0.02),
    ]
    bd.polygon(bang_pts, fill=C['hair_main'])
    
    # Bang highlight
    bd.polygon(bang_pts[:6], fill=(*C['hair_light'], 65))
    
    bang_ov = bang_ov.filter(ImageFilter.GaussianBlur(radius=int(3*sc)))
    img = Image.alpha_composite(img, bang_ov)
    
    d = ImageDraw.Draw(img)
    
    # Individual bang strands
    for strand_i in range(4):
        strand_x = face_cx - face_rx*0.28 + strand_i * face_rx*0.24
        strand_top = bang_base_y - face_ry*0.18
        strand_bot = face_cy - face_ry*0.08 + strand_i * face_ry*0.07
        strand_w = (7 + strand_i * 2.5) * sc
        
        strand_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
        sd = ImageDraw.Draw(strand_ov)
        sd.polygon([
            (strand_x - strand_w, strand_top),
            (strand_x + strand_w*0.3, strand_top + (strand_bot-strand_top)*0.3),
            (strand_x + strand_w*0.5, strand_bot),
            (strand_x - strand_w*0.55, strand_bot - (strand_bot-strand_top)*0.18),
        ], fill=C['hair_main'] if strand_i % 2 == 0 else C['hair_mid'])
        strand_ov = strand_ov.filter(ImageFilter.GaussianBlur(radius=int(2*sc)))
        img = Image.alpha_composite(img, strand_ov)
    
    d = ImageDraw.Draw(img)
    
    # ======== BUTTERFLY BOW (Right side) ========
    bow_cx = face_cx + face_rx * 1.02
    bow_cy = face_cy - face_ry * 0.23
    bow_sz = face_rx * 0.34
    
    # Left wing
    wing_l_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    wld = ImageDraw.Draw(wing_l_ov)
    
    wl_pts = []
    for i in range(28):
        t = i / 27
        angle = math.radians(-68 + t * 136)
        r = bow_sz * (0.94 if t < 0.4 else (0.88 - 0.38 * abs(t-0.5)))
        wx = bow_cx - bow_sz*0.18 + r * math.cos(angle)
        wy = bow_cy + r * math.sin(angle) * 0.64
        wl_pts.append((wx, wy))
    
    wld.polygon(wl_pts, fill=C['bow_main'])
    wld.polygon(wl_pts[:16], fill=(*C['bow_light'], 75))
    wing_l_ov = wing_l_ov.filter(ImageFilter.GaussianBlur(radius=int(3*sc)))
    img = Image.alpha_composite(img, wing_l_ov)
    
    # Right wing (smaller)
    wing_r_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    wrd = ImageDraw.Draw(wing_r_ov)
    
    wr_pts = []
    for i in range(22):
        t = i / 21
        angle = math.radians(32 + t * 96)
        r = bow_sz * 0.63 * (0.88 if t < 0.5 else 0.68)
        wx = bow_cx + bow_sz*0.12 + r * math.cos(angle)
        wy = bow_cy + r * math.sin(angle) * 0.54
        wr_pts.append((wx, wy))
    
    wrd.polygon(wr_pts, fill=C['bow_main'])
    wing_r_ov = wing_r_ov.filter(ImageFilter.GaussianBlur(radius=int(2.5*sc)))
    img = Image.alpha_composite(img, wing_r_ov)
    
    d = ImageDraw.Draw(img)
    
    # Bow knot
    knot_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    kd = ImageDraw.Draw(knot_ov)
    kd.ellipse([bow_cx-bow_sz*0.14, bow_cy-bow_sz*0.11,
              bow_cx+bow_sz*0.14, bow_cy+bow_sz*0.11], fill=C['bow_center'])
    knot_ov = knot_ov.filter(ImageFilter.GaussianBlur(radius=int(2*sc)))
    img = Image.alpha_composite(img, knot_ov)
    
    # Ribbon tails
    for tail_i in range(2):
        tail_x = bow_cx + (-1 if tail_i == 0 else 1) * bow_sz*0.14
        tail_top = bow_cy + bow_sz*0.09
        tail_bot = bow_cy + bow_sz*0.52
        tail_w = bow_sz * 0.11
        
        tail_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
        td = ImageDraw.Draw(tail_ov)
        td.polygon([
            (tail_x - tail_w, tail_top),
            (tail_x + tail_w*0.48, tail_top + (tail_bot-tail_top)*0.38),
            (tail_x + tail_w*0.28, tail_bot),
            (tail_x - tail_w*0.58, tail_bot - (tail_bot-tail_top)*0.18),
        ], fill=C['bow_light'])
        tail_ov = tail_ov.filter(ImageFilter.GaussianBlur(radius=int(2*sc)))
        img = Image.alpha_composite(img, tail_ov)
    
    d = ImageDraw.Draw(img)
    
    # ======== SPEECH BUBBLE (Bottom-right) ========
    bub_cx = int(s * 0.81)
    bub_cy = int(s * 0.77)
    bub_w = int(s * 0.25)
    bub_h = int(s * 0.17)
    bub_r = int(16 * sc)
    
    # Bubble shadow
    bub_sh_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    bsd = ImageDraw.Draw(bub_sh_ov)
    bsd.rounded_rectangle([bub_cx-bub_w//2+4*sc, bub_cy-bub_h//2+4*sc,
                          bub_cx+bub_w//2+4*sc, bub_cy+bub_h//2+4*sc],
                         radius=bub_r, fill=(0, 0, 0, 35))
    bub_sh_ov = bub_sh_ov.filter(ImageFilter.GaussianBlur(radius=int(8*sc)))
    img = Image.alpha_composite(img, bub_sh_ov)
    
    # Main bubble
    bub_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    bud = ImageDraw.Draw(bub_ov)
    
    # Rounded rectangle + tail
    bub_main_pts = [
        (bub_cx-bub_w//2, bub_cy-bub_h//2+bub_r),
        (bub_cx-bub_w//2, bub_cy+bub_h//2-bub_r),
        (bub_cx-bub_w//2+bub_r, bub_cy+bub_h//2),
        (bub_cx+bub_w//2-bub_r, bub_cy+bub_h//2),
        (bub_cx+bub_w//2, bub_cy+bub_h//2-bub_r),
        (bub_cx+bub_w//2, bub_cy-bub_h//2+bub_r),
        (bub_cx+bub_w//2-bub_r, bub_cy-bub_h//2),
        (bub_cx-bub_w//2+bub_r, bub_cy-bub_h//2),
        # Tail
        (bub_cx-bub_w*0.28, bub_cy+bub_h*0.10),
        (bub_cx-bub_w*0.44, bub_cy+bub_h*0.36),
        (bub_cx-bub_w*0.18, bub_cy+bub_h*0.19),
    ]
    bud.polygon(bub_main_pts, fill=(255, 255, 252, 242))
    
    # Typing dots
    dot_colors = [(175, 115, 175), (195, 135, 195), (165, 105, 165)]
    for di, dc in enumerate(dot_colors):
        dx = bub_cx - bub_w*0.18 + di * bub_w*0.14
        dy = bub_cy
        dr = 5.5 * sc
        
        dot_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
        dd = ImageDraw.Draw(dot_ov)
        dd.ellipse([dx-dr, dy-dr, dx+dr, dy+dr], fill=(*dc, 195))
        dot_ov = dot_ov.filter(ImageFilter.GaussianBlur(radius=int(1.5*sc)))
        img = Image.alpha_composite(img, dot_ov)
    
    bub_ov = bub_ov.filter(ImageFilter.GaussianBlur(radius=int(1.5*sc)))
    img = Image.alpha_composite(img, bub_ov)
    
    # ======== FINAL VIGNETTE ========
    vig_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    vd = ImageDraw.Draw(vig_ov)
    for vi in range(25, 0, -1):
        vt = vi / 25
        vr = int(s * 0.51 * vt)
        va = int(22 * (1-vt))
        vd.ellipse([s//2-vr, s//2-vr, s//2+vr, s//2+vr], fill=(10, 5, 20, va))
    vig_ov = vig_ov.filter(ImageFilter.GaussianBlur(radius=int(25*sc)))
    img = Image.alpha_composite(img, vig_ov)
    
    # Convert to RGB
    final = Image.new('RGB', (s, s), C['bg_edge'])
    final.paste(img, (0, 0), img if img.mode == 'RGBA' else None)
    
    return final


if __name__ == '__main__':
    print("Generating v6 icon (balanced anti-AI aesthetic)...")
    
    sizes = [1024, 512, 192, 96, 72, 48]
    
    for sz in sizes:
        print(f"  Generating {sz}x{sz}...", end=' ', flush=True)
        icon = generate_icon(size=sz, seed=88888)
        
        filename = f'{OUTPUT_DIR}/game_icon_v6_{sz}.png'
        icon.save(filename, 'PNG')
        
        fsize = os.path.getsize(filename) if os.path.exists(filename) else 0
        print(f"✓ {filename} ({fsize:,} bytes)")
    
    print("\n✓ Done! v6 icons generated.")
