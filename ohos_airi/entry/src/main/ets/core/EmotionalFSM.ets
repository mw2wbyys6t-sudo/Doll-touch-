/**
 * EmotionalFSM - 情绪有限状态机
 * HarmonyOS NEXT ArkTS 标准实现
 */

import { Dispatcher } from './Dispatcher';
import { EmotionStore, EmotionType } from './EmotionStore';

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

interface StateLock {
  state: FSMState;
  reason: string;
  timeout: number;
  startTime: number;
}

@Observed
export class EmotionalFSM {
  private static instance: EmotionalFSM | null = null;

  @Track
  private _currentState: FSMState = FSMState.IDLE;

  @Track
  private _previousState: FSMState = FSMState.IDLE;

  @Track
  private _stateDuration: number = 0;

  private _stateEnterTime: number = 0;

  @Track
  private _activeLocks: StateLock[] = [];

  private _stateHistory: Array<{ state: FSMState; timestamp: number }> = [];

  private readonly MAX_HISTORY_SIZE: number = 50;

  private _transitions: Array<{ from: FSMState; to: FSMState; priority: number }> = [];

  private durationTimerId: number | null = null;

  private dispatcher: Dispatcher;
  private emotionStore: EmotionStore;

  public static getInstance(): EmotionalFSM {
    if (EmotionalFSM.instance === null) {
      EmotionalFSM.instance = new EmotionalFSM();
    }
    return EmotionalFSM.instance;
  }

  private constructor() {
    this.dispatcher = Dispatcher.getInstance();
    this.emotionStore = EmotionStore.getInstance();
    this.initializeTransitions();
    this.startDurationMonitor();
  }

  private initializeTransitions(): void {
    this._transitions = [
      { from: FSMState.IDLE, to: FSMState.TALKING, priority: 10 },
      { from: FSMState.IDLE, to: FSMState.THINKING, priority: 10 },
      { from: FSMState.IDLE, to: FSMState.HAPPY, priority: 10 },
      { from: FSMState.IDLE, to: FSMState.SAD, priority: 10 },
      { from: FSMState.IDLE, to: FSMState.ANGRY, priority: 10 },
      { from: FSMState.IDLE, to: FSMState.EXCITED, priority: 10 },
      { from: FSMState.IDLE, to: FSMState.SLEEPING, priority: 10 },
      { from: FSMState.TALKING, to: FSMState.IDLE, priority: 8 },
      { from: FSMState.TALKING, to: FSMState.HAPPY, priority: 9 },
      { from: FSMState.TALKING, to: FSMState.SAD, priority: 9 },
      { from: FSMState.THINKING, to: FSMState.IDLE, priority: 8 },
      { from: FSMState.THINKING, to: FSMState.EXCITED, priority: 9 },
      { from: FSMState.THINKING, to: FSMState.CONFUSED, priority: 9 },
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
      { from: FSMState.SLEEPING, to: FSMState.IDLE, priority: 5 },
    ];
  }

  public get currentState(): FSMState {
    return this._currentState;
  }

  public get previousState(): FSMState {
    return this._previousState;
  }

  public get stateDuration(): number {
    return this._stateDuration;
  }

  public get activeLocks(): StateLock[] {
    return this._activeLocks;
  }

  public transitionTo(targetState: FSMState, force: boolean = false, context?: Object): boolean {
    if (!force && this.hasActiveLock()) {
      const lock = this._activeLocks[0];
      console.info(`[EmotionalFSM] 状态转换被锁定: ${lock.reason}`);
      this.dispatcher.emit('fsm:transitionBlocked', {
        from: this._currentState,
        to: targetState,
        reason: lock.reason
      });
      return false;
    }

    if (!this.canTransition(this._currentState, targetState)) {
      console.warn(`[EmotionalFSM] 不允许的状态转换: ${this._currentState} -> ${targetState}`);
      this.dispatcher.emit('fsm:transitionInvalid', {
        from: this._currentState,
        to: targetState
      });
      return false;
    }

    const oldState = this._currentState;
    this._previousState = oldState;
    this._currentState = targetState;
    this._stateEnterTime = Date.now();
    this._stateDuration = 0;

    this.addToHistory(targetState);
    this.syncEmotionWithState(targetState);

    this.dispatcher.emit('fsm:stateChanged', {
      from: oldState,
      to: targetState,
      context: context
    });

    console.info(`[EmotionalFSM] 状态转换: ${oldState} -> ${targetState}`);
    return true;
  }

  public canTransition(from: FSMState, to: FSMState): boolean {
    if (from === to) {
      return false;
    }

    for (const transition of this._transitions) {
      if (transition.from === from && transition.to === to) {
        return true;
      }
    }

    return false;
  }

  public getAvailableTransitions(): FSMState[] {
    const available: FSMState[] = [];
    for (const transition of this._transitions) {
      if (transition.from === this._currentState) {
        available.push(transition.to);
      }
    }
    return available;
  }

  public addLock(state: FSMState, reason: string, timeout: number = 0): void {
    const lock: StateLock = {
      state: state,
      reason: reason,
      timeout: timeout,
      startTime: Date.now()
    };

    this._activeLocks.push(lock);
    console.info(`[EmotionalFSM] 添加状态锁: ${state}, 原因: ${reason}`);

    this.dispatcher.emit('fsm:lockAdded', {
      state: state,
      reason: reason,
      timeout: timeout
    });

    if (timeout > 0) {
      setTimeout(() => {
        this.removeLock(state);
      }, timeout);
    }
  }

  public removeLock(state?: FSMState): void {
    if (state !== undefined) {
      const index = this._activeLocks.findIndex(lock => lock.state === state);
      if (index !== -1) {
        const removed = this._activeLocks.splice(index, 1)[0];
        console.info(`[EmotionalFSM] 移除状态锁: ${removed.state}`);
        this.dispatcher.emit('fsm:lockRemoved', {
          state: removed.state,
          reason: removed.reason
        });
      }
    } else {
      const count = this._activeLocks.length;
      this._activeLocks = [];
      console.info(`[EmotionalFSM] 移除所有状态锁, 数量: ${count}`);
    }
  }

  public hasActiveLock(): boolean {
    this.cleanupExpiredLocks();
    return this._activeLocks.length > 0;
  }

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

  private addToHistory(state: FSMState): void {
    this._stateHistory.push({
      state: state,
      timestamp: Date.now()
    });

    if (this._stateHistory.length > this.MAX_HISTORY_SIZE) {
      this._stateHistory.shift();
    }
  }

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

    this.emotionStore.setEmotion(emotion, priority, true);
  }

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

  public resetToIdle(): void {
    this.transitionTo(FSMState.IDLE, true);
    this.removeLock();
    this._stateHistory = [];
  }

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

export const emotionalFSM = EmotionalFSM.getInstance();
