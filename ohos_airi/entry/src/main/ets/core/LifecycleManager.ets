/**
 * LifecycleManager - 生命周期管理器
 * HarmonyOS NEXT ArkTS 实现
 * 管理应用和页面的生命周期
 */

import { Dispatcher } from './Dispatcher';
import { EmotionalFSM, FSMState } from './EmotionalFSM';

// 生命周期类型
export enum LifecycleEvent {
  ON_CREATE = 'onCreate',
  ON_DESTROY = 'onDestroy',
  ON_APPEAR = 'onAppear',
  ON_DISAPPEAR = 'onDisappear',
  ON_FOREGROUND = 'onForeground',
  ON_BACKGROUND = 'onBackground',
  ON_PAGE_SHOW = 'onPageShow',
  ON_PAGE_HIDE = 'onPageHide'
}

// 资源类型
export enum ResourceType {
  TIMER = 'timer',
  LISTENER = 'listener',
  TTS = 'tts',
  AUDIO = 'audio',
  NETWORK = 'network',
  OTHER = 'other'
}

// 资源信息接口
interface ResourceInfo {
  id: string;
  type: ResourceType;
  name: string;
  cleanup: () => void;
  createdAt: number;
}

// 页面信息接口
interface PageInfo {
  pageName: string;
  onAppear?: () => void;
  onDisappear?: () => void;
  registeredAt: number;
}

// 观察者类
export class LifecycleManager {
  // 单例实例
  private static instance: LifecycleManager | null = null;

  // 事件分发器
  private dispatcher: Dispatcher;

  // FSM 实例
  private fsm: EmotionalFSM;

  // 应用是否在前台
  private _isInForeground: boolean = true;

  // 应用是否已初始化
  private _isInitialized: boolean = false;

  // 注册的资源列表
  private _registeredResources: ResourceInfo[] = [];

  // 注册的页面列表
  private _registeredPages: Map<string, PageInfo> = new Map();

  // 空闲超时时间（毫秒）
  private idleTimeout: number = 5 * 60 * 1000; // 默认 5 分钟

  // 空闲定时器 ID
  private idleTimerId: number | null = null;

  // 最后活动时间
  private lastActivityTime: number = Date.now();

  // 用户活动锁（防止自动睡眠）
  private _isUserActivityLocked: boolean = false;

  // 睡眠状态
  private _isSleeping: boolean = false;

  // 睡眠模式
  private _sleepModeEnabled: boolean = true;

  // 睡眠超时时间（毫秒）
  private sleepTimeout: number = 30 * 60 * 1000; // 默认 30 分钟

  // 睡眠定时器 ID
  private sleepTimerId: number | null = null;

  // 调试模式
  private debugMode: boolean = false;

  /**
   * 获取单例实例
   */
  public static getInstance(): LifecycleManager {
    if (LifecycleManager.instance === null) {
      LifecycleManager.instance = new LifecycleManager();
    }
    return LifecycleManager.instance;
  }

  /**
   * 私有构造函数
   */
  private constructor() {
    this.dispatcher = Dispatcher.getInstance();
    this.fsm = EmotionalFSM.getInstance();
  }

  /**
   * 获取前台状态
   */
  public get isInForeground(): boolean {
    return this._isInForeground;
  }

  /**
   * 获取初始化状态
   */
  public get isInitialized(): boolean {
    return this._isInitialized;
  }

  /**
   * 获取睡眠状态
   */
  public get isSleeping(): boolean {
    return this._isSleeping;
  }

  /**
   * 获取活动锁状态
   */
  public get isUserActivityLocked(): boolean {
    return this._isUserActivityLocked;
  }

  /**
   * 获取已注册资源
   */
  public get registeredResources(): ResourceInfo[] {
    return this._registeredResources;
  }

  /**
   * 获取已注册页面
   */
  public get registeredPages(): Map<string, PageInfo> {
    return this._registeredPages;
  }

  /**
   * 初始化
   */
  public async init(): Promise<void> {
    if (this._isInitialized) {
      console.warn('[LifecycleManager] 已初始化，跳过');
      return;
    }

    console.info('[LifecycleManager] 开始初始化');

    // 订阅必要事件
    this.subscribeToEvents();

    // 启动空闲监控
    this.startIdleMonitor();

    // 启动睡眠监控
    if (this._sleepModeEnabled) {
      this.startSleepMonitor();
    }

    this._isInitialized = true;

    // 发送初始化完成事件
    this.dispatcher.emit(LifecycleEvent.ON_CREATE, {});

    console.info('[LifecycleManager] 初始化完成');
  }

