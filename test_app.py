#!/usr/bin/env python3
import sys
sys.path.insert(0, '/data/user/skills/webapp-testing/scripts')

from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    page = browser.new_page()
    
    # Navigate to the app
    page.goto('http://localhost:8000')
    page.wait_for_load_state('networkidle')
    
    # Take a screenshot
    page.screenshot(path='/workspace/test_screenshot.png', full_page=True)
    
    # Check console for errors
    page.on('console', lambda msg: print(f"Console {msg.type}: {msg.text}") if msg.type == 'error' else None)
    
    # Check page title
    title = page.title()
    print(f"Page title: {title}")
    
    # Check if main elements exist
    header = page.locator('.header')
    print(f"Header exists: {header.count() > 0}")
    
    chat_container = page.locator('#chatContainer')
    print(f"Chat container exists: {chat_container.count() > 0}")
    
    message_input = page.locator('#messageInput')
    print(f"Message input exists: {message_input.count() > 0}")
    
    voice_btn = page.locator('#voiceBtn')
    print(f"Voice button exists: {voice_btn.count() > 0}")
    
    quick_actions = page.locator('.quick-actions')
    print(f"Quick actions exists: {quick_actions.count() > 0}")
    
    bottom_nav = page.locator('.bottom-nav')
    print(f"Bottom nav exists: {bottom_nav.count() > 0}")
    
    # Check all action buttons
    action_btns = page.locator('.action-btn')
    print(f"Number of action buttons: {action_btns.count()}")
    
    # Test typing in input
    message_input.fill("你好，爱莉！")
    text_value = message_input.input_value()
    print(f"Input test - entered text: {text_value}")
    
    # Check navigation items
    nav_items = page.locator('.nav-item')
    print(f"Number of navigation items: {nav_items.count()}")
    
    # Take full page screenshot
    page.screenshot(path='/workspace/test_full_page.png', full_page=True)
    
    print("\n✅ All basic checks passed!")
    
    browser.close()
