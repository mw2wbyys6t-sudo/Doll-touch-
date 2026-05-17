/**
 * DebugPanel - 调试面板组件
 * HarmonyOS NEXT ArkUI 实现
 * 实时显示系统状态信息
 */

import { Dispatcher } from './Dispatcher';
import { EmotionStore, EmotionType } from './EmotionStore';
import { EmotionalFSM, FSMState } from './EmotionalFSM';
import { LifecycleManager } from './LifecycleManager';

// 调试面板配置
interface DebugPanelConfig {
  visible: boolean;
  opacity: number;
  positionX: number;
  positionY: number;
  width: number;
  height: number;
}

// 观察者类
export class DebugPanelViewModel {
  // 调试面板可见性
  private _isVisible: boolean = false;

  // 调试面板配置
  private _config: DebugPanelConfig = {
    visible: true,
    opacity: 0.9,
    positionX: 0,
    positionY: 0,
    width: 300,
    height: 400
  };

  // 当前状态
  private _currentState: FSMState = FSMState.IDLE;

  // 当前情绪
  private _currentEmotion: EmotionType = EmotionType.IDLE;

  // 情绪权重列表
  private _emotionWeights: Array<{ emotion: string; weight: number }> = [];

  // 活动锁列表
  private _activeLocks: Array<{ state: string; reason: string; timeout: number }> = [];

  // 应用状态
  private _isInForeground: boolean = true;

  private _isSleeping: boolean = false;

  private _isInitialized: boolean = false;

  // 资源统计
  private _resourceCount: number = 0;

  private _pageCount: number = 0;

  // FPS 信息
  private _fps: number = 60;

  // 内存信息（模拟）
  private _memoryUsage: string = '0 MB';

  // 事件分发器
  private dispatcher: Dispatcher;

  // 情绪存储
  private emotionStore: EmotionStore;

  // FSM
  private fsm: EmotionalFSM;

  // Lifecycle Manager
  private lifecycleManager: LifecycleManager;

  // 订阅者ID
  private subscriberIds: string[] = [];

  // FPS 定时器
  private fpsTimerId: number | null = null;

  // 更新间隔
  private updateInterval: number = 500;

  /**
   * 获取单例实例
   */
  public static getInstance(): DebugPanelViewModel {
    // 使用 AppStorage 或全局变量存储实例
    const storageKey = 'debugPanelViewModel';
    let instance = AppStorage.get<DebugPanelViewModel>(storageKey);

    if (instance === undefined) {
      instance = new DebugPanelViewModel();
      AppStorage.setOrCreate<DebugPanelViewModel>(storageKey, instance);
    }

    return instance;
  }

  /**
   * 私有构造函数
   */
  private constructor() {
    this.dispatcher = Dispatcher.getInstance();
    this.emotionStore = EmotionStore.getInstance();
    this.fsm = EmotionalFSM.getInstance();
    this.lifecycleManager = LifecycleManager.getInstance();

    // 初始化
    this.subscribeToEvents();
  }

  /**
   * 获取可见性
   */
  public get isVisible(): boolean {
    return this._isVisible;
  }

  /**
   * 获取配置
   */
  public get config(): DebugPanelConfig {
    return this._config;
  }

  /**
   * 获取当前状态
   */
  public get currentState(): FSMState {
    return this._currentState;
  }

  /**
   * 获取当前情绪
   */
  public get currentEmotion(): EmotionType {
    return this._currentEmotion;
  }

  /**
   * 获取情绪权重列表
   */
  public get emotionWeights(): Array<{ emotion: string; weight: number }> {
    return this._emotionWeights;
  }

  /**
   * 获取活动锁列表
   */
  public get activeLocks(): Array<{ state: string; reason: string; timeout: number }> {
    return this._activeLocks;
  }

  /**
   * 获取应用状态
   */
  public get isInForeground(): boolean {
    return this._isInForeground;
  }

  public get isSleeping(): boolean {
    return this._isSleeping;
  }

  public get isInitialized(): boolean {
    return this._isInitialized;
  }

  /**
   * 获取资源统计
   */
  public get resourceCount(): number {
    return this._resourceCount;
  }

  public get pageCount(): number {
    return this._pageCount;
  }

  /**
   * 获取 FPS
   */
  public get fps(): number {
    return this._fps;
  }

  /**
   * 获取内存使用
   */
  public get memoryUsage(): string {
    return this._memoryUsage;
  }

