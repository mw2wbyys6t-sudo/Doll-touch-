#!/usr/bin/env python3
"""
星空愛莉 (Hoshizora Airi) App Icon Generator v5
ANTI-AI AESTHETIC: Hand-drawn feel, organic lines, soft cel-shading
"""
from PIL import Image, ImageDraw, ImageFilter, ImageFont
import math
import random
import os

OUTPUT_DIR = '/workspace/ohos_airi'

# ======== CHARACTER PALETTE (Same accurate colors) ========
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
    return tuple(int(a + (b - a) * min(1, max(0, t))) for a, b in zip(c1, c2))

def jitter(val, amount=1.5):
    """Add hand-drawn jitter"""
    return val + random.uniform(-amount, amount)

def soft_ellipse(draw, cx, cy, rx, ry, fill_color, outline=None, outline_width=0, jitter_amt=2):
    """Draw ellipse with organic imperfection"""
    points = []
    steps = 60
    for i in range(steps):
        angle = 2 * math.pi * i / steps
        rj_x = rx + random.uniform(-jitter_amt, jitter_amt)
        rj_y = ry + random.uniform(-jitter_amt, jitter_amt)
        px = cx + rj_x * math.cos(angle)
        py = cy + rj_y * math.sin(angle)
        points.append((px, py))
    
    if len(points) >= 3:
        draw.polygon(points, fill=fill_color)
        if outline and outline_width > 0:
            draw.line(points + [points[0]], fill=outline, width=outline_width)

def bezier_curve(p0, p1, p2, p3, t):
    """Cubic bezier interpolation"""
    u = 1 - t
    x = u**3*p0[0] + 3*u**2*t*p1[0] + 3*u*t**2*p2[0] + t**3*p3[0]
    y = u**3*p0[1] + 3*u**2*t*p1[1] + 3*u*t**2*p2[1] + t**3*p3[1]
    return (x, y)

def draw_bezier_shape(draw, control_points, fill_color, close=True, jitter_amt=1):
    """Draw shape using bezier curves with hand-drawn feel"""
    all_points = []
    
    for i in range(len(control_points) - 3):
        p0 = control_points[i]
        p1 = control_points[i+1]
        p2 = control_points[i+2]
        p3 = control_points[i+3]
        
        for step in range(20):
            t = step / 19
            pt = bezier_curve(p0, p1, p2, p3, t)
            jpt = (jitter(pt[0], jitter_amt), jitter(pt[1], jitter_amt))
            all_points.append(jpt)
    
    if close and len(all_points) > 2:
        all_points.append(all_points[0])
    
    if len(all_points) >= 3:
        draw.polygon(all_points, fill=fill_color)

