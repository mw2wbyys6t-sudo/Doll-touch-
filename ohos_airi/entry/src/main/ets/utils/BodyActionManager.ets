import { safeGetAppStorageNumber, safeSetAppStorageNumber, requestAnimationFrame } from './AppStorageHelper';

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
  private returnToIdleTimer: number | null = null;

  private bodyParams: Record<BodyActionType, BodyParams> = {
    idle_sway: { bodyAngleX: 0.0, bodyAngleY: 0.0, bodyAngleZ: 0.0, armLeftAngleX: 0.0, armLeftAngleY: 0.0, armRightAngleX: 0.0, armRightAngleY: 0.0, legAngleX: 0.0, legAngleY: 0.0, hairSwing: 0.0, clothingSwing: 0.0 },
    wave: { bodyAngleX: 0.0, bodyAngleY: 0.05, bodyAngleZ: 0.0, armLeftAngleX: 0.0, armLeftAngleY: 0.0, armRightAngleX: 0.6, armRightAngleY: 0.3, legAngleX: 0.0, legAngleY: 0.0, hairSwing: 0.1, clothingSwing: 0.05 },
    dance: { bodyAngleX: 0.1, bodyAngleY: 0.1, bodyAngleZ: 0.1, armLeftAngleX: 0.4, armLeftAngleY: 0.4, armRightAngleX: -0.4, armRightAngleY: 0.4, legAngleX: 0.2, legAngleY: 0.2, hairSwing: 0.3, clothingSwing: 0.2 },
    jump: { bodyAngleX: 0.0, bodyAngleY: 0.0, bodyAngleZ: 0.0, armLeftAngleX: 0.5, armLeftAngleY: -0.5, armRightAngleX: 0.5, armRightAngleY: -0.5, legAngleX: 0.0, legAngleY: 0.0, hairSwing: 0.4, clothingSwing: 0.3 },
    sit: { bodyAngleX: 0.3, bodyAngleY: 0.0, bodyAngleZ: 0.0, armLeftAngleX: 0.2, armLeftAngleY: 0.3, armRightAngleX: 0.2, armRightAngleY: 0.3, legAngleX: 0.5, legAngleY: 0.3, hairSwing: 0.0, clothingSwing: 0.1 },
    stand: { bodyAngleX: 0.0, bodyAngleY: 0.0, bodyAngleZ: 0.0, armLeftAngleX: 0.1, armLeftAngleY: 0.2, armRightAngleX: -0.1, armRightAngleY: 0.2, legAngleX: 0.0, legAngleY: 0.0, hairSwing: 0.0, clothingSwing: 0.0 },
    point: { bodyAngleX: 0.0, bodyAngleY: 0.1, bodyAngleZ: 0.0, armLeftAngleX: 0.0, armLeftAngleY: 0.0, armRightAngleX: 0.8, armRightAngleY: -0.2, legAngleX: 0.0, legAngleY: 0.0, hairSwing: 0.1, clothingSwing: 0.05 }
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

    this.clearReturnToIdleTimer();

    this.isAnimating = true;
    this.currentAction = action;

    try {
      await this.animateAction(action, duration);
    } catch (error) {
      console.error(`Body action failed: ${error}`);
    } finally {
      this.isAnimating = false;
      if (action !== 'idle_sway') {
        this.scheduleReturnToIdle(duration + 200);
      }
    }
  }

  private scheduleReturnToIdle(delay: number): void {
    this.clearReturnToIdleTimer();
    this.returnToIdleTimer = setTimeout(() => {
      this.returnToIdleTimer = null;
      if (!this.isAnimating) {
        this.playAction('idle_sway', 300);
      }
    }, delay) as unknown as number;
  }

  private clearReturnToIdleTimer(): void {
    if (this.returnToIdleTimer !== null) {
      clearTimeout(this.returnToIdleTimer);
      this.returnToIdleTimer = null;
    }
  }

  private async animateAction(action: BodyActionType, duration: number): Promise<void> {
    const targetParams = this.getBodyParams(action);
    const params = Object.keys(targetParams) as (keyof BodyParams)[];
    params.forEach(key => {
      safeSetAppStorageNumber(key, targetParams[key]);
    });
    return new Promise(resolve => {
      setTimeout(resolve, duration);
    });
  }

  startIdleAnimation(): void {
    this.stopCurrentAction();
    this.clearReturnToIdleTimer();

    let time = 0;
    this.animationTimer = setInterval(() => {
      try {
        time += 0.05;
        const sway = Math.sin(time) * 0.02;
        const hairSwing = Math.sin(time * 1.5) * 0.05;
        const clothingSwing = Math.sin(time * 0.8) * 0.03;
        safeSetAppStorageNumber('bodyAngleY', sway);
        safeSetAppStorageNumber('hairSwing', hairSwing);
        safeSetAppStorageNumber('clothingSwing', clothingSwing);
        const armSwing = Math.sin(time * 2) * 0.05;
        safeSetAppStorageNumber('armLeftAngleX', armSwing);
        safeSetAppStorageNumber('armRightAngleX', -armSwing);
      } catch (error) {
        console.error('BodyActionManager: idle animation failed:', error);
      }
    }, 50) as unknown as number;
  }

  stopCurrentAction(): void {
    if (this.animationTimer) {
      clearInterval(this.animationTimer);
      this.animationTimer = null;
    }
    this.isAnimating = false;
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
      const startAngle = safeGetAppStorageNumber('armRightAngleX', 0.6);
      let time = 0;
      const animate = () => {
        try {
          time += 0.1;
          safeSetAppStorageNumber('armRightAngleX', startAngle * Math.sin(time * 10));
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
            const t = elapsed / 1000;
            safeSetAppStorageNumber('bodyAngleX', Math.sin(t * 3) * 0.1);
            safeSetAppStorageNumber('bodyAngleY', Math.cos(t * 4) * 0.1);
            safeSetAppStorageNumber('bodyAngleZ', Math.sin(t * 2) * 0.05);
            safeSetAppStorageNumber('armLeftAngleX', Math.sin(t * 5) * 0.4);
            safeSetAppStorageNumber('armRightAngleX', Math.cos(t * 5) * 0.4);
            safeSetAppStorageNumber('armLeftAngleY', Math.cos(t * 3) * 0.4);
            safeSetAppStorageNumber('armRightAngleY', Math.sin(t * 3) * 0.4);
            safeSetAppStorageNumber('hairSwing', Math.sin(t * 6) * 0.3);
            safeSetAppStorageNumber('clothingSwing', Math.sin(t * 4) * 0.2);
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
