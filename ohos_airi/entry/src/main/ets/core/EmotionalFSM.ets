/**
 * EmotionalFSM - 情绪有限状态机
 * HarmonyOS NEXT ArkTS 实现
 * 管理角色情绪状态转换
 */

import { EmotionStore, EmotionType } from './EmotionStore';
import { Dispatcher } from './Dispatcher';

// FSM 状态类型
export enum FSMState {
  IDLE = 'idle',
  TALKING = 'talking',
  THINKING = 'thinking',
  HAPPY = 'happy',
  SAD = 'sad',
  ANGRY = 'angry',
  EXCITED = 'excited',
  SCARED = 'scared',
  CONFUSED = 'confused',
  SLEEPING = 'sleeping'
}

// 状态转换配置
interface TransitionConfig {
  from: FSMState;
  to: FSMState;
  condition?: (from: FSMState, to: FSMState, context?: Object) => boolean;
  emotion?: EmotionType;
  priority?: number;
}

// 状态锁配置
interface StateLock {
  state: FSMState;
  reason: string;
  timeout: number;
  startTime: number;
}

// 观察者类
export class EmotionalFSM {
  // 单例实例
  private static instance: EmotionalFSM | null = null;

  // 当前状态
  private _currentState: FSMState = FSMState.IDLE;

  // 上一个状态
  private _previousState: FSMState = FSMState.IDLE;

  // 状态持续时间
  private _stateDuration: number = 0;

  // 状态进入时间戳
  private _stateEnterTime: number = 0;

  // 状态锁列表
  private _activeLocks: StateLock[] = [];

  // 状态历史记录
  private _stateHistory: Array<{ state: FSMState; timestamp: number }> = [];

  // 最大历史记录数
  private readonly MAX_HISTORY_SIZE: number = 50;

  // 状态转换配置
  private _transitions: TransitionConfig[] = [];

  // 状态持续时间监控定时器
  private durationTimerId: number | null = null;

  // 事件分发器
  private dispatcher: Dispatcher;

  // 情绪存储
  private emotionStore: EmotionStore;

  /**
   * 获取单例实例
   */
  public static getInstance(): EmotionalFSM {
    if (EmotionalFSM.instance === null) {
      EmotionalFSM.instance = new EmotionalFSM();
    }
    return EmotionalFSM.instance;
  }

  /**
   * 私有构造函数
   */
  private constructor() {
    this.dispatcher = Dispatcher.getInstance();
    this.emotionStore = EmotionStore.getInstance();
    this.initializeTransitions();
    this.startDurationMonitor();
  }

  /**
   * 初始化状态转换规则
   */
  private initializeTransitions(): void {
    // 定义允许的状态转换
    this._transitions = [
      // 从 IDLE 可以转换到任何状态
      { from: FSMState.IDLE, to: FSMState.TALKING, priority: 10 },
      { from: FSMState.IDLE, to: FSMState.THINKING, priority: 10 },
      { from: FSMState.IDLE, to: FSMState.HAPPY, priority: 10 },
      { from: FSMState.IDLE, to: FSMState.SAD, priority: 10 },
      { from: FSMState.IDLE, to: FSMState.ANGRY, priority: 10 },
      { from: FSMState.IDLE, to: FSMState.EXCITED, priority: 10 },
      { from: FSMState.IDLE, to: FSMState.SLEEPING, priority: 10 },

      // 从 TALKING 可以转换到情绪状态或回到 IDLE
      { from: FSMState.TALKING, to: FSMState.IDLE, priority: 8 },
      { from: FSMState.TALKING, to: FSMState.HAPPY, priority: 9 },
      { from: FSMState.TALKING, to: FSMState.SAD, priority: 9 },

      // 从 THINKING 可以转换到情绪状态或回到 IDLE
      { from: FSMState.THINKING, to: FSMState.IDLE, priority: 8 },
      { from: FSMState.THINKING, to: FSMState.EXCITED, priority: 9 },
      { from: FSMState.THINKING, to: FSMState.CONFUSED, priority: 9 },

      // 情绪状态可以转换到其他情绪状态或回到 IDLE
      { from: FSMState.HAPPY, to: FSMState.IDLE, priority: 7 },
      { from: FSMState.HAPPY, to: FSMState.EXCITED, priority: 8 },

      { from: FSMState.SAD, to: FSMState.IDLE, priority: 7 },
      { from: FSMState.SAD, to: FSMState.SCARED, priority: 8 },

      { from: FSMState.ANGRY, to: FSMState.IDLE, priority: 7 },
      { from: FSMState.ANGRY, to: FSMState.TALKING, priority: 8 },

      { from: FSMState.EXCITED, to: FSMState.IDLE, priority: 7 },
      { from: FSMState.EXCITED, to: FSMState.HAPPY, priority: 8 },

      { from: FSMState.SCARED, to: FSMState.IDLE, priority: 7 },
      { from: FSMState.SCARED, to: FSMState.SAD, priority: 8 },

      { from: FSMState.CONFUSED, to: FSMState.IDLE, priority: 7 },
      { from: FSMState.CONFUSED, to: FSMState.THINKING, priority: 8 },

      // 睡眠状态
      { from: FSMState.SLEEPING, to: FSMState.IDLE, priority: 5 },

      // 任何状态都可以紧急转换到睡眠（低优先级）
      { from: FSMState.IDLE, to: FSMState.SLEEPING, priority: 1 },
      { from: FSMState.TALKING, to: FSMState.SLEEPING, priority: 1 },
      { from: FSMState.THINKING, to: FSMState.SLEEPING, priority: 1 },
    ];
  }

