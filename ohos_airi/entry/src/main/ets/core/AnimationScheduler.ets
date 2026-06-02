import { EmotionalState, EmotionalFSM } from './EmotionalFSM';

// 兼容 HarmonyOS NEXT 的 requestAnimationFrame 替代实现
let rafId = 0;
type FrameRequestCallback = (timestamp: number) => void;
const rafCallbacks = new Map<number, FrameRequestCallback>();

function requestAnimationFrame(callback: FrameRequestCallback): number {
  const id = ++rafId;
  rafCallbacks.set(id, callback);
  setTimeout(() => {
    const cb = rafCallbacks.get(id);
    if (cb) {
      rafCallbacks.delete(id);
      cb(Date.now());
    }
  }, 16);
  return id;
}

function cancelAnimationFrame(id: number): void {
  rafCallbacks.delete(id);
}

export type AnimationType = 'expression' | 'motion' | 'lip_sync' | 'idle';

export interface AnimationQueueItem {
  id: string;
  type: AnimationType;
  name: string;
  priority: number;
  duration: number;
  interruptible: boolean;
  params: Record<string, number>;
  timestamp: number;
  onComplete?: () => void;
  onInterrupt?: () => void;
}

export interface Live2DState {
  currentExpression: string;
  currentMotion: string;
  isTalking: boolean;
  isThinking: boolean;
  lipSyncProgress: number;
  blinkProgress: number;
}

export enum AnimationPriority {
  IDLE = 0,
  BACKGROUND = 10,
  LOW = 30,
  NORMAL = 50,
  HIGH = 70,
  URGENT = 90,
  CRITICAL = 100,
}

export class AnimationScheduler {
  private static instance: AnimationScheduler | null = null;
  private queue: AnimationQueueItem[] = [];
  private currentItem: AnimationQueueItem | null = null;
  private isPlaying: boolean = false;
  private state: Live2DState = {
    currentExpression: 'idle',
    currentMotion: 'idle',
    isTalking: false,
    isThinking: false,
    lipSyncProgress: 0,
    blinkProgress: 0,
  };

  private idleTimer: number = -1;
  private blinkTimer: number = -1;
  private playingAnimationFrame: number = -1;
  private queueLock: boolean = false;

  private readonly TALKING_LOCKED: string[] = ['idle', 'sleeping', 'wave'];
  private readonly THINKING_LOCKED: string[] = ['wave', 'dance', 'jump'];

  private constructor() {}

  static getInstance(): AnimationScheduler {
    if (!this.instance) {
      this.instance = new AnimationScheduler();
    }
    return this.instance;
  }

