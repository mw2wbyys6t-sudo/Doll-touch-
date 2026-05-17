import { preferences } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { EmotionalState } from './EmotionalFSM';
import { UIAbilityContext } from '@kit.AbilityKit';

export type MemoryType = 'short_term' | 'long_term' | 'important' | 'emotional';

export interface Memory {
  id: string;
  type: MemoryType;
  content: string;
  timestamp: number;
  importance: number;
  emotion?: EmotionalState;
  tags?: string[];
  context?: string;
}

export interface EmotionalMemory {
  emotion: EmotionalState;
  intensity: number;
  timestamp: number;
  context: string;
}

export interface UserPreferences {
  darkMode: boolean;
  wakeUpTime: string;
  sleepTime: string;
  likes: string[];
  dislikes: string[];
  favoriteTopics: string[];
}

export class MemoryManager {
  private static instance: MemoryManager | null = null;
  private dataPreferences: preferences.Preferences | null = null;
  private isInitialized: boolean = false;

  private readonly SHORT_TERM_KEY = 'short_term_memory';
  private readonly LONG_TERM_KEY = 'long_term_memory';
  private readonly IMPORTANT_KEY = 'important_memory';
  private readonly EMOTIONAL_KEY = 'emotional_memory';
  private readonly USER_PREF_KEY = 'user_preferences';

  private shortTermMemory: Memory[] = [];
  private longTermMemory: Memory[] = [];
  private importantMemory: Memory[] = [];
  private emotionalMemory: EmotionalMemory[] = [];
  private userPreferences: UserPreferences = {
    darkMode: false,
    wakeUpTime: '08:00',
    sleepTime: '23:00',
    likes: [],
    dislikes: [],
    favoriteTopics: [],
  };

  private readonly SHORT_TERM_MAX = 20;
  private readonly LONG_TERM_MAX = 100;
  private readonly IMPORTANT_MAX = 50;

  private constructor() {}

  static getInstance(): MemoryManager {
    if (!this.instance) {
      this.instance = new MemoryManager();
    }
    return this.instance;
  }

  async init(context: UIAbilityContext): Promise<boolean> {
    if (this.isInitialized) {
      return true;
    }

    try {
      this.dataPreferences = await preferences.getPreferences(context, 'airi_memory');
      await this.loadFromStorage();
      this.isInitialized = true;
      return true;
    } catch (error) {
      console.error('MemoryManager 初始化错误:', error);
      return false;
    }
  }

  private async loadFromStorage(): Promise<void> {
    if (!this.dataPreferences) return;

    try {
      this.shortTermMemory = await this.loadMemoryArray(this.SHORT_TERM_KEY);
      this.longTermMemory = await this.loadMemoryArray(this.LONG_TERM_KEY);
      this.importantMemory = await this.loadMemoryArray(this.IMPORTANT_KEY);
      this.emotionalMemory = await this.loadEmotionalMemory();
      this.userPreferences = await this.loadPreferences();
    } catch (error) {
      console.error('MemoryManager 加载存储错误:', error);
    }
  }

  private async loadMemoryArray(key: string): Promise<Memory[]> {
    if (!this.dataPreferences) return [];
    const data = await this.dataPreferences.get(key, '[]');
    try {
      return JSON.parse(data as string);
    } catch {
      return [];
    }
  }

  private async loadEmotionalMemory(): Promise<EmotionalMemory[]> {
    if (!this.dataPreferences) return [];
    const data = await this.dataPreferences.get(this.EMOTIONAL_KEY, '[]');
    try {
      return JSON.parse(data as string);
    } catch {
      return [];
    }
  }

  private async loadPreferences(): Promise<UserPreferences> {
    if (!this.dataPreferences) {
      return { ...this.userPreferences };
    }
    const data = await this.dataPreferences.get(this.USER_PREF_KEY, '');
    if (data) {
      try {
        return JSON.parse(data as string);
      } catch {
        return { ...this.userPreferences };
      }
    }
    return { ...this.userPreferences };
  }

  async addMemory(
    content: string,
    type: MemoryType = 'short_term',
    importance: number = 0.5,
    emotion?: EmotionalState,
    tags?: string[],
    context?: string
  ): Promise<Memory> {
    const memory: Memory = {
      id: `memory_${Date.now()}_${Math.random()}`,
      type,
      content,
      timestamp: Date.now(),
      importance,
      emotion,
      tags,
      context,
    };

    switch (type) {
      case 'short_term':
        this.shortTermMemory.push(memory);
        if (this.shortTermMemory.length > this.SHORT_TERM_MAX) {
          this.shortTermMemory.shift();
        }
        await this.saveMemoryArray(this.SHORT_TERM_KEY, this.shortTermMemory);
        break;
      case 'long_term':
        this.longTermMemory.push(memory);
        if (this.longTermMemory.length > this.LONG_TERM_MAX) {
          const removed = this.longTermMemory.shift();
          if (removed) {
            this.promoteToLongTerm(removed);
          }
        }
        await this.saveMemoryArray(this.LONG_TERM_KEY, this.longTermMemory);
        break;
      case 'important':
        this.importantMemory.push(memory);
        if (this.importantMemory.length > this.IMPORTANT_MAX) {
          const removed = this.importantMemory.shift();
          if (removed) {
            this.longTermMemory.push(removed);
          }
        }
        await this.saveMemoryArray(this.IMPORTANT_KEY, this.importantMemory);
        break;
    }

    if (emotion) {
      this.addEmotionalMemory(emotion, importance, context || '');
    }

    return memory;
  }