  /**
   * 获取当前状态
   */
  public get currentState(): FSMState {
    return this._currentState;
  }

  /**
   * 获取上一个状态
   */
  public get previousState(): FSMState {
    return this._previousState;
  }

  /**
   * 获取状态持续时间
   */
  public get stateDuration(): number {
    return this._stateDuration;
  }

  /**
   * 获取活动锁
   */
  public get activeLocks(): StateLock[] {
    return this._activeLocks;
  }

  /**
   * 获取状态历史
   */
  public get stateHistory(): Array<{ state: FSMState; timestamp: number }> {
    return this._stateHistory;
  }

  /**
   * 转换到目标状态
   * @param targetState 目标状态
   * @param force 是否强制转换（可突破锁）
   * @param context 转换上下文
   */
  public transitionTo(targetState: FSMState, force: boolean = false, context?: Object): boolean {
    // 检查是否有锁
    if (!force && this.hasActiveLock()) {
      const lock = this._activeLocks[0];
      console.info(`[EmotionalFSM] 状态转换被锁定: ${lock.reason}, 锁定状态: ${lock.state}`);

      this.dispatcher.emit('fsm:transitionBlocked', {
        from: this._currentState,
        to: targetState,
        reason: lock.reason
      });

      return false;
    }

    // 检查是否允许转换
    if (!this.canTransition(this._currentState, targetState)) {
      console.warn(`[EmotionalFSM] 不允许的状态转换: ${this._currentState} -> ${targetState}`);

      this.dispatcher.emit('fsm:transitionInvalid', {
        from: this._currentState,
        to: targetState
      });

      return false;
    }

    // 执行转换
    const oldState = this._currentState;
    this._previousState = oldState;
    this._currentState = targetState;
    this._stateEnterTime = Date.now();
    this._stateDuration = 0;

    // 添加到历史记录
    this.addToHistory(targetState);

    // 根据状态设置情绪
    this.syncEmotionWithState(targetState);

    // 发送事件
    this.dispatcher.emit('fsm:stateChanged', {
      from: oldState,
      to: targetState,
      context: context
    });

    console.info(`[EmotionalFSM] 状态转换: ${oldState} -> ${targetState}`);

    return true;
  }

  /**
   * 检查是否可以从一个状态转换到另一个状态
   */
  public canTransition(from: FSMState, to: FSMState): boolean {
    // 相同状态不需要转换
    if (from === to) {
      return false;
    }

    // 查找转换规则
    for (const transition of this._transitions) {
      if (transition.from === from && transition.to === to) {
        // 如果有条件，检查条件
        if (transition.condition) {
          return transition.condition(from, to);
        }
        return true;
      }
    }

    return false;
  }

  /**
   * 获取可转换的目标状态列表
   */
  public getAvailableTransitions(): FSMState[] {
    const available: FSMState[] = [];

    for (const transition of this._transitions) {
      if (transition.from === this._currentState) {
        available.push(transition.to);
      }
    }

    return available;
  }

  /**
   * 添加状态锁
   * @param state 锁定的状态
   * @param reason 锁定原因
   * @param timeout 超时时间（毫秒）
   */
  public addLock(state: FSMState, reason: string, timeout: number = 0): void {
    const lock: StateLock = {
      state: state,
      reason: reason,
      timeout: timeout,
      startTime: Date.now()
    };

    this._activeLocks.push(lock);

    console.info(`[EmotionalFSM] 添加状态锁: ${state}, 原因: ${reason}, 超时: ${timeout}ms`);

    this.dispatcher.emit('fsm:lockAdded', {
      state: state,
      reason: reason,
      timeout: timeout
    });

    // 如果设置了超时
    if (timeout > 0) {
      setTimeout(() => {
        this.removeLock(state);
      }, timeout);
    }
  }

