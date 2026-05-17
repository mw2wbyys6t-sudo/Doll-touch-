import { PreferencesUtil } from './PreferencesUtil';

export interface MemoryItem {
  id: string;
  type: 'short_term' | 'long_term' | 'important';
  content: string;
  timestamp: number;
  importance: number;
  emotion?: string;
  tags?: string[];
  accessCount: number;
  lastAccess: number;
}

export interface UserProfile {
  name?: string;
  preferences: Record<string, any>;
  interests: string[];
  interactionCount: number;
  lastInteraction: number;
  emotionalHistory: EmotionalRecord[];
}

export interface EmotionalRecord {
  timestamp: number;
  emotion: string;
  intensity: number;
  trigger?: string;
}

export class MemoryManager {
  private static instance: MemoryManager | null = null;
  private shortTermMemory: MemoryItem[] = [];
  private longTermMemory: MemoryItem[] = [];
  private importantMemory: MemoryItem[] = [];
  private userProfile: UserProfile | null = null;
  private readonly MAX_SHORT_TERM = 50;
  private readonly MAX_LONG_TERM = 200;

  private constructor() {}

  static getInstance(): MemoryManager {
    if (!this.instance) {
      this.instance = new MemoryManager();
    }
    return this.instance;
  }

  async init(): Promise<void> {
    try {
      const profile = await PreferencesUtil.getObject<UserProfile>('userProfile');
      if (profile) {
        this.userProfile = profile as UserProfile;
      } else {
        this.userProfile = {
          preferences: {},
          interests: [],
          interactionCount: 0,
          lastInteraction: Date.now(),
          emotionalHistory: []
        };
      }

      const shortMemory = await PreferencesUtil.getObject<MemoryItem[]>('shortTermMemory');
      if (shortMemory) {
        this.shortTermMemory = shortMemory as MemoryItem[];
      }

      const longMemory = await PreferencesUtil.getObject<MemoryItem[]>('longTermMemory');
      if (longMemory) {
        this.longTermMemory = longMemory as MemoryItem[];
      }

      const importantMemory = await PreferencesUtil.getObject<MemoryItem[]>('importantMemory');
      if (importantMemory) {
        this.importantMemory = importantMemory as MemoryItem[];
      }

      console.info('MemoryManager initialized successfully');
    } catch (error) {
      console.error('Failed to initialize MemoryManager:', error);
    }
  }

  addMemory(content: string, type: 'short_term' | 'long_term' | 'important', emotion?: string, tags?: string[]): MemoryItem {
    const memory: MemoryItem = {
      id: `mem_${Date.now()}_${Math.random().toString(36).substring(2)}`,
      type,
      content,
      timestamp: Date.now(),
      importance: this.calculateImportance(content, emotion),
      emotion,
      tags,
      accessCount: 0,
      lastAccess: Date.now()
    };

    if (type === 'short_term') {
      this.shortTermMemory.unshift(memory);
      if (this.shortTermMemory.length > this.MAX_SHORT_TERM) {
        this.consolidateToLongTerm();
      }
    } else if (type === 'long_term') {
      this.longTermMemory.unshift(memory);
      if (this.longTermMemory.length > this.MAX_LONG_TERM) {
        this.pruneOldMemories();
      }
    } else {
      this.importantMemory.unshift(memory);
    }

    this.saveMemory();
    return memory;
  }

  private calculateImportance(content: string, emotion?: string): number {
    let importance = 0.5;

    if (emotion) {
      importance += 0.2;
    }

    const keywords = ['喜欢', '讨厌', '想要', '需要', '重要', '生日', '纪念日', '承诺'];
    keywords.forEach(keyword => {
      if (content.indexOf(keyword) !== -1) {
        importance += 0.1;
      }
    });

    if (content.length > 50) {
      importance += 0.1;
    }

    return Math.min(1, importance);
  }

  private consolidateToLongTerm(): void {
    const toKeep = this.shortTermMemory.slice(0, 10);
    const toConsolidate = this.shortTermMemory.slice(10);

    toConsolidate.forEach(memory => {
      if (memory.importance > 0.6) {
        const longTermMemory: MemoryItem = {
          ...memory,
          type: 'long_term'
        };
        this.longTermMemory.unshift(longTermMemory);
      }
    });

    this.shortTermMemory = toKeep;
    this.saveMemory();
  }