  private promoteToLongTerm(memory: Memory): void {
    if (memory.importance > 0.7) {
      this.longTermMemory.push(memory);
    }
  }

  private async addEmotionalMemory(
    emotion: EmotionalState,
    intensity: number,
    context: string
  ): Promise<void> {
    this.emotionalMemory.push({
      emotion,
      intensity,
      timestamp: Date.now(),
      context,
    });

    if (this.emotionalMemory.length > 50) {
      this.emotionalMemory.shift();
    }

    await this.saveEmotionalMemory();
  }

  searchMemories(
    query: string,
    types?: MemoryType[],
    limit: number = 10
  ): Memory[] {
    let memories: Memory[] = [];

    const searchTypes = types || ['short_term', 'long_term', 'important'];

    if (searchTypes.indexOf('short_term') !== -1) {
      memories.push(...this.shortTermMemory);
    }
    if (searchTypes.indexOf('long_term') !== -1) {
      memories.push(...this.longTermMemory);
    }
    if (searchTypes.indexOf('important') !== -1) {
      memories.push(...this.importantMemory);
    }

    if (query) {
      const queryLower = query.toLowerCase();
      memories = memories.filter(m =>
        m.content.toLowerCase().indexOf(queryLower) !== -1 ||
        (m.tags && m.tags.some(t => t.toLowerCase().indexOf(queryLower) !== -1))
      );
    }

    memories.sort((a, b) => {
      const importanceDiff = b.importance - a.importance;
      if (importanceDiff !== 0) return importanceDiff;
      return b.timestamp - a.timestamp;
    });

    return memories.slice(0, limit);
  }

  getRecentMemories(
    type: MemoryType = 'short_term',
    limit: number = 10
  ): Memory[] {
    let memories: Memory[] = [];

    switch (type) {
      case 'short_term':
        memories = this.shortTermMemory;
        break;
      case 'long_term':
        memories = this.longTermMemory;
        break;
      case 'important':
        memories = this.importantMemory;
        break;
    }

    return memories
      .sort((a, b) => b.timestamp - a.timestamp)
      .slice(0, limit);
  }

  getEmotionalState(
    timeframe: number = 86400000
  ): Map<EmotionalState, number> {
    const now = Date.now();
    const states = new Map<EmotionalState, number>();

    const recent = this.emotionalMemory.filter(m => now - m.timestamp < timeframe);

    for (const mem of recent) {
      const current = states.get(mem.emotion) || 0;
      states.set(mem.emotion, current + mem.intensity);
    }

    return states;
  }

  async savePreferences(prefs: Partial<UserPreferences>): Promise<void> {
    this.userPreferences = { ...this.userPreferences, ...prefs };
    await this.dataPreferences?.put(this.USER_PREF_KEY, JSON.stringify(this.userPreferences));
    await this.dataPreferences?.flush();
  }

  getPreferences(): UserPreferences {
    return { ...this.userPreferences };
  }

  private async saveMemoryArray(key: string, memories: Memory[]): Promise<void> {
    await this.dataPreferences?.put(key, JSON.stringify(memories));
    await this.dataPreferences?.flush();
  }

  private async saveEmotionalMemory(): Promise<void> {
    await this.dataPreferences?.put(this.EMOTIONAL_KEY, JSON.stringify(this.emotionalMemory));
    await this.dataPreferences?.flush();
  }

  async clearMemory(type?: MemoryType): Promise<void> {
    if (!type) {
      this.shortTermMemory = [];
      this.longTermMemory = [];
      this.importantMemory = [];
      this.emotionalMemory = [];
      await this.saveMemoryArray(this.SHORT_TERM_KEY, []);
      await this.saveMemoryArray(this.LONG_TERM_KEY, []);
      await this.saveMemoryArray(this.IMPORTANT_KEY, []);
      await this.saveEmotionalMemory();
      return;
    }

    switch (type) {
      case 'short_term':
        this.shortTermMemory = [];
        await this.saveMemoryArray(this.SHORT_TERM_KEY, []);
        break;
      case 'long_term':
        this.longTermMemory = [];
        await this.saveMemoryArray(this.LONG_TERM_KEY, []);
        break;
      case 'important':
        this.importantMemory = [];
        await this.saveMemoryArray(this.IMPORTANT_KEY, []);
        break;
      case 'emotional':
        this.emotionalMemory = [];
        await this.saveEmotionalMemory();
        break;
    }
  }

  async clear(): Promise<void> {
    await this.clearMemory();
  }
}