  async enqueue(item: AnimationQueueItem): Promise<boolean> {
    while (this.queueLock) {
      await new Promise(resolve => setTimeout(resolve, 10));
    }

    if (this.canBeInterrupted(item.priority)) {
      await this.interruptCurrent();
    }

    if (this.isLocked(item)) {
      console.log(`动作 ${item.name} 被当前状态锁定`);
      return false;
    }

    this.queueLock = true;
    try {
      const insertIndex = this.findInsertionIndex(item.priority);
      this.queue.splice(insertIndex, 0, item);
      this.queueLock = false;

      if (!this.isPlaying) {
        this.processQueue();
      }

      return true;
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

  private canBeInterrupted(newPriority: number): boolean {
    if (!this.currentItem) return false;
    if (!this.currentItem.interruptible) return false;
    return newPriority > this.currentItem.priority;
  }

  private isLocked(item: AnimationQueueItem): boolean {
    const fsm = EmotionalFSM.getInstance();
    const state = fsm.currentState;

    if (state === 'talking' && this.TALKING_LOCKED.indexOf(item.name) !== -1) {
      return true;
    }
    if (state === 'thinking' && this.THINKING_LOCKED.indexOf(item.name) !== -1) {
      return true;
    }
    return false;
  }

  private async interruptCurrent(): Promise<void> {
    if (this.currentItem && this.currentItem.onInterrupt) {
      this.currentItem.onInterrupt();
    }
    this.stopAnimation();
  }

  private async processQueue(): Promise<void> {
    while (this.queue.length > 0) {
      const item = this.queue.shift()!;
      await this.playItem(item);
    }
    this.isPlaying = false;
  }

  private async playItem(item: AnimationQueueItem): Promise<void> {
    this.currentItem = item;
    this.isPlaying = true;

    try {
      switch (item.type) {
        case 'expression':
          await this.playExpression(item);
          break;
        case 'motion':
          await this.playMotion(item);
          break;
        case 'lip_sync':
          await this.playLipSync(item);
          break;
        case 'idle':
          await this.playIdle(item);
          break;
      }

      if (item.onComplete) {
        item.onComplete();
      }
    } catch (error) {
      console.error(`Animation ${item.name} failed:`, error);
    } finally {
      this.currentItem = null;
    }
  }

  private playExpression(item: AnimationQueueItem): Promise<void> {
    return new Promise(resolve => {
      this.state.currentExpression = item.name;
      const params = Object.entries(item.params);

      params.forEach(([key, value]) => {
        AppStorage.setOrCreate(key, value);
      });

      setTimeout(() => {
        resolve();
      }, item.duration);
    });
  }

  private playMotion(item: AnimationQueueItem): Promise<void> {
    return new Promise(resolve => {
      this.state.currentMotion = item.name;

      const startTime = Date.now();
      const animate = () => {
        const elapsed = Date.now() - startTime;
        const progress = elapsed / item.duration;

        if (progress < 1) {
          for (const [key, value] of Object.entries(item.params)) {
            AppStorage.setOrCreate(key, value);
          }
          requestAnimationFrame(animate);
        } else {
          resolve();
        }
      };
      animate();
    });
  }

  private playLipSync(item: AnimationQueueItem): Promise<void> {
    return new Promise(resolve => {
      this.state.isTalking = true;
      const startTime = Date.now();
      const animate = () => {
        const elapsed = Date.now() - startTime;
        const progress = elapsed / item.duration;

        if (progress < 1) {
          this.state.lipSyncProgress = Math.sin(progress * Math.PI * 8) * 0.5 + 0.5;
          AppStorage.setOrCreate('mouthOpen', this.state.lipSyncProgress);
          requestAnimationFrame(animate);
        } else {
          this.state.isTalking = false;
          AppStorage.setOrCreate('mouthOpen', 0.1);
          resolve();
        }
      };
      animate();
    });
  }

  private playIdle(item: AnimationQueueItem): Promise<void> {
    return new Promise(resolve => {
      const startTime = Date.now();
      const animate = () => {
        const elapsed = Date.now() - startTime;
        const time = elapsed / 1000;

        const sway = Math.sin(time * 0.5) * 0.02;
        const hairSwing = Math.sin(time * 1.5) * 0.05;

        AppStorage.setOrCreate('bodyAngleY', sway);
        AppStorage.setOrCreate('hairSwing', hairSwing);

        if (elapsed < item.duration) {
          requestAnimationFrame(animate);
        } else {
          resolve();
        }
      };
      animate();
    });
  }

  private stopAnimation(): void {
    if (this.playingAnimationFrame !== -1) {
      cancelAnimationFrame(this.playingAnimationFrame);
      this.playingAnimationFrame = -1;
    }
  }

  startIdleLoop(): void {
    if (this.idleTimer !== -1) {
      clearInterval(this.idleTimer);
    }

    this.idleTimer = setInterval(() => {
      if (!this.isPlaying) {
        this.enqueue({
          id: 'idle_' + Date.now(),
          type: 'idle',
          name: 'idle',
          priority: AnimationPriority.IDLE,
          duration: 3000,
          interruptible: true,
          params: {},
          timestamp: Date.now(),
        });
      }
    }, 3000);

    this.startBlinkLoop();
  }

  private startBlinkLoop(): void {
    if (this.blinkTimer !== -1) {
      clearTimeout(this.blinkTimer);
    }

    const blink = () => {
      const fsm = EmotionalFSM.getInstance();
      const state = fsm.currentState;

      if (state !== 'talking' && state !== 'thinking' && !this.isPlaying) {
        this.enqueue({
          id: 'blink_' + Date.now(),
          type: 'expression',
          name: 'blink',
          priority: AnimationPriority.BACKGROUND,
          duration: 200,
          interruptible: true,
          params: {
            eyeOpen: 0,
          },
          timestamp: Date.now(),
        });
      }

      const nextBlink = 3000 + Math.random() * 3000;
      this.blinkTimer = setTimeout(blink, nextBlink);
    };

    blink();
  }

  getState(): Live2DState {
    return { ...this.state };
  }

  clearQueue(): void {
    this.queue = [];
  }

  async stop(): Promise<void> {
    if (this.idleTimer !== -1) {
      clearInterval(this.idleTimer);
      this.idleTimer = -1;
    }
    if (this.blinkTimer !== -1) {
      clearTimeout(this.blinkTimer);
      this.blinkTimer = -1;
    }
    this.stopAnimation();
    this.queue = [];
    this.isPlaying = false;
    this.currentItem = null;
  }
}

export function createAnimationItem(
  type: AnimationType,
  name: string,
  priority: AnimationPriority,
  duration: number,
  params: Record<string, number> = {},
  interruptible: boolean = true,
): AnimationQueueItem {
  return {
    id: `${type}_${name}_${Date.now()}_${Math.random()}`,
    type,
    name,
    priority,
    duration,
    interruptible,
    params,
    timestamp: Date.now(),
  };
}
