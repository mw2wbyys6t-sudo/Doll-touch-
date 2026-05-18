#!/usr/bin/env python3
"""
星空愛莉 (Hoshizora Airi) App Icon Generator v4
Based on REAL character reference - dark brown hair, violet eyes, butterfly bow
"""
from PIL import Image, ImageDraw, ImageFilter, ImageFont
import math
import os

OUTPUT_DIR = '/workspace/ohos_airi'

# ======== CHARACTER-COLOR-ACCURATE PALETTE ========
# Extracted from the official character reference sheet
C = {
    # Hair: dark brown main + pink-lavender tips
    'hair_main':       (78, 55, 40),    # #4E3728 deep brown
    'hair_mid':        (95, 68, 50),    # #5F4432 medium brown  
    'hair_light':      (130, 95, 75),   # #825F4B light brown
    'hair_tip_pink':   (220, 150, 170), # DC96AA pink tip
    'hair_tip_lavender':(180, 140, 200),# B48CC8 lavender tip
    
    # Eyes: violet/purple (THE signature color!)
    'eye_outer':       (120, 80, 200),  # 7850C8 violet
    'eye_main':        (155, 100, 220), # 9B64DC bright violet
    'eye_inner':       (190, 140, 235), # BE8CEB light violet
    'eye_highlight':   (255, 255, 255), # white
    'pupil':           (35, 20, 60),    # 23143C dark purple
    'pupil_inner':     (60, 35, 100),   # 3C2364
    
    # Skin: warm fair
    'skin_light':      (255, 248, 240), # FFF8F0
    'skin_main':       (250, 235, 222), # FAEBDE
    'skin_shadow':     (230, 210, 195), # E6D2C3
    'blush':           (245, 180, 190), # F5B4BE soft pink blush
    
    # Mouth
    'mouth':           (220, 100, 120), # DC6478 coral pink
    
    # Bow accessory: pink-purple (right side of hair)
    'bow_main':        (230, 130, 180), # E682B4 pink-purple
    'bow_light':       (250, 180, 210), # FAB4D2 light pink
    'bow_center':      (200, 100, 160), # C864A0 dark center
    'bow_highlight':   (255, 220, 240), # FFDCF0
    
    # Background: dreamy starry night (soft version)
    'bg_center':       (45, 25, 65),    # 2D1941 deep indigo
    'bg_mid':          (30, 15, 45),    # 1E0F2D darker
    'bg_edge':         (18, 8, 30),     # 12081E darkest
    'glow_purple':     (150, 80, 200, 180), # glow
    'glow_pink':       (255, 150, 200, 140),
    
    # Stars
    'star_bright':     (255, 255, 255, 250),
    'star_dim':        (255, 255, 255, 120),
    
    # Speech bubble
    'bubble_fill':     (255, 255, 255, 245),
    'bubble_stroke':   (255, 255, 255),
    'bubble_dots':     (180, 100, 170, 200), # violet-pink dots
}

def lerp(c1, c2, t):
    """Linear interpolation between two colors"""
    return tuple(int(a + (b - a) * t) for a, b in zip(c1, c2))

def radial_gradient(draw, cx, cy, r, c_inner, c_outer):
    """Draw a radial gradient circle"""
    for i in range(r, 0, -1):
        t = i / r
        color = lerp(c_inner, c_outer, 1 - t)
        draw.ellipse([cx-i, cy-i, cx+i, cy+i], fill=color)

def draw_star(draw, cx, cy, r, points=5, rotation=0, color=C['star_bright']):
    """Draw a star shape"""
    import math
    angles = []
    for i in range(points * 2):
        angle = math.pi / points * i + rotation - math.pi / 2
        if i % 2 == 0:
            angles.append((cx + r * math.cos(angle), cy + r * math.sin(angle)))
        else:
            angles.append((cx + r * 0.4 * math.cos(angle), cy + r * 0.4 * math.sin(angle)))
    
    draw.polygon(angles, fill=color)

