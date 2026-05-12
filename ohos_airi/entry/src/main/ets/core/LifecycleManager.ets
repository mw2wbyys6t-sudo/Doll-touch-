import { EmotionalFSM } from './EmotionalFSM';
import { AnimationScheduler } from './AnimationScheduler';
import { TTSManager } from './TTSManager';
import { MemoryManager } from './MemoryManager';
import { Store, ActionType } from './Store';
import { EventDispatcher } from './EventDispatcher';

export interface LifecycleState {
  isInitialized: boolean;
  isActive: boolean;
  isBackground: boolean;
  currentPage: string;
  lastActiveTime: number;
  resourceUsage: {
    memory: number;
    cpu: number;
    gpu: number;
  };
}

export interface ResourceRef {
  id: string;
  type: 'timer' | 'interval' | 'listener' | 'animation' | 'tts' | 'memory';
  ref: any;
  cleanup: () => void;
  page?: string;
}

export class LifecycleManager {
  private static instance: LifecycleManager | null = null;
  private state: LifecycleState;
  private resources: ResourceRef[] = [];
  private pages: Map<string, { onAppear?: () => void; onDisappear?: () => void }> = new Map();
  private store: Store;
  private eventDispatcher: EventDispatcher;
  private heartbeatTimer: number | null = null;
  private inactivityTimer: number | null = null;
  private readonly INACTIVITY_THRESHOLD = 5 * 60 * 1000;

  private constructor() {
    this.store = Store.getInstance();
    this.eventDispatcher = EventDispatcher.getInstance();
    this.state = {
      isInitialized: false,
      isActive: false,
      isBackground: false,
      currentPage: '',
      lastActiveTime: Date.now(),
      resourceUsage: {
        memory: 0,
        cpu: 0,
        gpu: 0,
      },
    };
  }

  static getInstance(): LifecycleManager {
    if (!this.instance) {
      this.instance = new LifecycleManager();
    }
    return this.instance;
  }

  async init(): Promise<void> {
    if (this.state.isInitialized) {
      return;
    }

    console.log('LifecycleManager 初始化');

    this.state.isInitialized = true;
    this.state.isActive = true;
    this.state.lastActiveTime = Date.now();

    this.startHeartbeat();
    this.startInactivityMonitor();

    this.setupEventListeners();

    await this.startCoreModules();
  }

  private async startCoreModules(): Promise<void> {
    try {
      const fsm = EmotionalFSM.getInstance();
      fsm.init();

      const animation = AnimationScheduler.getInstance();
      animation.startIdleLoop();

      const tts = TTSManager.getInstance();
      await tts.init();

    } catch (error) {
      console.error('Core modules 启动错误:', error);
    }
  }

  private setupEventListeners(): void {
    this.eventDispatcher.on('USER_INTERACTED', () => {
      this.state.lastActiveTime = Date.now();
    });
  }

  private startHeartbeat(): void {
    if (this.heartbeatTimer) {
      clearInterval(this.heartbeatTimer);
    }

    this.heartbeatTimer = setInterval(() => {
      this.performHealthCheck();
    }, 30000) as unknown as number;

    this.registerResource({
      id: 'heartbeat',
      type: 'interval',
      ref: this.heartbeatTimer,
      cleanup: () => {
        if (this.heartbeatTimer) {
          clearInterval(this.heartbeatTimer);
          this.heartbeatTimer = null;
        }
      },
    });
  }

  private startInactivityMonitor(): void {
    if (this.inactivityTimer) {
      clearInterval(this.inactivityTimer);
    }

    this.inactivityTimer = setInterval(() => {
      const now = Date.now();
      const inactiveTime = now - this.state.lastActiveTime;

      if (inactiveTime > this.INACTIVITY_THRESHOLD && !this.state.isBackground) {
        this.handleInactivity();
      }
    }, 60000) as unknown as number;

    this.registerResource({
      id: 'inactivity',
      type: 'interval',
      ref: this.inactivityTimer,
      cleanup: () => {
        if (this.inactivityTimer) {
          clearInterval(this.inactivityTimer);
          this.inactivityTimer = null;
        }
      },
    });
  }

  private handleInactivity(): void {
    console.log('检测到用户长时间未活动');

    const fsm = EmotionalFSM.getInstance();
    fsm.triggerEmotion('sleeping', 0.8);

    const animation = AnimationScheduler.getInstance();
    animation.clearQueue();
  }

  private performHealthCheck(): void {
    console.log('LifecycleManager 健康检查');
  }

  onAppear(page: string): void {
    console.log(`页面 ${page} 出现`);

    this.state.currentPage = page;
    this.state.isActive = true;
    this.state.lastActiveTime = Date.now();

    this.eventDispatcher.dispatch('PAGE_APPEARED', { page });

    const pageConfig = this.pages.get(page);
    if (pageConfig && pageConfig.onAppear) {
      pageConfig.onAppear();
    }

    const fsm = EmotionalFSM.getInstance();
    if (fsm.getState().current === 'sleeping') {
      fsm.triggerEmotion('idle', 1);
    }
  }

  onDisappear(page: string): void {
    console.log(`页面 ${page} 消失`);

    this.eventDispatcher.dispatch('PAGE_DISAPPEARED', { page });

    const pageConfig = this.pages.get(page);
    if (pageConfig && pageConfig.onDisappear) {
      pageConfig.onDisappear();
    }

    this.cleanupPageResources(page);
  }

  onBackground(): void {
    console.log('应用进入后台');

    this.state.isBackground = true;
    this.state.isActive = false;
    this.eventDispatcher.dispatch('APP_BACKGROUND');
    this.pauseBackgroundResources();
  }

  onForeground(): void {
    console.log('应用回到前台');

    this.state.isBackground = false;
    this.state.isActive = true;
    this.state.lastActiveTime = Date.now();

    this.eventDispatcher.dispatch('APP_FOREGROUND');
    this.resumeForegroundResources();
  }

  private pauseBackgroundResources(): void {
    const tts = TTSManager.getInstance();
    tts.stop();
    tts.clearQueue();

    const animation = AnimationScheduler.getInstance();
    animation.clearQueue();
  }

  private resumeForegroundResources(): void {
    const animation = AnimationScheduler.getInstance();
    animation.startIdleLoop();
  }

  registerPage(
    page: string,
    onAppear?: () => void,
    onDisappear?: () => void
  ): void {
    this.pages.set(page, { onAppear, onDisappear });
  }

  registerResource(resource: ResourceRef): void {
    this.resources.push(resource);
  }

  unregisterResource(id: string): void {
    const index = this.resources.findIndex(r => r.id === id);
    if (index >= 0) {
      const resource = this.resources[index];
      resource.cleanup();
      this.resources.splice(index, 1);
    }
  }

  private cleanupPageResources(page: string): void {
    const pageResources = this.resources.filter(r => r.page === page);

    for (const resource of pageResources) {
      resource.cleanup();
    }

    this.resources = this.resources.filter(r => r.page !== page);
  }

  getState(): LifecycleState {
    return { ...this.state };
  }

  markUserActivity(): void {
    this.state.lastActiveTime = Date.now();
  }

  async destroy(): Promise<void> {
    console.log('LifecycleManager 销毁');

    for (const resource of this.resources) {
      resource.cleanup();
    }
    this.resources = [];

    const fsm = EmotionalFSM.getInstance();
    await fsm.stop();

    const animation = AnimationScheduler.getInstance();
    await animation.stop();

    const tts = TTSManager.getInstance();
    await tts.release();

    this.state.isInitialized = false;
    this.state.isActive = false;
  }
}
