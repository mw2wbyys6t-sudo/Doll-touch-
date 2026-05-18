#!/usr/bin/env python3
"""Run Seedream with simplified prompt"""
import asyncio
import sys
import os

sys.path.insert(0, '/data/user/skills/byted-seedream-image-generate/scripts')
from seedream_image_generate import seedream_generate

OUTPUT_DIR = '/workspace/ohos_airi'

# Simplified, cleaner prompt
PROMPT = """Japanese anime idol girl app icon, violet eyes, brown hair with pink tips, pink bow, smile, circular frame, stars background"""

async def main():
    print("=" * 60)
    print("   Seedream 5.0 — Simplified Prompt Test")
    print("=" * 60 + "\n")
    
    tasks = [{
        "prompt": PROMPT,
        "size": "1024x1024",
        "watermark": False,
        "output_format": "png",
    }]
    
    print(f"Prompt: {PROMPT}\n")
    
    result = await seedream_generate(tasks, version="5.0", timeout=300)
    
    print(f"\nStatus: {result.get('status')}")
    
    if result["status"] == "success" and result.get("success_list"):
        item = result["success_list"][0]
        for name, val in item.items():
            if val.startswith('http'):
                out_path = f'{OUTPUT_DIR}/game_icon_v11_1024.png'
                import urllib.request
                urllib.request.urlretrieve(val, out_path)
                
                size = os.path.getsize(out_path)
                print(f"✅ Downloaded: {out_path} ({size:,} bytes)")
                return out_path
            elif val.startswith('data:'):
                import base64
                out_path = f'{OUTPUT_DIR}/game_icon_v11_1024.png'
                b64data = val.split(',', 1)[1]
                with open(out_path, 'wb') as f:
                    f.write(base64.b64decode(b64data))
                size = os.path.getsize(out_path)
                print(f"✅ Saved: {out_path} ({size:,} bytes)")
                return out_path
    
    print(f"Errors: {result.get('error_list', result)}")
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
            print(f"  ✓ {out}")
        
        p48 = path.replace('1024', '48')
        shutil.copy(p48, f'{OUTPUT_DIR}/AppScope/resources/base/media/icon.png')
        shutil.copy(p48, f'{OUTPUT_DIR}/entry/src/main/resources/base/media/icon.png')
        print("\n✅ Deployed!")