  /**
   * 移除状态锁
   * @param state 要移除锁的状态（不传则移除所有）
   */
  public removeLock(state?: FSMState): void {
    if (state !== undefined) {
      const index = this._activeLocks.findIndex(lock => lock.state === state);
      if (index !== -1) {
        const removed = this._activeLocks.splice(index, 1)[0];
        console.info(`[EmotionalFSM] 移除状态锁: ${removed.state}, 原因: ${removed.reason}`);

        this.dispatcher.emit('fsm:lockRemoved', {
          state: removed.state,
          reason: removed.reason
        });
      }
    } else {
      // 移除所有锁
      const count = this._activeLocks.length;
      this._activeLocks = [];
      console.info(`[EmotionalFSM] 移除所有状态锁, 数量: ${count}`);

      this.dispatcher.emit('fsm:lockRemoved', {
        count: count
      });
    }
  }

  /**
   * 检查是否有活动锁
   */
  public hasActiveLock(): boolean {
    // 清理过期锁
    this.cleanupExpiredLocks();
    return this._activeLocks.length > 0;
  }

  /**
   * 清理过期的锁
   */
  private cleanupExpiredLocks(): void {
    const now = Date.now();
    const expired = this._activeLocks.filter(
      lock => lock.timeout > 0 && now - lock.startTime > lock.timeout
    );

    for (const lock of expired) {
      const index = this._activeLocks.findIndex(l => l.state === lock.state);
      if (index !== -1) {
        this._activeLocks.splice(index, 1);
        console.info(`[EmotionalFSM] 自动移除过期锁: ${lock.state}`);
      }
    }
  }

  /**
   * 添加到状态历史
   */
  private addToHistory(state: FSMState): void {
    this._stateHistory.push({
      state: state,
      timestamp: Date.now()
    });

    // 限制历史记录数量
    if (this._stateHistory.length > this.MAX_HISTORY_SIZE) {
      this._stateHistory.shift();
    }
  }

  /**
   * 同步情绪和状态
   */
  private syncEmotionWithState(state: FSMState): void {
    let emotion: EmotionType = EmotionType.NEUTRAL;
    let priority: number = 50;

    switch (state) {
      case FSMState.IDLE:
        emotion = EmotionType.IDLE;
        priority = 50;
        break;
      case FSMState.TALKING:
        emotion = EmotionType.NEUTRAL;
        priority = 30;
        break;
      case FSMState.THINKING:
        emotion = EmotionType.CONFUSED;
        priority = 40;
        break;
      case FSMState.HAPPY:
        emotion = EmotionType.HAPPY;
        priority = 80;
        break;
      case FSMState.SAD:
        emotion = EmotionType.SAD;
        priority = 80;
        break;
      case FSMState.ANGRY:
        emotion = EmotionType.ANGRY;
        priority = 90;
        break;
      case FSMState.EXCITED:
        emotion = EmotionType.EXCITED;
        priority = 90;
        break;
      case FSMState.SCARED:
        emotion = EmotionType.FEARFUL;
        priority = 80;
        break;
      case FSMState.CONFUSED:
        emotion = EmotionType.CONFUSED;
        priority = 60;
        break;
      case FSMState.SLEEPING:
        emotion = EmotionType.TIRED;
        priority = 100;
        break;
    }

    // 设置情绪（强制）
    this.emotionStore.setEmotion(emotion, priority, true);
  }

  /**
   * 开始持续时间监控
   */
  private startDurationMonitor(): void {
    if (this.durationTimerId !== null) {
      clearInterval(this.durationTimerId);
    }

    this.durationTimerId = setInterval(() => {
      if (this._stateEnterTime > 0) {
        this._stateDuration = Date.now() - this._stateEnterTime;
      }
    }, 100) as unknown as number;
  }

  /**
   * 重置到 IDLE 状态
   */
  public resetToIdle(): void {
    this.transitionTo(FSMState.IDLE, true);
    this.removeLock();
    this._stateHistory = [];
  }

  /**
   * 获取状态信息摘要
   */
  public getStateSummary(): Object {
    return {
      currentState: this._currentState,
      previousState: this._previousState,
      stateDuration: this._stateDuration,
      activeLocks: this._activeLocks,
      historyLength: this._stateHistory.length
    };
  }

  /**
   * 销毁（用于测试或完全清理）
   */
  public destroy(): void {
    if (this.durationTimerId !== null) {
      clearInterval(this.durationTimerId);
      this.durationTimerId = null;
    }

    this._activeLocks = [];
    this._stateHistory = [];
    EmotionalFSM.instance = null;
  }
}

// 导出单例快捷访问
export const emotionalFSM = EmotionalFSM.getInstance();
