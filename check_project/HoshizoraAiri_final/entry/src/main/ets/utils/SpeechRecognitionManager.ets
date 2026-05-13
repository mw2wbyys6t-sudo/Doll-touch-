import { speechRecognizer } from '@kit.CoreSpeechKit';
import { BusinessError } from '@kit.BasicServicesKit';

export interface RecognitionCallbacks {
  onStart?: (sessionId: string) => void;
  onResult?: (sessionId: string, result: string, isComplete: boolean) => void;
  onComplete?: (sessionId: string) => void;
  onError?: (sessionId: string, errorCode: number, errorMessage: string) => void;
}

export class SpeechRecognitionManager {
  private static asrEngine: speechRecognizer.SpeechRecognitionEngine | null = null;
  private static isInitialized: boolean = false;
  private static listeners: RecognitionCallbacks = {};
  private static currentSessionId: string = '';

  static async init(callbacks?: RecognitionCallbacks): Promise<boolean> {
    if (this.isInitialized && this.asrEngine) {
      return true;
    }

    if (callbacks) {
      this.listeners = callbacks;
    }

    try {
      const extraParam: Record<string, Object> = {
        'locate': 'CN',
        'recognizerMode': 'short'
      };

      const initParamsInfo: speechRecognizer.CreateEngineParams = {
        language: 'zh-CN',
        online: 1,
        extraParams: extraParam
      };

      return new Promise<boolean>((resolve) => {
        speechRecognizer.createEngine(initParamsInfo, (err: BusinessError, engine: speechRecognizer.SpeechRecognitionEngine) => {
          if (err) {
            console.error(`ASR引擎创建失败: Code: ${err.code}, message: ${err.message}`);
            resolve(false);
            return;
          }

          this.asrEngine = engine;
          this.isInitialized = true;
          console.info('ASR引擎创建成功');

          const recognitionListener: speechRecognizer.RecognitionListener = {
            onStart: (sessionId: string, eventMessage: string) => {
              console.info(`ASR开始识别, sessionId: ${sessionId}, eventMessage: ${eventMessage}`);
              this.listeners.onStart?.(sessionId);
            },
            onEvent: (sessionId: string, eventCode: number, eventMessage: string) => {
              console.info(`ASR事件, sessionId: ${sessionId}, eventCode: ${eventCode}, eventMessage: ${eventMessage}`);
            },
            onResult: (sessionId: string, result: speechRecognizer.SpeechRecognitionResult) => {
              const isFinal = result.isFinal;
              let text = '';
              
              if (result.strings && result.strings.length > 0) {
                text = result.strings[0];
              }
              
              console.info(`ASR识别结果, sessionId: ${sessionId}, text: ${text}, isFinal: ${isFinal}`);
              this.listeners.onResult?.(sessionId, text, isFinal);
            },
            onComplete: (sessionId: string, eventMessage: string) => {
              console.info(`ASR识别完成, sessionId: ${sessionId}, eventMessage: ${eventMessage}`);
              this.listeners.onComplete?.(sessionId);
            },
            onError: (sessionId: string, errorCode: number, errorMessage: string) => {
              console.error(`ASR识别错误, sessionId: ${sessionId}, errorCode: ${errorCode}, errorMessage: ${errorMessage}`);
              this.listeners.onError?.(sessionId, errorCode, errorMessage);
            }
          };

          this.asrEngine!.setListener(recognitionListener);
          resolve(true);
        });
      });
    } catch (err) {
      const error = err as BusinessError;
      console.error(`ASR初始化失败: Code: ${error.code}, message: ${error.message}`);
      return false;
    }
  }

  static async startListening(): Promise<boolean> {
    if (!this.asrEngine || !this.isInitialized) {
      console.warn('ASR引擎未初始化');
      const initialized = await this.init();
      if (!initialized) {
        return false;
      }
    }

    try {
      this.currentSessionId = `airi_asr_${Date.now()}`;
      
      const audioParam: speechRecognizer.AudioInfo = {
        audioType: 'pcm',
        sampleRate: 16000,
        soundChannel: 1,
        sampleBit: 16
      };

      const extraParam: Record<string, Object> = {
        'vadBegin': 2000,
        'vadEnd': 3000,
        'maxAudioDuration': 40000
      };

      const startParams: speechRecognizer.StartParams = {
        audioInfo: audioParam,
        extraParams: extraParam
      };

      this.asrEngine!.startListening(startParams);
      console.info(`ASR开始监听, sessionId: ${this.currentSessionId}`);
      return true;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`ASR开始监听失败: Code: ${error.code}, message: ${error.message}`);
      return false;
    }
  }

  static async stopListening(): Promise<void> {
    if (!this.asrEngine || !this.isInitialized) {
      return;
    }

    try {
      this.asrEngine.finish(this.currentSessionId);
      console.info('ASR停止监听');
    } catch (err) {
      const error = err as BusinessError;
      console.error(`ASR停止监听失败: Code: ${error.code}, message: ${error.message}`);
    }
  }

  static async cancel(): Promise<void> {
    if (!this.asrEngine || !this.isInitialized) {
      return;
    }

    try {
      this.asrEngine.cancel(this.currentSessionId);
      console.info('ASR已取消');
    } catch (err) {
      const error = err as BusinessError;
      console.error(`ASR取消失败: Code: ${error.code}, message: ${error.message}`);
    }
  }

  static async isListening(): Promise<boolean> {
    if (!this.asrEngine || !this.isInitialized) {
      return false;
    }

    try {
      return this.asrEngine.isBusy();
    } catch (err) {
      return false;
    }
  }

  static async shutdown(): Promise<void> {
    if (!this.asrEngine || !this.isInitialized) {
      return;
    }

    try {
      await this.cancel();
      this.asrEngine.shutdown();
      this.asrEngine = null;
      this.isInitialized = false;
      console.info('ASR引擎已关闭');
    } catch (err) {
      const error = err as BusinessError;
      console.error(`ASR引擎关闭失败: Code: ${error.code}, message: ${error.message}`);
    }
  }
}
