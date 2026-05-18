#!/usr/bin/env python3
"""
星空愛莉 (Hoshizora Airi) App Icon v11 — AI Generated
Using text_to_image API with professional idol game quality prompt.
Based on: canvas-design philosophy "Stellar Resonance"
Based on: BanG Dream / Idolmaster / Ensemble Stars visual language
Character reference: 星空愛莉 (ほしぞらあいり) from Twinkle☆Palette
"""
import urllib.request
import urllib.parse
import urllib.error
import os
import sys
import time
import json

OUTPUT_DIR = '/workspace/ohos_airi'

# ======== MASTER PROMPT (English for best AI generation results) ========
PROMPT_EN = """Professional Japanese mobile rhythm/idol game app icon, circular format, featuring a beautiful close-up portrait of an anime girl character named Hoshizora Airi (星空愛莉), age 16.

EXACT CHARACTER APPEARANCE (must match precisely):
- Face: Large expressive anime eyes in VIOLET PURPLE color (#9B64DC) with 3-layer iris gradient (dark violet outer → bright violet mid → light lavender inner), multiple white sparkle highlights including one large top-left highlight and one small bottom-right highlight, gentle happy smile showing friendliness, soft pink oval blush on both cheeks, tiny cute nose hint
- Hair: Rich DEEP BROWN hair (#4E3728) with natural warm tone, long flowing side-swept locks on LEFT side of head that extend past shoulders, hair TIPS gradient into ROSE PINK (#DC96AA) then LAVENDER (#B48CC8) at the very ends, stylish asymmetrical bangs across forehead that partially cover the RIGHT eye, individual visible hair strands with volume and layering
- Accessory: Pink-magenta BUTTERFLY BOW RIBBON (#E682B4) attached on the RIGHT SIDE of her head, with ribbon tails hanging down, bow has highlight sheen
- Skin: Warm porcelain fair skin tone (#FFF8F0) with subtle top-left lighting creating natural shadow on bottom-right of face
- Expression: Cheerful, bright, welcoming idol smile — the expression of a girl who is your AI assistant companion
- Overall vibe: Cute, energetic, youthful Japanese idol

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

ART QUALITY REQUIREMENTS:
- Must look like official promotional art from BanG Dream, Idolmaster, or Ensemble Stars
- Master-level anime illustration craftsmanship
- Crisp clean lineart with professional line weight variation
- Rich vibrant colors with proper contrast and saturation
- Professional color grading suitable for app store display
- High detail in eyes (the signature feature) and hair strands
- 4K quality illustration rendered to 1024x1024"""

# Chinese version as backup
PROMPT_CN = """专业日本二次元偶像手游应用图标，圆形构图，特写一位美丽的动漫少女角色「星空愛莉」（16岁）。

精确角色外观（必须严格匹配）：
- 面部：超大的动漫风格紫罗兰色眼睛（#9B64DC），三层虹膜渐变（外圈深紫→中圈亮紫→内圈浅紫），多重白色高光点（左上大高光+右下小高光+微小第三高光），温柔开心的微笑，脸颊两侧粉色椭圆形腮红，小巧可爱的鼻子
- 发型：浓郁的深棕色头发（#4E3728），左侧有长发束垂过肩膀，发梢渐变为玫瑰粉（#DC96AA）再过渡到淡紫色（#B48CC8），刘海不对称地斜跨额头遮住右眼，可见独立发丝层次和体积感
- 配饰：右侧头部有洋红色蝴蝶结发饰（#E682B4），带下垂的缎带尾，蝴蝶结有高光光泽
- 肤色：温暖的瓷白肤色（#FFF8F0），左上方自然光照，右下方自然阴影
- 表情：开朗、明亮、充满活力的偶像微笑——作为AI助手伴侣的表情

构图（《BanG Dream!少女乐团派对》风格）：
- 角色面部占图标画面75-80%（超大特写）
- 轻微动态倾斜角度（非完全正面）
- 眼睛是绝对焦点——最大最精细的元素
- 专业赛璐珞动漫画风，清晰的深色描边
- 角色直视观众，眼神交流感强

背景与特效：
- 深靛蓝到暗紫色的径向渐变背景
- 右上角微妙的品红/紫色光晕
- 黄金比例位置的四角星闪光效果
- 有机散布的小菱形闪点
- 无文字、无字母、无水印、无UI元素

艺术质量要求：
- 必须看起来像《BanG Dream》《偶像大师》《偶像梦幻祭》的官方宣传图
- 大师级动漫插画工艺
- 清晰干净的线条，专业的线宽变化
- 丰富鲜艳的色彩，正确的对比度和饱和度
- 适合应用商店展示的专业色彩分级
- 眼睛（标志性特征）和发丝的高细节
- 4K画质级别渲染至1024×1024"""


