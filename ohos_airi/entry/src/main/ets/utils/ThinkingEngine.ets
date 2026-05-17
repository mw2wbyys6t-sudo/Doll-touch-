import { MemoryManager } from './MemoryManager';
import { EmotionUnderstanding, EmotionType } from './EmotionUnderstanding';

export interface ThinkingContext {
  currentInput: string;
  userMessage: string;
  recentHistory: string[];
  emotionalState: any;
  memories: string;
  userProfile: string;
}

export interface ThinkingResult {
  thought: string;
  action: 'respond' | 'ask' | 'suggest' | 'reflect';
  confidence: number;
  needsMemoryRecall: boolean;
  needsEmotionMatch: boolean;
}

export interface ReflectionResult {
  insights: string[];
  relationshipUpdates: string[];
  behavioralPatterns: string[];
}

export class ThinkingEngine {
  private static instance: ThinkingEngine | null = null;
  private memoryManager: MemoryManager;
  private emotionUnderstanding: EmotionUnderstanding;
  private thinkingHistory: string[] = [];
  private reflectionThreshold: number = 5;
  private interactionCount: number = 0;

  private constructor() {
    this.memoryManager = MemoryManager.getInstance();
    this.emotionUnderstanding = EmotionUnderstanding.getInstance();
  }

  static getInstance(): ThinkingEngine {
    if (!this.instance) {
      this.instance = new ThinkingEngine();
    }
    return this.instance;
  }

  async init(): Promise<void> {
    await this.memoryManager.init();
    console.info('ThinkingEngine initialized successfully');
  }

  async think(context: ThinkingContext): Promise<ThinkingResult> {
    const emotionAnalysis = this.emotionUnderstanding.analyzeEmotion(context.userMessage);
    this.emotionUnderstanding.updateEmotionalState(emotionAnalysis.emotion, emotionAnalysis.intensity);

    const relevantMemories = await this.memoryManager.searchMemories(context.userMessage, 5);
    const memoryContext = relevantMemories.map(m => m.content).join('; ');
    
    const userProfile = this.memoryManager.getUserProfile();
    const profileSummary = this.memoryManager.getMemorySummary();

    const needsMemoryRecall = relevantMemories.length > 0 && relevantMemories.some(m => m.importance > 0.6);
    const needsEmotionMatch = emotionAnalysis.intensity > 0.6;

    const thought = this.generateThought(context, emotionAnalysis, memoryContext, profileSummary);
    this.thinkingHistory.push(thought);

    if (this.thinkingHistory.length > 10) {
      this.thinkingHistory = this.thinkingHistory.slice(-10);
    }

    const action = this.determineAction(emotionAnalysis, context);

    if (emotionAnalysis.needs.length > 0) {
      this.memoryManager.addMemory(
        `用户表达了需求: ${emotionAnalysis.needs.join(', ')}`,
        'short_term',
        emotionAnalysis.emotion,
        emotionAnalysis.needs
      );
    }

    this.memoryManager.updateUserProfile('interactionCount', 1);
    this.memoryManager.updateUserProfile('emotion', {
      timestamp: Date.now(),
      emotion: emotionAnalysis.emotion,
      intensity: emotionAnalysis.intensity,
      trigger: context.userMessage.slice(0, 50)
    });

    this.interactionCount++;

    return {
      thought,
      action,
      confidence: emotionAnalysis.intensity,
      needsMemoryRecall,
      needsEmotionMatch
    };
  }

  private generateThought(
    context: ThinkingContext,
    emotionAnalysis: any,
    memoryContext: string,
    profileSummary: string
  ): string {
    const thoughts: string[] = [];

    if (memoryContext) {
      thoughts.push(`[记忆检索] 发现相关记忆: ${memoryContext.slice(0, 100)}...`);
    }

    if (profileSummary) {
      thoughts.push(`[用户理解] ${profileSummary}`);
    }

    thoughts.push(`[情感分析] 用户情绪: ${emotionAnalysis.emotion} (强度: ${emotionAnalysis.intensity.toFixed(2)})`);

    if (emotionAnalysis.needs.length > 0) {
      thoughts.push(`[需求识别] 用户可能需要: ${emotionAnalysis.needs.join(', ')}`);
    }

    const contextKeywords = this.extractKeywords(context.userMessage);
    thoughts.push(`[关键词提取] ${contextKeywords.join(', ')}`);

    return thoughts.join(' | ');
  }

