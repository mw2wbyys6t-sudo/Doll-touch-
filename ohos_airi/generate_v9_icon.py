#!/usr/bin/env python3
"""
星空愛莉 (Hoshizora Airi) App Icon Generator v9
PURE HAND-DRAWN STYLE: Analog Ink & Wash Aesthetic

Key techniques to simulate real hand-drawing:
1. Paper texture (cold-press watercolor paper grain)
2. Variable-pressure lines (simulated brush strokes)
3. Watercolor wash layers (translucent color buildup)
4. Ink bleed at edges (organic, non-uniform borders)
5. Sketch construction lines (visible pencil guides)
6. Marker bleed effect (color slightly outside line work)
7. Organic asymmetry (human hand never draws perfectly)
"""
from PIL import Image, ImageDraw, ImageFilter, ImageEnhance
import math
import random
import os

OUTPUT_DIR = '/workspace/ohos_airi'

# ======== ANALOG PALETTE (Copic/Watercolor inspired) ========
C = {
    # Hair: warm brown with rose-pink tips
    'hair_base':       (95, 65, 48),     # Warm umber brown
    'hair_shadow':     (68, 45, 32),     # Burnt umber shadow
    'hair_highlight':  (145, 110, 85),   # Raw sienna highlight
    'hair_tip_rose':   (235, 155, 175),  # Rose pink tip
    'hair_tip_lav':    (195, 155, 215),  # Lavender tip
    
    # Eyes: violet (the character's signature!)
    'eye_violet':      (145, 95, 210),
    'eye_bright':      (185, 140, 240),
    'eye_light':       (220, 195, 255),
    'eye_deep':        (75, 45, 140),
    'eye_pupil':       (30, 18, 55),
    
    # Skin: warm watercolor flesh tones
    'skin_base':       (255, 238, 222),
    'skin_shadow':     (235, 212, 192),
    'skin_warm':       (255, 248, 240),
    'blush_wash':      (250, 175, 185),
    
    # Mouth
    'mouth_ink':       (210, 85, 105),
    
    # Bow accessory
    'bow_magenta':     (235, 125, 180),
    'bow_light':       (252, 190, 220),
    'bow_shadow':      (200, 90, 150),
    
    # Paper & ink colors
    'paper_white':     (252, 248, 242),
    'paper_cream':     (248, 242, 232),
    'ink_dark':        (42, 32, 28),
    'ink_medium':      (72, 58, 50),
    'sketch_pencil':    (120, 110, 100),
    
    # Background: indigo watercolor wash
    'wash_indigo':     (55, 35, 85),
    'wash_deep':       (28, 15, 48),
    'wash_accent':     (100, 65, 150),
}


def lerp(c1, c2, t):
    t = max(0, min(1, t))
    return tuple(int(a + (b-a)*t) for a,b in zip(c1,c2))


