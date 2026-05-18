#!/usr/bin/env python3
"""使用Seedream 5.0 Image-to-Image精修图标"""
import asyncio
import sys
import os
import base64
import httpx

sys.path.insert(0, '/data/user/skills/byted-seedream-image-generate/scripts')
from seedream_image_generate import seedream_generate

OUTPUT_DIR = '/workspace/ohos_airi'

async def refine_icon():
    # 读取当前v11图片作为base64
    with open(f'{OUTPUT_DIR}/game_icon_v11_2048.png', 'rb') as f:
        img_b64 = base64.b64encode(f.read()).decode()
    
    # 基于参考图的精修prompt - 详细描述差异
    prompt = """Refine this anime girl icon to match the reference character Hoshizora Airi (星空愛莉):
    
Key modifications needed:
1. HAIR: Change to long straight hair reaching past shoulders, deep brown (#4E3728) with pink-purple gradient highlights at tips, more volume and flow
2. BOW: Move pink butterfly bow from LEFT side to RIGHT side of head, make it slightly larger with flower detail
3. EXPRESSION: Change gentle smile to bright cheerful grin showing teeth, more energetic idol expression
4. EYES: Keep violet purple eyes but add more sparkle highlights, larger iris with 3-layer gradient
5. Add subtle idol costume elements: white frilled collar with gold trim visible at neck area
6. Keep circular crop format, starry night background, cel-shaded anime style like BanG Dream
7. Character should fill 75-80% of circle frame"""

    tasks = [{
        "prompt": prompt,
        "size": "2048x2048",
        "image": img_b64,
        "watermark": False,
        "output_format": "png",
    }]

    print("🎨 使用 Seedream 5.0 Image-to-Image 精修...")
    print(f"📐 尺寸: 2048x2048")
    print(f"🖼️ 输入: game_icon_v11_2048.png (base64)")
    print(f"📝 Prompt长度: {len(prompt)} 字符")
    
    result = await seedream_generate(tasks, version="5.0", timeout=180)
    
    status = result.get("status")
    success_list = result.get("success_list", [])
    errors = result.get("error_list", [])
    
    print(f"\n状态: {status}")
    print(f"成功数: {len(success_list)}")
    if errors:
        print(f"错误: {errors}")
    
    if success_list:
        for key, url in success_list.items():
            print(f"\n✅ 图片URL: {url[:100]}...")
            
            # 下载图片
            async with httpx.AsyncClient(timeout=60) as client:
                resp = await client.get(url)
                if resp.status_code == 200:
                    out_path = f'{OUTPUT_DIR}/game_icon_v12_2048.png'
                    with open(out_path, 'wb') as f:
                        f.write(resp.content)
                    print(f"💾 已保存: {out_path} ({len(resp.content)/1024/1024:.1f}MB)")
                else:
                    print(f"❌ 下载失败: {resp.status_code}")

if __name__ == "__main__":
    asyncio.run(refine_icon())
