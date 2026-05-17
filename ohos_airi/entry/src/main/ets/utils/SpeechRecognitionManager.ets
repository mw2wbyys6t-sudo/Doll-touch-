import { BusinessError } from '@kit.BasicServicesKit';

export interface RecognitionCallbacks {
  onStart?: (sessionId: string) => void;
  onResult?: (sessionId: string, result: string, isComplete: boolean) => void;
  onComplete?: (sessionId: string) => void;
  onError?: (sessionId: string, errorCode: number, errorMessage: string) => void;
}

export class SpeechRecognitionManager {
  private static isInitialized: boolean = false;
  private static listeners: RecognitionCallbacks = {};
  private static currentSessionId: string = '';

  static async init(callbacks?: RecognitionCallbacks): Promise<boolean> {
    if (this.isInitialized) {
      return true;
    }

    if (callbacks) {
      this.listeners = callbacks;
    }

    try {
      console.info('ASR引擎初始化（模拟）');
      this.isInitialized = true;
      return true;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`ASR初始化失败: Code: ${error.code}, message: ${error.message}`);
      return false;
    }
  }

  static async startListening(): Promise<boolean> {
    if (!this.isInitialized) {
      console.warn('ASR引擎未初始化');
      const initialized = await this.init();
      if (!initialized) {
        return false;
      }
    }

    try {
      this.currentSessionId = `airi_asr_${Date.now()}`;
      console.info(`ASR开始监听, sessionId: ${this.currentSessionId}`);
      this.listeners.onStart?.(this.currentSessionId);
      return true;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`ASR开始监听失败: Code: ${error.code}, message: ${error.message}`);
      return false;
    }
  }

  static async stopListening(): Promise<void> {
    if (!this.isInitialized) {
      return;
    }

    try {
      console.info('ASR停止监听');
      this.listeners.onComplete?.(this.currentSessionId);
    } catch (err) {
      const error = err as BusinessError;
      console.error(`ASR停止监听失败: Code: ${error.code}, message: ${error.message}`);
    }
  }

  static async cancel(): Promise<void> {
    if (!this.isInitialized) {
      return;
    }

    try {
      console.info('ASR已取消');
    } catch (err) {
      const error = err as BusinessError;
      console.error(`ASR取消失败: Code: ${error.code}, message: ${error.message}`);
    }
  }

  static async isListening(): Promise<boolean> {
    return false;
  }

  static async shutdown(): Promise<void> {
    if (!this.isInitialized) {
      return;
    }

    try {
      this.isInitialized = false;
      console.info('ASR引擎已关闭');
    } catch (err) {
      const error = err as BusinessError;
      console.error(`ASR引擎关闭失败: Code: ${error.code}, message: ${error.message}`);
    }
  }
}
