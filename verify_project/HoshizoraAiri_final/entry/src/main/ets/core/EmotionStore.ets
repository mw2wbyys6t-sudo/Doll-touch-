/**
 * EmotionStore - 情绪存储管理器
 * HarmonyOS NEXT ArkTS 实现
 * 用于管理角色情绪状态和权重
 */

import { Dispatcher } from './Dispatcher';

// 情绪类型枚举
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

// 情绪配置接口
interface EmotionConfig {
  type: EmotionType;
  weight: number;
  maxWeight: number;
  minWeight: number;
  decayRate: number;
  timestamp: number;
}

// 情绪状态接口
interface EmotionState {
  currentEmotion: EmotionType;
  emotionWeights: Map<EmotionType, EmotionConfig>;
  isLocked: boolean;
  lockReason: string;
}

// 观察者类
@Observed
export class EmotionStore {
  // 单例实例
  private static instance: EmotionStore | null = null;

  // 当前主要情绪
  @Track
  private _currentEmotion: EmotionType = EmotionType.IDLE;

  // 情绪权重映射
  @Track
  private _emotionWeights: Map<EmotionType, number> = new Map();

  // 情绪最大权重
  private readonly MAX_WEIGHT: number = 100;

  // 情绪最小权重
  private readonly MIN_WEIGHT: number = 0;

  // 默认衰减率
  private readonly DEFAULT_DECAY_RATE: number = 5;

  // 衰减定时器ID
  private decayTimerId: number | null = null;

  // 是否正在衰减
  private _isDecaying: boolean = false;

  // 是否被锁定
  @Track
  private _isLocked: boolean = false;

  // 锁定原因
  @Track
  private _lockReason: string = '';

  // 事件分发器
  private dispatcher: Dispatcher;

  // 锁定超时（毫秒）
  private lockTimeout: number = 0;

  // 锁定定时器
  private lockTimerId: number | null = null;

  /**
   * 获取单例实例
   */
  public static getInstance(): EmotionStore {
    if (EmotionStore.instance === null) {
      EmotionStore.instance = new EmotionStore();
    }
    return EmotionStore.instance;
  }

  /**
   * 私有构造函数
   */
  private constructor() {
    this.dispatcher = Dispatcher.getInstance();
    this.initializeEmotions();
  }

  /**
   * 初始化所有情绪
   */
  private initializeEmotions(): void {
    const emotions = Object.values(EmotionType);
    for (const emotion of emotions) {
      this._emotionWeights.set(emotion, 0);
    }
    // 默认idle情绪为50
    this._emotionWeights.set(EmotionType.IDLE, 50);
    this._currentEmotion = EmotionType.IDLE;
  }

  /**
   * 获取当前主要情绪（只读）
   */
  public get currentEmotion(): EmotionType {
    return this._currentEmotion;
  }

  /**
   * 获取所有情绪权重（只读）
   */
  public get emotionWeights(): Map<EmotionType, number> {
    return this._emotionWeights;
  }

  /**
   * 获取指定情绪的权重
   * @param emotion 情绪类型
   */
  public getEmotionWeight(emotion: EmotionType): number {
    return this._emotionWeights.get(emotion) ?? 0;
  }

  /**
   * 获取当前是否正在衰减
   */
  public get isDecaying(): boolean {
    return this._isDecaying;
  }

  /**
   * 获取锁定状态
   */
  public get isLocked(): boolean {
    return this._isLocked;
  }

  /**
   * 获取锁定原因
   */
  public get lockReason(): string {
    return this._lockReason;
  }

  /**
   * 设置情绪（带锁定检查）
   * @param emotion 目标情绪
   * @param weight 权重（可选，默认100）
   * @param force 是否强制设置（可突破锁定）
   */
  public setEmotion(emotion: EmotionType, weight: number = 100, force: boolean = false): void {
    // 检查是否被锁定
    if (this._isLocked && !force) {
      console.info(`[EmotionStore] 情绪被锁定: ${this._lockReason}, 尝试设置 ${emotion} 被拒绝`);
      this.dispatcher.emit('emotion:lockBlocked', {
        emotion: emotion,
        reason: this._lockReason
      });
      return;
    }

    // 限制权重范围
    const clampedWeight = Math.max(this.MIN_WEIGHT, Math.min(this.MAX_WEIGHT, weight));

    // 更新权重
    this._emotionWeights.set(emotion, clampedWeight);

    // 更新当前情绪（如果新情绪权重最高）
    const shouldUpdate = this.shouldUpdateCurrentEmotion(emotion, clampedWeight);
    if (shouldUpdate) {
      const oldEmotion = this._currentEmotion;
      this._currentEmotion = emotion;

      // 发送事件
      this.dispatcher.emit('emotion:changed', {
        oldEmotion: oldEmotion,
        newEmotion: emotion,
        weight: clampedWeight
      });

      console.info(`[EmotionStore] 情绪变化: ${oldEmotion} -> ${emotion}, 权重: ${clampedWeight}`);
    }
  }

  /**
   * 判断是否应该更新当前情绪
   */
  private shouldUpdateCurrentEmotion(emotion: EmotionType, weight: number): boolean {
    // 如果是同一个情绪，检查权重是否显著增加
    if (this._currentEmotion === emotion) {
      const currentWeight = this._emotionWeights.get(emotion) ?? 0;
      return weight > currentWeight + 10; // 权重增加超过10才更新
    }

    // 如果是新情绪，检查权重是否比当前情绪高
    const currentWeight = this._emotionWeights.get(this._currentEmotion) ?? 0;
    return weight > currentWeight;
  }

