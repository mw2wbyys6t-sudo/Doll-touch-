#!/usr/bin/env python3
"""Debug and try different approaches"""
import asyncio
import sys
import os
import httpx
import json

sys.path.insert(0, '/data/user/skills/byted-seedream-image-generate/scripts')
from seedream_image_generate import seedream_generate

OUTPUT_DIR = '/workspace/ohos_airi'

async def try_all_versions():
    """Try all three versions and report results"""
    
    versions = ["5.0", "4.5", "4.0"]
    results = {}
    
    for ver in versions:
        print(f"\n{'='*60}")
        print(f"Testing Seedream {ver}...")
        print('='*60)
        
        try:
            tasks = [{
                "prompt": "anime girl icon",
                "size": "512x512",
                "watermark": False,
                "output_format": "png" if ver == "5.0" else None,
            }]
            
            result = await seedream_generate(tasks, version=ver, timeout=120)
            
            status = result.get("status", "unknown")
            success_count = len(result.get("success_list", []))
            errors = result.get("error_list", [])
            
            results[ver] = {
                "status": status,
                "success_count": success_count,
                "errors": errors,
            }
            
            print(f"  Status: {status}")
            print(f"  Success count: {success_count}")
            print(f"  Errors: {errors}")
            
        except Exception as e:
            print(f"  Exception: {e}")
            results[ver] = {"error": str(e)}
    
    return results


async def try_direct_api():
    """Try direct httpx call to see detailed error"""
    print("\n" + "="*60)
    print("Direct API Debug...")
    print("="*60)
    
    api_key = "WW1ZMFl6Z3labUl4TURabU5HVm1PRGhrT0dNd05XRmlNMkprTW1VNVptUQ=="
    
    url = "https://ark.cn-beijing.volces.com/api/v3/images/generations"
    
    payload = {
        "model": "doubao-seedream-5-0-260128",
        "prompt": "anime girl",
        "size": "512x512",
        "watermark": False,
    }
    
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {api_key}",
    }
    
    async with httpx.AsyncClient(timeout=120.0) as client:
        try:
            response = await client.post(url, json=payload, headers=headers)
            print(f"\nStatus code: {response.status_code}")
            print(f"Response: {response.text[:2000]}")
        except Exception as e:
            print(f"Error: {e}")


async def main():
    print("="*60)
    print("   Seedream Debug - Finding Working Configuration")
    print("="*60)
    
    # First try direct API to see exact error
    await try_direct_api()
    
    # Then try all versions
    results = await try_all_versions()
    
    print("\n" + "="*60)
    print("Summary:")
    print("="*60)
    for ver, res in results.items():
        print(f"  {ver}: {res}")


if __name__ == '__main__':
    asyncio.run(main())
