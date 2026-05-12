/**
 * EmotionStore - 情绪存储管理器
 * HarmonyOS NEXT ArkTS 标准实现
 */

import { Dispatcher } from './Dispatcher';

export enum EmotionType {
  IDLE = 'idle',
  HAPPY = 'happy',
  SAD = 'sad',
  ANGRY = 'angry',
  FEARFUL = 'fearful',
  SURPRISED = 'surprised',
  EXCITED = 'excited',
  ANXIOUS = 'anxious',
  SHY = 'shy',
  EMBARRASSED = 'embarrassed',
  TIRED = 'tired',
  CONFUSED = 'confused',
  NEUTRAL = 'neutral'
}

@Observed
export class EmotionStore {
  private static instance: EmotionStore | null = null;

  @Track
  private _currentEmotion: EmotionType = EmotionType.IDLE;

  @Track
  private _emotionWeights: Map<EmotionType, number> = new Map();

  @Track
  private _isLocked: boolean = false;

  @Track
  private _lockReason: string = '';

  private readonly MAX_WEIGHT: number = 100;
  private readonly MIN_WEIGHT: number = 0;
  private readonly DEFAULT_DECAY_RATE: number = 5;

  private decayTimerId: number | null = null;
  private _isDecaying: boolean = false;
  private lockTimerId: number | null = null;

  private dispatcher: Dispatcher;

  public static getInstance(): EmotionStore {
    if (EmotionStore.instance === null) {
      EmotionStore.instance = new EmotionStore();
    }
    return EmotionStore.instance;
  }

  private constructor() {
    this.dispatcher = Dispatcher.getInstance();
    this.initializeEmotions();
  }

  private initializeEmotions(): void {
    const emotions = Object.values(EmotionType);
    for (const emotion of emotions) {
      this._emotionWeights.set(emotion, 0);
    }
    this._emotionWeights.set(EmotionType.IDLE, 50);
    this._currentEmotion = EmotionType.IDLE;
  }

  public get currentEmotion(): EmotionType {
    return this._currentEmotion;
  }

  public get emotionWeights(): Map<EmotionType, number> {
    return this._emotionWeights;
  }

  public get isDecaying(): boolean {
    return this._isDecaying;
  }

  public get isLocked(): boolean {
    return this._isLocked;
  }

  public get lockReason(): string {
    return this._lockReason;
  }

  public getEmotionWeight(emotion: EmotionType): number {
    return this._emotionWeights.get(emotion) ?? 0;
  }

  public setEmotion(emotion: EmotionType, weight: number = 100, force: boolean = false): void {
    if (this._isLocked && !force) {
      console.info(`[EmotionStore] 情绪被锁定: ${this._lockReason}`);
      return;
    }

    const clampedWeight = Math.max(this.MIN_WEIGHT, Math.min(this.MAX_WEIGHT, weight));
    this._emotionWeights.set(emotion, clampedWeight);

    const oldEmotion = this._currentEmotion;
    this._currentEmotion = emotion;

    this.dispatcher.emit('emotion:changed', {
      oldEmotion: oldEmotion,
      newEmotion: emotion,
      weight: clampedWeight
    });

    console.info(`[EmotionStore] 情绪变化: ${oldEmotion} -> ${emotion}`);
  }

  public increaseEmotion(emotion: EmotionType, amount: number): void {
    const currentWeight = this.getEmotionWeight(emotion);
    this.setEmotion(emotion, currentWeight + amount);
  }

  public decreaseEmotion(emotion: EmotionType, amount: number): void {
    const currentWeight = this.getEmotionWeight(emotion);
    this.setEmotion(emotion, Math.max(this.MIN_WEIGHT, currentWeight - amount));
  }

  public startDecay(rate: number = this.DEFAULT_DECAY_RATE, interval: number = 1000): void {
    if (this._isDecaying) {
      this.stopDecay();
    }

    this._isDecaying = true;
    console.info(`[EmotionStore] 开始情绪衰减`);

    this.decayTimerId = setInterval(() => {
      this.performDecay(rate);
    }, interval) as unknown as number;
  }

  private performDecay(rate: number): void {
    let hasChange = false;

    this._emotionWeights.forEach((weight, emotion) => {
      if (emotion === this._currentEmotion) {
        const newWeight = Math.max(0, weight - rate * 0.5);
        if (newWeight !== weight) {
          this._emotionWeights.set(emotion, newWeight);
          hasChange = true;
        }
      } else if (emotion !== EmotionType.IDLE) {
        const newWeight = Math.max(0, weight - rate);
        if (newWeight !== weight) {
          this._emotionWeights.set(emotion, newWeight);
          hasChange = true;
        }
      }
    });

    const currentWeight = this._emotionWeights.get(this._currentEmotion) ?? 0;
    if (currentWeight <= 10 && this._currentEmotion !== EmotionType.IDLE) {
      this._currentEmotion = EmotionType.IDLE;
      hasChange = true;
    }

    if (!hasChange) {
      this.stopDecay();
    }
  }

  public stopDecay(): void {
    if (this.decayTimerId !== null) {
      clearInterval(this.decayTimerId);
      this.decayTimerId = null;
    }
    this._isDecaying = false;
    console.info('[EmotionStore] 停止情绪衰减');
  }

  public lock(reason: string, timeout: number = 0): void {
    this._isLocked = true;
    this._lockReason = reason;
    console.info(`[EmotionStore] 情绪已锁定: ${reason}`);

    if (timeout > 0) {
      if (this.lockTimerId !== null) {
        clearTimeout(this.lockTimerId);
      }
      this.lockTimerId = setTimeout(() => {
        this.unlock();
      }, timeout) as unknown as number;
    }
  }

  public unlock(): void {
    if (this._isLocked) {
      this._isLocked = false;
      this._lockReason = '';

      if (this.lockTimerId !== null) {
        clearTimeout(this.lockTimerId);
        this.lockTimerId = null;
      }

      console.info('[EmotionStore] 情绪已解锁');
    }
  }

  public reset(): void {
    this.stopDecay();
    this.unlock();
    this.initializeEmotions();
    console.info('[EmotionStore] 情绪已重置');
  }

  public getTopEmotions(count: number = 3): Array<{ emotion: EmotionType; weight: number }> {
    const emotions: Array<{ emotion: EmotionType; weight: number }> = [];

    this._emotionWeights.forEach((weight, emotion) => {
      emotions.push({ emotion: emotion, weight: weight });
    });

    emotions.sort((a, b) => b.weight - a.weight);
    return emotions.slice(0, count);
  }

  public destroy(): void {
    this.stopDecay();
    this.unlock();
    this._emotionWeights.clear();
    EmotionStore.instance = null;
  }
}

export const emotionStore = EmotionStore.getInstance();
