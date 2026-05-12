export type EmotionalState = 
  | 'idle'
  | 'happy'
  | 'sad'
  | 'shy'
  | 'angry'
  | 'surprised'
  | 'excited'
  | 'anxious'
  | 'lonely'
  | 'thinking'
  | 'talking'
  | 'listening'
  | 'sleeping';

export interface EmotionalTransition {
  from: EmotionalState | EmotionalState[];
  to: EmotionalState;
  condition?: () => boolean;
  weight: number;
  duration: number;
  easing: 'easeIn' | 'easeOut' | 'easeInOut' | 'linear';
}

export interface EmotionalValue {
  intensity: number;
  decayRate: number;
  priority: number;
  timestamp: number;
}

export interface EmotionalStateSnapshot {
  current: EmotionalState;
  intensity: number;
  previous: EmotionalState;
  transitionProgress: number;
  valueMap: Map<EmotionalState, EmotionalValue>;
}

export class EmotionalFSM {
  private static instance: EmotionalFSM | null = null;
  private state: EmotionalState = 'idle';
  private intensity: number = 0;
  private previousState: EmotionalState = 'idle';
  private transitionProgress: number = 1;
  private valueMap: Map<EmotionalState, EmotionalValue> = new Map();
  private isTransitioning: boolean = false;
  private transitionTimer: number | null = null;
  private decayTimer: number | null = null;

  private readonly transitions: EmotionalTransition[] = [
    { from: '*', to: 'happy', weight: 0.3, duration: 500, easing: 'easeOut' },
    { from: ['sad', 'angry'], to: 'idle', weight: 0.5, duration: 800, easing: 'easeInOut' },
    { from: ['idle', 'happy'], to: 'sad', weight: 0.2, duration: 600, easing: 'easeIn' },
    { from: '*', to: 'talking', weight: 0.9, duration: 300, easing: 'easeOut' },
    { from: 'talking', to: 'idle', weight: 0.8, duration: 400, easing: 'easeOut' },
    { from: '*', to: 'listening', weight: 0.8, duration: 200, easing: 'linear' },
    { from: 'listening', to: 'idle', weight: 0.7, duration: 300, easing: 'easeOut' },
    { from: '*', to: 'thinking', weight: 0.6, duration: 400, easing: 'easeInOut' },
    { from: 'thinking', to: 'idle', weight: 0.5, duration: 500, easing: 'easeOut' },
    { from: '*', to: 'sleeping', weight: 0.1, duration: 1500, easing: 'easeInOut' },
    { from: 'sleeping', to: 'idle', weight: 0.8, duration: 800, easing: 'easeOut' },
  ];

  private readonly statePriorities: Map<EmotionalState, number> = new Map([
    ['idle', 0],
    ['talking', 100],
    ['listening', 95],
    ['thinking', 90],
    ['happy', 70],
    ['sad', 75],
    ['shy', 60],
    ['angry', 80],
    ['surprised', 65],
    ['excited', 72],
    ['anxious', 78],
    ['lonely', 68],
    ['sleeping', 99],
  ]);

  private readonly stateDecayRates: Map<EmotionalState, number> = new Map([
    ['idle', 0.01],
    ['happy', 0.008],
    ['sad', 0.005],
    ['shy', 0.006],
    ['angry', 0.007],
    ['surprised', 0.015],
    ['excited', 0.012],
    ['anxious', 0.009],
    ['lonely', 0.004],
    ['thinking', 0.02],
    ['talking', 0.0],
    ['listening', 0.0],
    ['sleeping', 0.0],
  ]);

  private constructor() {
    this.init();
  }

  static getInstance(): EmotionalFSM {
    if (!this.instance) {
      this.instance = new EmotionalFSM();
    }
    return this.instance;
  }

  init(): void {
    for (const state of this.statePriorities.keys()) {
      this.valueMap.set(state, {
        intensity: 0,
        decayRate: this.stateDecayRates.get(state) || 0.01,
        priority: this.statePriorities.get(state) || 0,
        timestamp: Date.now(),
      });
    }
    this.valueMap.get('idle')!.intensity = 1;
    this.startDecay();
  }

  getState(): EmotionalStateSnapshot {
    return {
      current: this.state,
      intensity: this.intensity,
      previous: this.previousState,
      transitionProgress: this.transitionProgress,
      valueMap: new Map(this.valueMap),
    };
  }

