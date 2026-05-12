/**
 * LifecycleManager - 生命周期管理器
 * HarmonyOS NEXT ArkTS 标准实现
 */

import { Dispatcher } from './Dispatcher';
import { EmotionalFSM, FSMState } from './EmotionalFSM';

export enum LifecycleEvent {
  ON_CREATE = 'onCreate',
  ON_DESTROY = 'onDestroy',
  ON_APPEAR = 'onAppear',
  ON_DISAPPEAR = 'onDisappear',
  ON_FOREGROUND = 'onForeground',
  ON_BACKGROUND = 'onBackground'
}

export enum ResourceType {
  TIMER = 'timer',
  LISTENER = 'listener',
  TTS = 'tts',
  AUDIO = 'audio',
  NETWORK = 'network',
  OTHER = 'other'
}

interface ResourceInfo {
  id: string;
  type: ResourceType;
  name: string;
  cleanup: () => void;
  createdAt: number;
}

interface PageInfo {
  pageName: string;
  onAppear?: () => void;
  onDisappear?: () => void;
  registeredAt: number;
}

@Observed
export class LifecycleManager {
  private static instance: LifecycleManager | null = null;

  private dispatcher: Dispatcher;
  private fsm: EmotionalFSM;

  @Track
  private _isInForeground: boolean = true;

  @Track
  private _isInitialized: boolean = false;

  @Track
  private _registeredResources: ResourceInfo[] = [];

  @Track
  private _registeredPages: Map<string, PageInfo> = new Map();

  private idleTimeout: number = 5 * 60 * 1000;
  private idleTimerId: number | null = null;
  private lastActivityTime: number = Date.now();

  private _isUserActivityLocked: boolean = false;

  @Track
  private _isSleeping: boolean = false;

  @Track
  private _sleepModeEnabled: boolean = true;

  private sleepTimeout: number = 30 * 60 * 1000;
  private sleepTimerId: number | null = null;

  public static getInstance(): LifecycleManager {
    if (LifecycleManager.instance === null) {
      LifecycleManager.instance = new LifecycleManager();
    }
    return LifecycleManager.instance;
  }

  private constructor() {
    this.dispatcher = Dispatcher.getInstance();
    this.fsm = EmotionalFSM.getInstance();
  }

  public get isInForeground(): boolean {
    return this._isInForeground;
  }

  public get isInitialized(): boolean {
    return this._isInitialized;
  }

  public get isSleeping(): boolean {
    return this._isSleeping;
  }

  public get isUserActivityLocked(): boolean {
    return this._isUserActivityLocked;
  }

  public get registeredResources(): ResourceInfo[] {
    return this._registeredResources;
  }

  public get registeredPages(): Map<string, PageInfo> {
    return this._registeredPages;
  }

  public async init(): Promise<void> {
    if (this._isInitialized) {
      console.warn('[LifecycleManager] 已初始化，跳过');
      return;
    }

    console.info('[LifecycleManager] 开始初始化');

    this.subscribeToEvents();
    this.startIdleMonitor();

    if (this._sleepModeEnabled) {
      this.startSleepMonitor();
    }

    this._isInitialized = true;
    this.dispatcher.emit(LifecycleEvent.ON_CREATE, {});
    console.info('[LifecycleManager] 初始化完成');
  }

  private subscribeToEvents(): void {
    this.dispatcher.subscribe('user:activity', () => {
      this.markUserActivity();
    });
  }

  public destroy(): void {
    console.info('[LifecycleManager] 开始销毁');

    this.stopIdleMonitor();
    this.stopSleepMonitor();
    this.cleanupAllResources();
    this._registeredPages.clear();

    this._isInitialized = false;
    this._isInForeground = false;

    this.dispatcher.emit(LifecycleEvent.ON_DESTROY, {});
    console.info('[LifecycleManager] 销毁完成');
  }

