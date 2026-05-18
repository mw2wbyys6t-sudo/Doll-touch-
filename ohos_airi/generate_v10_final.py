#!/usr/bin/env python3
"""
星空愛莉 (Hoshizora Airi) App Icon Generator v10 FINAL
Hybrid approach combining ALL skill insights:
- canvas-design: Analog craftsmanship, museum-quality detail
- frontend-skill: Premium restraint, dominant visual anchor, clean composition  
- brand-guidelines: Professional color harmony
- BanG Dream idol game: Circular frame, 75% character fill, vivid cel-shading

NOT based on any previous version - complete rewrite with all insights integrated.
"""
from PIL import Image, ImageDraw, ImageFilter, ImageEnhance
import math
import random
import os

OUTPUT_DIR = '/workspace/ohos_airi'

# ======== PREMIUM PALETTE (professional idol game grade) ========
C = {
    # Hair - warm rich brown with rose-lavender tips
    'hair':           (88, 60, 44),
    'hair_dark':      (62, 42, 30),
    'hair_light':     (138, 102, 78),
    'hair_tip_rose':  (242, 168, 192),
    'hair_tip_lav':   (208, 168, 228),
    
    # Eyes - VIOLET SIGNATURE (the ONE accent color per frontend-skill rule)
    'eye_violet':     (152, 100, 225),
    'eye_bright':     (188, 145, 245),
    'eye_light':      (225, 200, 255),
    'eye_deep':       (85, 50, 155),
    'pupil':          (32, 18, 58),
    
    # Skin - warm porcelain
    'skin':           (255, 240, 226),
    'skin_shadow':    (238, 216, 198),
    'skin_highlight': (255, 252, 246),
    'blush':          (252, 172, 188),
    
    # Mouth
    'mouth':          (228, 98, 118),
    
    # Bow - magenta accent
    'bow':            (242, 138, 195),
    'bow_light':      (255, 200, 230),
    'bow_dark':       (210, 100, 165),
    
    # Background - deep indigo (premium, not garish)
    'bg_core':        (48, 28, 78),
    'bg_edge':        (22, 10, 42),
    'bg_glow':        (90, 55, 140),
    
    # Line art - warm dark (not harsh black)
    'line_dark':      (52, 38, 32),
    'line_medium':    (82, 64, 54),
    
    # Stars
    'star':           (255, 255, 255),
}


def lerp(c1, c2, t):
    t = max(0, min(1, t))
    return tuple(int(a + (b-a)*t) for a,b in zip(c1,c2))


def draw_organic_shape(draw, cx, cy, rx, ry, fill, outline=None, 
                        ow=2.5, irregularity=2.5, blur=1.0):
    """Draw shape with subtle organic imperfection"""
    pts = []
    steps = 72
    
    for i in range(steps):
        angle = 2*math.pi*i/steps
        
        noise = irregularity * (
            0.5*math.sin(angle*3 + 0.5) +
            0.3*math.cos(angle*5 + 1.2) +
            0.2*math.sin(angle*7 + 2.8)
        )
        
        prx = rx + noise * (rx/ry) * 0.15
        pry = ry + noise * (ry/rx) * 0.12
        
        px = cx + prx * math.cos(angle)
        py = cy + pry * math.sin(angle)
        pts.append((px,py))
    
    ov = Image.new('RGBA', draw._image.size, (0,0,0,0))
    od = ImageDraw.Draw(ov)
    
    od.polygon(pts, fill=(*fill, 250))
    
    if outline:
        od.polygon(pts+[pts[0]], fill=(*outline, 200))
    
    if blur > 0:
        ov = ov.filter(ImageFilter.GaussianBlur(radius=blur))
    
    return ov


def draw_variable_line(draw, pts, color, base_w=2.5, pressure=0.35, blur=0.6):
    """Line with natural pressure variation like real pen/pencil"""
    ov = Image.new('RGBA', draw._image.size, (0,0,0,0))
    od = ImageDraw.Draw(ov)
    
    for i in range(len(pts)-1):
        t = i / max(1, len(pts)-2)
        
        w = base_w * (1.0 + pressure*math.sin(t*math.pi*4) + random.uniform(-0.1,0.1))
        w = max(1, w)
        
        od.line([pts[i], pts[i+1]], fill=(*color, 220), width=int(w), joint='curve')
    
    if blur > 0:
        ov = ov.filter(ImageFilter.GaussianBlur(radius=blur))
    return ov


