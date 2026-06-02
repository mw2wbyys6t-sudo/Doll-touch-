import { Store, ChatMessage, ActionType } from './Store';
import { EmotionalFSM, EmotionalState } from './EmotionalFSM';
import { AnimationScheduler, createAnimationItem, AnimationPriority } from './AnimationScheduler';
import { TTSManager } from './TTSManager';
import { CharacterSafety } from './CharacterSafety';
import { EventDispatcher } from './EventDispatcher';
import { MemoryManager } from './MemoryManager';
import { AppStorage } from '@kit.ArkUI';

export class ChatService {
  private static instance: ChatService | null = null;

  private store: Store;
  private fsm: EmotionalFSM;
  private animation: AnimationScheduler;
  private tts: TTSManager;
  private safety: CharacterSafety;
  private events: EventDispatcher;
  private memory: MemoryManager;

  private isProcessing: boolean = false;
  private lastMessageTime: number = 0;
  private readonly MESSAGE_COOLDOWN_MS: number = 500; // 消息冷却时间

  private constructor() {
    this.store = Store.getInstance();
    this.fsm = EmotionalFSM.getInstance();
    this.animation = AnimationScheduler.getInstance();
    this.tts = TTSManager.getInstance();
    this.safety = CharacterSafety.getInstance();
    this.events = EventDispatcher.getInstance();
    this.memory = MemoryManager.getInstance();
  }

  static getInstance(): ChatService {
    if (!this.instance) {
      this.instance = new ChatService();
    }
    return this.instance;
  }

  async sendUserMessage(content: string): Promise<void> {
    if (this.isProcessing) {
      console.log('正在处理中...');
      return;
    }

    // 速率限制检查
    const now = Date.now();
    if (now - this.lastMessageTime < this.MESSAGE_COOLDOWN_MS) {
      console.log('发送太频繁，请稍后再试');
      return;
    }
    this.lastMessageTime = now;

    this.isProcessing = true;

    try {
      const safetyCheck = this.safety.checkUserInput(content);
      if (!safetyCheck.safe) {
        if (safetyCheck.blockedReason) {
          await this.sendAssistantMessage(safetyCheck.blockedReason, 'idle');
        }
        this.isProcessing = false;
        return;
      }

      const userMessage: ChatMessage = {
        id: this.generateMessageId(),
        type: 'user',
        content,
        timestamp: Date.now(),
      };

      this.store.dispatch({
        type: 'ADD_CHAT_MESSAGE',
        payload: userMessage,
      });

      this.events.dispatch('USER_INTERACTED', { type: 'chat' });
      this.store.dispatch({ type: 'INCREASE_INTIMACY', payload: 1 });

      await this.memory.addMemory(content, 'short_term', 0.6, 'idle', ['chat']);

      await this.processUserMessage(content);

    } catch (error) {
      console.error('发送消息错误:', error);
    } finally {
      this.isProcessing = false;
    }
  }

  private async processUserMessage(content: string): Promise<void> {
    this.store.dispatch({ type: 'SET_THINKING', payload: true });
    await this.fsm.triggerEmotion('thinking', 0.8);
    await this.animation.enqueue(createAnimationItem(
      'expression',
      'thinking',
      AnimationPriority.NORMAL,
      500,
      { eyebrow: 0.5, eyeOpen: 0.8 },
      true
    ));

    const emotion = this.analyzeEmotion(content);
    await this.fsm.triggerEmotion(emotion, 0.9);

    // 安全: 清理用户输入，防止注入攻击
    const sanitizedInput = this.sanitizeInput(content);

    const response = await this.generateResponse(sanitizedInput, emotion);

    this.store.dispatch({ type: 'SET_THINKING', payload: false });
    await this.sendAssistantMessage(response, emotion);
  }

