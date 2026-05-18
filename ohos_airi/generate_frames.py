#!/usr/bin/env python3
"""Seedream 5.0 批量生成6帧 + 自动下载 v3"""
import subprocess, json, os, sys, re, httpx

OUTPUT_DIR = '/workspace/ohos_airi/entry/src/main/resources/rawfile'
SCRIPT = '/data/user/skills/byted-seedream-image-generate/scripts/seedream_image_generate.py'
os.makedirs(OUTPUT_DIR, exist_ok=True)

FRAMES = [
    ("airi_idle", "Japanese idol anime girl Hoshizora Airi age 16, long wavy deep brown hair with pink-purple gradient tips, large violet-purple eyes with sparkle, pink butterfly bow on RIGHT side with flower, white frilled idol collar, BanG Dream style, gentle sweet smile happy closed eyes, head tilted right, hands clasped at chest, relaxed pose, soft warm lighting, circular crop starry background"),
    ("airi_happy", "Japanese idol anime girl Hoshizora Airi age 16, long wavy deep brown hair with pink-purple gradient tips, large violet-purple eyes with sparkle, pink butterfly bow on RIGHT side with flower, white frilled idol collar, BanG Dream style, big bright cheerful grin teeth showing, eyes squeezed shut happiness, both hands raised excited near face, leaning forward, vibrant lighting, circular crop sparkling starry background"),
    ("airi_shy", "Japanese idol anime girl Hoshizora Airi age 16, long wavy deep brown hair with pink-purple gradient tips, large violet-purple eyes with sparkle, pink butterfly bow on RIGHT side with flower, white frilled idol collar, BanG Dream style, shy embarrassed blushing pink cheeks, eyes looking down side, small nervous smile, hand touching cheek, shoulders hunched, soft pink lighting, circular crop dreamy background"),
    ("airi_excited", "Japanese idol anime girl Hoshizora Airi age 16, long wavy deep brown hair with pink-purple gradient tips, large violet-purple eyes with sparkle, pink butterfly bow on RIGHT side with flower, white frilled idol collar, BanG Dream style, super excited wide open mouth D-smile, large sparkling star-shaped eyes, both arms raised high celebration, bouncing energy sparkles around, dynamic bright lighting, circular crop explosive starburst background"),
    ("airi_surprised", "Japanese idol anime girl Hoshizora Airi age 16, long wavy deep brown hair with pink-purple gradient tips, large violet-purple eyes with sparkle, pink butterfly bow on RIGHT side with flower, white frilled idol collar, BanG Dream style, surprised shocked wide round O_O eyes, small O-mouth, eyebrows raised high, hands near cheeks surprise gesture, leaning back, dramatic front lighting, circular crop speed lines background"),
    ("airi_sing", "Japanese idol anime girl Hoshizora Airi age 16, long wavy deep brown hair with pink-purple gradient tips, large violet-purple eyes with sparkle, pink butterfly bow on RIGHT side with flower, white frilled idol collar, BanG Dream style, singing passionately closed happy eyes, open singing mouth shape, holding microphone right hand, left hand on chest, body sway performing, stage spotlight above, circular crop concert stage colorful lights"),
]

def extract_urls(text):
    urls = re.findall(r'https?://[^\s"\'\]>]+\.(?:png|jpg|jpeg)[^\s"\'\>]*', text)
    # Also try to find URLs in the raw output
    if not urls:
        urls = re.findall(r'(https?://ark[^\s"\']*)', text)
    return urls

ok = 0
for i, (name, prompt) in enumerate(FRAMES):
    out = f'{OUTPUT_DIR}/{name}.png'
    if os.path.exists(out) and os.path.getsize(out) > 10000:
        print(f"[{i+1}] {name}: SKIP ({os.path.getsize(out)//1024}KB)")
        ok += 1
        continue

    print(f"[{i+1}/{len(FRAMES)}] {name}...", end=" ", flush=True)
    r = subprocess.run(
        [sys.executable, SCRIPT, '-p', prompt, '-s', '2048x2048',
         '--no-watermark', '--version', '5.0', '--output-format', 'png', '-t', '180'],
        capture_output=True, text=True, timeout=200,
        env={**os.environ, 'ARK_API_KEY': 'ark-d0dd55e5-ee35-426f-9321-7c09b8d76a81-4283b'}
    )
    output = r.stdout + r.stderr

    # Method 1: Extract URL directly from text
    urls = extract_urls(output)

    if not urls:
        # Method 2: Try to parse the last JSON object in output
        try:
            # Find all JSON objects, take the last complete one
            objs = list(json.decoder.JSONDecoder().raw_decode(output))
            if objs:
                json_data = objs[0][0]
                sl = json_data.get('success_list', [])
                if isinstance(sl, list):
                    for item in sl:
                        if isinstance(item, dict):
                            for v in item.values():
                                if isinstance(v, str) and v.startswith('http'):
                                    urls.append(v)
                                elif isinstance(v, str) and 'tos' in v:
                                    urls.append(v)
        except:
            pass

    if urls:
        url = urls[0]
        try:
            resp = httpx.get(url, timeout=60, follow_redirects=True)
            ct = resp.headers.get('content-type', '')
            if resp.status_code == 200 and ('image' in ct or len(resp.content) > 50000):
                with open(out, 'wb') as f:
                    f.write(resp.content)
                sz = len(resp.content) // 1024
                print(f"OK ({sz}KB)")
                ok += 1
            else:
                print(f"bad response ({resp.status_code}, {ct}, {len(resp.content)}B)")
        except Exception as e2:
            print(f"dload err: {e2}")
    else:
        # Show snippet of output for debugging
        snippet = output[-300:] if len(output) > 300 else output
        clean = snippet.replace('\n', '\\n')
        print(f"FAIL (no url) [{len(output)} chars]")
        print(f"  tail: ...{clean[-150:]}")

print(f"\n{'='*40}")
print(f"DONE: {ok}/{len(FRAMES)} frames")
for n, _ in FRAMES:
    p = f'{OUTPUT_DIR}/{n}.png'
    s = os.path.getsize(p)//1024 if os.path.exists(p) else 0
    print(f"  {'OK' if s > 0 else '--'} {n}.png ({s}KB)")