  /**
   * 订阅事件
   */
  private subscribeToEvents(): void {
    // 订阅用户活动事件
    this.dispatcher.subscribe('user:activity', () => {
      this.markUserActivity();
    });
  }

  /**
   * 销毁
   */
  public destroy(): void {
    console.info('[LifecycleManager] 开始销毁');

    // 停止所有定时器
    this.stopIdleMonitor();
    this.stopSleepMonitor();

    // 清理所有资源
    this.cleanupAllResources();

    // 清空页面注册
    this._registeredPages.clear();

    // 取消订阅
    this.dispatcher.unsubscribeAll('user:activity');

    this._isInitialized = false;
    this._isInForeground = false;

    // 发送销毁事件
    this.dispatcher.emit(LifecycleEvent.ON_DESTROY, {});

    console.info('[LifecycleManager] 销毁完成');
  }

  /**
   * 页面出现
   */
  public onAppear(pageName: string, onAppearCallback?: () => void, onDisappearCallback?: () => void): void {
    const pageInfo: PageInfo = {
      pageName: pageName,
      onAppear: onAppearCallback,
      onDisappear: onDisappearCallback,
      registeredAt: Date.now()
    };

    this._registeredPages.set(pageName, pageInfo);

    if (this.debugMode) {
      console.info(`[LifecycleManager] 页面注册: ${pageName}`);
    }

    // 标记用户活动
    this.markUserActivity();

    // 发送页面出现事件
    this.dispatcher.emit(LifecycleEvent.ON_APPEAR, { pageName: pageName });

    // 如果有回调，执行
    if (onAppearCallback) {
      try {
        onAppearCallback();
      } catch (error) {
        console.error(`[LifecycleManager] 页面 ${pageName} onAppear 回调失败: ${error}`);
      }
    }
  }

  /**
   * 页面消失
   */
  public onDisappear(pageName: string): void {
    const pageInfo = this._registeredPages.get(pageName);

    if (pageInfo) {
      // 如果有回调，执行
      if (pageInfo.onDisappear) {
        try {
          pageInfo.onDisappear();
        } catch (error) {
          console.error(`[LifecycleManager] 页面 ${pageName} onDisappear 回调失败: ${error}`);
        }
      }

      // 清理页面相关资源
      this.cleanupPageResources(pageName);

      // 移除页面注册
      this._registeredPages.delete(pageName);

      if (this.debugMode) {
        console.info(`[LifecycleManager] 页面注销: ${pageName}`);
      }
    }

    // 发送页面消失事件
    this.dispatcher.emit(LifecycleEvent.ON_DISAPPEAR, { pageName: pageName });
  }

  /**
   * 进入前台
   */
  public onForeground(): void {
    if (this._isInForeground) {
      return;
    }

    this._isInForeground = true;

    if (this.debugMode) {
      console.info('[LifecycleManager] 应用进入前台');
    }

    // 标记用户活动
    this.markUserActivity();

    // 唤醒（如果正在睡眠）
    if (this._isSleeping) {
      this.wakeup();
    }

    // 恢复资源
    this.resumeResources();

    // 发送前台事件
    this.dispatcher.emit(LifecycleEvent.ON_FOREGROUND, {});
  }

  /**
   * 进入后台
   */
  public onBackground(): void {
    if (!this._isInForeground) {
      return;
    }

    this._isInForeground = false;

    if (this.debugMode) {
      console.info('[LifecycleManager] 应用进入后台');
    }

    // 暂停资源
    this.pauseResources();

    // 发送后台事件
    this.dispatcher.emit(LifecycleEvent.ON_BACKGROUND, {});
  }

  /**
   * 注册资源
   */
  public registerResource(
    id: string,
    type: ResourceType,
    name: string,
    cleanup: () => void
  ): void {
    // 检查是否已存在
    const existingIndex = this._registeredResources.findIndex(r => r.id === id);
    if (existingIndex !== -1) {
      console.warn(`[LifecycleManager] 资源 ${id} 已存在，将被替换`);
      this._registeredResources.splice(existingIndex, 1);
    }

    const resource: ResourceInfo = {
      id: id,
      type: type,
      name: name,
      cleanup: cleanup,
      createdAt: Date.now()
    };

    this._registeredResources.push(resource);

    if (this.debugMode) {
      console.info(`[LifecycleManager] 资源注册: ${id} (${type}) - ${name}`);
    }
  }

  /**
   * 注销资源
   */
  public unregisterResource(id: string): void {
    const index = this._registeredResources.findIndex(r => r.id === id);
    if (index !== -1) {
      const resource = this._registeredResources.splice(index, 1)[0];
      try {
        resource.cleanup();
        if (this.debugMode) {
          console.info(`[LifecycleManager] 资源已清理: ${id}`);
        }
      } catch (error) {
        console.error(`[LifecycleManager] 清理资源 ${id} 失败: ${error}`);
      }
    }
  }

