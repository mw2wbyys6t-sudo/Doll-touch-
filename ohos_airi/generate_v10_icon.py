#!/usr/bin/env python3
"""
Generate v10 icon using Seedream 5.0 + fallback to text_to_image API
Professional idol game app icon for 星空愛莉 (Hoshizora Airi)
"""
import asyncio
import sys
import os
import json
import urllib.request
import urllib.error
import urllib.parse

sys.path.insert(0, '/data/user/skills/byted-seedream-image-generate/scripts')
from seedream_image_generate import seedream_generate

OUTPUT_DIR = '/workspace/ohos_airi'

# ======== MASTER PROMPT (BanG Dream / Idol Game Style) ========
PROMPT = """A professional anime-style mobile game app icon featuring a close-up portrait of a beautiful 16-year-old Japanese idol girl character named Hoshizora Airi (星空愛莉). 

CHARACTER DETAILS:
- Face: Large expressive violet-purple anime eyes with multiple white sparkle highlights, gentle warm smile showing happiness, soft pink blush on cheeks, small cute nose
- Hair: Rich deep brown hair with flowing long side locks on left side, hair tips gradient into pink and lavender colors, stylish bangs sweeping across forehead covering part of right eye
- Accessory: Pink-magenta butterfly bow ribbon on the right side of her head with ribbon tails hanging down
- Skin: Warm fair skin tone with natural lighting from top-left
- Expression: Cheerful, friendly, inviting smile - perfect for an AI assistant app icon

COMPOSITION & STYLE:
- Circular app icon format (character fills 75% of frame)
- Dynamic slight tilt angle (not perfectly frontal)
- BanG Dream Girls Band Party / Idolmaster / Ensemble Stars art style
- High-quality cel-shaded anime illustration
- Clean dark outline strokes around character features
- Vibrant saturated colors - especially the violet eyes which are the signature feature
- Professional Japanese mobile game icon design quality
- Starburst sparkle effects in background
- Deep indigo-to-purple gradient background with subtle glow
- No text, no words, no letters, no watermark

ART QUALITY:
- Master-level anime illustration craftsmanship
- Crisp clean lines like official game promotional art
- Professional color grading with rich contrast
- Looks like it could be from a real released idol game"""

async def try_seedream():
    """Try Seedream 5.0 generation"""
    print("=" * 60)
    print("🎨 Attempting Seedream 5.0 generation...")
    print("=" * 60)
    
    tasks = [{
        "prompt": PROMPT,
        "size": "1024x1024",
        "watermark": False,
        "output_format": "png",
    }]
    
    result = await seedream_generate(tasks, version="5.0", timeout=300)
    
    if result["status"] == "success" and result["success_list"]:
        return result["success_list"][0]
    else:
        print(f"Seedream failed: {result.get('error_list', 'unknown')}")
        return None


def try_text_to_image():
    """Fallback: use text_to_image URL API"""
    print("\n" + "=" * 60)
    print("🖼️ Fallback: Using text_to_image API...")
    print("=" * 60)
    
    encoded_prompt = urllib.parse.quote(PROMPT)
    url = f"https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt={encoded_prompt}&image_size=square_hd"
    
    print(f"Requesting: {url[:100]}...")
    
    try:
        req = urllib.request.Request(url)
        req.add_header('User-Agent', 'Mozilla/5.0')
        
        with urllib.request.urlopen(req, timeout=120) as response:
            data = response.read()
            
            output_path = f'{OUTPUT_DIR}/game_icon_v10_1024.png'
            with open(output_path, 'wb') as f:
                f.write(data)
            
            size = os.path.getsize(output_path)
            print(f"✓ Downloaded: {output_path} ({size:,} bytes)")
            return output_path
            
    except Exception as e:
        print(f"text_to_image failed: {e}")
        return None


def resize_icon(src_path, sizes=[512, 192, 96, 72, 48]):
    """Resize generated icon to all required sizes"""
    from PIL import Image
    
    base_img = Image.open(src_path)
    
    # Convert to RGB if needed
    if base_img.mode == 'RGBA':
        bg = Image.new('RGB', base_img.size, (255, 255, 255))
        bg.paste(base_img, mask=base_img.split()[-1])
        base_img = bg
    
    results = []
    for sz in sizes:
        out_path = src_path.replace('1024', str(sz))
        resized = base_img.resize((sz, sz), Image.LANCZOS)
        resized.save(out_path, 'PNG', optimize=True)
        fsize = os.path.getsize(out_path)
        print(f"✓ {out_path} ({fsize:,} bytes)")
        results.append(out_path)
    
    return results


async def main():
    print("\n" + "=" * 60)
    print("  星空愛莉 App Icon Generator v10")
    print("  Seedream 5.0 + Professional Idol Game Style")
    print("=" * 60 + "\n")
    
    # Try Seedream first
    seedream_result = None
    
    api_key = os.getenv("ARK_API_KEY") or os.getenv("MODEL_IMAGE_API_KEY") or os.getenv("MODEL_AGENT_API_KEY")
    
    if api_key:
        print(f"✓ API Key found ({api_key[:8]}...), trying Seedream 5.0\n")
        seedream_result = await try_seedream()
    else:
        print("⚠ No API Key found, skipping Seedream\n")
    
    image_path = None
    
    if seedream_result:
        for name, url_or_data in seedream_result.items():
            if url_or_data.startswith('http'):
                print(f"\nDownloading from URL: {url_or_data[:80]}...")
                try:
                    urllib.request.urlretrieve(url_or_data, 
                        f'{OUTPUT_DIR}/game_icon_v10_1024.png')
                    image_path = f'{OUTPUT_DIR}/game_icon_v10_1024.png'
                except Exception as e:
                    print(f"Download failed: {e}")
            elif url_or_data.startswith('data:'):
                import base64
                b64data = url_or_data.split(',', 1)[1]
                image_path = f'{OUTPUT_DIR}/game_icon_v10_1024.png'
                with open(image_path, 'wb') as f:
                    f.write(base64.b64decode(b64data))
                print(f"✓ Saved base64 image: {image_path}")
    
    # Fallback to text_to_image
    if not image_path or not os.path.exists(image_path):
        image_path = try_text_to_image()
    
    if image_path and os.path.exists(image_path):
        print("\n" + "-" * 40)
        print("Resizing to all required sizes...")
        print("-" * 40)
        
        resize_icon(image_path)
        
        # Deploy to project paths
        print("\nDeploying to project...")
        import shutil
        shutil.copy(f'{OUTPUT_DIR}/game_icon_v10_48.png',
                   f'{OUTPUT_DIR}/AppScope/resources/base/media/icon.png')
        shutil.copy(f'{OUTPUT_DIR}/game_icon_v10_48.png',
                   f'{OUTPUT_DIR}/entry/src/main/resources/base/media/icon.png')
        print("✓ Deployed to HarmonyOS project paths")
        
        print("\n" + "=" * 60)
        print("✅ v10 Icon Generation Complete!")
        print("=" * 60)
    else:
        print("\n❌ All generation methods failed")


if __name__ == '__main__':
    asyncio.run(main())
