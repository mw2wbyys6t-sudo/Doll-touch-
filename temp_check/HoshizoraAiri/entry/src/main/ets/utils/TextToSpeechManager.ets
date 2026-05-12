import { textToSpeech } from '@kit.CoreSpeechKit';
import { BusinessError } from '@kit.BasicServicesKit';

export interface SpeakOptions {
  speed?: number;
  volume?: number;
  pitch?: number;
  requestId?: string;
}

export interface SpeakCallbacks {
  onStart?: (requestId: string) => void;
  onComplete?: (requestId: string) => void;
  onStop?: (requestId: string) => void;
  onError?: (requestId: string, errorCode: number, errorMessage: string) => void;
}

export class TextToSpeechManager {
  private static ttsEngine: textToSpeech.TextToSpeechEngine | null = null;
  private static isInitialized: boolean = false;
  private static listeners: SpeakCallbacks = {};

  static async init(callbacks?: SpeakCallbacks): Promise<boolean> {
    if (this.isInitialized && this.ttsEngine) {
      return true;
    }

    if (callbacks) {
      this.listeners = callbacks;
    }

    try {
      const initParamsInfo: textToSpeech.CreateEngineParams = {
        language: 'zh-CN',
        person: 0,
        online: 1,
        extraParams: {
          'style': 'interaction-broadcast',
          'locate': 'CN',
          'name': 'airi_tts_engine'
        }
      };

      return new Promise<boolean>((resolve) => {
        textToSpeech.createEngine(initParamsInfo, (err: BusinessError, engine: textToSpeech.TextToSpeechEngine) => {
          if (err) {
            console.error(`TTS引擎创建失败: Code: ${err.code}, message: ${err.message}`);
            resolve(false);
            return;
          }

          this.ttsEngine = engine;
          this.isInitialized = true;
          console.info('TTS引擎创建成功');

          const speakListener: textToSpeech.SpeakListener = {
            onStart: (requestId: string, response: textToSpeech.StartResponse) => {
              console.info(`TTS开始播报, requestId: ${requestId}`);
              this.listeners.onStart?.(requestId);
            },
            onComplete: (requestId: string, response: textToSpeech.CompleteResponse) => {
              console.info(`TTS播报完成, requestId: ${requestId}`);
              this.listeners.onComplete?.(requestId);
            },
            onStop: (requestId: string, response: textToSpeech.StopResponse) => {
              console.info(`TTS停止播报, requestId: ${requestId}`);
              this.listeners.onStop?.(requestId);
            },
            onError: (requestId: string, errorCode: number, errorMessage: string) => {
              console.error(`TTS播报出错, requestId: ${requestId}, errorCode: ${errorCode}, errorMessage: ${errorMessage}`);
              this.listeners.onError?.(requestId, errorCode, errorMessage);
            }
          };

          this.ttsEngine!.setListener(speakListener);
          resolve(true);
        });
      });
    } catch (err) {
      const error = err as BusinessError;
      console.error(`TTS初始化失败: Code: ${error.code}, message: ${error.message}`);
      return false;
    }
  }

  static async speak(text: string, options?: SpeakOptions): Promise<boolean> {
    if (!this.ttsEngine || !this.isInitialized) {
      console.warn('TTS引擎未初始化');
      const initialized = await this.init();
      if (!initialized) {
        return false;
      }
    }

    try {
      const requestId = options?.requestId || `airi_${Date.now()}`;
      
      const extraParams: Record<string, Object> = {
        'speed': options?.speed ?? 1.0,
        'volume': options?.volume ?? 1.5,
        'pitch': options?.pitch ?? 1.0
      };

      const speakParams: textToSpeech.SpeakParams = {
        requestId: requestId,
        extraParams: extraParams
      };

      this.ttsEngine!.speak(text, speakParams);
      console.info(`TTS开始播报文本: ${text.substring(0, 20)}...`);
      return true;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`TTS播报失败: Code: ${error.code}, message: ${error.message}`);
      return false;
    }
  }

  static async stop(): Promise<void> {
    if (!this.ttsEngine || !this.isInitialized) {
      return;
    }

    try {
      this.ttsEngine.stop();
      console.info('TTS已停止');
    } catch (err) {
      const error = err as BusinessError;
      console.error(`TTS停止失败: Code: ${error.code}, message: ${error.message}`);
    }
  }

  static async isSpeaking(): Promise<boolean> {
    if (!this.ttsEngine || !this.isInitialized) {
      return false;
    }

    try {
      return this.ttsEngine.isBusy();
    } catch (err) {
      return false;
    }
  }

  static async shutdown(): Promise<void> {
    if (!this.ttsEngine || !this.isInitialized) {
      return;
    }

    try {
      await this.stop();
      this.ttsEngine.shutdown();
      this.ttsEngine = null;
      this.isInitialized = false;
      console.info('TTS引擎已关闭');
    } catch (err) {
      const error = err as BusinessError;
      console.error(`TTS引擎关闭失败: Code: ${error.code}, message: ${error.message}`);
    }
  }

  static async listVoices(): Promise<textToSpeech.VoiceInfo[]> {
    if (!this.ttsEngine || !this.isInitialized) {
      console.warn('TTS引擎未初始化');
      return [];
    }

    try {
      return new Promise((resolve) => {
        this.ttsEngine!.listVoices({
          online: 1
        }, (err: BusinessError, voices: textToSpeech.VoiceInfo[]) => {
          if (err) {
            console.error(`获取音色列表失败: Code: ${err.code}`);
            resolve([]);
            return;
          }
          console.info(`获取到${voices.length}个音色`);
          resolve(voices);
        });
      });
    } catch (err) {
      console.error('获取音色列表异常');
      return [];
    }
  }
}
