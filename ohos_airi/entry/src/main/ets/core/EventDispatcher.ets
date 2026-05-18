import { EmotionalState } from './EmotionalFSM';

export type EventType =
  | 'CHAT_MESSAGE_RECEIVED'
  | 'EMOTION_CHANGED'
  | 'TTS_STARTED'
  | 'TTS_COMPLETED'
  | 'TTS_INTERRUPTED'
  | 'ANIMATION_STARTED'
  | 'ANIMATION_COMPLETED'
  | 'MEMORY_ADDED'
  | 'MEMORY_RETRIEVED'
  | 'INTIMACY_UPDATED'
  | 'USER_INTERACTED'
  | 'PAGE_APPEARED'
  | 'PAGE_DISAPPEARED'
  | 'APP_BACKGROUND'
  | 'APP_FOREGROUND'
  | 'ERROR_OCCURRED';

export interface EventData {
  [key: string]: any;
}

export interface Event {
  type: EventType;
  timestamp: number;
  data?: EventData;
}

export type EventHandler = (event: Event) => void | Promise<void>;

export class EventDispatcher {
  private static instance: EventDispatcher | null = null;
  private listeners: Map<EventType, EventHandler[]> = new Map();
  private allListeners: EventHandler[] = [];
  private eventQueue: Event[] = [];
  private isProcessing: boolean = false;
  private maxQueueSize: number = 1000;

  private constructor() {}

  static getInstance(): EventDispatcher {
    if (!this.instance) {
      this.instance = new EventDispatcher();
    }
    return this.instance;
  }

  on(type: EventType, handler: EventHandler): () => void {
    if (!this.listeners.has(type)) {
      this.listeners.set(type, []);
    }
    const handlers = this.listeners.get(type)!;
    handlers.push(handler);

    return () => {
      this.off(type, handler);
    };
  }

  off(type: EventType, handler: EventHandler): void {
    const handlers = this.listeners.get(type);
    if (handlers) {
      this.listeners.set(type, handlers.filter(h => h !== handler));
    }
  }

  onAll(handler: EventHandler): () => void {
    this.allListeners.push(handler);
    return () => {
      this.allListeners = this.allListeners.filter(h => h !== handler);
    };
  }

  async dispatch(type: EventType, data?: EventData): Promise<void> {
    const event: Event = {
      type,
      timestamp: Date.now(),
      data,
    };

    this.eventQueue.push(event);

    if (this.eventQueue.length > this.maxQueueSize) {
      this.eventQueue.shift();
    }

    if (!this.isProcessing) {
      await this.processQueue();
    }
  }

  private async processQueue(): Promise<void> {
    if (this.isProcessing || this.eventQueue.length === 0) {
      return;
    }

    this.isProcessing = true;

    while (this.eventQueue.length > 0) {
      const event = this.eventQueue.shift()!;
      await this.executeEvent(event);
    }

    this.isProcessing = false;
  }

  private async executeEvent(event: Event): Promise<void> {
    const handlers = this.listeners.get(event.type) || [];

    const allHandlers = [...this.allListeners, ...handlers];

    for (const handler of allHandlers) {
      try {
        const result = handler(event);
        if (result && result instanceof Promise) {
          await result;
        }
      } catch (error) {
        console.error(`Event handler error for ${event.type}:`, error);
      }
    }
  }

  getRecentEvents(count: number = 10): Event[] {
    return this.eventQueue.slice(-count);
  }

  clear(): void {
    this.eventQueue = [];
    this.listeners.clear();
    this.allListeners = [];
  }
}

export class EventFactory {
  static chatMessageReceived(_text: string, _type: 'user' | 'assistant'): EventType {
    return 'CHAT_MESSAGE_RECEIVED';
  }

  static emotionChanged(_emotion: EmotionalState, _intensity: number): EventType {
    return 'EMOTION_CHANGED';
  }

  static ttsStarted(_text: string): EventType {
    return 'TTS_STARTED';
  }

  static ttsCompleted(): EventType {
    return 'TTS_COMPLETED';
  }

  static userInteracted(_interactionType: string): EventType {
    return 'USER_INTERACTED';
  }

  static appBackground(): EventType {
    return 'APP_BACKGROUND';
  }

  static appForeground(): EventType {
    return 'APP_FOREGROUND';
  }

  static pageAppeared(_page: string): EventType {
    return 'PAGE_APPEARED';
  }

  static pageDisappeared(_page: string): EventType {
    return 'PAGE_DISAPPEARED';
  }

  static errorOccurred(_error: string, _source?: string): EventType {
    return 'ERROR_OCCURRED';
  }
}