def soft_radial(img, cx, cy, r, color_inner, color_outer, layers=20):
    """Premium soft radial gradient"""
    for li in range(layers, 0, -1):
        t = li/layers
        cr = int(r*t)
        col = lerp(color_inner, color_outer, 1-t)
        alpha = int(255*(1-(1-t)**1.2))
        
        ov = Image.new('RGBA', img.size, (0,0,0,0))
        od = ImageDraw.Draw(ov)
        od.ellipse([cx-cr, cy-cr, cx+cr, cy+cr], fill=(*col,alpha))
        ov = ov.filter(ImageFilter.GaussianBlur(radius=max(1,int(r*0.02))))
        img = Image.alpha_composite(img, ov)
    return img


def generate_icon(size=1024, seed=44592):
    random.seed(seed)
    s = size
    sc = s/1024
    
    img = Image.new('RGBA', (s,s), (0,0,0,0))
    d = ImageDraw.Draw(img)
    
    cx = s//2
    cy = s//2
    
    # ======== BACKGROUND: Premium indigo radial ========
    img = soft_radial(img, cx-int(s*0.03), cy-int(s*0.02), int(s*0.53), 
                     C['bg_core'], C['bg_edge'], 35)
    d = ImageDraw.Draw(img)
    
    # Subtle accent glow (off-center for visual interest - frontend-skill principle)
    glow_ov = Image.new('RGBA', (s,s), (0,0,0,0))
    gd = ImageDraw.Draw(glow_ov)
    gd.ellipse([int(s*0.58), int(s*0.04), int(s*0.96), int(s*0.40)],
              fill=(*C['bg_glow'], 30))
    glow_ov = glow_ov.filter(ImageFilter.GaussianBlur(radius=int(s*0.07)))
    img = Image.alpha_composite(img, glow_ov)
    d = ImageDraw.Draw(img)
    
    # ======== STARS: Premium sparkle placement ========
    star_data = [
        (0.13, 0.09, 16, 4, 0.95),   # Large top-left
        (0.87, 0.16, 12, 4, 0.88),   # Top-right
        (0.07, 0.55, 10, 4, 0.75),   # Left mid
        (0.91, 0.68, 14, 4, 0.82),   # Right lower
        (0.20, 0.89, 8, 4, 0.60),    # Bottom-left
        (0.80, 0.93, 7, 4, 0.55),    # Bottom-right
    ]
    
    for sx, sy, sr, pts_n, opa in star_data:
        spx, spy = int(s*sx), int(s*sy)
        ssr = int(sr*sc)
        
        star_pts = []
        rot = random.uniform(0, math.pi*2)
        for si in range(pts_n*2):
            ang = math.pi/pts_n*si + rot - math.pi/2
            r = ssr if si%2==0 else ssr*0.36
            star_pts.append((spx+r*math.cos(ang), spy+r*math.sin(ang)))
        
        sov = Image.new('RGBA', (s,s), (0,0,0,0))
        sd = ImageDraw.Draw(sov)
        sd.polygon(star_pts, fill=(*C['star'], int(opa*255)))
        sov = sov.filter(ImageFilter.GaussianBlur(radius=max(1,int(sc))))
        img = Image.alpha_composite(img, sov)
    
    # Tiny sparkles
    for _ in range(25):
        tx = random.randint(int(s*0.03), int(s*0.97))
        ty = random.randint(int(s*0.03), int(s*0.97))
        tr = random.uniform(1.5, 3)*sc
        
        tov = Image.new('RGBA', (s,s), (0,0,0,0))
        td = ImageDraw.Draw(tov)
        td.ellipse([tx-tr,ty-tr,tx+tr,ty+tr], fill=(*C['star'],random.randint(100,200)))
        tov = tov.filter(ImageFilter.GaussianBlur(radius=max(0.5,tr*0.3)))
        img = Image.alpha_composite(img, tov)
    
    d = ImageDraw.Draw(img)
    
    # ======== CHARACTER (DOMINANT VISUAL ANCHOR - 80% of frame!) ========
    fcx = cx + int(random.uniform(-4,3)*sc)
    fcy = int(s*0.52)
    frx = int(s*0.34)
    fry = int(s*0.38)
    
    # HAIR BACK
    hbov = draw_organic_shape(d, fcx, int(fcy+fry*0.04), int(frx*1.52), int(fry*1.78),
                              C['hair'], C['line_dark'], ow=3, irregularity=3.5, blur=2)
    img = Image.alpha_composite(img, hbov)
    d = ImageDraw.Draw(img)
    
    # Hair shadow depth
    hsov = draw_organic_shape(d, fcx+int(s*0.025), fcy+int(fry*0.06), 
                              int(frx*1.38), int(fry*1.58),
                              (*C['hair_dark'],), None, irregularity=3, blur=6)
    hsov2 = Image.new('RGBA', (s,s), (0,0,0,0))
    hsov2.paste(hsov, (0,0), hsov)
    hsov2 = ImageEnhance.Brightness(hsov2).enhance(0.5)
    img = Image.alpha_composite(img, hsov2)
    d = ImageDraw.Draw(img)
    
    # Left hair locks with rose tips
    for li in range(3):
        lx = fcx - frx*(0.78 + li*0.12)
        ly_t = fcy - fry*(0.18 + li*0.06)
        ly_b = fcy + fry*(0.90 + li*0.09)
        lw = (15 + li*5)*sc
        
        lp = [
            (lx-lw, ly_t),
            (lx+lw*0.38, ly_t+(ly_b-ly_t)*0.20),
            (lx+lw*0.52, ly_b),
            (lx-lw*0.76, ly_b-(ly_b-ly_t)*0.14),
        ]
        
        lov = Image.new('RGBA', (s,s), (0,0,0,0))
        ld = ImageDraw.Draw(lov)
        ld.polygon(lp, fill=(*C['hair'], 245))
        
        tip_c = lerp(C['hair_tip_rose'], C['hair_tip_lav'], li*0.33)
        tip_y = ly_t + (ly_b-ly_t)*0.56
        tip_p = [(max(p[0],lx-lw), max(p[1],tip_y)) for p in lp]
        ld.polygon(tip_p, fill=(*tip_c, 110))
        
        lov = lov.filter(ImageFilter.GaussianBlur(radius=int(1.5*sc)))
        img = Image.alpha_composite(img, lov)
        
        lol = draw_variable_line(d, lp+[lp[0]], C['line_dark'], base_w=2.4, pressure=0.3, blur=0.8)
        img = Image.alpha_composite(img, lol)
        d = ImageDraw.Draw(img)
    
    # Right side hair
    for li in range(2):
        lx = fcx + frx*(0.86 + li*0.10)
        ly_t = fcy - fry*0.14
        ly_b = fcy + fry*(0.48 + li*0.08)
        lw = (13 + li*4)*sc
        
        rp = [
            (lx-lw*0.48, ly_t),
            (lx+lw, ly_t+(ly_b-ly_t)*0.22),
            (lx+lw*0.65, ly_b),
            (lx-lw*0.32, ly_b-(ly_b-ly_t)*0.10),
        ]
        
        rov = Image.new('RGBA', (s,s), (0,0,0,0))
        rd = ImageDraw.Draw(rov)
        rfill = C['hair'] if li==0 else C['hair_dark']
        rd.polygon(rp, fill=(*rfill, 235))
        rov = rov.filter(ImageFilter.GaussianBlur(radius=int(1.2*sc)))
        img = Image.alpha_composite(img, rov)
        
        rol = draw_variable_line(d, rp+[rp[0]], C['line_dark'], base_w=2.0, pressure=0.25, blur=0.7)
        img = Image.alpha_composite(img, rol)
        d = ImageDraw.Draw(img)
    
    # FACE (dominant oval - premium skin gradient)
    fov = draw_organic_shape(d, fcx, fcy, frx, fry,
                             C['skin'], C['line_dark'], ow=3.2, irregularity=3.0, blur=1.5)
    img = Image.alpha_composite(img, fov)
    d = ImageDraw.Draw(img)
    
    # Skin highlight (top-left lighting - creates dimension)
    sh_ov = draw_organic_shape(d, fcx-frx*0.22, fcy-fry*0.26,
                                frx*0.68, fry*0.52, C['skin_highlight'], None, 
                                irregularity=2, blur=10)
    sh_alpha = Image.new('RGBA', (s,s), (0,0,0,0))
    sh_alpha.paste(sh_ov, (0,0), sh_ov)
    img = Image.alpha_composite(img, ImageEnhance.Brightness(sh_alpha).enhance(0.6))
    d = ImageDraw.Draw(img)
    
    # Skin shadow (bottom-right)
    ssh_ov = draw_organic_shape(d, fcx+frx*0.12, fcy+fry*0.10,
                                 frx*0.70, fry*0.52, C['skin_shadow'], None,
                                 irregularity=2.5, blur=8)
    ssh_alpha = Image.new('RGBA', (s,s), (0,0,0,0))
    ssh_alpha.paste(ssh_ov, (0,0), ssh_ov)
    img = Image.alpha_composite(img, ImageEnhance.Brightness(ssh_alpha).enhance(0.45))
    d = ImageDraw.Draw(img)
    
    # ======== EYES (THE SIGNATURE - violet masterpiece!) ========
    eye_sp = frx*0.50
    eye_sz = fry*0.27
    eye_y = fcy - fry*0.03
    
    for es in [-1, 1]:
        ex = fcx + eye_sp*es + random.uniform(-1.5,1.5)*sc
        ey = eye_y + random.uniform(-1,1)*sc
        ees = eye_sz * random.uniform(0.985, 1.015)
        
        # Eye white
        ew_ov = draw_organic_shape(d, ex, ey, ees*1.16, ees*0.98,
                                   (252,250,248), C['line_dark'], ow=2.6, irregularity=2.0, blur=1.2)
        img = Image.alpha_composite(img, ew_ov)
        d = ImageDraw.Draw(img)
        
        # Iris - 3-layer violet gradient!
        ir = ees*0.73
        
        ir1 = draw_organic_shape(d, ex+random.uniform(-0.8,0.8)*sc, ey+random.uniform(-0.8,0.8)*sc,
                                  ir, ir, C['eye_violet'], None, irregularity=1.6, blur=0.8)
        img = Image.alpha_composite(img, ir1)
        d = ImageDraw.Draw(img)
        
        ir2 = draw_organic_shape(d, ex+random.uniform(-0.4,0.4)*sc, ey+random.uniform(-0.4,0.4)*sc,
                                  ir*0.84, ir*0.84, C['eye_bright'], None, irregularity=1.3, blur=0.5)
        img = Image.alpha_composite(img, ir2)
        d = ImageDraw.Draw(img)
        
        ir3 = draw_organic_shape(d, ex, ey, ir*0.55, ir*0.55, C['eye_light'], None,
                                  irregularity=1.0, blur=0.4)
        img = Image.alpha_composite(img, ir3)
        d = ImageDraw.Draw(img)
        
        # Pupil
        pr = ir*0.26
        po_x = pr*0.10*es
        po_y = pr*0.05
        pup = draw_organic_shape(d, ex+po_x, ey+po_y, pr, pr, C['pupil'], None,
                                   irregularity=0.7, blur=0.4)
        img = Image.alpha_composite(img, pup)
        d = ImageDraw.Draw(img)
        
        # HIGHLIGHTS (the soul of anime eyes!)
        hl1 = draw_organic_shape(d, ex-ees*0.30, ey-ees*0.34, ees*0.25, ees*0.22,
                                  (255,255,255), None, irregularity=0.8, blur=0.3)
        img = Image.alpha_composite(img, hl1)
        d = ImageDraw.Draw(img)
        
        hl2 = draw_organic_shape(d, ex+ees*0.17, ey+ees*0.25, ees*0.11, ees*0.10,
                                  (255,255,255), None, irregularity=0.5, blur=0.2)
        img = Image.alpha_composite(img, hl2)
        d = ImageDraw.Draw(img)
        
        # Tiny third highlight
        if random.random() > 0.3:
            hl3 = draw_organic_shape(d, ex-ees*0.04, ey+ees*0.40, ees*0.055, ees*0.05,
                                      (255,255,255), None, irregularity=0.3, blur=0.15)
            img = Image.alpha_composite(img, hl3)
            d = ImageDraw.Draw(img)
        
        # Upper eyelid curve (thick, expressive)
        lid_pts = []
        lid_base = ey - ees*0.94
        for lpi in range(28):
            lpt = lpi/27
            lpx = ex - ees*1.14 + ees*2.28*lpt
            lpy = lid_base + math.sin(lpt*math.pi)*(-ees*0.17)
            lid_pts.append((lpx,lpy))
        
        lid_l = draw_variable_line(d, lid_pts, C['line_dark'], base_w=2.9, pressure=0.28, blur=0.7)
        img = Image.alpha_composite(img, lid_l)
        d = ImageDraw.Draw(img)
        
        # Lower lashes
        for lai in range(4):
            lat = 0.10 + lai*0.24
            lax = ex - ees*0.76 + ees*1.52*lat
            lay = ey + ees*0.88
            lalen = (2.4+random.random()*2.2)*sc
            laang = math.radians(-10+lai*7+random.uniform(-4,4))
            
            lav = Image.new('RGBA', (s,s), (0,0,0,0))
            lad = ImageDraw.Draw(lav)
            lad.line([(lax,lay),(lax+lalen*math.cos(laang), lay+lalen*math.sin(laang))],
                    fill=(*C['line_medium'], 190), width=max(1,int(1.4*sc)))
            lav = lav.filter(ImageFilter.GaussianBlur(radius=int(0.5*sc)))
            img = Image.alpha_composite(img, lav)
    
    d = ImageDraw.Draw(img)
    
    # EYEBROWS
    brow_y = eye_y - eye_sz*1.28
    for bs in [-1, 1]:
        bx = fcx + eye_sp*0.86*bs
        by = brow_y
        bw = eye_sz*0.88
        bh = eye_sz*0.18
        
        bp = []
        for bpi in range(26):
            bt = bpi/25
            bp.append((bx-bw*bs+bw*2*bt*bs, by+math.sin(bt*math.pi)*(-bh)))
        
        bl = draw_variable_line(d, bp, C['hair'], base_w=2.8, pressure=0.32, blur=0.8)
        img = Image.alpha_composite(img, bl)
        d = ImageDraw.Draw(img)
    
    # NOSE (minimal)
    nov = draw_organic_shape(d, fcx+random.uniform(-1,1)*sc, fcy+fry*0.12,
                               3.5*sc, 2.5*sc, C['skin_shadow'], None, irregularity=1.0, blur=2)
    img = Image.alpha_composite(img, nov)
    d = ImageDraw.Draw(img)
    
    # BLUSH (soft watercolor ovals)
    blush_y = fcy + fry*0.24
    for bls in [-1, 1]:
        blx = fcx + frx*0.38*bls
        bly = blush_y
        blr = fry*0.15
        
        for bli in range(3):
            bla = 30 - bli*8
            bls_s = 1 + bli*0.24
            
            blov = Image.new('RGBA', (s,s), (0,0,0,0))
            bld = ImageDraw.Draw(blov)
            ex0 = min(blx-blr*bls-2, blx+blr*bls+2)
            ey0 = min(bly-blr*bls*0.76-2, bly+blr*bls*0.76+2)
            ex1 = max(blx-blr*bls-2, blx+blr*bls+2)
            ey1 = max(bly-blr*bls*0.76-2, bly+blr*bls*0.76+2)
            bld.ellipse([ex0, ey0, ex1, ey1], fill=(*C['blush'], bla))
            blov = blov.filter(ImageFilter.GaussianBlur(radius=int(5+bli*2)*sc))
            img = Image.alpha_composite(img, blov)
    d = ImageDraw.Draw(img)
    
    # MOUTH: gentle smile
    mx = fcx
    my = fcy + fry*0.47
    mw = frx*0.16
    md = fry*0.038
    
    sm_pts = []
    for spi in range(22):
        sp = spi/21
        sm_pts.append((mx-mw+mw*2*sp, my+math.sin(sp*math.pi)*md))
    
    sml = draw_variable_line(d, sm_pts, C['mouth'], base_w=2.4, pressure=0.22, blur=0.6)
    img = Image.alpha_composite(img, sml)
    d = ImageDraw.Draw(img)
    
    # BANGS
    bang_base = fcy - fry*0.57
    
    bang_pts = [
        (fcx+frx*1.04+random.uniform(-3,3)*sc, bang_base-fry*0.28),
        (fcx+frx*0.54+random.uniform(-2,2)*sc, bang_base-fry*0.18),
        (fcx+frx*0.04+random.uniform(-2,2)*sc, bang_base-fry*0.08),
        (fcx-frx*0.30+random.uniform(-2,2)*sc, bang_base+fry*0.07),
        (fcx-frx*0.52+random.uniform(-3,3)*sc, bang_base+fry*0.21),
        (fcx-frx*0.36+random.uniform(-2,2)*sc, bang_base+fry*0.35),
        (fcx+frx*0.04+random.uniform(-2,2)*sc, bang_base+fry*0.25),
        (fcx+frx*0.46+random.uniform(-2,2)*sc, bang_base+fry*0.11),
        (fcx+frx*0.84+random.uniform(-3,3)*sc, bang_base-fry*0.01),
    ]
    
    bov = Image.new('RGBA', (s,s), (0,0,0,0))
    bd = ImageDraw.Draw(bov)
    bd.polygon(bang_pts, fill=(*C['hair'], 242))
    bd.polygon(bang_pts[:6], fill=(*C['hair_light'], 60))
    bov = bov.filter(ImageFilter.GaussianBlur(radius=int(1.6*sc)))
    img = Image.alpha_composite(img, bov)
    
    bol = draw_variable_line(d, bang_pts+[bang_pts[0]], C['line_dark'], base_w=3.0, pressure=0.32, blur=1.0)
    img = Image.alpha_composite(img, bol)
    d = ImageDraw.Draw(img)
    
    # Bang strands
    for si in range(4):
        sx = fcx - frx*0.26 + si*frx*0.23
        sy_t = bang_base - fry*0.12
        sy_b = fcy - fry*0.05 + si*fry*0.065
        sw = (8+si*2.5)*sc
        
        sp = [
            (sx-sw, sy_t),
            (sx+sw*0.28, sy_t+(sy_b-sy_t)*0.28),
            (sx+sw*0.48, sy_b),
            (sx-sw*0.52, sy_b-(sy_b-sy_t)*0.15),
        ]
        
        sov = Image.new('RGBA', (s,s), (0,0,0,0))
        sd = ImageDraw.Draw(sov)
        scolor = C['hair'] if si%2==0 else C['hair_light']
        sd.polygon(sp, fill=(*scolor, 238))
        sov = sov.filter(ImageFilter.GaussianBlur(radius=int(1.2*sc)))
        img = Image.alpha_composite(img, sov)
        
        sol = draw_variable_line(d, sp+[sp[0]], C['line_dark'], base_w=2.0, pressure=0.26, blur=0.7)
        img = Image.alpha_composite(img, sol)
        d = ImageDraw.Draw(img)
    
    # BUTTERFLY BOW
    bcx = fcx + frx*0.98
    bcy = fcy - fry*0.18
    bsz = frx*0.31
    
    # Left wing
    lw_pts = []
    for lwi in range(26):
        lwt = lwi/25
        lw_ang = math.radians(-66 + lwt*130)
        lr = bsz*(0.90 if lwt<0.4 else (0.84-0.34*abs(lwt-0.5)))
        lw_pts.append((bcx-bsz*0.14+lr*math.cos(lw_ang)+random.uniform(-1.5,1.5)*sc,
                       bcy+lr*math.sin(lw_ang)*0.58+random.uniform(-1.5,1.5)*sc))
    
    lwov = Image.new('RGBA', (s,s), (0,0,0,0))
    lwd = ImageDraw.Draw(lwov)
    lwd.polygon(lw_pts, fill=(*C['bow'], 240))
    lwd.polygon(lw_pts[:14], fill=(*C['bow_light'], 78))
    lwov = lwov.filter(ImageFilter.GaussianBlur(radius=int(1.6*sc)))
    img = Image.alpha_composite(img, lwov)
    
    lwol = draw_variable_line(d, lw_pts+[lw_pts[0]], C['line_dark'], base_w=2.2, pressure=0.30, blur=0.9)
    img = Image.alpha_composite(img, lwol)
    d = ImageDraw.Draw(img)
    
    # Right wing
    rw_pts = []
    for rwi in range(20):
        rwt = rwi/19
        rw_ang = math.radians(32 + rwt*96)
        rr = bsz*0.58*(0.84 if rwt<0.5 else 0.64)
        rw_pts.append((bcx+bsz*0.10+rr*math.cos(rw_ang)+random.uniform(-1.2,1.2)*sc,
                       bcy+rr*math.sin(rw_ang)*0.50+random.uniform(-1.2,1.2)*sc))
    
    rwov = Image.new('RGBA', (s,s), (0,0,0,0))
    rwd = ImageDraw.Draw(rwov)
    rwd.polygon(rw_pts, fill=(*C['bow'], 232))
    rwov = rwov.filter(ImageFilter.GaussianBlur(radius=int(1.4*sc)))
    img = Image.alpha_composite(img, rwov)
    
    rwol = draw_variable_line(d, rw_pts+[rw_pts[0]], C['line_dark'], base_w=1.8, pressure=0.26, blur=0.7)
    img = Image.alpha_composite(img, rwol)
    d = ImageDraw.Draw(img)
    
    # Knot
    knov = draw_organic_shape(d, bcx, bcy+bsz*0.008, bsz*0.13, bsz*0.10,
                               C['bow_dark'], C['line_dark'], ow=1.5, irregularity=1.3, blur=1.2)
    img = Image.alpha_composite(img, knov)
    d = ImageDraw.Draw(img)
    
    # Ribbon tails
    for ti in range(2):
        tx = bcx + (-1 if ti==0 else 1)*bsz*0.10
        ty_t = bcy + bsz*0.06
        ty_b = bcy + bsz*0.47
        tw = bsz*0.09
        
        tp = [
            (tx-tw+random.uniform(-1,1)*sc, ty_t+random.uniform(-1,1)*sc),
            (tx+tw*0.40+random.uniform(-1.2,1.2)*sc, ty_t+(ty_b-ty_t)*0.34),
            (tx+tw*0.24+random.uniform(-1.2,1.2)*sc, ty_b+random.uniform(-1.2,1.2)*sc),
            (tx-tw*0.52, ty_b-(ty_b-ty_t)*0.14),
        ]
        
        tov = Image.new('RGBA', (s,s), (0,0,0,0))
        td = ImageDraw.Draw(tov)
        td.polygon(tp, fill=(*C['bow_light'], 230))
        tov = tov.filter(ImageFilter.GaussianBlur(radius=int(1.2*sc)))
        img = Image.alpha_composite(img, tov)
        
        tol = draw_variable_line(d, tp, C['line_dark'], base_w=1.5, pressure=0.22, blur=0.6)
        img = Image.alpha_composite(img, tol)
        d = ImageDraw.Draw(img)
    
    # Convert to RGB
    final = Image.new('RGB', (s,s), C['bg_edge'])
    final.paste(img, (0,0), img if img.mode=='RGBA' else None)
    
    return final


