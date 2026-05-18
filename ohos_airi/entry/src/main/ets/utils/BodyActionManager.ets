import { AppStorage } from '@kit.ArkUI';

// 安全的 AppStorage 访问函数
function safeGetAppStorage(key: string, defaultValue: number): number {
  try {
    const value = AppStorage.get(key);
    return value !== undefined && value !== null ? Number(value) : defaultValue;
  } catch (e) {
    return defaultValue;
  }
}

function safeSetAppStorage(key: string, value: number): void {
  try {
    AppStorage.setOrCreate(key, value);
  } catch (e) {
    console.error(`BodyActionManager: 设置 ${key} 失败:`, e);
  }
}

// 兼容 HarmonyOS NEXT 的 requestAnimationFrame 替代实现
let rafId = 0;
type FrameRequestCallback = (timestamp: number) => void;
const rafCallbacks = new Map<number, FrameRequestCallback>();

function requestAnimationFrame(callback: FrameRequestCallback): number {
  const id = ++rafId;
  rafCallbacks.set(id, callback);
  setTimeout(() => {
    const cb = rafCallbacks.get(id);
    if (cb) {
      rafCallbacks.delete(id);
      try {
        cb(Date.now());
      } catch (e) {
        console.error('BodyActionManager: animationFrame callback failed:', e);
      }
    }
  }, 16);
  return id;
}

function cancelAnimationFrame(id: number): void {
  rafCallbacks.delete(id);
}

export type BodyActionType = 'wave' | 'dance' | 'idle_sway' | 'jump' | 'sit' | 'stand' | 'point';

export interface BodyParams {
  bodyAngleX: number;
  bodyAngleY: number;
  bodyAngleZ: number;
  armLeftAngleX: number;
  armLeftAngleY: number;
  armRightAngleX: number;
  armRightAngleY: number;
  legAngleX: number;
  legAngleY: number;
  hairSwing: number;
  clothingSwing: number;
}

export class BodyActionManager {
  private static instance: BodyActionManager | null = null;
  private currentAction: BodyActionType = 'idle_sway';
  private isAnimating: boolean = false;
  private animationTimer: number | null = null;

  private bodyParams: Record<BodyActionType, BodyParams> = {
    idle_sway: {
      bodyAngleX: 0.0,
      bodyAngleY: 0.0,
      bodyAngleZ: 0.0,
      armLeftAngleX: 0.0,
      armLeftAngleY: 0.0,
      armRightAngleX: 0.0,
      armRightAngleY: 0.0,
      legAngleX: 0.0,
      legAngleY: 0.0,
      hairSwing: 0.0,
      clothingSwing: 0.0
    },
    wave: {
      bodyAngleX: 0.0,
      bodyAngleY: 0.05,
      bodyAngleZ: 0.0,
      armLeftAngleX: 0.0,
      armLeftAngleY: 0.0,
      armRightAngleX: 0.6,
      armRightAngleY: 0.3,
      legAngleX: 0.0,
      legAngleY: 0.0,
      hairSwing: 0.1,
      clothingSwing: 0.05
    },
    dance: {
      bodyAngleX: 0.1,
      bodyAngleY: 0.1,
      bodyAngleZ: 0.1,
      armLeftAngleX: 0.4,
      armLeftAngleY: 0.4,
      armRightAngleX: -0.4,
      armRightAngleY: 0.4,
      legAngleX: 0.2,
      legAngleY: 0.2,
      hairSwing: 0.3,
      clothingSwing: 0.2
    },
    jump: {
      bodyAngleX: 0.0,
      bodyAngleY: 0.0,
      bodyAngleZ: 0.0,
      armLeftAngleX: 0.5,
      armLeftAngleY: -0.5,
      armRightAngleX: 0.5,
      armRightAngleY: -0.5,
      legAngleX: 0.0,
      legAngleY: 0.0,
      hairSwing: 0.4,
      clothingSwing: 0.3
    },
    sit: {
      bodyAngleX: 0.3,
      bodyAngleY: 0.0,
      bodyAngleZ: 0.0,
      armLeftAngleX: 0.2,
      armLeftAngleY: 0.3,
      armRightAngleX: 0.2,
      armRightAngleY: 0.3,
      legAngleX: 0.5,
      legAngleY: 0.3,
      hairSwing: 0.0,
      clothingSwing: 0.1
    },
    stand: {
      bodyAngleX: 0.0,
      bodyAngleY: 0.0,
      bodyAngleZ: 0.0,
      armLeftAngleX: 0.1,
      armLeftAngleY: 0.2,
      armRightAngleX: -0.1,
      armRightAngleY: 0.2,
      legAngleX: 0.0,
      legAngleY: 0.0,
      hairSwing: 0.0,
      clothingSwing: 0.0
    },
    point: {
      bodyAngleX: 0.0,
      bodyAngleY: 0.1,
      bodyAngleZ: 0.0,
      armLeftAngleX: 0.0,
      armLeftAngleY: 0.0,
      armRightAngleX: 0.8,
      armRightAngleY: -0.2,
      legAngleX: 0.0,
      legAngleY: 0.0,
      hairSwing: 0.1,
      clothingSwing: 0.05
    }
  };

