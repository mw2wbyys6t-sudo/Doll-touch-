import { MessageModel, Message } from '../model/MessageModel';
import { PreferencesUtil } from '../utils/PreferencesUtil';
import { NotificationManager } from '../utils/NotificationManager';
import { MemoryManager } from '../utils/MemoryManager';
import { EmotionUnderstanding } from '../utils/EmotionUnderstanding';
import { ThinkingEngine } from '../utils/ThinkingEngine';

export class ChatViewModel {
  messages: Message[] = [];
  isTyping: boolean = false;
  inputText: string = '';
  currentTab: string = 'chat';
  currentEmotion: string = 'neutral';
  thinkingActive: boolean = false;
  
  private memoryManager: MemoryManager;
  private emotionUnderstanding: EmotionUnderstanding;
  private thinkingEngine: ThinkingEngine;
  
  private static readonly MESSAGES_KEY = 'chat_messages';
  private static readonly TAB_KEY = 'current_tab';
  
  private responses = {
    greeting: [
      'こんにちは！星空爱莉です～ 今日も一緒に楽しく過ごしましょう！✨',
      'みんなを笑顔にするのが私の魔法です～ 何かお手伝いできることはありますか？',
      'はいっ！アイドルの魔法でお手伝いしますよ～ ☆'
    ],
    thanks: [
      'どういたしまいて～ みんなが笑顔になるのが私の幸せです！',
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

  constructor() {
    this.memoryManager = MemoryManager.getInstance();
    this.emotionUnderstanding = EmotionUnderstanding.getInstance();
    this.thinkingEngine = ThinkingEngine.getInstance();
  }

  async init(): Promise<void> {
    await this.loadMessages();
    await this.memoryManager.init();
    await this.thinkingEngine.init();
    
    const savedTab = await PreferencesUtil.getString(ChatViewModel.TAB_KEY, 'chat');
    this.currentTab = savedTab;
    
    if (this.messages.length === 0) {
      const welcomeMessage = MessageModel.createMessage(
        'みんなを笑顔にする！それが、私のアイドルの魔法だよっ☆',
        'ai'
      );
      this.messages.push(welcomeMessage);
      await this.saveMessages();
    }
  }

  async loadMessages(): Promise<void> {
    try {
      const saved = await PreferencesUtil.getString(ChatViewModel.MESSAGES_KEY);
      if (saved) {
        this.messages = JSON.parse(saved);
      }
    } catch (err) {
      console.error('ChatViewModel loadMessages failed:', err);
      this.messages = [];
    }
  }

  async saveMessages(): Promise<void> {
    try {
      await PreferencesUtil.putString(ChatViewModel.MESSAGES_KEY, JSON.stringify(this.messages));
    } catch (err) {
      console.error('ChatViewModel saveMessages failed:', err);
    }
  }

  async sendMessage(content: string): Promise<void> {
    if (!content.trim()) return;
    
    this.thinkingActive = true;
    
    const userMessage = MessageModel.createMessage(content, 'user');
    this.messages.push(userMessage);
    this.inputText = '';
    await this.saveMessages();
    
    this.isTyping = true;
    
    const thinkingContext = {
      currentInput: content,
      userMessage: content,
      recentHistory: this.messages.slice(-5).map(m => m.content),
      emotionalState: this.emotionUnderstanding.getEmotionalState(),
      memories: this.memoryManager.getMemorySummary(),
      userProfile: JSON.stringify(this.memoryManager.getUserProfile())
    };
    
    const thinkingResult = await this.thinkingEngine.think(thinkingContext);
    
    const emotionAnalysis = this.emotionUnderstanding.analyzeEmotion(content);
    this.currentEmotion = emotionAnalysis.emotion;
    
    this.isTyping = false;
    
    const response = await this.thinkingEngine.generateResponse(
      thinkingContext,
      emotionAnalysis,
      thinkingResult
    );
    
    const aiMessage = MessageModel.createMessage(response, 'ai');
    this.messages.push(aiMessage);
    await this.saveMessages();
    
    await NotificationManager.showNotification('星空爱莉', response);
    
    this.thinkingActive = false;
  }

  async generateResponse(text: string): Promise<string> {
    const lowerText = text.toLowerCase();

    if (lowerText.indexOf('你好') !== -1 || lowerText.indexOf('hi') !== -1 || lowerText.indexOf('hello') !== -1 || lowerText.indexOf('こんにちは') !== -1) {
      return this.getRandomResponse('greeting');
    }

    if (lowerText.indexOf('谢谢') !== -1 || lowerText.indexOf('ありがとう') !== -1 || lowerText.indexOf('thank') !== -1) {
      return this.getRandomResponse('thanks');
    }

    if (lowerText.indexOf('写') !== -1 || lowerText.indexOf('创作') !== -1 || lowerText.indexOf('画') !== -1 || lowerText.indexOf('诗') !== -1 || lowerText.indexOf('文案') !== -1) {
      return this.getRandomResponse('creative');
    }

    return this.getRandomResponse('default');
  }

  getRandomResponse(key: string): string {
    const responses = this.responses[key] || this.responses.default;
    return responses[Math.floor(Math.random() * responses.length)];
  }

  async handleAction(action: string): Promise<void> {
    const actions: Record<string, { title: string; message: string }> = {
      write: { title: '写文案', message: '好的！どんな文案を書きますか？ブログ、SNS、詩...何でもお任せください！📝' },
      schedule: { title: '日程管理', message: 'スケジュールを管理しましょう！何を予定しますか？追加，确认、リマインダー...何でもできますよ～ 📅' },
      image: { title: '生成图片', message: '画像生成をしましょう！どんな画像を作りたいですか？詳しく教えてください～ 🖼️' },
      music: { title: '音乐推荐', message: '音楽を探しましょう！好きなジャンルやアーティストはいますか？私がおすすめします！🎵' }
    };
    
    const actionData = actions[action];
    if (actionData) {
      await this.sendMessage(`我想${actionData.title}`);
      
      setTimeout(async () => {
        const aiMessage = MessageModel.createMessage(actionData.message, 'ai');
        this.messages.push(aiMessage);
        await this.saveMessages();
      }, 2000);
    }
  }

  async switchTab(tab: string): Promise<void> {
    if (tab === this.currentTab) return;
    this.currentTab = tab;
    await PreferencesUtil.putString(ChatViewModel.TAB_KEY, tab);
  }

  async clearMessages(): Promise<void> {
    this.messages = [];
    await this.saveMessages();
    this.memoryManager.clearShortTerm();
  }

  async checkAndTriggerProactiveMessage(): Promise<void> {
    const proactiveThought = await this.thinkingEngine.generateProactiveThought();
    
    if (proactiveThought && this.messages.length > 0) {
      const lastMessage = this.messages[this.messages.length - 1];
      const hoursSinceLastMessage = (Date.now() - lastMessage.timestamp) / (1000 * 60 * 60);
      
      if (hoursSinceLastMessage > 2) {
        const aiMessage = MessageModel.createMessage(proactiveThought, 'ai');
        this.messages.push(aiMessage);
        await this.saveMessages();
        await NotificationManager.showNotification('星空爱莉', proactiveThought);
      }
    }
  }

  getEmotionColor(): string {
    return this.emotionUnderstanding.getEmotionColor(this.currentEmotion as any);
  }

  getThinkingHistory(): string[] {
    return this.thinkingEngine.getThinkingHistory();
  }

  async searchMemories(query: string): Promise<string[]> {
    const memories = await this.memoryManager.searchMemories(query);
    return memories.map(m => m.content);
  }

  getMemorySummary(): string {
    return this.memoryManager.getMemorySummary();
  }
}
