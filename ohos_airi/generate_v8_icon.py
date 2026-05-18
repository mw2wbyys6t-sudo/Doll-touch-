#!/usr/bin/env python3
"""
星空愛莉 (Hoshizora Airi) App Icon Generator v8
COMPLETELY NEW: SVG vector + circular frame + idol game style
"""
import cairosvg
import os

OUTPUT_DIR = '/workspace/ohos_airi'

def generate_svg(size=1024):
    C = {
        'hair': '#5C3D2E',
        'hair_light': '#8B6B52',
        'hair_tip': '#E8A0C0',
        'eye': '#9B6ED8',
        'eye_light': '#C9A8F0',
        'eye_dark': '#5A3590',
        'skin': '#FFEDE0',
        'skin_shadow': '#E8D0BC',
        'blush': '#FFB0B8',
        'bow': '#E87DBA',
        'bow_light': '#FFC8E0',
        'bg_top': '#4A2878',
        'bg_bottom': '#1E0D38',
        'outline': '#3D2520',
    }
    
    # Pre-compute all coordinates
    cx = size // 2
    cy = size // 2
    
    # Helper to build SVG with proper negative number handling
    def neg(v): return -v
    def p(v): return int(v)
    
    svg = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {size} {size}" width="{size}" height="{size}">
    <defs>
        <radialGradient id="bgGrad" cx="45%" cy="40%" r="60%">
            <stop offset="0%" stop-color="{C['bg_top']}"/>
            <stop offset="100%" stop-color="{C['bg_bottom']}"/>
        </radialGradient>
        <linearGradient id="hairGrad" x1="0%" y1="0%" x2="0%" y2="100%">
            <stop offset="0%" stop-color="{C['hair_light']}"/>
            <stop offset="50%" stop-color="{C['hair']}"/>
            <stop offset="100%" stop-color="{C['hair_tip']}"/>
        </linearGradient>
        <radialGradient id="eyeGrad" cx="40%" cy="35%" r="60%">
            <stop offset="0%" stop-color="{C['eye_light']}"/>
            <stop offset="55%" stop-color="{C['eye']}"/>
            <stop offset="100%" stop-color="{C['eye_dark']}"/>
        </radialGradient>
        <radialGradient id="skinGrad" cx="42%" cy="38%" r="65%">
            <stop offset="0%" stop-color="#FFF8F4"/>
            <stop offset="70%" stop-color="{C['skin']}"/>
            <stop offset="100%" stop-color="{C['skin_shadow']}"/>
        </radialGradient>
        <filter id="glow">
            <feGaussianBlur stdDeviation="3" result="blur"/>
            <feMerge><feMergeNode in="blur"/><feMergeNode in="SourceGraphic"/></feMerge>
        </filter>
        <filter id="softShadow">
            <feGaussianBlur in="SourceAlpha" stdDeviation="8"/>
            <feOffset dx="3" dy="5"/>
            <feComponentTransfer><feFuncA type="linear" slope="0.3"/></feComponentTransfer>
            <feMerge><feMergeNode/><feMergeNode in="SourceGraphic"/></feMerge>
        </filter>
        <clipPath id="circleClip">
            <circle cx="{cx}" cy="{cy}" r="{cx-4}"/>
        </clipPath>
    </defs>

    <g clip-path="url(#circleClip)">
        <rect width="{size}" height="{size}" fill="url(#bgGrad)"/>
        
        <circle cx="{p(size*0.62)}" cy="{p(size*0.32)}" r="{p(size*0.22)}" 
                fill="#7B4BB8" opacity="0.25" filter="url(#glow)"/>

        <!-- Stars -->
        <g fill="#FFFFFF" filter="url(#glow)">
            <polygon points="{p(size*0.13)},{p(size*0.10)-14} {p(size*0.13)+4},{p(size*0.10)-4} {p(size*0.13)+14},{p(size*0.10)} {p(size*0.13)+4},{p(size*0.10)+4} {p(size*0.13)},{p(size*0.10)+14} {p(size*0.13)-4},{p(size*0.10)+4} {p(size*0.13)-14},{p(size*0.10)} {p(size*0.13)-4},{p(size*0.10)-4}" opacity="0.95"/>
            <polygon points="{p(size*0.86)},{p(size*0.15)-11} {p(size*0.86)+3},{p(size*0.15)-3} {p(size*0.86)+11},{p(size*0.15)} {p(size*0.86)+3},{p(size*0.15)+3} {p(size*0.86)},{p(size*0.15)+11} {p(size*0.86)-3},{p(size*0.15)+3} {p(size*0.86)-11},{p(size*0.15)} {p(size*0.86)-3},{p(size*0.15)-3}" opacity="0.85"/>
            <polygon points="{p(size*0.08)},{p(size*0.54)-9} {p(size*0.08)+3},{p(size*0.54)-3} {p(size*0.08)+9},{p(size*0.54)} {p(size*0.08)+3},{p(size*0.54)+3} {p(size*0.08)},{p(size*0.54)+9} {p(size*0.08)-3},{p(size*0.54)+3} {p(size*0.08)-9},{p(size*0.54)} {p(size*0.08)-3},{p(size*0.54)-3}" opacity="0.75"/>
            <polygon points="{p(size*0.90)},{p(size*0.70)-10} {p(size*0.90)+3},{p(size*0.70)-3} {p(size*0.90)+10},{p(size*0.70)} {p(size*0.90)+3},{p(size*0.70)+3} {p(size*0.90)},{p(size*0.70)+10} {p(size*0.90)-3},{p(size*0.70)+3} {p(size*0.90)-10},{p(size*0.70)} {p(size*0.90)-3},{p(size*0.70)-3}" opacity="0.8"/>
            <polygon points="{p(size*0.22)},{p(size*0.88)-5} {p(size*0.22)+5},{p(size*0.88)} {p(size*0.22)},{p(size*0.88)+5} {p(size*0.22)-5},{p(size*0.88)}" opacity="0.6"/>
            <polygon points="{p(size*0.78)},{p(size*0.92)-4} {p(size*0.78)+4},{p(size*0.92)} {p(size*0.78)},{p(size*0.92)+4} {p(size*0.78)-4},{p(size*0.92)}" opacity="0.55"/>
            <polygon points="{p(size*0.44)},{p(size*0.05)-4} {p(size*0.44)+4},{p(size*0.05)} {p(size*0.44)},{p(size*0.05)+4} {p(size*0.44)-4},{p(size*0.05)}" opacity="0.5"/>
            <circle cx="{p(size*0.30)}" cy="{p(size*0.12)}" r="3" opacity="0.5"/>
            <circle cx="{p(size*0.72)}" cy="{p(size*0.08)}" r="2.5" opacity="0.45"/>
            <circle cx="{p(size*0.95)}" cy="{p(size*0.42)}" r="2" opacity="0.4"/>
            <circle cx="{p(size*0.04)}" cy="{p(size*0.36)}" r="2.5" opacity="0.45"/>
            <circle cx="{p(size*0.55)}" cy="{p(size*0.94)}" r="2" opacity="0.4"/>
            <circle cx="{p(size*0.15)}" cy="{p(size*0.72)}" r="1.8" opacity="0.35"/>
            <circle cx="{p(size*0.84)}" cy="{p(size*0.88)}" r="2.2" opacity="0.4"/>
        </g>

        <!-- CHARACTER -->
        <g transform="translate({p(size*0.02)}, {p(size*-0.02)})">
            
            <!-- Hair Back -->
            <ellipse cx="{cx}" cy="{p(size*0.56)}" rx="{p(size*0.42)}" ry="{p(size*0.48)}" 
                     fill="{C['hair']}" filter="url(#softShadow)"/>
            <ellipse cx="{cx+p(size*0.03)}" cy="{p(size*0.62)}" rx="{p(size*0.38)}" ry="{p(size*0.40)}" 
                     fill="{C['hair']}" opacity="0.5"/>
            
            <!-- Left hair locks -->
            <path d="M {p(size*0.22)} {p(size*0.34)}
                     Q {p(size*0.18)} {p(size*0.55)}
                     {p(size*0.20)} {p(size*0.82)}
                     Q {p(size*0.26)} {p(size*0.80)}
                     {p(size*0.30)} {p(size*0.82)}
                     Q {p(size*0.26)} {p(size*0.55)}
                     {p(size*0.30)} {p(size*0.34)} Z"
                  fill="url(#hairGrad)" stroke="{C['outline']}" stroke-width="3"/>

            <path d="M {p(size*0.28)} {p(size*0.36)}
                     Q {p(size*0.24)} {p(size*0.56)}
                     {p(size*0.26)} {p(size*0.83)}
                     Q {p(size*0.32)} {p(size*0.81)}
                     {p(size*0.36)} {p(size*0.83)}
                     Q {p(size*0.32)} {p(size*0.56)}
                     {p(size*0.36)} {p(size*0.36)} Z"
                  fill="{C['hair']}" stroke="{C['outline']}" stroke-width="2.5"/>

            <path d="M {p(size*0.34)} {p(size*0.37)}
                     Q {p(size*0.30)} {p(size*0.57)}
                     {p(size*0.32)} {p(size*0.84)}
                     Q {p(size*0.38)} {p(size*0.82)}
                     {p(size*0.42)} {p(size*0.84)}
                     Q {p(size*0.38)} {p(size*0.57)}
                     {p(size*0.42)} {p(size*0.37)} Z"
                  fill="{C['hair_light']}" stroke="{C['outline']}" stroke-width="2"/>

            <!-- Right hair -->
            <path d="M {p(size*0.68)} {p(size*0.38)}
                     Q {p(size*0.73)} {p(size*0.52)}
                     {p(size*0.70)} {p(size*0.66)}
                     Q {p(size*0.74)} {p(size*0.64)}
                     {p(size*0.76)} {p(size*0.66)}
                     Q {p(size*0.74)} {p(size*0.52)}
                     {p(size*0.76)} {p(size*0.38)} Z"
                  fill="{C['hair']}" stroke="{C['outline']}" stroke-width="2"/>

            <!-- Face -->
            <ellipse cx="{cx}" cy="{p(size*0.54)}" rx="{p(size*0.30)}" ry="{p(size*0.35)}" 
                     fill="url(#skinGrad)" stroke="{C['outline']}" stroke-width="3.5"
                     filter="url(#softShadow)"/>

            <!-- LEFT EYE -->
            <g transform="translate({p(size*0.36)}, {p(size*0.51)})">
                <ellipse cx="0" cy="0" rx="{p(size*0.095)}" ry="{p(size*0.11)}" 
                         fill="#FEFCFA" stroke="{C['outline']}" stroke-width="2.5"/>
                <ellipse cx="{p(size*0.004)}" cy="0" rx="{p(size*0.068)}" ry="{p(size*0.078)}" 
                         fill="url(#eyeGrad)"/>
                <ellipse cx="{p(size*0.012)}" cy="{p(size*0.003)}" rx="{p(size*0.025)}" ry="{p(size*0.028)}" 
                         fill="#2D1850"/>
                <ellipse cx="{neg(p(size*0.022))}" cy="{neg(p(size*0.025))}" rx="{p(size*0.022)}" ry="{p(size*0.025)}" 
                         fill="#FFFFFF"/>
                <ellipse cx="{p(size*0.018)}" cy="{p(size*0.026)}" rx="{p(size*0.01)}" ry="{p(size*0.011)}" 
                         fill="#FFFFFF" opacity="0.9"/>
                <path d="M {neg(p(size*0.09))} {neg(p(size*0.095))}
                         Q 0 {neg(p(size*0.115))}
                         {p(size*0.09)} {neg(p(size*0.095))}"
                      fill="none" stroke="{C['outline']}" stroke-width="2.5" stroke-linecap="round"/>
            </g>

            <!-- RIGHT EYE -->
            <g transform="translate({p(size*0.58)}, {p(size*0.51)})">
                <ellipse cx="0" cy="0" rx="{p(size*0.095)}" ry="{p(size*0.11)}" 
                         fill="#FEFCFA" stroke="{C['outline']}" stroke-width="2.5"/>
                <ellipse cx="{p(size*0.004)}" cy="0" rx="{p(size*0.068)}" ry="{p(size*0.078)}" 
                         fill="url(#eyeGrad)"/>
                <ellipse cx="{p(size*0.012)}" cy="{p(size*0.003)}" rx="{p(size*0.025)}" ry="{p(size*0.028)}" 
                         fill="#2D1850"/>
                <ellipse cx="{neg(p(size*0.022))}" cy="{neg(p(size*0.025))}" rx="{p(size*0.022)}" ry="{p(size*0.025)}" 
                         fill="#FFFFFF"/>
                <ellipse cx="{p(size*0.018)}" cy="{p(size*0.026)}" rx="{p(size*0.01)}" ry="{p(size*0.011)}" 
                         fill="#FFFFFF" opacity="0.9"/>
                <path d="M {neg(p(size*0.09))} {neg(p(size*0.095))}
                         Q 0 {neg(p(size*0.115))}
                         {p(size*0.09)} {neg(p(size*0.095))}"
                      fill="none" stroke="{C['outline']}" stroke-width="2.5" stroke-linecap="round"/>
            </g>

            <!-- Eyebrows -->
            <path d="M {p(size*0.33)} {p(size*0.41)}
                     Q {p(size*0.37)} {p(size*0.395)}
                     {p(size*0.42)} {p(size*0.405)}"
                  fill="none" stroke="{C['hair']}" stroke-width="2.8" stroke-linecap="round"/>
            <path d="M {p(size*0.50)} {p(size*0.405)}
                     Q {p(size*0.55)} {p(size*0.395)}
                     {p(size*0.59)} {p(size*0.41)}"
                  fill="none" stroke="{C['hair']}" stroke-width="2.8" stroke-linecap="round"/>

            <!-- Nose hint -->
            <ellipse cx="{cx}" cy="{p(size*0.57)}" rx="4" ry="3" 
                     fill="{C['skin_shadow']}" opacity="0.6"/>

            <!-- Blush -->
            <ellipse cx="{p(size*0.35)}" cy="{p(size*0.63)}" rx="{p(size*0.055)}" ry="{p(size*0.035)}" 
                     fill="{C['blush']}" opacity="0.55"/>
            <ellipse cx="{p(size*0.59)}" cy="{p(size*0.63)}" rx="{p(size*0.055)}" ry="{p(size*0.035)}" 
                     fill="{C['blush']}" opacity="0.55"/>

            <!-- Mouth smile -->
            <path d="M {p(size*0.44)} {p(size*0.69)}
                     Q {cx} {p(size*0.71)}
                     {p(size*0.52)} {p(size*0.69)}"
                  fill="none" stroke="#E07890" stroke-width="2.5" stroke-linecap="round"/>

            <!-- Bangs -->
            <path d="M {p(size*0.64)} {p(size*0.24)}
                     Q {p(size*0.52)} {p(size*0.28)}
                     {p(size*0.42)} {p(size*0.26)}
                     Q {p(size*0.34)} {p(size*0.30)}
                     {p(size*0.30)} {p(size*0.36)}
                     Q {p(size*0.33)} {p(size*0.42)}
                     {p(size*0.38)} {p(size*0.40)}
                     Q {p(size*0.46)} {p(size*0.38)}
                     {p(size*0.52)} {p(size*0.34)}
                     Q {p(size*0.58)} {p(size*0.30)}
                     {p(size*0.64)} {p(size*0.28)} Z"
                  fill="{C['hair']}" stroke="{C['outline']}" stroke-width="3"/>

            <path d="M {p(size*0.60)} {p(size*0.255)}
                     Q {p(size*0.50)} {p(size*0.29)}
                     {p(size*0.42)} {p(size*0.27)}
                     Q {p(size*0.36)} {p(size*0.31)}
                     {p(size*0.33)} {p(size*0.365)}"
                  fill="{C['hair_light']}" opacity="0.7"/>

            <!-- Bang strands -->
            <path d="M {p(size*0.38)} {p(size*0.27)}
                     Q {p(size*0.36)} {p(size*0.35)}
                     {p(size*0.37)} {p(size*0.43)}
                     Q {p(size*0.40)} {p(size*0.38)}
                     {p(size*0.42)} {p(size*0.29)} Z"
                  fill="{C['hair']}" stroke="{C['outline']}" stroke-width="2"/>

            <path d="M {p(size*0.46)} {p(size*0.265)}
                     Q {p(size*0.44)} {p(size*0.34)}
                     {p(size*0.45)} {p(size*0.42)}
                     Q {p(size*0.48)} {p(size*0.37)}
                     {p(size*0.50)} {p(size*0.28)} Z"
                  fill="{C['hair_light']}" stroke="{C['outline']}" stroke-width="2"/>

            <path d="M {p(size*0.54)} {p(size*0.27)}
                     Q {p(size*0.52)} {p(size*0.34)}
                     {p(size*0.53)} {p(size*0.41)}
                     Q {p(size*0.56)} {p(size*0.36)}
                     {p(size*0.58)} {p(size*0.285)} Z"
                  fill="{C['hair']}" stroke="{C['outline']}" stroke-width="2"/>

            <!-- Butterfly Bow -->
            <g transform="translate({p(size*0.67)}, {p(size*0.36)})">
                <path d="M 0 0
                         Q {neg(p(size*0.06))} {neg(p(size*0.04))}
                         {neg(p(size*0.08))} 0
                         Q {neg(p(size*0.06))} {p(size*0.04)}
                         0 {p(size*0.03)}
                         Q {p(size*0.02)} {p(size*0.01)}
                         0 0 Z"
                      fill="{C['bow']}" stroke="{C['outline']}" stroke-width="2"/>
                
                <path d="M {neg(p(size*0.005))} {neg(p(size*0.005))}
                         Q {neg(p(size*0.04))} {neg(p(size*0.025))}
                         {neg(p(size*0.055))} {neg(p(size*0.003))}
                         Q {neg(p(size*0.04))} {p(size*0.18)}
                         {neg(p(size*0.005))} {p(size*0.015)} Z"
                      fill="{C['bow_light']}" opacity="0.75"/>

                <path d="M {p(size*0.015)} {p(size*0.005)}
                         Q {p(size*0.045)} {neg(p(size*0.02))}
                         {p(size*0.055)} {p(size*0.005)}
                         Q {p(size*0.04)} {p(size*0.025)}
                         {p(size*0.015)} {p(size*0.02)} Z"
                      fill="{C['bow']}" stroke="{C['outline']}" stroke-width="1.5"/>

                <ellipse cx="{neg(p(size*0.002))}" cy="{p(size*0.008)}" rx="{p(size*0.018)}" ry="{p(size*0.014)}" 
                         fill="#D06AA0" stroke="{C['outline']}" stroke-width="1.5"/>

                <path d="M {neg(p(size*0.008))} {p(size*0.02)}
                         Q {neg(p(size*0.012))} {p(size*0.055)}
                         {neg(p(size*0.005))} {p(size*0.075)}
                         Q {p(size*0.003)} {p(size*0.058)}
                         {p(size*0.008)} {p(size*0.022)} Z"
                      fill="{C['bow_light']}" stroke="{C['outline']}" stroke-width="1.2"/>
            </g>
        </g>
    </g>

    <circle cx="{cx}" cy="{cy}" r="{cx-3}" 
            fill="none" stroke="{C['outline']}" stroke-opacity="0.3" stroke-width="2"/>
</svg>'''
    
    return svg


if __name__ == '__main__':
    print("Generating v8 icon (SVG Vector + Circular Frame)...")

    sizes = [1024, 512, 192, 96, 72, 48]
    
    for sz in sizes:
        print(f"  Generating {sz}x{sz}...", end=' ', flush=True)
        svg_content = generate_svg(size=sz)
        filename = f'{OUTPUT_DIR}/game_icon_v8_{sz}.png'
        cairosvg.svg2png(bytestring=svg_content.encode('utf-8'),
                          write_to=filename,
                          output_width=sz,
                          output_height=sz)
        fsize = os.path.getsize(filename) if os.path.exists(filename) else 0
        print(f"✓ {filename} ({fsize:,} bytes)")

    print("\n✓ Done! v8 icons generated.")
