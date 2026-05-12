import { Observable, Decorator } from '@ohos.arkui.observable';
import { MessageModel, Message, ChatSession } from '../model/MessageModel';
import { PreferencesUtil } from '../utils/PreferencesUtil';
import { NotificationManager } from '../utils/NotificationManager';

const { observable, observe } = Decorator;

@observable
export class ChatViewModel {
  messages: Message[] = [];
  isTyping: boolean = false;
  inputText: string = '';
  currentTab: string = 'chat';
  
  private static readonly MESSAGES_KEY = 'chat_messages';
  private static readonly TAB_KEY = 'current_tab';
  
  private responses = {
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

  async init(): Promise<void> {
    await this.loadMessages();
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
    
    const userMessage = MessageModel.createMessage(content, 'user');
    this.messages.push(userMessage);
    this.inputText = '';
    await this.saveMessages();
    
    this.isTyping = true;
    
    setTimeout(async () => {
      this.isTyping = false;
      const response = this.generateResponse(content);
      const aiMessage = MessageModel.createMessage(response, 'ai');
      this.messages.push(aiMessage);
      await this.saveMessages();
      
      await NotificationManager.showNotification('星空爱莉', response);
    }, 1500 + Math.random() * 1000);
  }

  generateResponse(text: string): string {
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

  getRandomResponse(key: string): string {
    const responses = this.responses[key] || this.responses.default;
    return responses[Math.floor(Math.random() * responses.length)];
  }

  async handleAction(action: string): Promise<void> {
    const actions: Record<string, { title: string; message: string }> = {
      write: { title: '写文案', message: '好的！どんな文案を書きますか？ブログ、SNS、詩...何でもお任せください！📝' },
      schedule: { title: '日程管理', message: 'スケジュールを管理しましょう！何を予定しますか？追加、確認、リマインダー...何でもできますよ～ 📅' },
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
  }
}