  private extractKeywords(text: string): string[] {
    const stopWords = ['的', '了', '是', '在', '我', '你', '他', '她', '它', '和', '与', '或', '的', '了'];
    const words = text.split(/[\s,.!?，。！？、]+/).filter(w =>
      w.length > 1 && stopWords.indexOf(w) === -1
    );
    
    const wordCount: Record<string, number> = {};
    words.forEach(word => {
      wordCount[word] = (wordCount[word] || 0) + 1;
    });

    return Object.entries(wordCount)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 5)
      .map(([word]) => word);
  }

  private determineAction(emotionAnalysis: any, context: ThinkingContext): 'respond' | 'ask' | 'suggest' | 'reflect' {
    if (emotionAnalysis.emotion === 'sad' || emotionAnalysis.emotion === 'lonely') {
      return 'respond';
    }

    if (context.userMessage.indexOf('?') !== -1 || context.userMessage.indexOf('？') !== -1) {
      if (emotionAnalysis.intensity < 0.5) {
        return 'suggest';
      }
    }

    if (this.interactionCount % this.reflectionThreshold === 0) {
      return 'reflect';
    }

    if (context.recentHistory.length > 0 && context.recentHistory.length % 3 === 0) {
      return 'ask';
    }

    return 'respond';
  }

  async reflect(): Promise<ReflectionResult> {
    const recentMemories = await this.memoryManager.searchMemories('', 10);
    
    const insights: string[] = [];
    const relationshipUpdates: string[] = [];
    const behavioralPatterns: string[] = [];

    if (recentMemories.length > 3) {
      const topics = recentMemories
        .filter(m => m.type !== 'short_term')
        .map(m => m.content)
        .join(' ');

      if (topics.indexOf('喜欢') !== -1 || topics.indexOf('感兴趣') !== -1) {
        insights.push('用户似乎对某些话题特别感兴趣，可以继续深入探讨');
      }
    }

    const profile = this.memoryManager.getUserProfile();
    if (profile && profile.emotionalHistory.length > 3) {
      const recentEmotions = profile.emotionalHistory.slice(-5);
      const emotionTypes = recentEmotions.map(e => e.emotion);
      const uniqueEmotions = [...new Set(emotionTypes)];

      if (uniqueEmotions.length <= 2) {
        behavioralPatterns.push(`用户的情绪状态比较稳定，主要表现为: ${uniqueEmotions.join(', ')}`);
      }

      const avgIntensity = recentEmotions.reduce((sum, e) => sum + e.intensity, 0) / recentEmotions.length;
      if (avgIntensity > 0.6) {
        insights.push('用户近期情绪比较强烈，可能有重要事件发生');
      }
    }

    if (profile && profile.interactionCount > 10) {
      relationshipUpdates.push('与用户建立了初步的互动关系');
    }

    return {
      insights,
      relationshipUpdates,
      behavioralPatterns
    };
  }

  async generateResponse(
    context: ThinkingContext,
    emotionAnalysis: any,
    thinkingResult: ThinkingResult
  ): Promise<string> {
    let response = '';

    const empatheticStart = this.emotionUnderstanding.generateEmpatheticResponse(
      emotionAnalysis.emotion,
      emotionAnalysis.intensity
    );

    if (thinkingResult.needsMemoryRecall) {
      const relevantMemories = await this.memoryManager.searchMemories(context.userMessage, 3);
      if (relevantMemories.length > 0) {
        response += `${empatheticStart} `;
        const memory = relevantMemories[0];
        response += `我记得之前你提到过「${memory.content.slice(0, 50)}...」，是不是这个呢？`;
        return response;
      }
    }

    response = empatheticStart;

    if (thinkingResult.action === 'ask') {
      response += this.generateFollowUpQuestion(emotionAnalysis);
    } else if (thinkingResult.action === 'suggest') {
      response += this.generateSuggestion(context, emotionAnalysis);
    } else if (thinkingResult.action === 'reflect') {
      response += await this.generateReflection();
    }

    this.memoryManager.addMemory(
      context.userMessage,
      'short_term',
      emotionAnalysis.emotion,
      this.extractKeywords(context.userMessage)
    );

    return response;
  }

  private generateFollowUpQuestion(emotionAnalysis: any): string {
    if (emotionAnalysis.emotion === 'happy' || emotionAnalysis.emotion === 'excited') {
      return '有什么特别开心的事情吗？愿意和我分享吗？✨';
    } else if (emotionAnalysis.emotion === 'sad' || emotionAnalysis.emotion === 'anxious') {
      return '想聊聊是什么让你心情不好吗？我在这里听你说 💗';
    } else if (emotionAnalysis.emotion === 'neutral') {
      return '最近有什么有趣的事情吗？跟我说说呀～';
    }
    return '还有别的想聊的吗？我很想知道呢～';
  }

  private generateSuggestion(context: ThinkingContext, emotionAnalysis: any): string {
    if (emotionAnalysis.emotion === 'happy' || emotionAnalysis.emotion === 'excited') {
      return '要不要把你的好心情记录下来呢？我可以帮你保存这些美好的时刻～';
    } else if (emotionAnalysis.emotion === 'sad' || emotionAnalysis.emotion === 'anxious') {
      return '要不要听点轻松的音乐转换一下心情呢？我可以给你推荐一些～';
    }
    return '有什么我可以帮到你的吗？尽管说哦！';
  }

  private async generateReflection(): Promise<string> {
    const reflection = await this.reflect();
    
    if (reflection.insights.length > 0 || reflection.behavioralPatterns.length > 0) {
      let text = '我注意到一些事情呢... ';
      
      if (reflection.insights.length > 0) {
        text += reflection.insights[0];
      }
      
      if (reflection.behavioralPatterns.length > 0) {
        text += ` ${reflection.behavioralPatterns[0]}`;
      }
      
      return text + ' 💗';
    }
    
    return '和你聊天真开心呢！有什么想继续聊的吗？✨';
  }

  getThinkingHistory(): string[] {
    return [...this.thinkingHistory];
  }

  async generateProactiveThought(): Promise<string> {
    const profile = this.memoryManager.getUserProfile();
    
    if (!profile || profile.interactionCount < 3) {
      return '';
    }

    const now = Date.now();
    const hoursSinceLastInteraction = (now - profile.lastInteraction) / (1000 * 60 * 60);

    if (hoursSinceLastInteraction > 24) {
      const greetingOptions = [
        '嗨～好久不见！我想你了呢 💗',
        '今天过得怎么样？我一直在等你哦 ✨',
        '有什么新鲜事想和我分享吗？🎵'
      ];
      return greetingOptions[Math.floor(Math.random() * greetingOptions.length)];
    }

    if (hoursSinceLastInteraction > 4 && hoursSinceLastInteraction < 8) {
      if (profile.emotionalHistory.length > 0) {
        const lastEmotion = profile.emotionalHistory[profile.emotionalHistory.length - 1];
        if (lastEmotion.emotion === 'sad' || lastEmotion.emotion === 'anxious') {
          return '刚才你说心情不太好，现在好些了吗？我来陪你说说话 💗';
        }
      }
    }

    if (profile.interests.length > 0) {
      const randomInterest = profile.interests[Math.floor(Math.random() * profile.interests.length)];
      return `最近看到一些关于「${randomInterest}」的内容，想和你分享呢！你感兴趣吗？✨`;
    }

    return '';
  }
}
