import { tts } from '@kit.AIKit';
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
  private ttsEngine: tts.TtsEngine | null = null;
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
      this.ttsEngine = tts.getTtsEngine();
      if (!this.ttsEngine) {
        console.error('TTS Engine 初始化失败');
        return false;
      }

      await this.ttsEngine.init('com.huawei.hiai.tts');

      const listeners: Record<string, (...args: Object[]) => void> = {
        'initComplete': (err: BusinessError) => {
          console.log('TTS 引擎初始化完成');
        },
        'synthesizeComplete': (err: BusinessError, audioBuffer: ArrayBuffer) => {
          console.log('TTS 合成完成');
        },
        'playStart': () => {
          console.log('TTS 播放开始');
          this.onPlayStart();
        },
        'playPause': () => {
          console.log('TTS 播放暂停');
        },
        'playResume': () => {
          console.log('TTS 播放恢复');
        },
        'playStop': () => {
          console.log('TTS 播放停止');
          this.onPlayComplete();
        },
        'playProgress': (str: string) => {
          console.log('TTS 播放进度', str);
          this.onPlayProgress();
        },
      };

      for (const [key, callback] of Object.entries(listeners)) {
        this.ttsEngine.on(key, callback);
      }

      this.animationScheduler = AnimationScheduler.getInstance();
      this.isInitialized = true;
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
    if (!this.ttsEngine) {
      console.error('TTS Engine 未初始化');
      return;
    }

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

      const ttsParams = this.getTTSParams(item.config, item.emotion);

      await this.ttsEngine.speak(item.text, ttsParams);

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

  private getTTSParams(config: VoiceConfig, emotion: EmotionalState): tts.TtsPlayerParams {
    let speed = 1.0;
    let pitch = 1.0;

    switch (config.speed) {
      case 'slow': speed = 0.8; break;
      case 'fast': speed = 1.2; break;
      default: speed = 1.0;
    }

    switch (config.pitch) {
      case 'low': pitch = 0.8; break;
      case 'high': pitch = 1.2; break;
      default: pitch = 1.0;
    }

    switch (emotion) {
      case 'happy':
        speed *= 1.1;
        pitch *= 1.1;
        break;
      case 'sad':
        speed *= 0.9;
        pitch *= 0.9;
        break;
      case 'excited':
        speed *= 1.2;
        pitch *= 1.15;
        break;
      case 'shy':
        speed *= 0.95;
        pitch *= 1.05;
        break;
      case 'angry':
        speed *= 1.15;
        pitch *= 1.1;
        break;
    }

    return {
      volume: config.volume,
      speed,
      pitch,
      category: tts.Category.TTS_CATEGORY_WAKEUP,
    };
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

  private onPlayStart(): void {
    console.log('TTS 播放开始事件');
  }

  private onPlayComplete(): void {
    console.log('TTS 播放完成事件');
  }

  private onPlayProgress(): void {
  }

  async stop(): Promise<void> {
    if (this.ttsEngine) {
      try {
        this.ttsEngine.stop();
      } catch (error) {
        console.error('TTS Stop 错误:', error);
      }
    }
    this.isPlaying = false;
    this.speakingState = 'idle';
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
    if (this.ttsEngine) {
      try {
        this.ttsEngine.shutdown();
      } catch (error) {
        console.error('TTS 关闭错误:', error);
      }
      this.ttsEngine = null;
    }
    this.isInitialized = false;
  }
}