def draw_butterfly_bow(draw, cx, cy, size, rotation=10):
    """Draw the characteristic butterfly bow accessory"""
    import math
    s = size
    
    # Left wing (larger)
    wing_l_pts = []
    for i in range(20):
        t = i / 19
        angle = math.radians(-60 + t * 120) + math.radians(rotation)
        r = s * (0.9 if t < 0.5 else 0.7 - 0.5 * ((t-0.5)*2))
        wx = cx - s*0.3 + r * math.cos(angle)
        wy = cy + r * math.sin(angle) * 0.6
        wing_l_pts.append((wx, wy))
    
    # Right wing (larger)
    wing_r_pts = []
    for i in range(20):
        t = i / 19
        angle = math.radians(-60 + t * 120) - math.radians(rotation)
        r = s * (0.9 if t < 0.5 else 0.7 - 0.5 * ((t-0.5)*2))
        wx = cx + s*0.3 + r * math.cos(angle)
        wy = cy + r * math.sin(angle) * 0.6
        wing_r_pts.append((wx, wy))
    
    # Draw wings with gradient effect
    # Left wing
    draw.polygon(wing_l_pts, fill=C['bow_main'])
    # Inner left wing highlight
    inner_l = [(x*0.85 + cx*0.15, y*0.85 + cy*0.15) for x,y in wing_l_pts[:10]] + \
              [(wing_l_pts[10][0]*0.9 + cx*0.1, wing_l_pts[10][1]*0.9 + cy*0.1)] + \
              [(x*0.82 + cx*0.18, y*0.82 + cy*0.18) for x,y in wing_l_pts[10:]]
    draw.polygon(inner_l, fill=C['bow_light'])
    
    # Right wing
    draw.polygon(wing_r_pts, fill=C['bow_main'])
    inner_r = [(x*0.85 + cx*0.15, y*0.85 + cy*0.15) for x,y in wing_r_pts[:10]] + \
              [(wing_r_pts[10][0]*0.9 + cx*0.1, wing_r_pts[10][1]*0.9 + cy*0.1)] + \
              [(x*0.82 + cx*0.18, y*0.82 + cy*0.18) for x,y in wing_r_pts[10:]]
    draw.polygon(inner_r, fill=C['bow_light'])
    
    # Center knot
    knot_r = s * 0.22
    draw.ellipse([cx-knot_r, cy-knot_r*0.7, cx+knot_r, cy+knot_r*0.7], fill=C['bow_center'])
    # Knot highlight
    draw.ellipse([cx-knot_r*0.5, cy-knot_r*0.4, cx+knot_r*0.4, cy+knot_r*0.2], fill=C['bow_highlight'])
    
    # Ribbon tails hanging down
    tail_len = s * 0.8
    # Left tail
    tail_l = [
        (cx - s*0.15, cy + s*0.4),
        (cx - s*0.25, cy + tail_len),
        (cx - s*0.08, cy + tail_len + s*0.15),
        (cx - s*0.02, cy + s*0.45),
    ]
    draw.polygon(tail_l, fill=C['bow_main'])
    
    # Right tail
    tail_r = [
        (cx + s*0.12, cy + s*0.38),
        (cx + s*0.22, cy + tail_len),
        (cx + s*0.08, cy + tail_len + s*0.12),
        (cx + s*0.02, cy + s*0.42),
    ]
    draw.polygon(tail_r, fill=C['bow_main'])