  /**
   * 增加情绪权重
   * @param emotion 情绪类型
   * @param amount 增加量
   */
  public increaseEmotion(emotion: EmotionType, amount: number): void {
    const currentWeight = this.getEmotionWeight(emotion);
    this.setEmotion(emotion, currentWeight + amount);
  }

  /**
   * 减少情绪权重
   * @param emotion 情绪类型
   * @param amount 减少量
   */
  public decreaseEmotion(emotion: EmotionType, amount: number): void {
    const currentWeight = this.getEmotionWeight(emotion);
    this.setEmotion(emotion, Math.max(this.MIN_WEIGHT, currentWeight - amount));
  }

  /**
   * 情绪衰减
   * @param rate 衰减率（可选，默认5）
   * @param interval 衰减间隔（毫秒，可选，默认1000）
   */
  public startDecay(rate: number = this.DEFAULT_DECAY_RATE, interval: number = 1000): void {
    // 如果已经在衰减，先停止
    if (this._isDecaying) {
      this.stopDecay();
    }

    this._isDecaying = true;
    console.info(`[EmotionStore] 开始情绪衰减, 速率: ${rate}/s, 间隔: ${interval}ms`);

    this.decayTimerId = setInterval(() => {
      this.performDecay(rate);
    }, interval) as unknown as number;
  }

  /**
   * 执行一次衰减
   */
  private performDecay(rate: number): void {
    let hasChange = false;

    // 遍历所有情绪
    this._emotionWeights.forEach((weight, emotion) => {
      if (emotion === this._currentEmotion) {
        // 当前情绪衰减较慢
        const newWeight = Math.max(0, weight - rate * 0.5);
        if (newWeight !== weight) {
          this._emotionWeights.set(emotion, newWeight);
          hasChange = true;
        }
      } else if (emotion === EmotionType.IDLE) {
        // IDLE情绪不衰减
        return;
      } else {
        // 其他情绪正常衰减
        const newWeight = Math.max(0, weight - rate);
        if (newWeight !== weight) {
          this._emotionWeights.set(emotion, newWeight);
          hasChange = true;
        }
      }
    });

    // 检查是否需要切换回IDLE
    const currentWeight = this._emotionWeights.get(this._currentEmotion) ?? 0;
    if (currentWeight <= 10 && this._currentEmotion !== EmotionType.IDLE) {
      this._currentEmotion = EmotionType.IDLE;
      hasChange = true;

      this.dispatcher.emit('emotion:changed', {
        oldEmotion: this._currentEmotion,
        newEmotion: EmotionType.IDLE,
        reason: 'weight_too_low'
      });
    }

    // 如果所有情绪都衰减到0，停止衰减
    if (!hasChange && currentWeight <= 10) {
      this.stopDecay();
    }
  }

  /**
   * 停止衰减
   */
  public stopDecay(): void {
    if (this.decayTimerId !== null) {
      clearInterval(this.decayTimerId);
      this.decayTimerId = null;
    }
    this._isDecaying = false;
    console.info('[EmotionStore] 停止情绪衰减');
  }

  /**
   * 锁定情绪状态
   * @param reason 锁定原因
   * @param timeout 超时时间（毫秒，0表示永久）
   */
  public lock(reason: string, timeout: number = 0): void {
    this._isLocked = true;
    this._lockReason = reason;

    console.info(`[EmotionStore] 情绪已锁定: ${reason}, 超时: ${timeout}ms`);

    // 如果设置了超时
    if (timeout > 0) {
      if (this.lockTimerId !== null) {
        clearTimeout(this.lockTimerId);
      }
      this.lockTimerId = setTimeout(() => {
        this.unlock();
      }, timeout) as unknown as number;
    }

    this.dispatcher.emit('emotion:locked', {
      reason: reason,
      timeout: timeout
    });
  }

  /**
   * 解锁情绪状态
   */
  public unlock(): void {
    if (this._isLocked) {
      const oldReason = this._lockReason;
      this._isLocked = false;
      this._lockReason = '';

      if (this.lockTimerId !== null) {
        clearTimeout(this.lockTimerId);
        this.lockTimerId = null;
      }

      console.info(`[EmotionStore] 情绪已解锁: ${oldReason}`);

      this.dispatcher.emit('emotion:unlocked', {
        reason: oldReason
      });
    }
  }

  /**
   * 重置所有情绪
   */
  public reset(): void {
    this.stopDecay();
    this.unlock();
    this.initializeEmotions();

    console.info('[EmotionStore] 情绪已重置');

    this.dispatcher.emit('emotion:reset', {});
  }

  /**
   * 获取当前状态摘要
   */
  public getStateSummary(): EmotionState {
    return {
      currentEmotion: this._currentEmotion,
      emotionWeights: this._emotionWeights,
      isLocked: this._isLocked,
      lockReason: this._lockReason
    };
  }

  /**
   * 获取主要情绪及其权重
   */
  public getTopEmotions(count: number = 3): Array<{ emotion: EmotionType; weight: number }> {
    const emotions: Array<{ emotion: EmotionType; weight: number }> = [];

    this._emotionWeights.forEach((weight, emotion) => {
      emotions.push({ emotion: emotion, weight: weight });
    });

    // 按权重排序
    emotions.sort((a, b) => b.weight - a.weight);

    // 返回前N个
    return emotions.slice(0, count);
  }

  /**
   * 销毁（用于测试或完全清理）
   */
  public destroy(): void {
    this.stopDecay();
    this.unlock();
    this._emotionWeights.clear();
    EmotionStore.instance = null;
  }
}

// 导出单例快捷访问
export const emotionStore = EmotionStore.getInstance();