if __name__ == '__main__':
    print("="*60)
    print("  星空愛莉 App Icon v10 FINAL")
    print("  All Skills Integrated | Premium Idol Game Style")
    print("="*60 + "\n")
    
    sizes = [1024, 512, 192, 96, 72, 48]
    
    for sz in sizes:
        print(f"  Generating {sz}x{sz}...", end=' ', flush=True)
        icon = generate_icon(size=sz, seed=44592)
        
        filename = f'{OUTPUT_DIR}/game_icon_v10_{sz}.png'
        icon.save(filename, 'PNG', optimize=True)
        
        fsize = os.path.getsize(filename) if os.path.exists(filename) else 0
        print(f"✓ {filename} ({fsize:,} bytes)")
    
    # Deploy
    print("\nDeploying...")
    import shutil
    shutil.copy(f'{OUTPUT_DIR}/game_icon_v10_48.png',
               f'{OUTPUT_DIR}/AppScope/resources/base/media/icon.png')
    shutil.copy(f'{OUTPUT_DIR}/game_icon_v10_48.png',
               f'{OUTPUT_DIR}/entry/src/main/resources/base/media/icon.png')
    print("✓ Deployed to HarmonyOS project paths")
    
    print("\n" + "="*60)
    print("✅ v10 Final Complete!")
    print("="*60)
