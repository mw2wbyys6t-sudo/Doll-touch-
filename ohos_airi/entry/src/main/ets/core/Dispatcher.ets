/**
 * Dispatcher - 事件分发器
 * HarmonyOS NEXT ArkTS 标准实现
 */

type EventCallback = (data?: Object) => void;

interface SubscriberInfo {
  id: string;
  event: string;
  callback: EventCallback;
}

export class Dispatcher {
  private static instance: Dispatcher | null = null;
  private subscribers: Map<string, SubscriberInfo[]> = new Map();
  private subscriberIdCounter: number = 0;

  private constructor() {
    this.subscribers = new Map();
  }

  public static getInstance(): Dispatcher {
    if (Dispatcher.instance === null) {
      Dispatcher.instance = new Dispatcher();
    }
    return Dispatcher.instance;
  }

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
    console.info(`[Dispatcher] 订阅: ${event}, ID: ${id}`);
    return id;
  }

  public unsubscribe(id: string): void {
    let found = false;

    this.subscribers.forEach((subscribers, event) => {
      const index = subscribers.findIndex(sub => sub.id === id);
      if (index !== -1) {
        subscribers.splice(index, 1);
        found = true;
        console.info(`[Dispatcher] 取消订阅: ${event}`);
      }
    });

    if (!found) {
      console.warn(`[Dispatcher] 订阅者ID不存在: ${id}`);
    }
  }

  public emit(event: string, data?: Object): void {
    const subscribers = this.subscribers.get(event);
    if (subscribers && subscribers.length > 0) {
      const subscribersCopy = [...subscribers];
      for (const subscriber of subscribersCopy) {
        try {
          subscriber.callback(data);
        } catch (error) {
          console.error(`[Dispatcher] 回调失败: ${event}, 错误: ${error}`);
        }
      }
    }
  }

  public clear(): void {
    this.subscribers.clear();
  }

  public static destroy(): void {
    if (Dispatcher.instance !== null) {
      Dispatcher.instance.clear();
      Dispatcher.instance = null;
    }
  }
}

export const dispatcher = Dispatcher.getInstance();