def generate_icon(size=1024, seed=88888):
    """Generate the Hoshizora Airi app icon"""
    
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    S = size / 1024  # scale factor
    cx, cy = size // 2, size // 2 - int(20 * S)
    
    import random
    random.seed(seed)
    
    # ======== LAYER 1: Background (soft starry gradient) ========
    # Main background gradient
    for r in range(size, 0, -2):
        t = r / size
        if t < 0.5:
            c = lerp(C['bg_center'], C['bg_mid'], t * 2)
        else:
            c = lerp(C['bg_mid'], C['bg_edge'], (t - 0.5) * 2)
        draw.ellipse([size//2-r, size//2-r, size//2+r, size//2+r], fill=c)
    
    # Soft ambient glow behind character
    glow_size = int(380 * S)
    glow = Image.new('RGBA', (glow_size*2, glow_size*2), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    for r in range(glow_size, 0, -3):
        alpha = int(35 * (1 - r/glow_size))
        c = (180, 120, 220, alpha)
        glow_draw.ellipse([glow_size-r, glow_size-r, glow_size+r, glow_size+r], fill=c)
    glow = glow.filter(ImageFilter.GaussianBlur(radius=int(25*S)))
    img.paste(glow, (int(cx-glow_size), int(cy-glow_size-int(60*S))), glow)
    
    # ======== LAYER 2: Subtle stars (few, not overwhelming) ========
    star_positions = [
        (120*S, 100*S, 3.5*S, True), (880*S, 90*S, 3.0*S, True),
        (220*S, 180*S, 2.5*S, False), (800*S, 160*S, 2.8*S, True),
        (150*S, 750*S, 3.2*S, True), (900*S, 820*S, 2.9*S, True),
        (90*S, 400*S, 2.0*S, False), (930*S, 450*S, 2.3*S, False),
        (280*S, 850*S, 2.2*S, False), (750*S, 880*S, 2.6*S, False),
        (400*S, 80*S, 1.8*S, False), (620*S, 110*S, 2.1*S, False),
        (70*S, 580*S, 1.9*S, False), (950*S, 600*S, 2.0*S, False),
        (180*S, 920*S, 2.4*S, False), (820*S, 940*S, 1.7*S, False),
    ]
    
    for sx, sy, ss, is_cross in star_positions:
        sx, sy, ss = int(sx), int(sy), ss
        # Star glow
        if is_cross:
            draw.ellipse([sx-ss*2, sy-ss*2, sx+ss*2, sy+ss*2], fill=(200, 170, 220, 60))
        # Star core
        draw.ellipse([sx-ss, sy-ss, sx+ss, sy+ss], fill=(255, 255, 255, 230 if is_cross else 180))
        # Cross rays for bright stars
        if is_cross and ss > 2*S:
            lw = max(1, int(S * 1.2))
            draw.line([int(sx-ss*3), int(sy), int(sx+ss*3), int(sy)], fill=(255,255,255,150), width=lw)
            draw.line([int(sx), int(sy-ss*3), int(sx), int(sy+ss*3)], fill=(255,255,255,150), width=lw)
    
    # ======== LAYER 3: SPEECH BUBBLE (chat/AI indicator) ========
    bx = int(cx + 260 * S)
    by = int(cy + 80 * S)
    bw = int(300 * S)
    bh = int(220 * S)
    br = int(55 * S)  # border radius
    
    # Bubble shadow
    shadow_offset = int(8 * S)
    bubble_shadow = Image.new('RGBA', (bw+20, bh+20), (0,0,0,0))
    sd = ImageDraw.Draw(bubble_shadow)
    sd.rounded_rectangle([10, 10+shadow_offset, bw+10, bh+10+shadow_offset], radius=br, 
                       fill=(100, 50, 120, 50))
    bubble_shadow = bubble_shadow.filter(ImageFilter.GaussianBlur(radius=int(12*S)))
    img.paste(bubble_shadow, (bx-10, by-10), bubble_shadow)
    
    # Bubble body
    draw.rounded_rectangle([bx, by, bx+bw, by+bh], radius=br, 
                          fill=C['bubble_fill'], outline=C['bubble_stroke'], width=max(3, int(8*S)))
    
    # Three dots (typing indicator) - violet-pink theme
    dot_r = int(16 * S)
    dot_y = by + bh // 2
    dots = [(bx + bw//3 - 30*S, dot_y), (bx + bw//2, dot_y), (bx + bw*2//3 + 30*S, dot_y)]
    for i, (dx, dy) in enumerate(dots):
        alpha = int(220 - i * 50)  # fading effect
        # Dot glow
        draw.ellipse([dx-dot_r*1.8, dy-dot_r*1.8, dx+dot_r*1.8, dy+dot_r*1.8], 
                   fill=(180, 100, 180, 60))
        # Dot body
        draw.ellipse([dx-dot_r, dy-dot_r, dx+dot_r, dy+dot_r], 
                   fill=(180, 110, 180, alpha))
        # Dot highlight
        draw.ellipse([dx-dot_r*0.4, dy-dot_r*0.4, dx+dot_r*0.3, dy+dot_r*0.3], 
                   fill=(255, 255, 255, 180))
    
    # Tiny sparkle on bubble
    sparkle_pos = (bx + bw - 35*S, by + 30*S)
    draw.ellipse([sparkle_pos[0]-4*S, sparkle_pos[1]-4*S, sparkle_pos[0]+4*S, sparkle_pos[1]+4*S],
               fill=(200, 220, 255, 200))
    
    # Bubble tail
    tail_pts = [
        (bx - 15*S, by + bh - 40*S),
        (bx - 45*S, by + bh + 20*S),
        (bx - 25*S, by + bh + 35*S),
        (bx - 5*S, by + bh - 20*S),
    ]
    draw.polygon(tail_pts, fill=C['bubble_fill'], outline=C['bubble_stroke'], width=max(2, int(6*S)))
    
    # ======== LAYER 4: CHARACTER FACE (the MAIN element - 60%+) ========
    face_cx = cx
    face_cy = cy
    face_w = int(290 * S)  # face width - BIG and prominent
    face_h = int(350 * S)  # face height
    
    # --- Hair BACK layers (dark brown with gradient) ---
    hair_back_layers = [
        (face_cx, face_cy - 30*S, face_w*1.15, face_h*0.95, C['hair_tip_lavender'], 0.15),
        (face_cx, face_cy - 20*S, face_w*1.08, face_h*0.9, C['hair_tip_pink'], 0.18),
        (face_cx, face_cy - 10*S, face_w*1.0, face_h*0.85, C['hair_light'], 0.22),
        (face_cx, face_cy, face_w*0.92, face_h*0.8, C['hair_mid'], 0.28),
    ]
    
    for hcx, hcy, hw, hh, hc, alpha_mult in hair_back_layers:
        alpha = int(255 * alpha_mult)
        hc_alpha = (*hc[:3], alpha)
        draw.ellipse([hcx-hw/2, hcy-hh/2, hcx+hw/2, hcy+hh/2], fill=hc_alpha)
    
    # --- SIDE HAIR (long strands, dark brown) ---
    # Left side hair
    side_hair_l = [
        (face_cx - face_w*0.52, face_cy + 20*S),
        (face_cx - face_w*0.58, face_cy + 120*S),
        (face_cx - face_w*0.42, face_cy + 250*S),
        (face_cx - face_w*0.32, face_cy + 140*S),
        (face_cx - face_w*0.44, face_cy + 40*S),
    ]
    # Gradient fill for side hair
    for i in range(len(side_hair_l)-1):
        t = i / (len(side_hair_l)-1)
        c = lerp(C['hair_main'], C['hair_tip_pink'], t*0.7)  # slight pink at tips
        # Draw thick line segment
        p1, p2 = side_hair_l[i], side_hair_l[i+1]
        draw.line([p1, p2], fill=c, width=int(35*S))
    
    # Right side hair
    side_hair_r = [
        (face_cx + face_w*0.52, face_cy + 20*S),
        (face_cx + face_w*0.58, face_cy + 120*S),
        (face_cx + face_w*0.42, face_cy + 250*S),
        (face_cx + face_w*0.32, face_cy + 140*S),
        (face_cx + face_w*0.44, face_cy + 40*S),
    ]
    for i in range(len(side_hair_r)-1):
        t = i / (len(side_hair_r)-1)
        c = lerp(C['hair_main'], C['hair_tip_lavender'], t*0.7)
        p1, p2 = side_hair_r[i], side_hair_r[i+1]
        draw.line([p1, p2], fill=c, width=int(35*S))
    
    # --- FACE SHAPE (warm fair skin, large) ---
    # Face ellipse with soft gradient
    face_top = face_cy - face_h*0.35
    face_draw = ImageDraw.Draw(Image.new('RGBA', (face_w, face_h), (0,0,0,0)))
    for fy in range(face_h):
        t = fy / face_h
        # More shadow at bottom/sides
        shade = abs(t - 0.4) * 0.5
        c = lerp(C['skin_light'], C['skin_shadow'], min(shade, 0.4))
        fw_at_y = face_w * (1 - 0.08 * math.sin(t * math.pi))  # slightly narrower at top/bottom
        fx = (face_w - fw_at_y) / 2
        face_draw.line([(fx, fy), (fx+fw_at_y, fy)], fill=c, width=1)
    
    face_img = Image.new('RGBA', (face_w, face_h), (0,0,0,0))
    fdraw = ImageDraw.Draw(face_img)
    fdraw.ellipse([0, 0, face_w, face_h], fill=C['skin_main'])
    # Apply subtle shading
    face_img = face_img.filter(ImageFilter.GaussianBlur(radius=int(2*S)))
    img.paste(face_img, (int(face_cx-face_w//2), int(face_top)), face_img)
    
    # Redraw clean face outline over the blurred version area
    draw.ellipse([face_cx-face_w//2, face_top, face_cx+face_w//2, face_top+face_h], 
                fill=C['skin_main'])
    
    # --- EYES (VIOLET - THE SIGNATURE!) ---
    eye_spacing = int(95 * S)
    eye_y = face_cy - int(25 * S)  # eyes positioned upper-third
    eye_w = int(52 * S)
    eye_h = int(68 * S)
    
    for eye_side in [-1, 1]:
        ex = face_cx + eye_side * eye_spacing
        
        # Eye outer glow (violet tinted)
        for g in range(3):
            gr = 1 - g * 0.25
            ga = int(20 * (1-g))
            draw.ellipse([ex-eye_w*1.4*gr, eye_y-eye_h*1.4*gr, ex+eye_w*1.4*gr, eye_y+eye_h*1.4*gr],
                       fill=(150, 100, 220, ga))
        
        # Eye white (slightly off-white, warm)
        draw.ellipse([ex-eye_w, eye_y-eye_h, ex+eye_w, eye_y+eye_h], fill=(250, 242, 255, 255))
        
        # Iris (violet gradient - THE key color!)
        iris = Image.new('RGBA', (eye_w*2, eye_h*2), (0,0,0,0))
        idraw = ImageDraw.Draw(iris)
        for iy in range(eye_h*2):
            t = iy / (eye_h*2)
            c = lerp(C['eye_inner'], C['eye_outer'], t)
            idraw.line([(0, iy), (eye_w*2, iy)], fill=c, width=1)
        iris = iris.resize((eye_w*2, eye_h*2), Image.LANCZOS)
        
        # Create circular iris mask
        iris_mask = Image.new('L', (eye_w*2, eye_h*2), 0)
        imask_draw = ImageDraw.Draw(iris_mask)
        imask_draw.ellipse([0, 0, eye_w*2, eye_h*2], fill=255)
        iris.putalpha(iris_mask)
        
        img.paste(iris, (int(ex-eye_w), int(eye_y-eye_h)), iris)
        
        # Pupil (dark purple, not black!)
        pupil_w = int(24 * S)
        pupil_h = int(32 * S)
        px = ex + eye_side * int(3 * S)  # slight inward gaze
        py = eye_y + int(8 * S)
        
        # Pupil gradient
        for p in range(pupil_h):
            t = p / pupil_h
            c = lerp(C['pupil_inner'], C['pupil'], t)
            pw_at = pupil_w * (1 - 0.15 * abs(t-0.5))
            draw.ellipse([px-pw_at/2, py-pupil_h/2+p, px+pw_at/2, py-pupil_h/2+p], fill=c)
        
        # === EYE HIGHLIGHTS (critical for anime look!) ===
        # Main highlight (large, upper-left)
        hl1_x = ex - eye_side * int(14 * S) - int(8 * S)
        hl1_y = eye_y - int(22 * S)
        hl1_w = int(18 * S)
        hl1_h = int(22 * S)
        draw.ellipse([hl1_x-hl1_w/2, hl1_y-hl1_h/2, hl1_x+hl1_w/2, hl1_y+hl1_h/2], 
                   fill=(255, 255, 255, 245))
        
        # Secondary highlight (small, lower-right)
        hl2_x = ex + eye_side * int(10 * S) + int(6 * S)
        hl2_y = eye_y + int(14 * S)
        hl2_w = int(9 * S)
        hl2_h = int(11 * S)
        draw.ellipse([hl2_x-hl2_w/2, hl2_y-hl2_h/2, hl2_x+hl2_w/2, hl2_y+hl2_h/2], 
                   fill=(255, 255, 255, 190))
        
        # Tiny catchlight
        hl3_x = ex - eye_side * int(4 * S)
        hl3_y = eye_y + int(22 * S)
        draw.ellipse([hl3_x-int(4*S), hl3_y-int(5*S), hl3_x+int(4*S), hl3_y+int(5*S)], 
                   fill=(255, 255, 255, 140))
    
    # --- BLUSH/CHEEKS (subtle warm pink) ---
    blush_x = face_cx - eye_spacing - int(10 * S)
    blush_y = face_top + face_h - int(75 * S)
    blush_w = int(34 * S)
    blush_h = int(20 * S)
    
    # Left blush with soft edges
    blush_img = Image.new('RGBA', (blush_w*2, blush_h*2), (0,0,0,0))
    bdraw = ImageDraw.Draw(blush_img)
    bdraw.ellipse([0, 0, blush_w*2, blush_h*2], fill=(*C['blush'][:3], 100))
    blush_img = blush_img.filter(ImageFilter.GaussianBlur(radius=int(8*S)))
    img.paste(blush_img, (int(blush_x-blush_w), int(blush_y-blush_h)), blush_img)
    
    # Right blush
    img.paste(blush_img, (int(blush_x + eye_spacing*2 - blush_w), int(blush_y-blush_h)), blush_img)
    
    # --- MOUTH (small gentle smile) ---
    mouth_cx = face_cx
    mouth_cy = face_top + face_h - int(25 * S)
    mouth_w = int(28 * S)
    mouth_h = int(14 * S)
    
    # Smile curve
    smile_pts = []
    for i in range(20):
        t = i / 19
        x = mouth_cx - mouth_w/2 + mouth_w * t
        y = mouth_cy + mouth_h * 0.3 * math.sin(t * math.pi)  # upward curve
        smile_pts.append((x, y))
    
    # Draw smile with slight thickness
    if len(smile_pts) >= 2:
        # Upper lip
        draw.line(smile_pts, fill=C['mouth'], width=max(2, int(4*S)))
        # Lower lip (slightly below, lighter)
        lower_pts = [(x, y + int(4*S)) for x, y in smile_pts]
        draw.line(lower_pts, fill=tuple(min(255, c+40) for c in C['mouth'][:3])+(180,), 
                  width=max(1, int(3*S)))
    
    # --- NOSE (tiny subtle indication) ---
    nose_cx = face_cx
    nose_cy = face_top + face_h - int(65 * S)
    # Just a tiny shadow for nose
    draw.ellipse([nose_cx-int(6*S), nose_cy-int(3*S), nose_cx+int(6*S), nose_cy+int(5*S)],
               fill=C['skin_shadow'])
    
    # --- HAIR FRONT (bangs - dark brown!) ---
    # Center bang (longest, covers forehead center)
    bang_c_pts = [
        (face_cx - int(50*S), face_top - int(80*S)),
        (face_cx - int(30*S), face_top - int(160*S)),
        (face_cx, face_top - int(175*S)),  # peak
        (face_cx + int(30*S), face_top - int(160*S)),
        (face_cx + int(50*S), face_top - int(75*S)),
        (face_cx + int(35*S), face_top - int(40*S)),
        (face_cx - int(35*S), face_top - int(40*S)),
    ]
    draw.polygon(bang_c_pts, fill=C['hair_main'])
    # Bang highlight
    bang_hl = [(x + int(5*S), y - int(10*S)) for x, y in bang_c_pts[:4]] + [bang_c_pts[4]]
    if len(bang_hl) >= 3:
        draw.polygon(bang_hl, fill=(*C['hair_light'][:3], 120))
    
    # Left bang
    lbang_pts = [
        (face_cx - face_w*0.48, face_top - int(50*S)),
        (face_cx - face_w*0.38, face_top - int(140*S)),
        (face_cx - face_w*0.15, face_top - int(130*S)),
        (face_cx - face_w*0.05, face_top - int(60*S)),
        (face_cx - face_w*0.25, face_top - int(35*S)),
    ]
    draw.polygon(lbang_pts, fill=C['hair_mid'])
    
    # Right bang
    rbang_pts = [
        (face_cx + face_w*0.48, face_top - int(50*S)),
        (face_cx + face_w*0.38, face_top - int(140*S)),
        (face_cx + face_w*0.15, face_top - int(130*S)),
        (face_cx + face_w*0.05, face_top - int(60*S)),
        (face_cx + face_w*0.25, face_top - int(35*S)),
    ]
    draw.polygon(rbang_pts, fill=C['hair_mid'])
    
    # Hair shine highlights (on bangs)
    shine_l = [
        (face_cx - int(55*S), face_top - int(100*S)),
        (face_cx - int(35*S), face_top - int(60*S)),
        (face_cx - int(50*S), face_top - int(70*S)),
    ]
    draw.polygon(shine_l, fill=(*C['hair_light'][:3], 100))
    
    shine_r = [
        (face_cx + int(50*S), face_top - int(95*S)),
        (face_cx + int(35*S), face_top - int(55*S)),
        (face_cx + int(45*S), face_top - int(65*S)),
    ]
    draw.polygon(shine_r, fill=(*C['hair_light'][:3], 90))
    
    # --- BUTTERFLY BOW ACCESSORY (on RIGHT side of head!) ---
    bow_cx = face_cx + int(face_w * 0.52)
    bow_cy = face_top - int(20 * S)
    bow_size = int(55 * S)
    draw_butterfly_bow(draw, bow_cx, bow_cy, bow_size, rotation=-15)
    
    # Small star sparkles near bow
    draw_star(draw, bow_cx + int(35*S), bow_cy - int(40*S), int(10*S), 5, 0.3, (255, 240, 180, 200))
    draw_star(draw, bow_cx - int(25*S), bow_cy - int(30*S), int(6*S), 4, -0.2, (255, 220, 200, 160))
    
    # Tiny star accessory in hair (left side, smaller)
    tiny_star_cx = face_cx - int(face_w * 0.45)
    tiny_star_cy = face_top - int(10 * S)
    draw_star(draw, tiny_star_cx, tiny_star_cy, int(18*S), 5, 0.1, (255, 230, 180, 180))
    draw_star(draw, tiny_star_cx, tiny_star_cy, int(10*S), 5, 0.1, (255, 255, 230, 200))
    
    # ======== LAYER 5: Foreground depth overlay ========
    # Very subtle bottom vignette
    vignette = Image.new('RGBA', (size, size), (0,0,0,0))
    vdraw = ImageDraw.Draw(vignette)
    for r in range(size, size//2, -3):
        t = (r - size//2) / (size//2)
        alpha = int(25 * t*t)  # quadratic fade
        vdraw.ellipse([size//2-r, size//2-r, size//2+r, size//2+r], fill=(10, 5, 20, alpha))
    vignette = vignette.filter(ImageFilter.GaussianBlur(radius=int(15*S)))
    img.paste(vignette, (0, 0), vignette)
    
    return img

# ======== GENERATE ALL SIZES ========
if __name__ == '__main__':
    print("Generating Hoshizora Airi v4 icons (character-accurate colors)...")
    print("Character: dark brown hair + violet eyes + butterfly bow")
    print()
    
    for size in [1024, 512, 192, 96, 72, 48]:
        img = generate_icon(size=size, seed=88888)
        outpath = os.path.join(OUTPUT_DIR, f'game_icon_v4_{size}.png')
        img.save(outpath, 'PNG')
        file_size = os.path.getsize(outpath)
        print(f"  ✓ game_icon_v4_{size}.png ({file_size:,} bytes)")
    
    print("\nAll v4 icons generated successfully!")
    print("Key corrections from v3:")
    print("  • Hair: PINK → DARK BROWN (with pink/lavender tip gradient)")
    print("  • Eyes: PINK → VIOLET/PURPLE (character's signature color)")
    print("  • Added: Butterfly bow accessory (right side)")
    print("  • Added: Star accessory (left side)")
    print("  • Skin: Warmer fair tone")