  private constructor() {}

  static getInstance(): BodyActionManager {
    if (!this.instance) {
      this.instance = new BodyActionManager();
    }
    return this.instance;
  }

  getCurrentAction(): BodyActionType {
    return this.currentAction;
  }

  getBodyParams(action: BodyActionType): BodyParams {
    return this.bodyParams[action] || this.bodyParams.idle_sway;
  }

  async playAction(action: BodyActionType, duration: number = 500): Promise<void> {
    if (this.isAnimating) {
      this.stopCurrentAction();
    }

    this.isAnimating = true;
    this.currentAction = action;

    try {
      await this.animateAction(action, duration);
    } catch (error) {
      console.error(`Body action failed: ${error}`);
    } finally {
      if (action !== 'idle_sway') {
        setTimeout(() => {
          this.playAction('idle_sway', 300);
        }, duration + 200);
      }
      this.isAnimating = false;
    }
  }

  private async animateAction(action: BodyActionType, duration: number): Promise<void> {
    const targetParams = this.getBodyParams(action);
    
    const params = Object.keys(targetParams) as (keyof BodyParams)[];
    params.forEach(key => {
      safeSetAppStorage(key, targetParams[key]);
    });

    return new Promise(resolve => {
      setTimeout(resolve, duration);
    });
  }

  startIdleAnimation(): void {
    if (this.animationTimer) {
      clearInterval(this.animationTimer);
    }

    let time = 0;
    this.animationTimer = setInterval(() => {
      try {
        time += 0.05;
        
        const sway = Math.sin(time) * 0.02;
        const hairSwing = Math.sin(time * 1.5) * 0.05;
        const clothingSwing = Math.sin(time * 0.8) * 0.03;
        
        safeSetAppStorage('bodyAngleY', sway);
        safeSetAppStorage('hairSwing', hairSwing);
        safeSetAppStorage('clothingSwing', clothingSwing);
        
        const armSwing = Math.sin(time * 2) * 0.05;
        safeSetAppStorage('armLeftAngleX', armSwing);
        safeSetAppStorage('armRightAngleX', -armSwing);
      } catch (error) {
        console.error('BodyActionManager: idle animation failed:', error);
      }
    }, 50) as unknown as number;
    
    console.log('BodyActionManager: idle animation started');
  }

  stopCurrentAction(): void {
    if (this.animationTimer) {
      clearInterval(this.animationTimer);
      this.animationTimer = null;
    }
    this.isAnimating = false;
    console.log('BodyActionManager: action stopped');
  }

  async playWave(): Promise<void> {
    await this.playAction('wave', 300);
    
    for (let i = 0; i < 3; i++) {
      await this.animateWaveCycle();
    }
    
    await this.playAction('idle_sway', 300);
  }

  private async animateWaveCycle(): Promise<void> {
    return new Promise(resolve => {
      const startAngle = safeGetAppStorage('armRightAngleX', 0.6);
      let time = 0;
      
      const animate = () => {
        try {
          time += 0.1;
          const angle = startAngle * Math.sin(time * 10);
          safeSetAppStorage('armRightAngleX', angle);
          
          if (time < 0.6) {
            requestAnimationFrame(animate);
          } else {
            resolve();
          }
        } catch (error) {
          console.error('BodyActionManager: animateWaveCycle failed:', error);
          resolve();
        }
      };
      animate();
    });
  }

  async playDance(duration: number = 2000): Promise<void> {
    await this.playAction('dance', 300);
    
    const startTime = Date.now();
    return new Promise(resolve => {
      const animate = () => {
        try {
          const elapsed = Date.now() - startTime;
          
          if (elapsed < duration) {
            const time = elapsed / 1000;
            
            safeSetAppStorage('bodyAngleX', Math.sin(time * 3) * 0.1);
            safeSetAppStorage('bodyAngleY', Math.cos(time * 4) * 0.1);
            safeSetAppStorage('bodyAngleZ', Math.sin(time * 2) * 0.05);
            
            safeSetAppStorage('armLeftAngleX', Math.sin(time * 5) * 0.4);
            safeSetAppStorage('armRightAngleX', Math.cos(time * 5) * 0.4);
            safeSetAppStorage('armLeftAngleY', Math.cos(time * 3) * 0.4);
            safeSetAppStorage('armRightAngleY', Math.sin(time * 3) * 0.4);
            
            safeSetAppStorage('hairSwing', Math.sin(time * 6) * 0.3);
            safeSetAppStorage('clothingSwing', Math.sin(time * 4) * 0.2);
            
            requestAnimationFrame(animate);
          } else {
            resolve();
          }
        } catch (error) {
          console.error('BodyActionManager: playDance failed:', error);
          resolve();
        }
      };
      animate();
    });
  }
}