  public onAppear(pageName: string, onAppearCallback?: () => void, onDisappearCallback?: () => void): void {
    const pageInfo: PageInfo = {
      pageName: pageName,
      onAppear: onAppearCallback,
      onDisappear: onDisappearCallback,
      registeredAt: Date.now()
    };

    this._registeredPages.set(pageName, pageInfo);
    console.info(`[LifecycleManager] 页面注册: ${pageName}`);
    this.markUserActivity();

    this.dispatcher.emit(LifecycleEvent.ON_APPEAR, { pageName: pageName });

    if (onAppearCallback) {
      try {
        onAppearCallback();
      } catch (error) {
        console.error(`[LifecycleManager] 页面 ${pageName} onAppear 回调失败: ${error}`);
      }
    }
  }

  public onDisappear(pageName: string): void {
    const pageInfo = this._registeredPages.get(pageName);

    if (pageInfo) {
      if (pageInfo.onDisappear) {
        try {
          pageInfo.onDisappear();
        } catch (error) {
          console.error(`[LifecycleManager] 页面 ${pageName} onDisappear 回调失败: ${error}`);
        }
      }

      this.cleanupPageResources(pageName);
      this._registeredPages.delete(pageName);
      console.info(`[LifecycleManager] 页面注销: ${pageName}`);
    }

    this.dispatcher.emit(LifecycleEvent.ON_DISAPPEAR, { pageName: pageName });
  }

  public onForeground(): void {
    if (this._isInForeground) {
      return;
    }

    this._isInForeground = true;
    console.info('[LifecycleManager] 应用进入前台');
    this.markUserActivity();

    if (this._isSleeping) {
      this.wakeup();
    }

    this.resumeResources();
    this.dispatcher.emit(LifecycleEvent.ON_FOREGROUND, {});
  }

  public onBackground(): void {
    if (!this._isInForeground) {
      return;
    }

    this._isInForeground = false;
    console.info('[LifecycleManager] 应用进入后台');
    this.pauseResources();
    this.dispatcher.emit(LifecycleEvent.ON_BACKGROUND, {});
  }

  public registerResource(
    id: string,
    type: ResourceType,
    name: string,
    cleanup: () => void
  ): void {
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
    console.info(`[LifecycleManager] 资源注册: ${id} (${type})`);
  }

  public unregisterResource(id: string): void {
    const index = this._registeredResources.findIndex(r => r.id === id);
    if (index !== -1) {
      const resource = this._registeredResources.splice(index, 1)[0];
      try {
        resource.cleanup();
        console.info(`[LifecycleManager] 资源已清理: ${id}`);
      } catch (error) {
        console.error(`[LifecycleManager] 清理资源 ${id} 失败: ${error}`);
      }
    }
  }

  private cleanupPageResources(pageName: string): void {
    const timers = this._registeredResources.filter(
      r => r.type === ResourceType.TIMER && r.id.startsWith(`timer_${pageName}_`)
    );
    for (const timer of timers) {
      this.unregisterResource(timer.id);
    }

    const listeners = this._registeredResources.filter(
      r => r.type === ResourceType.LISTENER && r.id.startsWith(`listener_${pageName}_`)
    );
    for (const listener of listeners) {
      this.unregisterResource(listener.id);
    }
  }

  public cleanupAllResources(): void {
    console.info(`[LifecycleManager] 开始清理所有资源, 数量: ${this._registeredResources.length}`);

    const resourcesCopy = [...this._registeredResources];

    for (const resource of resourcesCopy) {
      try {
        resource.cleanup();
      } catch (error) {
        console.error(`[LifecycleManager] 清理资源 ${resource.id} 失败: ${error}`);
      }
    }

    this._registeredResources = [];
    console.info('[LifecycleManager] 所有资源已清理');
  }

