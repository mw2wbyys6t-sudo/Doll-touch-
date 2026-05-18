import { BusinessError } from '@kit.BasicServicesKit';
import { EmotionalState } from './EmotionalFSM';
import { AnimationScheduler, createAnimationItem, AnimationPriority } from './AnimationScheduler';

export type VoiceSpeed = 'slow' | 'normal' | 'fast';
export type VoicePitch = 'low' | 'normal' | 'high';

export interface VoiceConfig {
  speed: VoiceSpeed;
  pitch: VoicePitch;
  volume: number;
}

export interface AudioQueueItem {
  id: string;
  text: string;
  config: VoiceConfig;
  emotion: EmotionalState;
  priority: number;
  timestamp: number;
  onStart?: () => void;
  onComplete?: () => void;
  onInterrupt?: () => void;
}

export interface TTSEvent {
  type: 'start' | 'progress' | 'complete' | 'interrupt' | 'error';
  itemId?: string;
  text?: string;
  progress?: number;
  error?: string;
}

export class TTSManager {
  private static instance: TTSManager | null = null;
  private queue: AudioQueueItem[] = [];
  private currentItem: AudioQueueItem | null = null;
  private isPlaying: boolean = false;
  private isInitialized: boolean = false;
  private animationScheduler: AnimationScheduler | null = null;
  private listeners: Array<(event: TTSEvent) => void> = [];
  private queueLock: boolean = false;
  private speakingState: 'idle' | 'speaking' | 'interrupted' = 'idle';

  private constructor() {}

  static getInstance(): TTSManager {
    if (!this.instance) {
      this.instance = new TTSManager();
    }
    return this.instance;
  }

  async init(): Promise<boolean> {
    if (this.isInitialized) {
      return true;
    }

    try {
      this.animationScheduler = AnimationScheduler.getInstance();
      this.isInitialized = true;
      console.info('TTS Manager 初始化完成');
      return true;
    } catch (error) {
      console.error('TTS 初始化错误:', error);
      return false;
    }
  }

  async speak(
    text: string,
    emotion: EmotionalState = 'idle',
    priority: number = 50,
    config: Partial<VoiceConfig> = {}
  ): Promise<string> {
    await this.init();

    const defaultConfig: VoiceConfig = {
      speed: 'normal',
      pitch: 'normal',
      volume: 1.0,
      ...config,
    };

    const item: AudioQueueItem = {
      id: `tts_${Date.now()}_${Math.random()}`,
      text,
      config: defaultConfig,
      emotion,
      priority,
      timestamp: Date.now(),
    };

    await this.enqueue(item);
    return item.id;
  }

  private async enqueue(item: AudioQueueItem): Promise<void> {
    while (this.queueLock) {
      await new Promise(resolve => setTimeout(resolve, 10));
    }

    if (this.currentItem && this.canInterrupt(item.priority)) {
      await this.interruptCurrent();
    }

    this.queueLock = true;
    try {
      const insertIndex = this.findInsertionIndex(item.priority);
      this.queue.splice(insertIndex, 0, item);
      this.queueLock = false;

      if (!this.isPlaying) {
        this.processQueue();
      }
    } catch (error) {
      this.queueLock = false;
      throw error;
    }
  }

  private findInsertionIndex(priority: number): number {
    for (let i = 0; i < this.queue.length; i++) {
      if (priority > this.queue[i].priority) {
        return i;
      }
    }
    return this.queue.length;
  }

  private canInterrupt(newPriority: number): boolean {
    if (!this.currentItem) return false;
    return newPriority > this.currentItem.priority + 20;
  }

  private async interruptCurrent(): Promise<void> {
    if (this.currentItem) {
      this.speakingState = 'interrupted';
      if (this.currentItem.onInterrupt) {
        this.currentItem.onInterrupt();
      }
      this.notifyListeners({ type: 'interrupt', itemId: this.currentItem.id });
      await this.stop();
    }
  }

  private async processQueue(): Promise<void> {
    while (this.queue.length > 0) {
      const item = this.queue.shift()!;
      await this.playItem(item);
    }
    this.isPlaying = false;
  }

  private async playItem(item: AudioQueueItem): Promise<void> {
    this.currentItem = item;
    this.isPlaying = true;
    this.speakingState = 'speaking';

    try {
      this.notifyListeners({
        type: 'start',
        itemId: item.id,
        text: item.text,
      });

      if (item.onStart) {
        item.onStart();
      }

      await this.startLipSync(item.text, item.emotion);

      // 模拟 TTS 播放
      const duration = Math.max(1000, item.text.length * 200);
      await new Promise(resolve => setTimeout(resolve, duration));

      if (item.onComplete) {
        item.onComplete();
      }

      this.notifyListeners({
        type: 'complete',
        itemId: item.id,
      });

    } catch (error) {
      console.error('TTS 播放失败:', error);
      this.notifyListeners({
        type: 'error',
        itemId: item.id,
        error: String(error),
      });
    } finally {
      await this.stopLipSync();
      this.currentItem = null;
      this.speakingState = 'idle';
    }
  }

  private async startLipSync(text: string, emotion: EmotionalState): Promise<void> {
    if (!this.animationScheduler) {
      return;
    }

    const estimatedDuration = Math.max(1000, text.length * 200);

    await this.animationScheduler.enqueue(createAnimationItem(
      'lip_sync',
      'talking',
      AnimationPriority.HIGH,
      estimatedDuration,
      { isTalking: 1 },
      true,
    ));
  }

  private async stopLipSync(): Promise<void> {
    if (!this.animationScheduler) {
      return;
    }
  }

  async stop(): Promise<void> {
    this.isPlaying = false;
    this.speakingState = 'idle';
    this.currentItem = null;
    this.notifyListeners({ type: 'interrupt' });
  }

  clearQueue(): void {
    this.queue = [];
  }

  getCurrentItem(): AudioQueueItem | null {
    return this.currentItem;
  }

  addListener(callback: (event: TTSEvent) => void): void {
    this.listeners.push(callback);
  }

  removeListener(callback: (event: TTSEvent) => void): void {
    this.listeners = this.listeners.filter(l => l !== callback);
  }

  private notifyListeners(event: TTSEvent): void {
    this.listeners.forEach(listener => listener(event));
  }

  isSpeaking(): boolean {
    return this.speakingState === 'speaking';
  }

  getQueueLength(): number {
    return this.queue.length;
  }

  async release(): Promise<void> {
    await this.stop();
    this.clearQueue();
    this.listeners = [];
    this.isInitialized = false;
  }
}