def generate_with_text_api(prompt, output_path):
    """Use the text_to_image API"""
    encoded = urllib.parse.quote(prompt)
    url = f"https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt={encoded}&image_size=square_hd"
    
    print(f"Requesting text_to_image API...")
    print(f"Prompt length: {len(prompt)} chars")
    
    req = urllib.request.Request(url)
    req.add_header('User-Agent', 'Mozilla/5.0')
    
    try:
        with urllib.request.urlopen(req, timeout=180) as response:
            data = response.read()
            
            with open(output_path, 'wb') as f:
                f.write(data)
            
            size = os.path.getsize(output_path)
            return output_path, size
            
    except Exception as e:
        print(f"text_to_image error: {e}")
        return None, 0


def generate_with_seedream(prompt, output_path):
    """Try Seedream 5.0 if API key is available"""
    api_key = os.getenv("ARK_API_KEY") or os.getenv("MODEL_IMAGE_API_KEY")
    
    if not api_key:
        print("No ARK_API_KEY found, skipping Seedream")
        return None, 0
    
    try:
        import asyncio
        import sys
        
        sys.path.insert(0, '/data/user/skills/byted-seedream-image-generate/scripts')
        from seedream_image_generate import seedream_generate
        
        async def run():
            tasks = [{
                "prompt": prompt,
                "size": "1024x1024",
                "watermark": False,
                "output_format": "png",
            }]
            result = await seedream_generate(tasks, version="5.0", timeout=300)
            
            if result["status"] == "success" and result["success_list"]:
                item = result["success_list"][0]
                for name, val in item.items():
                    if val.startswith('http'):
                        urllib.request.urlretrieve(val, output_path)
                        return output_path, os.path.getsize(output_path)
                    elif val.startswith('data:'):
                        import base64
                        b64data = val.split(',', 1)[1]
                        with open(output_path, 'wb') as f:
                            f.write(base64.b64decode(b64data))
                        return output_path, os.path.getsize(output_path)
            return None, 0
        
        return asyncio.run(run())
        
    except ImportError:
        print("Seedream module import failed")
        return None, 0
    except Exception as e:
        print(f"Seedream error: {e}")
        return None, 0


def resize_and_deploy(src_path, sizes=[512, 192, 96, 72, 48]):
    """Resize to all required sizes and deploy to project paths"""
    from PIL import Image
    
    img = Image.open(src_path)
    
    if img.mode == 'RGBA':
        bg = Image.new('RGB', img.size, (255,255,255))
        bg.paste(img, mask=img.split()[-1])
        img = bg
    
    results = [src_path]
    
    for sz in sizes:
        out = src_path.replace('1024', str(sz))
        resized = img.resize((sz,sz), Image.LANCZOS)
        resized.save(out, 'PNG', optimize=True)
        results.append(out)
        print(f"  ✓ {out} ({os.path.getsize(out):,} bytes)")
    
    # Deploy 48px to HarmonyOS project paths
    p48 = src_path.replace('1024', '48')
    import shutil
    
    target_paths = [
        f'{OUTPUT_DIR}/AppScope/resources/base/media/icon.png',
        f'{OUTPUT_DIR}/entry/src/main/resources/base/media/icon.png',
    ]
    
    for tp in target_paths:
        shutil.copy(p48, tp)
        print(f"  ✓ Deployed to {tp}")
    
    return results


def main():
    print("=" * 65)
    print("   星空愛莉 App Icon v11 — AI Generated (Idol Game Quality)")
    print("   Based on: Stellar Resonance Design Philosophy")
    print("   Reference: BanG Dream / Idolmaster / Ensemble Stars Style")
    print("=" * 65)
    
    output_base = f'{OUTPUT_DIR}/game_icon_v11'
    output_1024 = f'{output_base}_1024.png'
    
    # Try English prompt first (better for most models)
    print("\n[1/3] Trying English prompt with AI image generation...")
    path, size = generate_with_text_api(PROMPT_EN, output_1024)
    
    # If English fails or produces bad result, try Chinese
    if not path or size < 10000:
        print("\n[2/3] Trying Chinese prompt...")
        path2, size2 = generate_with_text_api(PROMPT_CN, output_1024)
        if path2 and size2 > size:
            path, size = path2, size2
    
    # Try Seedream as another option
    if not path or size < 10000:
        print("\n[3/3] Trying Seedream 5.0...")
        spath, ssize = generate_with_seedream(PROMPT_EN, output_1024)
        if spath and ssize > size:
            path, size = spath, ssize
    
    if path and os.path.exists(path) and size > 5000:
        print(f"\n{'=' * 65}")
        print(f"  ✅ SUCCESS! Generated: {path} ({size:,} bytes)")
        print(f"{'=' * 65}")
        
        print("\nResizing and deploying...")
        resize_and_deploy(path)
        
        print(f"\n{'=' * 65}")
        print(f"  ✅ v11 Complete! All sizes generated and deployed.")
        print(f"{'=' * 65}")
        
        return True
    else:
        print(f"\n❌ All generation methods failed or produced invalid results")
        print(f"   Last result: {path}, size: {size}")
        return False


if __name__ == '__main__':
    main()