  /**
   * 清理特定页面的所有资源
   */
  private cleanupPageResources(pageName: string): void {
    // 清理定时器
    const timers = this._registeredResources.filter(
      r => r.type === ResourceType.TIMER && r.id.startsWith(`timer_${pageName}_`)
    );
    for (const timer of timers) {
      this.unregisterResource(timer.id);
    }

    // 清理监听器
    const listeners = this._registeredResources.filter(
      r => r.type === ResourceType.LISTENER && r.id.startsWith(`listener_${pageName}_`)
    );
    for (const listener of listeners) {
      this.unregisterResource(listener.id);
    }

    if (this.debugMode) {
      console.info(`[LifecycleManager] 页面 ${pageName} 的资源已清理`);
    }
  }

  /**
   * 清理所有资源
   */
  public cleanupAllResources(): void {
    console.info(`[LifecycleManager] 开始清理所有资源, 数量: ${this._registeredResources.length}`);

    // 复制数组，避免在清理过程中修改
    const resourcesCopy = [...this._registeredResources];

    for (const resource of resourcesCopy) {
      try {
        resource.cleanup();
        if (this.debugMode) {
          console.info(`[LifecycleManager] 资源已清理: ${resource.id}`);
        }
      } catch (error) {
        console.error(`[LifecycleManager] 清理资源 ${resource.id} 失败: ${error}`);
      }
    }

    this._registeredResources = [];
    console.info('[LifecycleManager] 所有资源已清理');
  }

  /**
   * 暂停所有资源
   */
  private pauseResources(): void {
    // 暂停定时器
    const timers = this._registeredResources.filter(r => r.type === ResourceType.TIMER);
    for (const timer of timers) {
      try {
        // 尝试清除定时器
        if (timer.id.startsWith('interval_')) {
          const timerId = parseInt(timer.id.replace('interval_', ''));
          clearInterval(timerId);
        } else if (timer.id.startsWith('timeout_')) {
          const timerId = parseInt(timer.id.replace('timeout_', ''));
          clearTimeout(timerId);
        }
      } catch (error) {
        console.error(`[LifecycleManager] 暂停定时器 ${timer.id} 失败: ${error}`);
      }
    }

    console.info('[LifecycleManager] 资源已暂停');
  }

  /**
   * 恢复所有资源
   */
  private resumeResources(): void {
    // 注意：定时器需要在页面代码中重新启动
    console.info('[LifecycleManager] 资源已恢复（定时器需重新启动）');
  }

  /**
   * 标记用户活动
   */
  public markUserActivity(): void {
    this.lastActivityTime = Date.now();

    // 重置空闲定时器
    this.resetIdleTimer();

    // 重置睡眠定时器
    if (this._isSleeping) {
      this.wakeup();
    } else {
      this.resetSleepTimer();
    }

    if (this.debugMode) {
      console.info('[LifecycleManager] 用户活动已标记');
    }
  }

  /**
   * 锁定用户活动（防止自动睡眠）
   */
  public lockUserActivity(reason: string): void {
    this._isUserActivityLocked = true;
    this.stopSleepMonitor();
    console.info(`[LifecycleManager] 用户活动已锁定: ${reason}`);
  }

  /**
   * 解锁用户活动
   */
  public unlockUserActivity(): void {
    if (this._isUserActivityLocked) {
      this._isUserActivityLocked = false;
      if (this._sleepModeEnabled) {
        this.startSleepMonitor();
      }
      console.info('[LifecycleManager] 用户活动已解锁');
    }
  }

  /**
   * 启动空闲监控
   */
  private startIdleMonitor(): void {
    this.stopIdleMonitor();

    this.idleTimerId = setTimeout(() => {
      this.onIdleTimeout();
    }, this.idleTimeout) as unknown as number;

    if (this.debugMode) {
      console.info(`[LifecycleManager] 空闲监控已启动, 超时: ${this.idleTimeout}ms`);
    }
  }

  /**
   * 停止空闲监控
   */
  private stopIdleMonitor(): void {
    if (this.idleTimerId !== null) {
      clearTimeout(this.idleTimerId);
      this.idleTimerId = null;
    }
  }

  /**
   * 重置空闲定时器
   */
  private resetIdleTimer(): void {
    if (this.idleTimerId !== null) {
      clearTimeout(this.idleTimerId);
      this.startIdleMonitor();
    }
  }