  async triggerEmotion(emotion: EmotionalState, intensity: number = 0.8): Promise<void> {
    const currentPriority = this.statePriorities.get(this.state) || 0;
    const newPriority = this.statePriorities.get(emotion) || 0;

    if (this.isTransitioning) {
      if (newPriority > currentPriority + 20) {
        console.log('高优先级情绪强制切换');
      } else {
        console.log('状态正在过渡，拒绝低优先级情绪');
        return;
      }
    }

    if (emotion === this.state) {
      const currentValue = this.valueMap.get(this.state)!;
      currentValue.intensity = Math.min(1, currentValue.intensity + intensity * 0.3);
      this.intensity = Math.min(1, this.intensity + intensity * 0.2);
      return;
    }

    if (!this.canTransition(this.state, emotion)) {
      console.log(`无法从 ${this.state} 过渡到 ${emotion}`);
      return;
    }

    await this.performTransition(emotion, intensity);
  }

  private canTransition(from: EmotionalState, to: EmotionalState): boolean {
    if (from === to) return false;

    if (from === 'sleeping' && !['idle'].includes(to)) {
      return false;
    }

    if (to === 'sleeping' && ['talking', 'listening'].includes(from)) {
      return false;
    }

    return true;
  }

  private async performTransition(target: EmotionalState, intensity: number): Promise<void> {
    this.isTransitioning = true;
    this.previousState = this.state;
    this.transitionProgress = 0;

    const transition = this.findTransition(this.previousState, target);

    return new Promise((resolve) => {
      const duration = transition?.duration || 500;
      const startTime = Date.now();
      const startIntensity = this.intensity;
      const targetValue = this.valueMap.get(target)!;
      targetValue.intensity = intensity;
      targetValue.timestamp = Date.now();

      const animate = () => {
        const elapsed = Date.now() - startTime;
        const progress = Math.min(1, elapsed / duration);

        this.transitionProgress = this.applyEasing(progress, transition?.easing || 'easeOut');

        if (transition?.easing === 'easeOut') {
          this.intensity = startIntensity * (1 - this.transitionProgress) + intensity * this.transitionProgress;
        } else {
          this.intensity = intensity;
        }

        if (progress >= 0.5 && this.state !== target) {
          this.state = target;
        }

        if (progress < 1) {
          requestAnimationFrame(animate);
        } else {
          this.state = target;
          this.transitionProgress = 1;
          this.isTransitioning = false;
          resolve();
        }
      };

      animate();
    });
  }

  private findTransition(from: EmotionalState, to: EmotionalState): EmotionalTransition | null {
    return this.transitions.find(t => {
      if (t.from === '*') return t.to === to;
      if (Array.isArray(t.from)) return t.from.includes(from) && t.to === to;
      return t.from === from && t.to === to;
    }) || null;
  }

  private applyEasing(value: number, easing: string): number {
    switch (easing) {
      case 'easeIn':
        return value * value;
      case 'easeOut':
        return value * (2 - value);
      case 'easeInOut':
        return value < 0.5 ? 2 * value * value : 1 - Math.pow(-2 * value + 2, 2) / 2;
      case 'linear':
      default:
        return value;
    }
  }

  private startDecay(): void {
    if (this.decayTimer) {
      clearInterval(this.decayTimer);
    }

    this.decayTimer = setInterval(() => {
      for (const [state, value] of this.valueMap) {
        if (state !== this.state) {
          value.intensity = Math.max(0, value.intensity - value.decayRate);
        }
      }

      if (this.state !== 'idle' && !this.isTransitioning) {
        const currentValue = this.valueMap.get(this.state)!;
        currentValue.intensity = Math.max(0, currentValue.intensity - currentValue.decayRate * 0.5);
        
        if (currentValue.intensity < 0.05) {
          this.triggerEmotion('idle', 1);
        }
      }
    }, 100) as unknown as number;
  }

  async stop(): Promise<void> {
    if (this.decayTimer) {
      clearInterval(this.decayTimer);
      this.decayTimer = null;
    }
    if (this.transitionTimer) {
      clearTimeout(this.transitionTimer);
      this.transitionTimer = null;
    }
  }

  getEmotionPriority(emotion: EmotionalState): number {
    return this.statePriorities.get(emotion) || 0;
  }

  getCurrentPriority(): number {
    return this.statePriorities.get(this.state) || 0;
  }
}
