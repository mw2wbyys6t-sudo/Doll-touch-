class AiriAI {
  constructor() {
    this.chatContainer = document.getElementById('chatContainer');
    this.messageInput = document.getElementById('messageInput');
    this.voiceBtn = document.getElementById('voiceBtn');
    this.emojiPicker = document.getElementById('emojiPicker');
    this.isRecording = false;
    this.recognition = null;
    this.currentTab = 'chat';
    
    this.responses = {
      greeting: [
        'こんにちは！星空爱莉です～ 今日も一緒に楽しく過ごしましょう！✨',
        'みんなを笑顔にするのが私の魔法です～ 何かお手伝いできることはありますか？',
        'はいっ！アイドルの魔法でお手伝いしますよ～ ☆'
      ],
      thanks: [
        'どういたしまして～ みんなが笑顔になるのが私の幸せです！',
        'ありがとう～ またいつでも呼んでね！',
        'えへへ～ お役に立てて嬉しいです！'
      ],
      creative: [
        '創作意欲MAX！一緒に素敵なものを作りましょう！🎨',
        'アイデアは無限大！どんなことに挑戦しますか？',
        '創作は魔法です～ 私と一緒に夢を叶えましょう！'
      ],
      default: [
        'それは素敵なことですね！もっと話してください～',
        'わかりました！一緒に考えましょう！',
        '面白いですね～ 続けてください！',
        '私もそう思います！一緒に頑張りましょう！'
      ]
    };
    
    this.setupEventListeners();
  }
  
  setupEventListeners() {
    document.addEventListener('click', (e) => {
      if (!this.emojiPicker.contains(e.target) && !e.target.classList.contains('emoji-btn')) {
        this.emojiPicker.style.display = 'none';
      }
    });
  }
  
  sendMessage(text) {
    if (!text.trim()) return;
    
    const userBubble = this.createMessageBubble(text, 'user');
    this.chatContainer.appendChild(userBubble);
    
    this.messageInput.value = '';
    this.scrollToBottom();
    
    setTimeout(() => {
      this.showTypingIndicator();
      
      setTimeout(() => {
        this.removeTypingIndicator();
        const response = this.generateResponse(text);
        const aiBubble = this.createMessageBubble(response, 'ai');
        this.chatContainer.appendChild(aiBubble);
        this.scrollToBottom();
      }, 1500 + Math.random() * 1000);
    }, 500);
  }
  
  createMessageBubble(text, type) {
    const bubble = document.createElement('div');
    bubble.className = `message-bubble ${type}`;
    
    const avatar = document.createElement('div');
    avatar.className = `avatar ${type === 'ai' ? 'ai-avatar' : 'user-avatar'}`;
    avatar.textContent = type === 'ai' ? '🎤' : '👤';
    
    const content = document.createElement('div');
    content.className = 'message-content';
    
    if (type === 'ai') {
      const name = document.createElement('span');
      name.className = 'message-name';
      name.textContent = '爱莉';
      content.appendChild(name);
    }
    
    const textElement = document.createElement('p');
    textElement.className = 'message-text';
    textElement.textContent = text;
    content.appendChild(textElement);
    
    if (type === 'ai') {
      const time = document.createElement('span');
      time.className = 'message-time';
      time.textContent = '刚刚';
      content.appendChild(time);
    }
    
    bubble.appendChild(avatar);
    bubble.appendChild(content);
    
    return bubble;
  }
  
  showTypingIndicator() {
    const indicator = document.createElement('div');
    indicator.className = 'message-bubble ai typing-indicator-wrap';
    indicator.innerHTML = `
      <div class="avatar ai-avatar">🎤</div>
      <div class="message-content">
        <span class="message-name">爱莉</span>
        <div class="typing-indicator">
          <span class="typing-dot"></span>
          <span class="typing-dot"></span>
          <span class="typing-dot"></span>
        </div>
      </div>
    `;
    indicator.id = 'typingIndicator';
    this.chatContainer.appendChild(indicator);
    this.scrollToBottom();
  }
  
  removeTypingIndicator() {
    const indicator = document.getElementById('typingIndicator');
    if (indicator) {
      indicator.remove();
    }
  }
  
  generateResponse(text) {
    const lowerText = text.toLowerCase();
    
    if (lowerText.includes('你好') || lowerText.includes('hi') || lowerText.includes('hello') || lowerText.includes('こんにちは')) {
      return this.getRandomResponse('greeting');
    }
    
    if (lowerText.includes('谢谢') || lowerText.includes('ありがとう') || lowerText.includes('thank')) {
      return this.getRandomResponse('thanks');
    }
    
    if (lowerText.includes('写') || lowerText.includes('创作') || lowerText.includes('画') || lowerText.includes('诗') || lowerText.includes('文案')) {
      return this.getRandomResponse('creative');
    }
    
    return this.getRandomResponse('default');
  }
  
  getRandomResponse(key) {
    const responses = this.responses[key] || this.responses.default;
    return responses[Math.floor(Math.random() * responses.length)];
  }
  
  scrollToBottom() {
    setTimeout(() => {
      this.chatContainer.scrollTop = this.chatContainer.scrollHeight;
    }, 100);
  }
  
  toggleEmojiPicker() {
    const isHidden = this.emojiPicker.style.display === 'none';
    this.emojiPicker.style.display = isHidden ? 'block' : 'none';
    this.emojiPicker.setAttribute('aria-hidden', !isHidden);
    this.emojiPicker.previousElementSibling.querySelector('.emoji-btn').setAttribute('aria-expanded', isHidden);
    
    if (isHidden) {
      const emojiGrid = this.emojiPicker.querySelector('.emoji-grid');
      const emojis = emojiGrid.querySelectorAll('span');
      
      emojis.forEach(emoji => {
        emoji.setAttribute('tabindex', '0');
        emoji.setAttribute('role', 'option');
        emoji.setAttribute('aria-selected', 'false');
        
        emoji.onclick = () => {
          this.messageInput.value += emoji.textContent;
          this.emojiPicker.style.display = 'none';
          this.emojiPicker.setAttribute('aria-hidden', 'true');
          this.emojiPicker.previousElementSibling.querySelector('.emoji-btn').setAttribute('aria-expanded', 'false');
          this.messageInput.focus();
        };
        
        emoji.onkeydown = (e) => {
          if (e.key === 'Enter' || e.key === ' ') {
            e.preventDefault();
            emoji.click();
          }
        };
      });
    }
  }
  
  toggleVoiceRecording() {
    if (!('webkitSpeechRecognition' in window) && !('SpeechRecognition' in window)) {
      alert('您的浏览器不支持语音识别功能');
      return;
    }
    
    if (this.isRecording) {
      this.stopRecording();
    } else {
      this.startRecording();
    }
  }
  
  startRecording() {
    const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
    this.recognition = new SpeechRecognition();
    this.recognition.lang = 'zh-CN';
    this.recognition.interimResults = false;
    this.recognition.maxAlternatives = 1;
    
    this.recognition.onstart = () => {
      this.isRecording = true;
      this.voiceBtn.classList.add('recording');
      this.voiceBtn.textContent = '🛑';
    };
    
    this.recognition.onresult = (event) => {
      const speechResult = event.results[0][0].transcript;
      this.messageInput.value = speechResult;
      this.sendMessage(speechResult);
    };
    
    this.recognition.onerror = (event) => {
      console.error('语音识别错误:', event.error);
      this.stopRecording();
    };
    
    this.recognition.onend = () => {
      if (this.isRecording) {
        this.stopRecording();
      }
    };
    
    this.recognition.start();
  }
  
  stopRecording() {
    if (this.recognition) {
      this.recognition.stop();
      this.recognition = null;
    }
    this.isRecording = false;
    this.voiceBtn.classList.remove('recording');
    this.voiceBtn.textContent = '🎤';
  }
  
  handleAction(action) {
    const actions = {
      write: { title: '写文案', message: '好的！どんな文案を書きますか？ブログ、SNS、詩...何でもお任せください！📝' },
      schedule: { title: '日程管理', message: 'スケジュールを管理しましょう！何を予定しますか？追加、確認、リマインダー...何でもできますよ～ 📅' },
      image: { title: '生成图片', message: '画像生成をしましょう！どんな画像を作りたいですか？詳しく教えてください～ 🖼️' },
      music: { title: '音乐推荐', message: '音楽を探しましょう！好きなジャンルやアーティストはいますか？私がおすすめします！🎵' }
    };
    
    const actionData = actions[action];
    if (actionData) {
      this.sendMessage(`我想${actionData.title}`);
      
      setTimeout(() => {
        const bubble = this.createMessageBubble(actionData.message, 'ai');
        this.chatContainer.appendChild(bubble);
        this.scrollToBottom();
      }, 2000);
    }
  }
  
  switchTab(tab) {
    if (tab === this.currentTab) return;
    
    document.querySelectorAll('.nav-item').forEach(item => {
      item.classList.remove('active');
    });
    
    event.target.classList.add('active');
    this.currentTab = tab;
    
    const tabMessages = {
      chat: 'チャット画面です～ 何か話しましょう！',
      tasks: 'タスク管理画面です～ 何か予定を追加しますか？',
      create: 'クリエイティブモードです！一緒に何か作りましょう～',
      profile: 'プロフィール画面です～ 設定を変更しますか？'
    };
    
    if (tab !== 'chat') {
      setTimeout(() => {
        const bubble = this.createMessageBubble(`「${tabMessages[tab]}」機能は開発中です～ 暫くお待ちください！✨`, 'ai');
        this.chatContainer.appendChild(bubble);
        this.scrollToBottom();
      }, 500);
    }
  }
}

function handleKeyPress(event) {
  if (event.key === 'Enter') {
    event.preventDefault();
    const text = document.getElementById('messageInput').value;
    ai.sendMessage(text);
  }
}

function toggleEmojiPicker() {
  ai.toggleEmojiPicker();
}

function toggleVoiceRecording() {
  ai.toggleVoiceRecording();
}

function handleAction(action) {
  ai.handleAction(action);
}

function switchTab(tab) {
  ai.switchTab(tab);
}

let ai;

document.addEventListener('DOMContentLoaded', () => {
  ai = new AiriAI();
});