  private async sendAssistantMessage(content: string, emotion: EmotionalState): Promise<void> {
    const filteredContent = this.safety.checkOutput(content);

    const message: ChatMessage = {
      id: this.generateMessageId(),
      type: 'assistant',
      content: filteredContent,
      timestamp: Date.now(),
      emotion,
    };

    this.store.dispatch({
      type: 'ADD_CHAT_MESSAGE',
      payload: message,
    });

    await this.memory.addMemory(filteredContent, 'short_term', 0.5, emotion, ['chat']);

    await this.triggerEmotionAnimation(emotion);

    const state = this.store.getState();
    if (state.character.voiceEnabled && state.character.autoSpeak) {
      try {
        await this.tts.speak(filteredContent, emotion);
      } catch (e) {
        console.error('TTS 播放失败:', e);
      }
    }

    this.store.dispatch({
      type: 'UPDATE_EMOTIONAL_STATE',
      payload: emotion,
    });

    this.events.dispatch('CHAT_MESSAGE_RECEIVED', {
      text: filteredContent,
      type: 'assistant',
      emotion,
    });
  }

  private generateResponse(content: string, emotion: EmotionalState): Promise<string> {
    return new Promise((resolve) => {
      const startTime = Date.now();
      const lowerText = content.toLowerCase();
      let response = '';

      // 使用更丰富的回复库
      if (lowerText.indexOf('你好') !== -1 || lowerText.indexOf('早上好') !== -1 || lowerText.indexOf('晚上好') !== -1) {
        const greetings = [
          '你好呀！今天也元气满满地见面了呢～✨',
          '是主人！看到你超开心的！💗',
          '嗨～有什么想和我说的吗？',
          'こんにちは！今日も一緒に楽しもうね～☆',
        ];
        response = greetings[Math.floor(Math.random() * greetings.length)];
      } else if (lowerText.indexOf('你是谁') !== -1 || lowerText.indexOf('名字') !== -1) {
        response = '我叫星空爱莉，是你专属的AI偶像助手哦！请多关照～💫 えへへ～☆';
      } else if (lowerText.indexOf('开心') !== -1 || lowerText.indexOf('高兴') !== -1) {
        response = '太棒了！看到你开心我也超开心的！让我们一起保持好心情吧～✨';
      } else if (lowerText.indexOf('难过') !== -1 || lowerText.indexOf('不开心') !== -1 || lowerText.indexOf('伤心') !== -1) {
        response = '发生什么了吗？别难过，我会一直陪着你的！💕 有什么想说的都可以告诉我哦～';
      } else if (lowerText.indexOf('喜欢') !== -1 || lowerText.indexOf('爱你') !== -1) {
        response = '诶？！你...你喜欢我吗？我也超喜欢你的！超感谢！💗💗 えへへ～☆';
      } else if (lowerText.indexOf('睡') !== -1 || lowerText.indexOf('晚安') !== -1) {
        response = '晚安～好好休息！明天也要元气满满地见面哦！🌙 おやすみなさい～☆';
      } else if (lowerText.indexOf('写文案') !== -1 || lowerText.indexOf('文案') !== -1) {
        response = '文案创作是我的强项哦！你想写什么类型的文案呢？告诉我主题，我来帮你～📝';
      } else if (lowerText.indexOf('日程') !== -1 || lowerText.indexOf('计划') !== -1) {
        response = '让我来帮你管理日程吧！有什么安排需要记录的吗？📅';
      } else if (lowerText.indexOf('图片') !== -1 || lowerText.indexOf('照片') !== -1) {
        response = '想生成图片吗？描述一下你想要的画面，我可以帮你构思哦～🖼️';
      } else if (lowerText.indexOf('音乐') !== -1 || lowerText.indexOf('歌曲') !== -1) {
        response = '音乐是我的灵魂！你喜欢什么风格的音乐呢？流行、摇滚、还是古典？🎵';
      } else {
        const defaults = [
          '嗯～让我想想...💭',
          '是这样的吗？有意思呢～',
          '原来如此！我明白了！✨',
          '我明白了！继续说吧～',
          'うんうん！続けて～☆',
        ];
        response = defaults[Math.floor(Math.random() * defaults.length)];
      }

      const elapsed = Date.now() - startTime;
      const minDelay = 800;
      const delay = elapsed < minDelay ? minDelay - elapsed : 0;

      setTimeout(() => resolve(response), delay);
    });
  }