  private pauseResources(): void {
    const timers = this._registeredResources.filter(r => r.type === ResourceType.TIMER);
    for (const timer of timers) {
      try {
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

  private resumeResources(): void {
    console.info('[LifecycleManager] 资源已恢复（定时器需重新启动）');
  }

  public markUserActivity(): void {
    this.lastActivityTime = Date.now();
    this.resetIdleTimer();

    if (this._isSleeping) {
      this.wakeup();
    } else {
      this.resetSleepTimer();
    }
  }

  public lockUserActivity(reason: string): void {
    this._isUserActivityLocked = true;
    this.stopSleepMonitor();
    console.info(`[LifecycleManager] 用户活动已锁定: ${reason}`);
  }

  public unlockUserActivity(): void {
    if (this._isUserActivityLocked) {
      this._isUserActivityLocked = false;
      if (this._sleepModeEnabled) {
        this.startSleepMonitor();
      }
      console.info('[LifecycleManager] 用户活动已解锁');
    }
  }

  private startIdleMonitor(): void {
    this.stopIdleMonitor();

    this.idleTimerId = setTimeout(() => {
      this.onIdleTimeout();
    }, this.idleTimeout) as unknown as number;

    console.info(`[LifecycleManager] 空闲监控已启动, 超时: ${this.idleTimeout}ms`);
  }

  private stopIdleMonitor(): void {
    if (this.idleTimerId !== null) {
      clearTimeout(this.idleTimerId);
      this.idleTimerId = null;
    }
  }

  private resetIdleTimer(): void {
    if (this.idleTimerId !== null) {
      clearTimeout(this.idleTimerId);
      this.startIdleMonitor();
    }
  }

  private onIdleTimeout(): void {
    console.info('[LifecycleManager] 空闲超时');

    this.dispatcher.emit('lifecycle:idle', {});

    if (this._sleepModeEnabled && !this._isUserActivityLocked) {
      this.enterSleep();
    }
  }

  private startSleepMonitor(): void {
    if (this._isUserActivityLocked) {
      return;
    }

    this.stopSleepMonitor();

    this.sleepTimerId = setTimeout(() => {
      this.enterSleep();
    }, this.sleepTimeout) as unknown as number;

    console.info(`[LifecycleManager] 睡眠监控已启动, 超时: ${this.sleepTimeout}ms`);
  }

  private stopSleepMonitor(): void {
    if (this.sleepTimerId !== null) {
      clearTimeout(this.sleepTimerId);
      this.sleepTimerId = null;
    }
  }

  private resetSleepTimer(): void {
    if (this.sleepTimerId !== null && !this._isUserActivityLocked) {
      clearTimeout(this.sleepTimerId);
      this.startSleepMonitor();
    }
  }

  public enterSleep(): void {
    if (this._isSleeping) {
      return;
    }

    this._isSleeping = true;
    console.info('[LifecycleManager] 进入睡眠模式');

    this.fsm.transitionTo(FSMState.SLEEPING, true);
    this.pauseResources();
    this.dispatcher.emit('lifecycle:sleep', {});
  }

  public wakeup(): void {
    if (!this._isSleeping) {
      return;
    }

    this._isSleeping = false;
    console.info('[LifecycleManager] 唤醒');

    this.fsm.transitionTo(FSMState.IDLE, true);
    this.resetSleepTimer();
    this.resumeResources();
    this.dispatcher.emit('lifecycle:wakeup', {});
  }

  public setSleepModeEnabled(enabled: boolean): void {
    this._sleepModeEnabled = enabled;
    if (enabled && !this._isSleeping && !this._isUserActivityLocked) {
      this.startSleepMonitor();
    } else {
      this.stopSleepMonitor();
    }
    console.info(`[LifecycleManager] 睡眠模式: ${enabled ? '启用' : '禁用'}`);
  }

  public static destroy(): void {
    if (LifecycleManager.instance !== null) {
      LifecycleManager.instance.destroy();
      LifecycleManager.instance = null;
    }
  }
}

export const lifecycleManager = LifecycleManager.getInstance();
