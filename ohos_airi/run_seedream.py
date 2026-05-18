#!/usr/bin/env python3
"""Run Seedream 5.0 with the idol game icon prompt"""
import asyncio
import sys
import os

sys.path.insert(0, '/data/user/skills/byted-seedream-image-generate/scripts')
from seedream_image_generate import seedream_generate

OUTPUT_DIR = '/workspace/ohos_airi'

PROMPT = """Professional Japanese mobile rhythm/idol game app icon, circular format, featuring a beautiful close-up portrait of an anime girl character named Hoshizora Airi (星空愛莉), age 16.

EXACT CHARACTER APPEARANCE:
- Face: Large expressive anime eyes in VIOLET PURPLE color (#9B64DC) with 3-layer iris gradient (dark violet outer → bright violet mid → light lavender inner), multiple white sparkle highlights including one large top-left highlight and one small bottom-right highlight, gentle happy smile showing friendliness, soft pink oval blush on both cheeks, tiny cute nose hint
- Hair: Rich DEEP BROWN hair (#4E3728) with natural warm tone, long flowing side-swept locks on LEFT side of head that extend past shoulders, hair TIPS gradient into ROSE PINK (#DC96AA) then LAVENDER (#B48CC8) at the very ends, stylish asymmetrical bangs across forehead that partially cover the RIGHT eye, individual visible hair strands with volume and layering
- Accessory: Pink-magenta BUTTERFLY BOW RIBBON (#E682B4) attached on the RIGHT SIDE of her head, with ribbon tails hanging down, bow has highlight sheen
- Skin: Warm porcelain fair skin tone (#FFF8F0) with subtle top-left lighting creating natural shadow on bottom-right of face
- Expression: Cheerful, bright, welcoming idol smile — the expression of a girl who is your AI assistant companion

COMPOSITION (BanG Dream Girls Band Party style):
- Character face occupies 75-80% of the entire icon frame (very large close-up)
- Slight dynamic angle tilt (not perfectly frontal, slightly turned)
- Eyes are the absolute focal point — largest most detailed element
- Professional cel-shaded anime art style with clean dark outlines
- Character looks directly at viewer with engaging eye contact

BACKGROUND & EFFECTS:
- Deep indigo to dark purple radial gradient background (#2D1B4E center → #12081F edges)
- Subtle magenta/purple glow spot in upper-right area
- Starburst sparkle effects (4-point stars) at golden-ratio positions around character
- Small diamond sparkles scattered organically
- No text, no letters, no words, no watermark, no UI elements
- Circular icon boundary implied by composition

ART QUALITY: Master-level anime illustration craftsmanship, crisp clean lineart, rich vibrant colors, professional color grading suitable for app store display, high detail in eyes and hair strands"""

async def main():
    print("=" * 65)
    print("   Seedream 5.0 — 星空愛莉 Idol Game Icon")
    print("=" * 65 + "\n")
    
    tasks = [{
        "prompt": PROMPT,
        "size": "1024x1024",
        "watermark": False,
        "output_format": "png",
    }]
    
    print("Calling Seedream 5.0...")
    print(f"Prompt length: {len(PROMPT)} characters\n")
    
    result = await seedream_generate(tasks, version="5.0", timeout=300)
    
    print(f"\nResult status: {result.get('status')}")
    print(f"Success count: {len(result.get('success_list', []))}")
    
    if result["status"] == "success" and result.get("success_list"):
        item = result["success_list"][0]
        
        for name, val in item.items():
            if val.startswith('http'):
                out_path = f'{OUTPUT_DIR}/game_icon_v11_1024.png'
                print(f"\nDownloading from URL: {val[:80]}...")
                
                urllib_import = "import urllib.request"
                exec(urllib_import)
                urllib.request.urlretrieve(val, out_path)
                
                size = os.path.getsize(out_path)
                print(f"✅ Saved: {out_path} ({size:,} bytes)")
                
                return out_path
            
            elif val.startswith('data:'):
                import base64
                b64data = val.split(',', 1)[1]
                out_path = f'{OUTPUT_DIR}/game_icon_v11_1024.png'
                
                with open(out_path, 'wb') as f:
                    f.write(base64.b64decode(b64data))
                
                size = os.path.getsize(out_path)
                print(f"✅ Saved: {out_path} ({size:,} bytes)")
                
                return out_path
    
    errors = result.get('error_list', [])
    if errors:
        print(f"\nErrors: {errors}")
    
    return None


if __name__ == '__main__':
    path = asyncio.run(main())
    
    if path and os.path.exists(path):
        from PIL import Image
        import shutil
        
        img = Image.open(path)
        if img.mode == 'RGBA':
            bg = Image.new('RGB', img.size, (255,255,255))
            bg.paste(img, mask=img.split()[-1])
            img = bg
        
        for sz in [512, 192, 96, 72, 48]:
            out = path.replace('1024', str(sz))
            resized = img.resize((sz,sz), Image.LANCZOS)
            resized.save(out, 'PNG', optimize=True)
            print(f"  ✓ {out} ({os.path.getsize(out):,} bytes)")
        
        p48 = path.replace('1024', '48')
        shutil.copy(p48, f'{OUTPUT_DIR}/AppScope/resources/base/media/icon.png')
        shutil.copy(p48, f'{OUTPUT_DIR}/entry/src/main/resources/base/media/icon.png')
        print("\n✅ Deployed to HarmonyOS project paths!")
    else:
        print("\n❌ Generation failed")
