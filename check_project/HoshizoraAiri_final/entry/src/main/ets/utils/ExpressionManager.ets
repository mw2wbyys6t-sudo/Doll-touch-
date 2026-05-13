import animator from '@ohos.animator';
import { BusinessError } from '@kit.BasicServicesKit';

export type ExpressionType = 'idle' | 'happy' | 'sad' | 'surprised' | 'angry' | 'shy' | 'excited' | 'sleepy';

export interface ExpressionParams {
  eyeOpen: number;
  eyeBrowY: number;
  mouthOpen: number;
  mouthForm: number;
  cheek: number;
  headAngleX: number;
  headAngleY: number;
  headAngleZ: number;
}

export interface AnimationConfig {
  duration: number;
  easing: string;
  fill: string;
  iterations: number;
}

export class ExpressionManager {
  private static instance: ExpressionManager | null = null;
  private currentExpression: ExpressionType = 'idle';
  private isAnimating: boolean = false;
  
  private expressionParams: Record<ExpressionType, ExpressionParams> = {
    idle: {
      eyeOpen: 1.0,
      eyeBrowY: 0.0,
      mouthOpen: 0.2,
      mouthForm: 0.0,
      cheek: 0.0,
      headAngleX: 0.0,
      headAngleY: 0.0,
      headAngleZ: 0.0
    },
    happy: {
      eyeOpen: 1.0,
      eyeBrowY: 0.3,
      mouthOpen: 0.8,
      mouthForm: 0.5,
      cheek: 0.4,
      headAngleX: 0.0,
      headAngleY: 0.1,
      headAngleZ: 0.05
    },
    sad: {
      eyeOpen: 0.6,
      eyeBrowY: -0.3,
      mouthOpen: 0.1,
      mouthForm: -0.3,
      cheek: 0.0,
      headAngleX: -0.05,
      headAngleY: -0.1,
      headAngleZ: 0.0
    },
    surprised: {
      eyeOpen: 1.2,
      eyeBrowY: 0.5,
      mouthOpen: 1.0,
      mouthForm: 0.0,
      cheek: 0.3,
      headAngleX: 0.1,
      headAngleY: 0.0,
      headAngleZ: 0.0
    },
    angry: {
      eyeOpen: 0.8,
      eyeBrowY: -0.2,
      mouthOpen: 0.4,
      mouthForm: -0.5,
      cheek: -0.2,
      headAngleX: 0.0,
      headAngleY: 0.05,
      headAngleZ: -0.1
    },
    shy: {
      eyeOpen: 0.5,
      eyeBrowY: -0.1,
      mouthOpen: 0.2,
      mouthForm: 0.1,
      cheek: 0.6,
      headAngleX: -0.1,
      headAngleY: -0.15,
      headAngleZ: 0.05
    },
    excited: {
      eyeOpen: 1.1,
      eyeBrowY: 0.4,
      mouthOpen: 0.9,
      mouthForm: 0.6,
      cheek: 0.5,
      headAngleX: 0.15,
      headAngleY: 0.1,
      headAngleZ: 0.1
    },
    sleepy: {
      eyeOpen: 0.3,
      eyeBrowY: -0.1,
      mouthOpen: 0.1,
      mouthForm: 0.0,
      cheek: 0.0,
      headAngleX: 0.2,
      headAngleY: 0.0,
      headAngleZ: 0.0
    }
  };

  private defaultConfig: AnimationConfig = {
    duration: 300,
    easing: 'easeOutCubic',
    fill: 'forwards',
    iterations: 1
  };

  private constructor() {}

  static getInstance(): ExpressionManager {
    if (!this.instance) {
      this.instance = new ExpressionManager();
    }
    return this.instance;
  }

  getCurrentExpression(): ExpressionType {
    return this.currentExpression;
  }

  getExpressionParams(expression: ExpressionType): ExpressionParams {
    return this.expressionParams[expression] || this.expressionParams.idle;
  }

  async playExpression(expression: ExpressionType, config?: Partial<AnimationConfig>): Promise<void> {
    if (this.isAnimating && this.currentExpression === expression) {
      return;
    }

    this.isAnimating = true;
    this.currentExpression = expression;

    const finalConfig: AnimationConfig = {
      ...this.defaultConfig,
      ...config
    };

    try {
      await this.animateExpression(expression, finalConfig);
    } catch (error) {
      console.error(`Expression animation failed: ${error}`);
    } finally {
      this.isAnimating = false;
    }
  }

  private async animateExpression(expression: ExpressionType, config: AnimationConfig): Promise<void> {
    return new Promise<void>((resolve) => {
      const targetParams = this.getExpressionParams(expression);
      
      AppStorage.setOrCreate('eyeOpen', targetParams.eyeOpen);
      AppStorage.setOrCreate('eyeBrowY', targetParams.eyeBrowY);
      AppStorage.setOrCreate('mouthOpen', targetParams.mouthOpen);
      AppStorage.setOrCreate('mouthForm', targetParams.mouthForm);
      AppStorage.setOrCreate('cheek', targetParams.cheek);
      AppStorage.setOrCreate('headAngleX', targetParams.headAngleX);
      AppStorage.setOrCreate('headAngleY', targetParams.headAngleY);
      AppStorage.setOrCreate('headAngleZ', targetParams.headAngleZ);

      setTimeout(() => {
        resolve();
      }, config.duration);
    });
  }

  async playBlink(): Promise<void> {
    if (this.isAnimating) return;
    
    this.isAnimating = true;
    try {
      const originalEyeOpen = AppStorage.get('eyeOpen', 1.0);
      
      await this.animateValue('eyeOpen', originalEyeOpen, 0.0, 100);
      await this.delay(50);
      await this.animateValue('eyeOpen', 0.0, originalEyeOpen, 100);
    } finally {
      this.isAnimating = false;
    }
  }

  async playIdleBounce(): Promise<void> {
    if (this.isAnimating) return;
    
    this.isAnimating = true;
    try {
      for (let i = 0; i < 3; i++) {
        await this.animateValue('headAngleY', 0, 0.05, 200);
        await this.animateValue('headAngleY', 0.05, -0.05, 300);
        await this.animateValue('headAngleY', -0.05, 0, 200);
      }
    } finally {
      this.isAnimating = false;
    }
  }

  private async animateValue(key: string, from: number, to: number, duration: number): Promise<void> {
    return new Promise<void>((resolve) => {
      const startTime = Date.now();
      const animate = () => {
        const elapsed = Date.now() - startTime;
        const progress = Math.min(elapsed / duration, 1);
        const eased = this.easeOutCubic(progress);
        const value = from + (to - from) * eased;
        
        AppStorage.setOrCreate(key, value);
        
        if (progress < 1) {
          requestAnimationFrame(animate);
        } else {
          resolve();
        }
      };
      animate();
    });
  }

  private easeOutCubic(t: number): number {
    return 1 - Math.pow(1 - t, 3);
  }

  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}