  /**
   * 订阅事件
   */
  private subscribeToEvents(): void {
    // FSM 状态变化
    const fsmSubId = this.dispatcher.subscribe('fsm:stateChanged', (data) => {
      this.updateFSMState();
    });
    this.subscriberIds.push(fsmSubId);

    // 情绪变化
    const emotionSubId = this.dispatcher.subscribe('emotion:changed', (data) => {
      this.updateEmotionState();
    });
    this.subscriberIds.push(emotionSubId);

    // 情绪锁定
    const lockSubId = this.dispatcher.subscribe('fsm:lockAdded', (data) => {
      this.updateLocks();
    });
    this.subscriberIds.push(lockSubId);

    // 应用生命周期
    const lifecycleSubId = this.dispatcher.subscribe('lifecycle:sleep', () => {
      this.updateAppState();
    });
    this.subscriberIds.push(lifecycleSubId);

    const wakeupSubId = this.dispatcher.subscribe('lifecycle:wakeup', () => {
      this.updateAppState();
    });
    this.subscriberIds.push(wakeupSubId);

    // 资源变化
    const resourceSubId = this.dispatcher.subscribe('resource:changed', () => {
      this.updateResources();
    });
    this.subscriberIds.push(resourceSubId);
  }

  /**
   * 开始更新
   */
  public startUpdates(): void {
    if (this.fpsTimerId !== null) {
      return;
    }

    // 立即更新一次
    this.updateAll();

    // 启动定时更新
    this.fpsTimerId = setInterval(() => {
      this.updateAll();
    }, this.updateInterval) as unknown as number;

    console.info('[DebugPanel] 开始更新');
  }

  /**
   * 停止更新
   */
  public stopUpdates(): void {
    if (this.fpsTimerId !== null) {
      clearInterval(this.fpsTimerId);
      this.fpsTimerId = null;
    }

    console.info('[DebugPanel] 停止更新');
  }

  /**
   * 更新所有状态
   */
  private updateAll(): void {
    this.updateFSMState();
    this.updateEmotionState();
    this.updateLocks();
    this.updateAppState();
    this.updateResources();
    this.updatePerformance();
  }

  /**
   * 更新 FSM 状态
   */
  private updateFSMState(): void {
    this._currentState = this.fsm.currentState;
  }

  /**
   * 更新情绪状态
   */
  private updateEmotionState(): void {
    this._currentEmotion = this.emotionStore.currentEmotion;

    // 更新权重列表
    const topEmotions = this.emotionStore.getTopEmotions(5);
    this._emotionWeights = topEmotions.map(item => ({
      emotion: item.emotion,
      weight: item.weight
    }));
  }

  /**
   * 更新锁状态
   */
  private updateLocks(): void {
    const locks = this.fsm.activeLocks;
    this._activeLocks = locks.map(lock => ({
      state: lock.state,
      reason: lock.reason,
      timeout: lock.timeout
    }));
  }

  /**
   * 更新应用状态
   */
  private updateAppState(): void {
    this._isInForeground = this.lifecycleManager.isInForeground;
    this._isSleeping = this.lifecycleManager.isSleeping;
    this._isInitialized = this.lifecycleManager.isInitialized;

    const pages = this.lifecycleManager.registeredPages;
    this._pageCount = pages.size;
  }

  /**
   * 更新资源统计
   */
  private updateResources(): void {
    const resources = this.lifecycleManager.registeredResources;
    this._resourceCount = resources.length;
  }

  /**
   * 更新性能信息
   */
  private updatePerformance(): void {
    // 模拟 FPS（实际应从系统获取）
    this._fps = 55 + Math.floor(Math.random() * 10);

    // 模拟内存使用
    const memoryMB = 80 + Math.floor(Math.random() * 30);
    this._memoryUsage = `${memoryMB} MB`;
  }

  /**
   * 显示面板
   */
  public show(): void {
    this._isVisible = true;
    this.startUpdates();
  }

  /**
   * 隐藏面板
   */
  public hide(): void {
    this._isVisible = false;
    this.stopUpdates();
  }

  /**
   * 切换可见性
   */
  public toggle(): void {
    if (this._isVisible) {
      this.hide();
    } else {
      this.show();
    }
  }

  /**
   * 设置更新间隔
   */
  public setUpdateInterval(interval: number): void {
    this.updateInterval = interval;
    if (this._isVisible && this.fpsTimerId !== null) {
      this.stopUpdates();
      this.startUpdates();
    }
  }

  /**
   * 获取状态摘要
   */
  public getStateSummary(): Object {
    return {
      currentState: this._currentState,
      currentEmotion: this._currentEmotion,
      emotionWeights: this._emotionWeights,
      activeLocks: this._activeLocks,
      isInForeground: this._isInForeground,
      isSleeping: this._isSleeping,
      isInitialized: this._isInitialized,
      resourceCount: this._resourceCount,
      pageCount: this._pageCount,
      fps: this._fps,
      memoryUsage: this._memoryUsage
    };
  }

  /**
   * 销毁
   */
  public destroy(): void {
    this.stopUpdates();

    // 取消订阅
    for (const id of this.subscriberIds) {
      this.dispatcher.unsubscribe(id);
    }
    this.subscriberIds = [];
  }
}

// 导出单例快捷访问
export const debugPanelViewModel = DebugPanelViewModel.getInstance();