  private pruneOldMemories(): void {
    const sorted = [...this.longTermMemory].sort((a, b) => b.lastAccess - a.lastAccess);
    this.longTermMemory = sorted.slice(0, this.MAX_LONG_TERM);
    this.saveMemory();
  }

  async searchMemories(query: string, limit: number = 10): Promise<MemoryItem[]> {
    const queryLower = query.toLowerCase();
    const allMemories = [
      ...this.shortTermMemory,
      ...this.longTermMemory,
      ...this.importantMemory
    ];

    const scored = allMemories.map(memory => {
      let score = 0;
      if (memory.content.toLowerCase().indexOf(queryLower) !== -1) {
        score += 0.5;
      }
      if (memory.tags?.some(tag => tag.toLowerCase().indexOf(queryLower) !== -1)) {
        score += 0.3;
      }

      const recency = 1 - (Date.now() - memory.lastAccess) / (7 * 24 * 60 * 60 * 1000);
      score += recency * 0.2;

      return { memory, score };
    });

    return scored
      .filter(item => item.score > 0)
      .sort((a, b) => b.score - a.score)
      .slice(0, limit)
      .map(item => {
        item.memory.accessCount++;
        item.memory.lastAccess = Date.now();
        return item.memory;
      });
  }

  getRelevantContext(currentTopic: string, limit: number = 5): string {
    const memories = this.shortTermMemory.filter(
      m => m.content.indexOf(currentTopic) !== -1 || m.tags?.some(t => t.indexOf(currentTopic) !== -1)
    ).slice(0, limit);

    if (memories.length === 0) {
      const recentMemories = this.shortTermMemory.slice(0, limit);
      return recentMemories.map(m => m.content).join('; ');
    }

    return memories.map(m => m.content).join('; ');
  }

  updateUserProfile(key: string, value: any): void {
    if (!this.userProfile) return;

    if (key === 'interests' && Array.isArray(value)) {
      this.userProfile.interests = [...new Set([...this.userProfile.interests, ...value])];
    } else if (key === 'emotion' && typeof value === 'object') {
      this.userProfile.emotionalHistory.push(value as EmotionalRecord);
      if (this.userProfile.emotionalHistory.length > 50) {
        this.userProfile.emotionalHistory = this.userProfile.emotionalHistory.slice(-50);
      }
    } else if (key === 'interactionCount') {
      this.userProfile.interactionCount++;
      this.userProfile.lastInteraction = Date.now();
    } else {
      this.userProfile.preferences[key] = value;
    }

    this.saveProfile();
  }

  getUserProfile(): UserProfile | null {
    return this.userProfile;
  }

  private async saveMemory(): Promise<void> {
    try {
      await PreferencesUtil.putObject('shortTermMemory', this.shortTermMemory);
      await PreferencesUtil.putObject('longTermMemory', this.longTermMemory);
      await PreferencesUtil.putObject('importantMemory', this.importantMemory);
    } catch (error) {
      console.error('Failed to save memory:', error);
    }
  }

  private async saveProfile(): Promise<void> {
    try {
      if (this.userProfile) {
        await PreferencesUtil.putObject('userProfile', this.userProfile);
      }
    } catch (error) {
      console.error('Failed to save profile:', error);
    }
  }

  clearShortTerm(): void {
    this.shortTermMemory = [];
    this.saveMemory();
  }

  getMemorySummary(): string {
    const profile = this.userProfile;
    if (!profile) return '';

    let summary = `用户基本信息：`;
    if (profile.name) {
      summary += `名字叫${profile.name}，`;
    }
    summary += `已交互${profile.interactionCount}次，`;

    if (profile.interests.length > 0) {
      summary += `感兴趣的话题包括：${profile.interests.slice(0, 5).join('、')}，`;
    }

    const recentEmotions = profile.emotionalHistory.slice(-5);
    if (recentEmotions.length > 0) {
      const emotionCount: Record<string, number> = {};
      recentEmotions.forEach(e => {
        emotionCount[e.emotion] = (emotionCount[e.emotion] || 0) + 1;
      });
      const dominantEmotion = Object.entries(emotionCount).sort((a, b) => b[1] - a[1])[0];
      if (dominantEmotion) {
        summary += `最近情绪倾向${dominantEmotion[0]}。`;
      }
    }

    return summary;
  }
}
