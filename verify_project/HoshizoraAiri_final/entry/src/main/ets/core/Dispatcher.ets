/**
 * Dispatcher - 事件分发器
 * HarmonyOS NEXT ArkTS 实现
 * 用于模块间的事件通信
 */

// 事件回调类型
type EventCallback = (data?: Object) => void;

// 订阅者信息
interface SubscriberInfo {
  id: string;
  event: string;
  callback: EventCallback;
}

// 事件队列项
interface QueuedEvent {
  event: string;
  data?: Object;
  timestamp: number;
}

export class Dispatcher {
  // 单例实例
  private static instance: Dispatcher | null = null;

  // 订阅者映射表：event -> SubscriberInfo[]
  private subscribers: Map<string, SubscriberInfo[]> = new Map();

  // 事件队列（用于异步处理）
  private eventQueue: QueuedEvent[] = [];

  // 是否正在处理队列
  private isProcessing: boolean = false;

  // 订阅者ID计数器
  private subscriberIdCounter: number = 0;

  // 调试模式
  private debugMode: boolean = false;

  private constructor() {
    this.subscribers = new Map();
    this.eventQueue = [];
  }

  /**
   * 获取单例实例
   */
  public static getInstance(): Dispatcher {
    if (Dispatcher.instance === null) {
      Dispatcher.instance = new Dispatcher();
    }
    return Dispatcher.instance;
  }

  /**
   * 订阅事件
   * @param event 事件名称
   * @param callback 回调函数
   * @returns 订阅者ID
   */
  public subscribe(event: string, callback: EventCallback): string {
    const id = `sub_${++this.subscriberIdCounter}_${Date.now()}`;

    const subscriber: SubscriberInfo = {
      id: id,
      event: event,
      callback: callback
    };

    if (!this.subscribers.has(event)) {
      this.subscribers.set(event, []);
    }

    this.subscribers.get(event)!.push(subscriber);

    if (this.debugMode) {
      console.info(`[Dispatcher] 订阅成功: ${event}, ID: ${id}`);
    }

    return id;
  }

  /**
   * 取消订阅
   * @param id 订阅者ID
   */
  public unsubscribe(id: string): void {
    let found = false;

    this.subscribers.forEach((subscribers, event) => {
      const index = subscribers.findIndex(sub => sub.id === id);
      if (index !== -1) {
        subscribers.splice(index, 1);
        found = true;
        if (this.debugMode) {
          console.info(`[Dispatcher] 取消订阅成功: ${event}, ID: ${id}`);
        }
      }
    });

    if (!found && this.debugMode) {
      console.warn(`[Dispatcher] 订阅者ID不存在: ${id}`);
    }
  }

  /**
   * 取消特定事件的所有订阅
   * @param event 事件名称
   */
  public unsubscribeAll(event: string): void {
    if (this.subscribers.has(event)) {
      const count = this.subscribers.get(event)!.length;
      this.subscribers.delete(event);
      if (this.debugMode) {
        console.info(`[Dispatcher] 取消事件所有订阅: ${event}, 数量: ${count}`);
      }
    }
  }

  /**
   * 发送事件（同步）
   * @param event 事件名称
   * @param data 事件数据
   */
  public emit(event: string, data?: Object): void {
    if (this.debugMode) {
      console.info(`[Dispatcher] 发送事件: ${event}`);
    }

    const subscribers = this.subscribers.get(event);
    if (subscribers && subscribers.length > 0) {
      // 复制数组，避免在回调中修改导致的问题
      const subscribersCopy = [...subscribers];
      for (const subscriber of subscribersCopy) {
        try {
          subscriber.callback(data);
        } catch (error) {
          console.error(`[Dispatcher] 事件回调执行失败: ${event}, 错误: ${error}`);
        }
      }
    } else {
      if (this.debugMode) {
        console.info(`[Dispatcher] 没有订阅者: ${event}`);
      }
    }
  }

  /**
   * 发送事件（异步，排队处理）
   * @param event 事件名称
   * @param data 事件数据
   */
  public emitAsync(event: string, data?: Object): void {
    const queuedEvent: QueuedEvent = {
      event: event,
      data: data,
      timestamp: Date.now()
    };

    this.eventQueue.push(queuedEvent);

    if (!this.isProcessing) {
      this.processEventQueue();
    }
  }

  /**
   * 处理事件队列
   */
  private processEventQueue(): void {
    if (this.eventQueue.length === 0) {
      this.isProcessing = false;
      return;
    }

    this.isProcessing = true;

    const event = this.eventQueue.shift();
    if (event) {
      this.emit(event.event, event.data);
    }

    // 使用 setTimeout 异步处理下一个事件
    setTimeout(() => {
      this.processEventQueue();
    }, 0);
  }

  /**
   * 设置调试模式
   * @param enabled 是否启用调试
   */
  public setDebugMode(enabled: boolean): void {
    this.debugMode = enabled;
    console.info(`[Dispatcher] 调试模式: ${enabled ? '启用' : '禁用'}`);
  }

  /**
   * 获取订阅者数量
   * @param event 事件名称
   * @returns 订阅者数量
   */
  public getSubscriberCount(event: string): number {
    const subscribers = this.subscribers.get(event);
    return subscribers ? subscribers.length : 0;
  }

  /**
   * 获取所有事件列表
   * @returns 事件名称数组
   */
  public getEventList(): string[] {
    const events: string[] = [];
    this.subscribers.forEach((_, event) => {
      events.push(event);
    });
    return events;
  }

  /**
   * 清空所有订阅
   */
  public clear(): void {
    const count = this.getTotalSubscriberCount();
    this.subscribers.clear();
    this.eventQueue = [];
    if (this.debugMode) {
      console.info(`[Dispatcher] 清空所有订阅, 数量: ${count}`);
    }
  }

  /**
   * 获取总订阅者数量
   * @returns 总订阅者数量
   */
  public getTotalSubscriberCount(): number {
    let count = 0;
    this.subscribers.forEach((subscribers) => {
      count += subscribers.length;
    });
    return count;
  }

  /**
   * 销毁单例（用于测试）
   */
  public static destroy(): void {
    if (Dispatcher.instance !== null) {
      Dispatcher.instance.clear();
      Dispatcher.instance = null;
    }
  }
}

// 导出单例快捷访问
export const dispatcher = Dispatcher.getInstance();