def radial_gradient_soft(img, cx, cy, radius, color_inner, color_outer, layers=25):
    """Soft radial gradient with alpha blending"""
    overlay = Image.new('RGBA', img.size, (0, 0, 0, 0))
    draw_over = ImageDraw.Draw(overlay)
    
    for i in range(layers, 0, -1):
        t = i / layers
        r = int(radius * t)
        color = lerp(color_inner, color_outer, 1-t)
        alpha = int(255 * (1 - (1-t)**0.5))
        
        soft_ellipse(draw_over, cx, cy, r, r, (*color, alpha), jitter_amt=0.5)
    
    # Apply gaussian blur for extra softness
    overlay = overlay.filter(ImageFilter.GaussianBlur(radius=radius//8))
    img.paste(Image.alpha_composite(img.convert('RGBA'), overlay).convert('RGB'), (0, 0))

def add_noise_texture(img, intensity=8):
    """Add subtle paper/grain texture to reduce AI look"""
    arr = img.load()
    w, h = img.size
    for _ in range(w * h // 10):
        x = random.randint(0, w-1)
        y = random.randint(0, h-1)
        pixel = list(arr[x, y])
        noise = random.randint(-intensity, intensity)
        pixel = [max(0, min(255, c + noise)) for c in pixel[:3]]
        arr[x, y] = tuple(pixel)

def generate_icon(size=1024, seed=88888):
    """Generate v5 icon with hand-drawn aesthetic"""
    random.seed(seed)
    
    s = size
    scale = s / 1024
    
    # Create base image with RGBA for layering
    img = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # ======== BACKGROUND: Soft dreamy gradient ========
    bg_layers = 35
    for i in range(bg_layers, 0, -1):
        t = i / bg_layers
        r = int(s * 0.55 * t)
        bg_color = lerp(C['bg_center'], C['bg_edge'], 1-t)
        alpha = int(250 * (1 - (1-t)**1.5))
        
        jitter_cx = s//2 + random.uniform(-3*scale, 3*scale)
        jitter_cy = s//2 + random.uniform(-3*scale, 3*scale)
        soft_ellipse(draw, jitter_cx, jitter_cy, r, r, (*bg_color, alpha), jitter_amt=1)
    
    # Add subtle purple glow off-center (breaks symmetry!)
    glow_x = int(s * 0.58)  # Slightly right of center
    glow_y = int(s * 0.42)  # Slightly above center
    for i in range(15, 0, -1):
        t = i / 15
        r = int(s * 0.18 * t)
        alpha = int(60 * (1-t))
        soft_ellipse(draw, glow_x + jitter(2), glow_y + jitter(2), r, int(r*0.85), 
                    (160, 90, 210, alpha), jitter_amt=1)
    
    # ======== STARS: Organic, varied sizes, not perfectly placed ========
    star_positions = [
        (s*0.18, s*0.15, 12*scale, 4),
        (s*0.78, s*0.22, 8*scale, 4),
        (s*0.12, s*0.55, 6*scale, 5),
        (s*0.88, s*0.62, 9*scale, 4),
        (s*0.25, s*0.82, 7*scale, 5),
        (s*0.72, s*0.88, 5*scale, 4),
        (s*0.45, s*0.08, 6*scale, 4),
        (s*0.92, s*0.38, 4*scale, 5),
        (s*0.08, s*0.38, 5*scale, 4),
    ]
    
    for sx, sy, sr, pts in star_positions:
        sx += random.uniform(-5*scale, 5*scale)
        sy += random.uniform(-5*scale, 5*scale)
        sr *= random.uniform(0.85, 1.15)
        
        angles = []
        rot = random.uniform(0, math.pi)
        for i in range(pts * 2):
            angle = math.pi / pts * i + rot - math.pi/2
            if i % 2 == 0:
                r = sr * random.uniform(0.95, 1.05)
            else:
                r = sr * 0.35 * random.uniform(0.9, 1.1)
            angles.append((sx + r*math.cos(angle), sy + r*math.sin(angle)))
        
        alpha = random.randint(180, 255)
        draw.polygon(angles, fill=(255, 255, 255, alpha))
    
    # Tiny sparkle dots
    for _ in range(30):
        dx = random.randint(int(s*0.05), int(s*0.95))
        dy = random.randint(int(s*0.05), int(s*0.95))
        ds = random.uniform(1, 2.5) * scale
        da = random.randint(80, 180)
        soft_ellipse(draw, dx, dy, ds, ds, (255, 255, 255, da), jitter_amt=0.3)
    
    # ======== CHARACTER BASE: Face shape (ORGANIC, not perfect circle) ========
    face_cx = s // 2 + int(random.uniform(-8*scale, 5*scale))  # Slight asymmetry
    face_cy = int(s * 0.52) + int(random.uniform(-3*scale, 3*scale))
    face_rx = int(s * 0.26) 
    face_ry = int(s * 0.30)
    
    # Face shadow/base (slightly larger, darker)
    soft_ellipse(draw, face_cx + 3*scale, face_cy + 4*scale, 
                face_rx + 8*scale, face_ry + 10*scale, 
                C['skin_shadow'], jitter_amt=3)
    
    # Main face
    soft_ellipse(draw, face_cx, face_cy, face_rx, face_ry, 
                C['skin_main'], jitter_amt=2.5)
    
    # Face highlight (top-left lighting)
    highlight_overlay = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    hdraw = ImageDraw.Draw(highlight_overlay)
    soft_ellipse(hdraw, face_cx - face_rx*0.25, face_cy - face_ry*0.3,
                face_rx * 0.75, face_ry * 0.6, 
                (*C['skin_light'], 60), jitter_amt=2)
    highlight_overlay = highlight_overlay.filter(ImageFilter.GaussianBlur(radius=int(15*scale)))
    img = Image.alpha_composite(img, highlight_overlay)
    draw = ImageDraw.Draw(img)
    
    # ======== HAIR BACK LAYER: Flowing organic shapes ========
    # Back hair is larger, darker, with organic flow
    hair_back_pts = [
        (face_cx - face_rx*0.9, face_cy - face_ry*0.6),
        (face_cx - face_rx*1.4, face_cy - face_ry*0.3),
        (face_cx - face_rx*1.5, face_cy + face_ry*0.2),
        (face_cx - face_rx*1.3, face_cy + face_ry*0.7),
        (face_cx - face_rx*0.9, face_cy + face_ry*1.0),
        (face_cx - face_rx*0.3, face_cy + face_ry*0.9),
        (face_cx + face_rx*0.3, face_cy + face_ry*0.95),
        (face_cx + face_rx*0.9, face_cy + face_ry*0.8),
        (face_cx + face_rx*1.3, face_cy + face_ry*0.5),
        (face_cx + face_rx*1.45, face_cy + face_ry*0.0),
        (face_cx + face_rx*1.35, face_cy - face_ry*0.35),
        (face_cx + face_rx*0.9, face_cy - face_ry*0.55),
        (face_cx + face_rx*0.4, face_cy - face_ry*0.6),
    ]
    
    # Add bezier control points for smooth curves
    hair_back_bezier = []
    for i, pt in enumerate(hair_back_pts):
        hair_back_bezier.append(pt)
        if i < len(hair_back_pts) - 1:
            next_pt = hair_back_pts[i+1]
            mid_x = (pt[0] + next_pt[0]) / 2 + random.uniform(-5*scale, 5*scale)
            mid_y = (pt[1] + next_pt[1]) / 2 + random.uniform(-5*scale, 5*scale)
            hair_back_bezier.append((mid_x, mid_y))
    
    draw.polygon(hair_back_bezier, fill=C['hair_main'])
    
    # Hair shading layers (soft gradients)
    for shade_i in range(3):
        shade_alpha = 40 - shade_i * 12
        shade_img = Image.new('RGBA', (s, s), (0, 0, 0, 0))
        sdraw = ImageDraw.Draw(shade_img)
        offset_x = -shade_i * 8 * scale
        offset_y = shade_i * 5 * scale
        
        shade_pts = [(p[0]+offset_x, p[1]+offset_y) for p in hair_back_bezier[:-1]]
        if len(shade_pts) >= 3:
            sdraw.polygon(shade_pts, fill=(*C['hair_mid'], shade_alpha))
        shade_img = shade_img.filter(ImageFilter.GaussianBlur(radius=int(8*scale + shade_i*3*scale)))
        img = Image.alpha_composite(img, shade_img)
        draw = ImageDraw.Draw(img)
    
    # Side hair locks (left side - flowing down)
    for lock_idx in range(3):
        lock_x = face_cx - face_rx*(0.85 + lock_idx*0.15) + random.uniform(-5,5)*scale
        lock_top = face_cy - face_ry*(0.3 + lock_idx*0.1)
        lock_bottom = face_cy + face_ry*(0.85 + lock_idx*0.12)
        lock_w = (12 + lock_idx*4) * scale
        
        lock_pts = [
            (lock_x - lock_w, lock_top),
            (lock_x + lock_w*0.3, lock_top + (lock_bottom-lock_top)*0.2),
            (lock_x + lock_w*0.5, lock_bottom),
            (lock_x - lock_w*0.7, lock_bottom - (lock_bottom-lock_top)*0.15),
        ]
        
        # Main lock color
        draw.polygon(lock_pts, fill=C['hair_main'])
        
        # Pink/lavender tip gradient on lower part
        tip_img = Image.new('RGBA', (s, s), (0, 0, 0, 0))
        tdraw = ImageDraw.Draw(tip_img)
        tip_pts = [(p[0], max(p[1], lock_top + (lock_bottom-lock_top)*0.6)) for p in lock_pts]
        tip_color = lerp(C['hair_tip_pink'], C['hair_tip_lavender'], lock_idx * 0.33)
        tdraw.polygon(tip_pts, fill=(*tip_color, 100))
        tip_img = tip_img.filter(ImageFilter.GaussianBlur(radius=int(5*scale)))
        img = Image.alpha_composite(img, tip_img)
        draw = ImageDraw.Draw(img)
    
    # Right side hair (shorter, behind ear area)
    for lock_idx in range(2):
        lock_x = face_cx + face_rx*(0.9 + lock_idx*0.12) + random.uniform(-3,3)*scale
        lock_top = face_cy - face_ry*0.2
        lock_bottom = face_cy + face_ry*(0.5 + lock_idx*0.1)
        lock_w = (10 + lock_idx*3) * scale
        
        lock_pts = [
            (lock_x - lock_w*0.5, lock_top),
            (lock_x + lock_w, lock_top + (lock_bottom-lock_top)*0.25),
            (lock_x + lock_w*0.6, lock_bottom),
            (lock_x - lock_w*0.3, lock_bottom - (lock_bottom-lock_top)*0.1),
        ]
        draw.polygon(lock_pts, fill=C['hair_mid'])
    
    # ======== EYES: The signature violet eyes (MOST IMPORTANT!) ========
    eye_spacing = face_rx * 0.52
    eye_size = face_ry * 0.22
    eye_y = face_cy - face_ry * 0.05  # Eyes slightly above center
    
    for eye_side in [-1, 1]:  # Left (-1) and Right (+1)
        ex = face_cx + eye_spacing * eye_side
        ey = eye_y + random.uniform(-3*scale, 3*scale) * eye_side  # Subtle asymmetry!
        es = eye_size * (1 + random.uniform(-0.03, 0.03))  # Slight size variation
        
        # Eye white (slightly off-white, not pure white)
        eye_white_color = (250, 248, 245)
        soft_ellipse(draw, ex, ey, es*1.15, es*0.95, eye_white_color, jitter_amt=1.5)
        
        # Iris - VIOLET GRADIENT (the character's signature!)
        iris_r = es * 0.78
        
        # Outer iris ring (dark violet)
        soft_ellipse(draw, ex, ey, iris_r, iris_r, C['eye_outer'], jitter_amt=1.2)
        
        # Mid iris (brighter violet) - slightly smaller
        soft_ellipse(draw, ex + jitter(0.5), ey + jitter(0.5), 
                    iris_r*0.82, iris_r*0.82, C['eye_main'], jitter_amt=1)
        
        # Inner iris (light violet) - even smaller
        soft_ellipse(draw, ex + jitter(0.3), ey + jitter(0.3),
                    iris_r*0.55, iris_r*0.55, C['eye_inner'], jitter_amt=0.8)
        
        # Pupil (dark, not pure black)
        pupil_r = iris_r * 0.32
        pupil_offset_x = pupil_r * 0.15 * eye_side  # Look slightly toward center
        pupil_offset_y = pupil_r * 0.1
        soft_ellipse(draw, ex + pupil_offset_x, ey + pupil_offset_y,
                    pupil_r, pupil_r, C['pupil'], jitter_amt=0.5)
        
        # Pupil inner highlight (small bright spot)
        soft_ellipse(draw, ex + pupil_offset_x - pupil_r*0.2, ey + pupil_offset_y - pupil_r*0.2,
                    pupil_r*0.4, pupil_r*0.4, (80, 50, 120), jitter_amt=0.3)
        
        # MAIN HIGHLIGHTS (make eyes sparkle! - key to anime style)
        # Large highlight (top-left)
        hl1_x = ex - es*0.28
        hl1_y = ey - es*0.32
        hl1_r = es * 0.22
        soft_ellipse(draw, hl1_x + jitter(1), hl1_y + jitter(1), hl1_r, hl1_r*0.85, 
                    C['eye_highlight'], jitter_amt=0.5)
        
        # Small secondary highlight (bottom-right)
        hl2_x = ex + es*0.18
        hl2_y = ey + es*0.22
        hl2_r = es * 0.1
        soft_ellipse(draw, hl2_x + jitter(0.5), hl2_y + jitter(0.5), hl2_r, hl2_r,
                    C['eye_highlight'], jitter_amt=0.3)
        
        # Tiny third highlight (optional, adds life)
        if random.random() > 0.4:
            hl3_x = ex - es*0.05
            hl3_y = ey + es*0.35
            hl3_r = es * 0.06
            soft_ellipse(draw, hl3_x, hl3_y, hl3_r, hl3_r, 
                        (255, 255, 255, 200), jitter_amt=0.2)
        
        # Upper eyelid line (soft, not harsh)
        lid_y = ey - es*0.9
        lid_pts = []
        for i in range(25):
            t = i / 24
            lx = ex - es*1.1 + es*2.2 * t
            ly = lid_y + math.sin(t * math.pi) * (-es*0.15) + jitter(0.5)
            lid_pts.append((lx, ly))
        
        if len(lid_pts) >= 2:
            draw.line(lid_pts, fill=(60, 35, 90), width=max(1, int(2.5*scale)))
        
        # Lower lash hints (just a few subtle strokes)
        for lash_idx in range(4):
            lash_t = 0.15 + lash_idx * 0.23
            lash_x = ex - es*0.8 + es*1.6 * lash_t
            lash_y = ey + es*0.85
            lash_len = (2 + random.random() * 2) * scale
            lash_angle = math.radians(-15 + lash_idx * 8 + random.uniform(-5, 5))
            
            lash_end_x = lash_x + lash_len * math.cos(lash_angle)
            lash_end_y = lash_y + lash_len * math.sin(lash_angle)
            draw.line([(lash_x, lash_y), (lash_end_x, lash_end_y)], 
                     fill=(70, 40, 100), width=max(1, int(1.2*scale)))
    
    # ======== EYEBROWS: Soft, natural arcs ========
    brow_y = eye_y - eye_size * 1.35
    for brow_side in [-1, 1]:
        bx = face_cx + eye_spacing * 0.9 * brow_side
        by = brow_y + random.uniform(-2*scale, 2*scale)
        brow_w = eye_size * 0.85
        brow_h = eye_size * 0.18
        
        # Eyebrow as a curved arc of points
        brow_pts = []
        for i in range(20):
            t = i / 19
            px = bx - brow_w * brow_side + brow_w * 2 * t * brow_side
            arc_height = math.sin(t * math.pi) * (-brow_h)
            py = by + arc_height + jitter(0.3)
            brow_pts.append((px, py))
        
        if len(brow_pts) >= 2:
            brow_color = lerp(C['hair_main'], C['hair_mid'], 0.5)
            draw.line(brow_pts, fill=brow_color, width=max(1, int(2.8*scale)), joint='curve')
    
    # ======== NOSE: Minimal anime style (tiny hint) ========
    nose_x = face_cx + random.uniform(-2, 2)*scale
    nose_y = face_cy + face_ry * 0.12
    # Just a tiny dot or very short line
    draw.ellipse([nose_x-1.5*scale, nose_y-1*scale, nose_x+1.5*scale, nose_y+2*scale],
                fill=C['skin_shadow'])
    
    # ======== BLUSH: Soft circular gradients ========
    blush_y = face_cy + face_ry * 0.28
    blush_x_offset = face_rx * 0.42
    
    for blush_side in [-1, 1]:
        blx = face_cx + blush_x_offset * blush_side + random.uniform(-5, 5)*scale
        bly = blush_y + random.uniform(-3, 3)*scale
        blr = face_ry * 0.14
        
        # Multi-layer blush for softness
        for bl_layer in range(4):
            bl_alpha = 35 - bl_layer * 8
            bl_scale = 1 + bl_layer * 0.25
            
            blush_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
            bldraw = ImageDraw.Draw(blush_ov)
            soft_ellipse(bldraw, blx, bly, blr*bl_scale, blr*bl_scale*0.75,
                        (*C['blush'], bl_alpha), jitter_amt=1)
            blush_ov = blush_ov.filter(ImageFilter.GaussianBlur(radius=int(6*scale + bl_layer*2*scale)))
            img = Image.alpha_composite(img, blush_ov)
            draw = ImageDraw.Draw(img)
    
    # ======== MOUTH: Gentle smile ========
    mouth_x = face_cx + random.uniform(-3, 3)*scale
    mouth_y = face_cy + face_ry * 0.48
    mouth_w = face_rx * 0.18
    
    # Smile curve
    smile_pts = []
    smile_depth = face_ry * 0.04
    for i in range(20):
        t = i / 19
        sx = mouth_x - mouth_w + mouth_w * 2 * t
        sy = mouth_y + math.sin(t * math.pi) * smile_depth + jitter(0.3)
        smile_pts.append((sx, sy))
    
    if len(smile_pts) >= 2:
        # Mouth line with slight color
        draw.line(smile_pts, fill=C['mouth'], width=max(1, int(2*scale)), joint='curve')
        
        # Slight lip tint below center
        lip_cx = mouth_x
        lip_cy = mouth_y + smile_depth * 0.5
        lip_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
        lipdraw = ImageDraw.Draw(lip_ov)
        soft_ellipse(lipdraw, lip_cx, lip_cy, mouth_w*0.4, mouth_w*0.15,
                    (*C['mouth'], 40), jitter_amt=0.5)
        lip_ov = lip_ov.filter(ImageFilter.GaussianBlur(radius=int(3*scale)))
        img = Image.alpha_composite(img, lip_ov)
        draw = ImageDraw.Draw(img)
    
    # ======== BANGS/Front Hair: Sweeping across forehead ========
    bang_base_y = face_cy - face_ry * 0.65
    
    # Main bang sweep (right to left, covering part of right eye)
    bang_pts = [
        (face_cx + face_rx*1.1, bang_base_y - face_ry*0.35),  # Top right (high)
        (face_cx + face_rx*0.6, bang_base_y - face_ry*0.25),   # Upper mid-right
        (face_cx + face_rx*0.1, bang_base_y - face_ry*0.15),   # Center-top
        (face_cx - face_rx*0.35, bang_base_y + face_ry*0.05),  # Left of center (covers left eye top)
        (face_cx - face_rx*0.6, bang_base_y + face_ry*0.2),    # Left end
        (face_cx - face_rx*0.4, bang_base_y + face_ry*0.35),   # Bottom left
        (face_cx + face_rx*0.0, bang_base_y + face_ry*0.25),   # Bottom center
        (face_cx + face_rx*0.5, bang_base_y + face_ry*0.1),    # Bottom right
        (face_cx + face_rx*0.9, bang_base_y),                   # Return to right side
    ]
    
    # Add jitter to make organic
    bang_pts = [(p[0] + random.uniform(-4,4)*scale, p[1] + random.uniform(-3,3)*scale) 
                for p in bang_pts]
    
    # Draw main bang
    draw.polygon(bang_pts, fill=C['hair_main'])
    
    # Bang highlight (lighter brown on top)
    bang_hl_pts = bang_pts[:5] + [bang_pts[4]]
    bang_hl_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    bhldraw = ImageDraw.Draw(bang_hl_ov)
    bhldraw.polygon(bang_hl_pts, fill=(*C['hair_light'], 70))
    bang_hl_ov = bang_hl_ov.filter(ImageFilter.GaussianBlur(radius=int(8*scale)))
    img = Image.alpha_composite(img, bang_hl_ov)
    draw = ImageDraw.Draw(img)
    
    # Individual bang strands (falling across forehead)
    for strand_idx in range(4):
        strand_x = face_cx - face_rx*0.3 + strand_idx * face_rx*0.25
        strand_top = bang_base_y - face_ry*0.2 + random.uniform(-5, 5)*scale
        strand_bot = face_cy - face_ry*0.1 + strand_idx * face_ry*0.08
        strand_w = (6 + strand_idx * 2) * scale
        
        strand_pts = [
            (strand_x - strand_w, strand_top),
            (strand_x + strand_w*0.3, strand_top + (strand_bot-strand_top)*0.3),
            (strand_x + strand_w*0.5, strand_bot),
            (strand_x - strand_w*0.6, strand_bot - (strand_bot-strand_top)*0.2),
        ]
        
        strand_color = C['hair_main'] if strand_idx % 2 == 0 else C['hair_mid']
        draw.polygon(strand_pts, fill=strand_color)
    
    # ======== BUTTERFLY BOW ACCESSORY (Right side) ========
    bow_cx = face_cx + face_rx * 1.05
    bow_cy = face_cy - face_ry * 0.25
    bow_size = face_rx * 0.35
    
    # Left wing (larger, more visible)
    wing_l_pts = []
    for i in range(25):
        t = i / 24
        angle = math.radians(-70 + t * 140)
        r = bow_size * (0.95 if t < 0.4 else (0.9 - 0.4 * abs(t-0.5)))
        wx = bow_cx - bow_size*0.2 + r * math.cos(angle) + random.uniform(-2,2)*scale
        wy = bow_cy + r * math.sin(angle) * 0.65 + random.uniform(-2,2)*scale
        wing_l_pts.append((wx, wy))
    
    draw.polygon(wing_l_pts, fill=C['bow_main'])
    
    # Wing highlight
    wing_hl_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    whldraw = ImageDraw.Draw(wing_hl_ov)
    whldraw.polygon(wing_l_pts[:15], fill=(*C['bow_light'], 80))
    wing_hl_ov = wing_hl_ov.filter(ImageFilter.GaussianBlur(radius=int(4*scale)))
    img = Image.alpha_composite(img, wing_hl_ov)
    draw = ImageDraw.Draw(img)
    
    # Right wing (smaller, partially hidden)
    wing_r_pts = []
    for i in range(20):
        t = i / 19
        angle = math.radians(30 + t * 100)
        r = bow_size * 0.65 * (0.9 if t < 0.5 else 0.7)
        wx = bow_cx + bow_size*0.15 + r * math.cos(angle) + random.uniform(-1.5,1.5)*scale
        wy = bow_cy + r * math.sin(angle) * 0.55 + random.uniform(-1.5,1.5)*scale
        wing_r_pts.append((wx, wy))
    
    draw.polygon(wing_r_pts, fill=C['bow_main'])
    
    # Bow center knot
    knot_ov = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    knotdraw = ImageDraw.Draw(knot_ov)
    soft_ellipse(knotdraw, bow_cx, bow_cy, bow_size*0.15, bow_size*0.12, C['bow_center'], jitter_amt=1)
    knot_ov = knot_ov.filter(ImageFilter.GaussianBlur(radius=int(2*scale)))
    img = Image.alpha_composite(img, knot_ov)
    draw = ImageDraw.Draw(img)
    
    # Ribbon tails hanging down
    for tail_idx in range(2):
        tail_x = bow_cx + (-1 if tail_idx == 0 else 1) * bow_size*0.15
        tail_top = bow_cy + bow_size*0.1
        tail_bot = bow_cy + bow_size*0.55
        tail_w = bow_size * 0.12
        
        tail_pts = [
            (tail_x - tail_w, tail_top),
            (tail_x + tail_w*0.5, tail_top + (tail_bot-tail_top)*0.4),
            (tail_x + tail_w*0.3 + random.uniform(-3,3)*scale, tail_bot + random.uniform(-2,2)*scale),
            (tail_x - tail_w*0.6, tail_bot - (tail_bot-tail_top)*0.2),
        ]
        
        draw.polygon(tail_pts, fill=C['bow_light'])
    
    # ======== SPEECH BUBBLE (Bottom-right, indicating AI assistant) ========
    bub_cx = int(s * 0.82)
    bub_cy = int(s * 0.78)
    bub_w = int(s * 0.26)
    bub_h = int(s * 0.18)
    
    # Bubble shadow
    bubble_shadow = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    bsdraw = ImageDraw.Draw(bubble_shadow)
    
    # Rounded rect approximation for bubble
    bub_corners = 18 * scale
    bub_shadow_pts = [
        (bub_cx - bub_w/2 + 4*scale, bub_cy - bub_h/2 + 4*scale + bub_corners),
        (bub_cx - bub_w/2 + 4*scale, bub_cy + bub_h/2 + 4*scale - bub_corners),
        (bub_cx - bub_w/2 + 4*scale + bub_corners, bub_cy + bub_h/2 + 4*scale),
        (bub_cx + bub_w/2 - bub_corners, bub_cy + bub_h/2 + 4*scale),
        (bub_cx + bub_w/2, bub_cy + bub_h/2 - bub_corners),
        (bub_cx + bub_w/2, bub_cy - bub_h/2 + bub_corners),
        (bub_cx + bub_w/2 - bub_corners, bub_cy - bub_h/2),
        (bub_cx - bub_w/2 + bub_corners, bub_cy - bub_h/2),
    ]
    bsdraw.polygon(bub_shadow_pts, fill=(0, 0, 0, 40))
    bubble_shadow = bubble_shadow.filter(ImageFilter.GaussianBlur(radius=int(8*scale)))
    img = Image.alpha_composite(img, bubble_shadow)
    draw = ImageDraw.Draw(img)
    
    # Bubble tail (pointing toward character)
    tail_pts = [
        (bub_cx - bub_w*0.3, bub_cy + bub_h*0.1),
        (bub_cx - bub_w*0.45, bub_cy + bub_h*0.35),
        (bub_cx - bub_w*0.2, bub_cy + bub_h*0.2),
    ]
    
    # Main bubble (white with slight warmth)
    bub_pts_main = [
        (bub_cx - bub_w/2, bub_cy - bub_h/2 + bub_corners),
        (bub_cx - bub_w/2, bub_cy + bub_h/2 - bub_corners),
        (bub_cx - bub_w/2 + bub_corners, bub_cy + bub_h/2),
        (bub_cx + bub_w/2 - bub_corners, bub_cy + bub_h/2),
        (bub_cx + bub_w/2, bub_cy + bub_h/2 - bub_corners),
        (bub_cx + bub_w/2, bub_cy - bub_h/2 + bub_corners),
        (bub_cx + bub_w/2 - bub_corners, bub_cy - bub_h/2),
        (bub_cx - bub_w/2 + bub_corners, bub_cy - bub_h/2),
    ] + tail_pts
    
    draw.polygon(bub_pts_main, fill=(255, 255, 252, 245))
    
    # Bubble inner dots (typing indicator style)
    dot_colors = [(180, 120, 180), (200, 140, 200), (170, 110, 170)]
    dot_start_x = bub_cx - bub_w * 0.2
    for di, dc in enumerate(dot_colors):
        dx = dot_start_x + di * bub_w * 0.15
        dy = bub_cy
        dr = 5 * scale
        soft_ellipse(draw, dx, dy, dr, dr, (*dc, 200), jitter_amt=0.5)
    
    # ======== FINAL POLISH: Vignette & Texture ========
    # Subtle dark vignette around edges (focus attention on character)
    vignette = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    vdraw = ImageDraw.Draw(vignette)
    for vi in range(20, 0, -1):
        vt = vi / 20
        vr = int(s * 0.52 * vt)
        va = int(25 * (1-vt))
        soft_ellipse(vdraw, s//2, s//2, vr, vr, (10, 5, 20, va), jitter_amt=1)
    vignette = vignette.filter(ImageFilter.GaussianBlur(radius=int(20*scale)))
    img = Image.alpha_composite(img, vignette)
    
    # Convert to RGB for output
    final = Image.new('RGB', (s, s), C['bg_edge'])
    final.paste(img, (0, 0), img if img.mode == 'RGBA' else None)
    
    # Add very subtle grain texture
    add_noise_texture(final, intensity=3)
    
    return final


if __name__ == '__main__':
    print("Generating v5 icon with hand-drawn aesthetic...")
    
    sizes = [1024, 512, 192, 96, 72, 48]
    
    for sz in sizes:
        print(f"  Generating {sz}x{sz}...", end=' ')
        icon = generate_icon(size=sz, seed=88888)
        
        filename = f'{OUTPUT_DIR}/game_icon_v5_{sz}.png'
        icon.save(filename, 'PNG')
        
        file_size = os.path.getsize(filename) if os.path.exists(filename) else 0
        print(f"✓ {filename} ({file_size:,} bytes)")
    
    print("\nDone! v5 icons generated with anti-AI aesthetic.")