def generate_paper_texture(w, h, intensity=18):
    """Generate cold-press watercolor paper texture"""
    paper = Image.new('RGB', (w, h), C['paper_white'])
    pixels = paper.load()
    
    for _ in range(w * h // 3):
        x = random.randint(0, w-1)
        y = random.randint(0, h-1)
        v = random.randint(-intensity, intensity//2)
        
        p = list(pixels[x,y])
        p = [max(230, min(255, c+v)) for c in p[:3]]
        pixels[x,y] = tuple(p)
    
    return paper.filter(ImageFilter.GaussianBlur(radius=0.6))


def draw_hand_line(draw, points, color, base_width=2.5, pressure_var=0.5,
                   jitter=1.2, bleed=1.5):
    """Draw a line with simulated hand pressure and organic imperfection"""
    if len(points) < 2:
        return
    
    result_img = Image.new('RGBA', draw._image.size, (0,0,0,0))
    rd = ImageDraw.Draw(result_img)
    
    prev_pt = None
    for i, pt in enumerate(points):
        if prev_pt is None:
            prev_pt = pt
            continue
        
        # Pressure variation along the stroke
        t = i / max(1, len(points)-1)
        pressure = 1.0 - abs(math.sin(t * math.pi * 3)) * pressure_var
        pressure *= random.uniform(0.82, 1.15)
        
        # Width varies with pressure
        w = base_width * pressure
        
        # Add micro-jitter to simulate hand tremor
        jx = random.uniform(-jitter, jitter)
        jy = random.uniform(-jitter, jitter)
        
        x0, y0 = prev_pt[0] + jx*0.3, prev_pt[1] + jy*0.3
        x1, y1 = pt[0] + jx, pt[1] + jy
        
        rd.line([(x0,y0),(x1,y1)], fill=(*color, 230), width=max(1,int(w)),
              joint='curve')
        
        prev_pt = pt
    
    # Soft edge bleed (simulates ink on paper)
    if bleed > 0:
        result_img = result_img.filter(ImageFilter.GaussianBlur(radius=max(0.3,bleed*0.4)))
    
    return result_img


def draw_hand_ellipse(draw, cx, cy, rx, ry, fill_color, outline_color=None,
                       outline_w=2.5, irregularity=3.5, rotation_jitter=0.03):
    """Draw an ellipse with organic hand-drawn imperfection"""
    steps = 64
    pts = []
    
    for i in range(steps+1):
        angle = 2 * math.pi * i / steps
        
        # Add irregularity to radius
        rj_x = rx + random.uniform(-irregularity, irregularity)
        rj_y = ry + random.uniform(-irregularity, irregularity)
        
        # Slight rotation wobble
        angle += random.uniform(-rotation_jitter, rotation_jitter)
        
        px = cx + rj_x * math.cos(angle)
        py = cy + rj_y * math.sin(angle)
        pts.append((px, py))
    
    ov = Image.new('RGBA', draw._image.size, (0,0,0,0))
    od = ImageDraw.Draw(ov)
    
    # Fill
    od.polygon(pts, fill=(*fill_color, 245))
    
    # Outline with variable pressure
    if outline_color:
        for i in range(len(pts)-1):
            pw = outline_w * random.uniform(0.78, 1.22)
            od.line([pts[i], pts[i+1]], fill=(*outline_color, 220),
                  width=max(1,int(pw)), joint='curve')
    
    ov = ov.filter(ImageFilter.GaussianBlur(radius=0.8))
    return ov


def watercolor_wash(img, cx, cy, rx, ry, color, opacity=40, layers=5):
    """Apply translucent watercolor wash effect"""
    for layer_i in range(layers):
        wash = Image.new('RGBA', img.size, (0,0,0,0))
        wd = ImageDraw.Draw(wash)
        
        off_x = random.uniform(-rx*0.08, rx*0.08)
        off_y = random.uniform(-ry*0.08, ry*0.08)
        scale = 1 + layer_i * 0.15
        
        wd.ellipse([cx-rx*scale+off_x, cy-ry*scale+off_y,
                   cx+rx*scale+off_x, cy+ry*scale+off_y],
                  fill=(*color, int(opacity * (1-layer_i*0.15))))
        
        wash = wash.filter(ImageFilter.GaussianBlur(radius=4+layer_i*3))
        img = Image.alpha_composite(img, wash)
    
    return img


def sketch_guideline(draw, points, alpha=35):
    """Draw light pencil construction guideline"""
    gl = Image.new('RGBA', draw._image.size, (0,0,0,0))
    gd = ImageDraw.Draw(gl)
    
    sketch_pts = []
    for pt in points:
        sx = pt[0] + random.uniform(-2, 2)
        sy = pt[1] + random.uniform(-2, 2)
        sketch_pts.append((sx, sy))
    
    if len(sketch_pts) >= 2:
        gd.line(sketch_pts, fill=(*C['sketch_pencil'], alpha), 
               width=1, joint='curve')
    
    gl = gl.filter(ImageFilter.GaussianBlur(radius=0.5))
    return gl


def marker_bleed(img, cx, cy, shape_pts, color, spread=4, alpha=60):
    """Simulate marker color bleeding outside the lines"""
    bleed = Image.new('RGBA', img.size, (0,0,0,0))
    bd = ImageDraw.Draw(bleed)
    
    offset_pts = [(p[0]+random.uniform(-spread,spread),
                    p[1]+random.uniform(-spread,spread)) for p in shape_pts]
    bd.polygon(offset_pts, fill=(*color, alpha))
    
    bleed = bleed.filter(ImageFilter.GaussianBlur(radius=spread*1.2))
    return Image.alpha_composite(img, bleed)


def generate_icon(size=1024, seed=77321):
    """Generate v9 pure hand-drawn style icon"""
    random.seed(seed)
    s = size
    sc = s / 1024
    
    # Start with paper texture as base
    img = generate_paper_texture(s, s, intensity=20).convert('RGBA')
    d = ImageDraw.Draw(img)
    
    # ======== BACKGROUND: Indigo watercolor wash ========
    bg_layers = 12
    for bl in range(bg_layers):
        bt = bl / bg_layers
        br = s * 0.54 * (1 - bt*0.3)
        balpha = int(200 * (1-bt)**1.5)
        
        bg_ov = Image.new('RGBA', (s,s), (0,0,0,0))
        bd = ImageDraw.Draw(bg_ov)
        
        bx = s//2 + random.uniform(-10,10)*sc
        by = s//2 + random.uniform(-8,8)*sc
        bd.ellipse([bx-br, by-br, bx+br, by+br], 
                  fill=lerp(C['wash_indigo'], C['wash_deep'], bt)+(balpha,))
        bg_ov = bg_ov.filter(ImageFilter.GaussianBlur(radius=int(8+bl*4)*sc))
        img = Image.alpha_composite(img, bg_ov)
    
    d = ImageDraw.Draw(img)
    
    # Accent glow
    acc_ov = Image.new('RGBA', (s,s), (0,0,0,0))
    ad = ImageDraw.Draw(acc_ov)
    ad.ellipse([int(s*0.56), int(s*0.04), int(s*0.98), int(s*0.38)],
              fill=(*C['wash_accent'], 35))
    acc_ov = acc_ov.filter(ImageFilter.GaussianBlur(radius=int(s*0.07)))
    img = Image.alpha_composite(img, acc_ov)
    d = ImageDraw.Draw(img)
    
    # ======== SKETCH GUIDELINES (pencil underdrawing!) ========
    face_cx = s//2 + int(random.uniform(-6,4)*sc)
    face_cy = int(s*0.53)
    frx = int(s*0.30)
    fry = int(s*0.34)
    
    # Face oval guide
    face_guide = []
    for gi in range(50):
        ga = 2*math.pi*gi/50
        gx = face_cx + frx*math.cos(ga) + random.uniform(-1.5,1.5)*sc
        gy = face_cy + fry*math.sin(ga) + random.uniform(-1.5,1.5)*sc
        face_guide.append((gx,gy))
    img = Image.alpha_composite(img, sketch_guideline(d, face_guide, 28))
    d = ImageDraw.Draw(img)
    
    # Eye placement guides
    eye_spacing = frx*0.52
    for es in [-1, 1]:
        ex = face_cx + eye_spacing*es
        ey = face_cy - fry*0.06
        er = fry*0.22
        
        eg = []
        for egi in range(36):
            ea = 2*math.pi*egi/36
            eg.append((ex+er*math.cos(ea)+random.uniform(-1,1)*sc,
                      ey+er*math.sin(ea)*0.92+random.uniform(-1,1)*sc))
        img = Image.alpha_composite(img, sketch_guideline(d, eg, 22))
    d = ImageDraw.Draw(img)
    
    # ======== HAIR BACK (watercolor wash first, then ink) ========
    hair_back = Image.new('RGBA', (s,s), (0,0,0,0))
    hbd = ImageDraw.Draw(hair_back)
    
    hb_rx = frx*1.5
    hb_ry = fry*1.7
    hb_pts = []
    hbs = 70
    for hi in range(hbs):
        ha = 2*math.pi*hi/hbs
        n = 2.4  # Superellipse
        hx = face_cx + hb_rx*(abs(math.cos(ha))**(2/n))*(1 if math.cos(ha)>=0 else -1)
        hy = face_cy + hb_ry*(abs(math.sin(ha))**(2/n))*0.82
        hx += random.uniform(-3,3)*sc
        hy += random.uniform(-3,3)*sc
        hb_pts.append((hx,hy))
    
    hbd.polygon(hb_pts, fill=(*C['hair_base'], 235))
    hair_back = hair_back.filter(ImageFilter.GaussianBlur(radius=int(2.5*sc)))
    img = Image.alpha_composite(img, hair_back)
    
    # Hair shadow wash
    img = watercolor_wash(img, face_cx+int(s*0.02), face_cy+int(s*0.05),
                          hb_rx*0.88, hb_ry*0.82, C['hair_shadow'], 35, 4)
    d = ImageDraw.Draw(img)
    
    # Left side hair locks (hand-drawn paths!)
    for li in range(3):
        lx = face_cx - frx*(0.80 + li*0.13) + random.uniform(-4,4)*sc
        ly_top = face_cy - fry*(0.20 + li*0.07)
        ly_bot = face_cy + fry*(0.88 + li*0.10)
        lw = (14 + li*5)*sc
        
        lock_path = [
            (lx-lw, ly_top),
            (lx+lw*0.35+random.uniform(-2,2)*sc, ly_top+(ly_bot-ly_top)*0.22),
            (lx+lw*0.5+random.uniform(-3,3)*sc, ly_bot+random.uniform(-2,2)*sc),
            (lx-lw*0.72, ly_bot-(ly_bot-ly_top)*0.16),
        ]
        
        lock_ov = Image.new('RGBA', (s,s), (0,0,0,0))
        ld = ImageDraw.Draw(lock_ov)
        ld.polygon(lock_path, fill=(*C['hair_base'], 238))
        
        # Pink tip wash
        tip_y = ly_top + (ly_bot-ly_top)*0.58
        tip_color = lerp(C['hair_tip_rose'], C['hair_tip_lav'], li*0.3)
        tip_pts = [(max(p[0], lx-lw), max(p[1], tip_y)) for p in lock_path]
        ld.polygon(tip_pts, fill=(*tip_color, 100))
        
        lock_ov = lock_ov.filter(ImageFilter.GaussianBlur(radius=int(1.8*sc)))
        img = Image.alpha_composite(img, lock_ov)
        
        # Hand-drawn outline
        ol = draw_hand_line(d, lock_path+[lock_path[0]], C['ink_dark'],
                           base_width=2.2, pressure_var=0.4, jitter=1.0, bleed=1.2)
        img = Image.alpha_composite(img, ol)
        d = ImageDraw.Draw(img)
    
    # Right side hair
    for li in range(2):
        lx = face_cx + frx*(0.84 + li*0.11) + random.uniform(-3,3)*sc
        ly_top = face_cy - fry*0.14
        ly_bot = face_cy + fry*(0.46 + li*0.08)
        lw = (12 + li*4)*sc
        
        rp = [
            (lx-lw*0.48, ly_top),
            (lx+lw+random.uniform(-2,2)*sc, ly_top+(ly_bot-ly_top)*0.24),
            (lx+lw*0.62+random.uniform(-2,2)*sc, ly_bot+random.uniform(-1.5,1.5)*sc),
            (lx-lw*0.3, ly_bot-(ly_bot-ly_top)*0.12),
        ]
        
        rov = Image.new('RGBA', (s,s), (0,0,0,0))
        rd = ImageDraw.Draw(rov)
        fill_c = C['hair_base'] if li==0 else C['hair_shadow']
        rd.polygon(rp, fill=(*fill_c, 230))
        rov = rov.filter(ImageFilter.GaussianBlur(radius=int(1.5*sc)))
        img = Image.alpha_composite(img, rov)
        
        ol = draw_hand_line(d, rp+[rp[0]], C['ink_dark'],
                           base_width=1.8, pressure_var=0.35, jitter=0.8, bleed=1.0)
        img = Image.alpha_composite(img, ol)
        d = ImageDraw.Draw(img)
    
    # ======== FACE (hand-drawn oval with skin wash) ========
    face_ov = draw_hand_ellipse(d, face_cx, face_cy, frx, fry,
                                fill_color=C['skin_base'],
                                outline_color=C['ink_dark'],
                                outline_w=3.0, irregularity=4.0)
    img = Image.alpha_composite(img, face_ov)
    d = ImageDraw.Draw(img)
    
    # Skin warmth wash (top-left lighting)
    img = watercolor_wash(img, face_cx-frx*0.25, face_cy-fry*0.28,
                          frx*0.65, fry*0.55, C['skin_warm'], 30, 3)
    d = ImageDraw.Draw(img)
    
    # Skin shadow wash (bottom-right)
    img = watercolor_wash(img, face_cx+frx*0.15, face_cy+fry*0.12,
                          frx*0.72, fry*0.55, C['skin_shadow'], 28, 3)
    d = ImageDraw.Draw(img)
    
    # ======== EYES (THE STAR! - hand-drawn with care) ========
    eye_y = face_cy - fry*0.04
    eye_size = fry*0.26
    
    for ei_side in [-1, 1]:
        ex = face_cx + eye_spacing*ei_side + random.uniform(-2,2)*sc
        ey = eye_y + random.uniform(-1.5,1.5)*sc
        es = eye_size * random.uniform(0.97, 1.03)
        
        # Eye white (hand-drawn ellipse)
        ew_ov = draw_hand_ellipse(d, ex, ey, es*1.14, es*0.96,
                                   fill_color=(253,251,248),
                                   outline_color=C['ink_dark'],
                                   outline_w=2.6, irregularity=2.5)
        img = Image.alpha_composite(img, ew_ov)
        d = ImageDraw.Draw(img)
        
        # Iris - layered violet wash!
        ir = es*0.74
        
        # Outer iris ring
        ir1_ov = draw_hand_ellipse(d, ex+random.uniform(-1,1)*sc,
                                    ey+random.uniform(-1,1)*sc, ir, ir,
                                    fill_color=C['eye_violet'],
                                    irregularity=1.8)
        ir1_ov = ir1_ov.filter(ImageFilter.GaussianBlur(radius=int(0.6*sc)))
        img = Image.alpha_composite(img, ir1_ov)
        d = ImageDraw.Draw(img)
        
        # Mid iris
        ir2_ov = draw_hand_ellipse(d, ex+random.uniform(-0.5,0.5)*sc,
                                    ey+random.uniform(-0.5,0.5)*sc,
                                    ir*0.83, ir*0.83,
                                    fill_color=C['eye_bright'],
                                    irregularity=1.4)
        ir2_ov = ir2_ov.filter(ImageFilter.GaussianBlur(radius=int(0.4*sc)))
        img = Image.alpha_composite(img, ir2_ov)
        d = ImageDraw.Draw(img)
        
        # Inner iris (lightest)
        ir3_ov = draw_hand_ellipse(d, ex, ey, ir*0.54, ir*0.54,
                                    fill_color=C['eye_light'],
                                    irregularity=1.2)
        ir3_ov = ir3_ov.filter(ImageFilter.GaussianBlur(radius=int(0.3*sc)))
        img = Image.alpha_composite(img, ir3_ov)
        d = ImageDraw.Draw(img)
        
        # Pupil
        pr = ir*0.27
        po_x = pr*0.1*ei_side
        po_y = pr*0.06
        pup_ov = draw_hand_ellipse(d, ex+po_x, ey+po_y, pr, pr,
                                   fill_color=C['eye_pupil'],
                                   irregularity=0.8)
        pup_ov = pup_ov.filter(ImageFilter.GaussianBlur(radius=int(0.3*sc)))
        img = Image.alpha_composite(img, pup_ov)
        d = ImageDraw.Draw(img)
        
        # HIGHLIGHTS (white of life!)
        # Main large highlight
        h1r = es*0.24
        h1_ov = draw_hand_ellipse(d, ex-es*0.30+random.uniform(-1,1)*sc,
                                   ey-es*0.34+random.uniform(-1,1)*sc,
                                   h1r, h1r*0.86,
                                   fill_color=(255,255,255),
                                   irregularity=1.0)
        img = Image.alpha_composite(img, h1_ov)
        d = ImageDraw.Draw(img)
        
        # Secondary small highlight
        h2r = es*0.11
        h2_ov = draw_hand_ellipse(d, ex+es*0.17+random.uniform(-0.5,0.5)*sc,
                                   ey+es*0.25+random.uniform(-0.5,0.5)*sc,
                                   h2r, h2r,
                                   fill_color=(255,255,255),
                                   irregularity=0.6)
        img = Image.alpha_composite(img, h2_ov)
        d = ImageDraw.Draw(img)
        
        # Tiny sparkle
        if random.random() > 0.35:
            h3r = es*0.055
            h3_ov = draw_hand_ellipse(d, ex-es*0.04, ey+es*0.39,
                                       h3r, h3r,
                                       fill_color=(255,255,255),
                                       irregularity=0.4)
            img = Image.alpha_composite(img, h3_ov)
            d = ImageDraw.Draw(img)
        
        # Upper eyelid (hand-drawn curved line!)
        lid_pts = []
        lid_base = ey - es*0.94
        for ldi in range(26):
            ldt = ldi/25
            ldx = ex - es*1.12 + es*2.24*ldt
            ldy = lid_base + math.sin(ldt*math.pi)*(-es*0.16) + random.uniform(-0.8,0.8)*sc
            lid_pts.append((ldx, ldy))
        
        lid_line = draw_hand_line(d, lid_pts, C['ink_dark'],
                                  base_width=2.8, pressure_var=0.3,
                                  jitter=0.6, bleed=0.8)
        img = Image.alpha_composite(img, lid_line)
        d = ImageDraw.Draw(img)
        
        # Lower lashes (individual strokes)
        for lai in range(4):
            lat = 0.10 + lai*0.24
            lax = ex - es*0.76 + es*1.52*lat
            lay = ey + es*0.86
            lalen = (2.2 + random.random()*2.2)*sc
            laang = math.radians(-10 + lai*7 + random.uniform(-4,4))
            
            lash = Image.new('RGBA', (s,s), (0,0,0,0))
            lasd = ImageDraw.Draw(lash)
            lasd.line([(lax,lay),
                      (lax+lalen*math.cos(laang), lay+lalen*math.sin(laang))],
                     fill=(*C['ink_medium'], 200), width=max(1,int(1.4*sc)))
            lash = lash.filter(ImageFilter.GaussianBlur(radius=int(0.5*sc)))
            img = Image.alpha_composite(img, lash)
    
    d = ImageDraw.Draw(img)
    
    # ======== EYEBROWS (expressive hand-drawn arcs) ========
    brow_y = eye_y - eye_size*1.30
    for bi_s in [-1, 1]:
        bx = face_cx + eye_spacing*0.86*bi_s + random.uniform(-2,2)*sc
        by = brow_y
        bw = eye_size*0.88
        bh = eye_size*0.18
        
        brow_pts = []
        for bpi in range(24):
            bpt = bpi/23
            bpx = bx - bw*bi_s + bw*2*bpt*bi_s
            bpy = by + math.sin(bpt*math.pi)*(-bh) + random.uniform(-0.6,0.6)*sc
            brow_pts.append((bpx,bpy))
        
        brow_l = draw_hand_line(d, brow_pts, C['hair_base'],
                               base_width=2.8, pressure_var=0.35,
                               jitter=0.7, bleed=0.9)
        brow_l = brow_l.filter(ImageFilter.GaussianBlur(radius=int(0.6*sc)))
        img = Image.alpha_composite(img, brow_l)
        d = ImageDraw.Draw(img)
    
    # ======== NOSE (minimal hint) ========
    nose_ov = draw_hand_ellipse(d, face_cx+random.uniform(-1.5,1.5)*sc,
                                 face_cy+fry*0.12+random.uniform(-1,1)*sc,
                                 3.5*sc, 2.5*sc,
                                 fill_color=C['skin_shadow'],
                                 irregularity=1.2)
    nose_ov = nose_ov.filter(ImageFilter.GaussianBlur(radius=int(1.8*sc)))
    img = Image.alpha_composite(img, nose_ov)
    d = ImageDraw.Draw(img)
    
    # ======== BLUSH (soft watercolor ovals) ========
    blush_y = face_cy + fry*0.24
    blush_xo = frx*0.38
    for bl_s in [-1, 1]:
        blx = face_cx + blush_xo*bl_s + random.uniform(-4,4)*sc
        bly = blush_y + random.uniform(-2,2)*sc
        blr = fry*0.15
        
        for bli in range(3):
            bla = 32 - bli*8
            bls = 1 + bli*0.22
            
            blov = draw_hand_ellipse(d, blx, bly, blr*bls, blr*bls*0.76,
                                     fill_color=C['blush_wash'],
                                     irregularity=2.5)
            # Apply alpha through overlay
            alpha_ov = Image.new('RGBA', (s,s), (0,0,0,0))
            ald = ImageDraw.Draw(alpha_ov)
            ald.ellipse([blx-blr*bls-2, bly-blr*bls*0.76-2,
                        blx+blr*bls+2, bly+blr*bls*0.76+2],
                       fill=(*C['blush_wash'], bla))
            alpha_ov = alpha_ov.filter(ImageFilter.GaussianBlur(radius=int(5+bli*2)*sc))
            img = Image.alpha_composite(img, alpha_ov)
        d = ImageDraw.Draw(img)
    
    # ======== MOUTH: gentle smile curve ========
    mx = face_cx + random.uniform(-2,2)*sc
    my = face_cy + fry*0.47
    mw = frx*0.16
    md = fry*0.038
    
    smile_pts = []
    for spi in range(22):
        sp = spi/21
        sx = mx - mw + mw*2*sp
        sy = my + math.sin(sp*math.pi)*md + random.uniform(-0.4,0.4)*sc
        smile_pts.append((sx,sy))
    
    smile_l = draw_hand_line(d, smile_pts, C['mouth_ink'],
                             base_width=2.3, pressure_var=0.25,
                             jitter=0.5, bleed=0.7)
    smile_l = smile_l.filter(ImageFilter.GaussianBlur(radius=int(0.6*sc)))
    img = Image.alpha_composite(img, smile_l)
    d = ImageDraw.Draw(img)
    
    # Lip tint wash
    lip_ov = draw_hand_ellipse(d, mx, my+md*0.3, mw*0.42, mw*0.15,
                                fill_color=C['mouth_ink'],
                                irregularity=1.8)
    lip_alpha = Image.new('RGBA', (s,s), (0,0,0,0))
    lad = ImageDraw.Draw(lip_alpha)
    lad.ellipse([mx-mw*0.44, my+md*0.2-mw*0.14,
                mx+mw*0.44, my+md*0.2+mw*0.14],
               fill=(*C['mouth_ink'], 32))
    lip_alpha = lip_alpha.filter(ImageFilter.GaussianBlur(radius=int(3*sc)))
    img = Image.alpha_composite(img, lip_alpha)
    d = ImageDraw.Draw(img)
    
    # ======== BANGS / FRONT HAIR (hand-drawn shape!) ========
    bang_base = face_cy - fry*0.58
    
    bang_pts = [
        (face_cx+frx*1.04+random.uniform(-4,4)*sc, bang_base-fry*0.29),
        (face_cx+frx*0.54+random.uniform(-3,3)*sc, bang_base-fry*0.19),
        (face_cx+frx*0.04+random.uniform(-3,3)*sc, bang_base-fry*0.09),
        (face_cx-frx*0.30+random.uniform(-3,3)*sc, bang_base+fry*0.07),
        (face_cx-frx*0.52+random.uniform(-4,4)*sc, bang_base+fry*0.21),
        (face_cx-frx*0.36+random.uniform(-3,3)*sc, bang_base+fry*0.35),
        (face_cx+frx*0.04+random.uniform(-3,3)*sc, bang_base+fry*0.25),
        (face_cx+frx*0.46+random.uniform(-3,3)*sc, bang_base+fry*0.11),
        (face_cx+frx*0.84+random.uniform(-4,4)*sc, bang_base-fry*0.01),
    ]
    
    # Bang fill
    bang_ov = Image.new('RGBA', (s,s), (0,0,0,0))
    bd = ImageDraw.Draw(bang_ov)
    bd.polygon(bang_pts, fill=(*C['hair_base'], 240))
    # Highlight area
    bd.polygon(bang_pts[:6], fill=(*C['hair_highlight'], 65))
    bang_ov = bang_ov.filter(ImageFilter.GaussianBlur(radius=int(1.8*sc)))
    img = Image.alpha_composite(img, bang_ov)
    
    # Bang outline (hand-drawn!)
    bang_ol = draw_hand_line(d, bang_pts+[bang_pts[0]], C['ink_dark'],
                              base_width=3.0, pressure_var=0.35,
                              jitter=1.0, bleed=1.2)
    img = Image.alpha_composite(img, bang_ol)
    d = ImageDraw.Draw(img)
    
    # Individual bang strands
    for si in range(4):
        sx = face_cx - frx*0.26 + si*frx*0.23 + random.uniform(-2,2)*sc
        sy_top = bang_base - fry*0.14
        sy_bot = face_cy - fry*0.06 + si*fry*0.065
        sw = (8 + si*2.5)*sc
        
        sp = [
            (sx-sw, sy_top+random.uniform(-1,1)*sc),
            (sx+sw*0.28+random.uniform(-1.5,1.5)*sc, sy_top+(sy_bot-sy_top)*0.28),
            (sx+sw*0.48+random.uniform(-2,2)*sc, sy_bot+random.uniform(-1.5,1.5)*sc),
            (sx-sw*0.52, sy_bot-(sy_bot-sy_top)*0.15),
        ]
        
        sov = Image.new('RGBA', (s,s), (0,0,0,0))
        sd = ImageDraw.Draw(sov)
        strand_c = C['hair_base'] if si%2==0 else C['hair_highlight']
        sd.polygon(sp, fill=(*strand_c, 235))
        sov = sov.filter(ImageFilter.GaussianBlur(radius=int(1.2*sc)))
        img = Image.alpha_composite(img, sov)
        
        sol = draw_hand_line(d, sp+[sp[0]], C['ink_dark'],
                             base_width=2.0, pressure_var=0.3, jitter=0.7, bleed=0.9)
        img = Image.alpha_composite(img, sol)
        d = ImageDraw.Draw(img)
    
    # ======== BUTTERFLY BOW (hand-painted!) ========
    bcx = face_cx + frx*0.98 + random.uniform(-3,3)*sc
    bcy = face_cy - fry*0.19 + random.uniform(-2,2)*sc
    bsz = frx*0.31
    
    # Left wing (larger)
    lw_pts = []
    for lwi in range(26):
        lwt = lwi/25
        lw_ang = math.radians(-66 + lwt*130)
        lr = bsz * (0.90 if lwt<0.4 else (0.84 - 0.34*abs(lwt-0.5)))
        lwx = bcx - bsz*0.15 + lr*math.cos(lw_ang) + random.uniform(-2,2)*sc
        lwy = bcy + lr*math.sin(lw_ang)*0.60 + random.uniform(-2,2)*sc
        lw_pts.append((lwx,lwy))
    
    lw_ov = Image.new('RGBA', (s,s), (0,0,0,0))
    lwd = ImageDraw.Draw(lw_ov)
    lwd.polygon(lw_pts, fill=(*C['bow_magenta'], 238))
    lwd.polygon(lw_pts[:14], fill=(*C['bow_light'], 80))
    lw_ov = lw_ov.filter(ImageFilter.GaussianBlur(radius=int(1.8*sc)))
    img = Image.alpha_composite(img, lw_ov)
    
    lw_ol = draw_hand_line(d, lw_pts+[lw_pts[0]], C['ink_dark'],
                            base_width=2.2, pressure_var=0.35,
                            jitter=0.8, bleed=1.0)
    img = Image.alpha_composite(img, lw_ol)
    d = ImageDraw.Draw(img)
    
    # Right wing (smaller)
    rw_pts = []
    for rwi in range(20):
        rwt = rwi/19
        rw_ang = math.radians(32 + rwt*96)
        rr = bsz*0.58 * (0.84 if rwt<0.5 else 0.64)
        rwx = bcx + bsz*0.10 + rr*math.cos(rw_ang) + random.uniform(-1.5,1.5)*sc
        rwy = bcy + rr*math.sin(rw_ang)*0.50 + random.uniform(-1.5,1.5)*sc
        rw_pts.append((rwx,rwy))
    
    rw_ov = Image.new('RGBA', (s,s), (0,0,0,0))
    rwd = ImageDraw.Draw(rw_ov)
    rwd.polygon(rw_pts, fill=(*C['bow_magenta'], 230))
    rw_ov = rw_ov.filter(ImageFilter.GaussianBlur(radius=int(1.5*sc)))
    img = Image.alpha_composite(img, rw_ov)
    
    rw_ol = draw_hand_line(d, rw_pts+[rw_pts[0]], C['ink_dark'],
                            base_width=1.8, pressure_var=0.3,
                            jitter=0.6, bleed=0.8)
    img = Image.alpha_composite(img, rw_ol)
    d = ImageDraw.Draw(img)
    
    # Center knot
    kn_ov = draw_hand_ellipse(d, bcx, bcy+bsz*0.008, bsz*0.13, bsz*0.10,
                                fill_color=C['bow_shadow'],
                                outline_color=C['ink_dark'],
                                outline_w=1.5, irregularity=1.5)
    kn_ov = kn_ov.filter(ImageFilter.GaussianBlur(radius=int(1.2*sc)))
    img = Image.alpha_composite(img, kn_ov)
    d = ImageDraw.Draw(img)
    
    # Ribbon tails
    for ti in range(2):
        tx = bcx + (-1 if ti==0 else 1)*bsz*0.11
        ty_top = bcy + bsz*0.07
        ty_bot = bcy + bsz*0.48
        tw = bsz*0.09
        
        tp = [
            (tx-tw+random.uniform(-1,1)*sc, ty_top+random.uniform(-1,1)*sc),
            (tx+tw*0.42+random.uniform(-1.5,1.5)*sc, ty_top+(ty_bot-ty_top)*0.34),
            (tx+tw*0.24+random.uniform(-1.5,1.5)*sc, ty_bot+random.uniform(-1.5,1.5)*sc),
            (tx-tw*0.52, ty_bot-(ty_bot-ty_top)*0.14),
        ]
        
        tov = Image.new('RGBA', (s,s), (0,0,0,0))
        td = ImageDraw.Draw(tov)
        td.polygon(tp, fill=(*C['bow_light'], 228))
        tov = tov.filter(ImageFilter.GaussianBlur(radius=int(1.2*sc)))
        img = Image.alpha_composite(img, tov)
        
        tol = draw_hand_line(d, tp, C['ink_dark'],
                             base_width=1.5, pressure_var=0.25,
                             jitter=0.5, bleed=0.7)
        img = Image.alpha_composite(img, tol)
        d = ImageDraw.Draw(img)
    
    # ======== FINAL PAPER TEXTURE OVERLAY ========
    paper_overlay = generate_paper_texture(s, s, intensity=12).convert('RGBA')
    paper_overlay = ImageEnhance.Brightness(paper_overlay).enhance(0.97)
    img = Image.blend(img, paper_overlay, alpha=0.18)
    
    # Convert to RGB
    final = Image.new('RGB', (s,s), C['wash_deep'])
    final.paste(img, (0,0), img if img.mode=='RGBA' else None)
    
    return final


if __name__ == '__main__':
    print("Generating v9 icon (Pure Hand-Drawn / Analog Ink style)...")
    
    sizes = [1024, 512, 192, 96, 72, 48]
    
    for sz in sizes:
        print(f"  Generating {sz}x{sz}...", end=' ', flush=True)
        icon = generate_icon(size=sz, seed=77321)
        
        filename = f'{OUTPUT_DIR}/game_icon_v9_{sz}.png'
        icon.save(filename, 'PNG')
        
        fsize = os.path.getsize(filename) if os.path.exists(filename) else 0
        print(f"✓ {filename} ({fsize:,} bytes)")
    
    print("\n✓ Done! v9 icons generated (Pure Hand-Drawn style).")