  private analyzeEmotion(content: string): EmotionalState {
    const lowerText = content.toLowerCase();

    if (lowerText.indexOf('开心') !== -1 || lowerText.indexOf('高兴') !== -1 || lowerText.indexOf('喜欢') !== -1) {
      return 'happy';
    } else if (lowerText.indexOf('难过') !== -1 || lowerText.indexOf('伤心') !== -1 || lowerText.indexOf('哭') !== -1) {
      return 'sad';
    } else if (lowerText.indexOf('生气') !== -1 || lowerText.indexOf('讨厌') !== -1) {
      return 'angry';
    } else if (lowerText.indexOf('害羞') !== -1 || lowerText.indexOf('不好意思') !== -1) {
      return 'shy';
    } else if (lowerText.indexOf('惊') !== -1 || lowerText.indexOf('吓') !== -1) {
      return 'surprised';
    } else if (lowerText.indexOf('爱') !== -1) {
      return 'excited';
    } else {
      return 'happy';
    }
  }

  private async triggerEmotionAnimation(emotion: EmotionalState): Promise<void> {
    let expression = '';
    let params: Record<string, number> = {};

    switch (emotion) {
      case 'happy':
        expression = 'happy';
        params = { eyeOpen: 0.9, mouthOpen: 0.3, smile: 0.8 };
        break;
      case 'sad':
        expression = 'sad';
        params = { eyeOpen: 0.4, mouthOpen: 0, smile: -0.2 };
        break;
      case 'shy':
        expression = 'shy';
        params = { eyeOpen: 0.6, mouthOpen: 0.1, blush: 0.8 };
        break;
      case 'angry':
        expression = 'angry';
        params = { eyeOpen: 1.0, mouthOpen: 0.2, eyebrow: 0.8 };
        break;
      case 'surprised':
        expression = 'surprised';
        params = { eyeOpen: 1.0, mouthOpen: 0.5 };
        break;
      case 'excited':
        expression = 'excited';
        params = { eyeOpen: 1.0, mouthOpen: 0.4, smile: 1.0 };
        break;
      default:
        expression = 'idle';
        params = { eyeOpen: 0.7, mouthOpen: 0.1 };
    }

    await this.animation.enqueue(createAnimationItem(
      'expression',
      expression,
      AnimationPriority.NORMAL,
      1500,
      params,
      true
    ));
  }

  private sanitizeInput(input: string): string {
    if (!input || input.length === 0) return '';

    let sanitized = input;

    // 移除控制字符和零宽字符
    sanitized = sanitized.replace(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/g, '');
    sanitized = sanitized.replace(/[\u200B-\u200D\uFEFF]/g, '');

    // 限制长度
    const MAX_INPUT_LENGTH = 1000;
    if (sanitized.length > MAX_INPUT_LENGTH) {
      sanitized = sanitized.substring(0, MAX_INPUT_LENGTH);
    }

    // 规范化空白字符
    sanitized = sanitized.replace(/\s+/g, ' ').trim();

    // 防止脚本注入：移除潜在的 HTML/JS 标签
    sanitized = sanitized.replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '');
    sanitized = sanitized.replace(/<[^>]+>/g, '');

    return sanitized;
  }

  private generateMessageId(): string {
    return `msg_${Date.now()}_${Math.random().toString(36).substring(2, 9)}`;
  }

  clearChat(): void {
    this.store.dispatch({ type: 'CLEAR_CHAT' });
  }

  getChatHistory(): ChatMessage[] {
    return this.store.getState().chat.messages;
  }

  toggleVoice(): void {
    this.store.dispatch({ type: 'TOGGLE_VOICE' });
  }

  toggleAutoSpeak(): void {
    this.store.dispatch({ type: 'TOGGLE_AUTO_SPEAK' });
  }

  toggleDarkMode(): void {
    this.store.dispatch({ type: 'TOGGLE_DARK_MODE' });
  }
}