  /**
   * 空闲超时处理
   */
  private onIdleTimeout(): void {
    if (this.debugMode) {
      console.info('[LifecycleManager] 空闲超时');
    }

    // 发送空闲事件
    this.dispatcher.emit('lifecycle:idle', {});

    // 如果启用了睡眠模式，进入睡眠
    if (this._sleepModeEnabled && !this._isUserActivityLocked) {
      this.enterSleep();
    }
  }

  /**
   * 启动睡眠监控
   */
  private startSleepMonitor(): void {
    if (this._isUserActivityLocked) {
      return;
    }

    this.stopSleepMonitor();

    this.sleepTimerId = setTimeout(() => {
      this.enterSleep();
    }, this.sleepTimeout) as unknown as number;

    if (this.debugMode) {
      console.info(`[LifecycleManager] 睡眠监控已启动, 超时: ${this.sleepTimeout}ms`);
    }
  }

  /**
   * 停止睡眠监控
   */
  private stopSleepMonitor(): void {
    if (this.sleepTimerId !== null) {
      clearTimeout(this.sleepTimerId);
      this.sleepTimerId = null;
    }
  }

  /**
   * 重置睡眠定时器
   */
  private resetSleepTimer(): void {
    if (this.sleepTimerId !== null && !this._isUserActivityLocked) {
      clearTimeout(this.sleepTimerId);
      this.startSleepMonitor();
    }
  }

  /**
   * 进入睡眠
   */
  public enterSleep(): void {
    if (this._isSleeping) {
      return;
    }

    this._isSleeping = true;

    console.info('[LifecycleManager] 进入睡眠模式');

    // 切换 FSM 到睡眠状态
    this.fsm.transitionTo(FSMState.SLEEPING, true);

    // 暂停资源
    this.pauseResources();

    // 发送睡眠事件
    this.dispatcher.emit('lifecycle:sleep', {});
  }

  /**
   * 唤醒
   */
  public wakeup(): void {
    if (!this._isSleeping) {
      return;
    }

    this._isSleeping = false;

    console.info('[LifecycleManager] 唤醒');

    // 切换 FSM 到 IDLE 状态
    this.fsm.transitionTo(FSMState.IDLE, true);

    // 重置睡眠定时器
    this.resetSleepTimer();

    // 恢复资源
    this.resumeResources();

    // 发送唤醒事件
    this.dispatcher.emit('lifecycle:wakeup', {});
  }

  /**
   * 设置空闲超时
   */
  public setIdleTimeout(timeout: number): void {
    this.idleTimeout = timeout;
    if (this._isInitialized) {
      this.resetIdleTimer();
    }
    console.info(`[LifecycleManager] 空闲超时设置为: ${timeout}ms`);
  }

  /**
   * 设置睡眠超时
   */
  public setSleepTimeout(timeout: number): void {
    this.sleepTimeout = timeout;
    if (this._isInitialized && !this._isUserActivityLocked) {
      this.resetSleepTimer();
    }
    console.info(`[LifecycleManager] 睡眠超时设置为: ${timeout}ms`);
  }

  /**
   * 启用/禁用睡眠模式
   */
  public setSleepModeEnabled(enabled: boolean): void {
    this._sleepModeEnabled = enabled;
    if (enabled && !this._isSleeping && !this._isUserActivityLocked) {
      this.startSleepMonitor();
    } else {
      this.stopSleepMonitor();
    }
    console.info(`[LifecycleManager] 睡眠模式: ${enabled ? '启用' : '禁用'}`);
  }

  /**
   * 设置调试模式
   */
  public setDebugMode(enabled: boolean): void {
    this.debugMode = enabled;
    console.info(`[LifecycleManager] 调试模式: ${enabled ? '启用' : '禁用'}`);
  }

  /**
   * 获取状态摘要
   */
  public getStateSummary(): Object {
    return {
      isInForeground: this._isInForeground,
      isInitialized: this._isInitialized,
      isSleeping: this._isSleeping,
      isUserActivityLocked: this._isUserActivityLocked,
      sleepModeEnabled: this._sleepModeEnabled,
      registeredResources: this._registeredResources.length,
      registeredPages: Array.from(this._registeredPages.keys()),
      lastActivityTime: this.lastActivityTime,
      idleTimeout: this.idleTimeout,
      sleepTimeout: this.sleepTimeout
    };
  }

  /**
   * 销毁单例（用于测试）
   */
  public static destroy(): void {
    if (LifecycleManager.instance !== null) {
      LifecycleManager.instance.destroy();
      LifecycleManager.instance = null;
    }
  }
}

// 导出单例快捷访问
export const lifecycleManager = LifecycleManager.getInstance();
