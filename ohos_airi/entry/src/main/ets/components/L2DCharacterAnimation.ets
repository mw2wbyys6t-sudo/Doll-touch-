/**
 * L2DCharacterAnimation - Live2D风格多帧角色动画组件 (优化版)
 * 基于 Seedream AI 生成的6帧高质量角色图片实现平滑表情切换
 * 优化点：消除重复代码、减少重渲染、优化内存使用
 */
import { AppStorage } from '@kit.ArkUI';

interface FrameConfig {
  name: string;
  file: string;
}

@Component
export struct L2DCharacterAnimation {
  @StorageProp('bodyAngleX') bodyAngleX: number = 0.0;
  @StorageProp('bodyAngleY') bodyAngleY: number = 0.0;
  @StorageProp('bodyAngleZ') bodyAngleZ: number = 0.0;
  @StorageProp('hairSwing') hairSwing: number = 0.0;
  @StorageProp('clothingSwing') clothingSwing: number = 0.0;

  @State currentFrame: string = 'airi_idle';
  @State frameOpacity: number = 1.0;
  @State prevFrame: string = '';
  @State isTransitioning: boolean = false;
  @State imageLoadError: boolean = false;
  @State retryCount: number = 0;

  private readonly MAX_RETRIES: number = 3;
  private retryTimer: number = -1;
  private expressionWatcherTimer: number = -1;

  // 帧配置数组 - 消除重复代码
  private static readonly FRAME_CONFIGS: FrameConfig[] = [
    { name: 'airi_idle', file: 'airi_idle.png' },
    { name: 'airi_happy', file: 'airi_happy.png' },
    { name: 'airi_shy', file: 'airi_shy.png' },
    { name: 'airi_excited', file: 'airi_excited.png' },
    { name: 'airi_surprised', file: 'airi_surprised.png' },
    { name: 'airi_sing', file: 'airi_sing.png' },
  ];

  // 表情到帧的映射
  private readonly frameMap: Record<string, string> = {
    'idle': 'airi_idle',
    'happy': 'airi_happy',
    'sad': 'airi_shy',
    'surprised': 'airi_surprised',
    'excited': 'airi_excited',
    'shy': 'airi_shy',
    'angry': 'airi_excited',
    'sleepy': 'airi_idle',
    'sing': 'airi_sing',
  };

  aboutToAppear(): void {
    this.startExpressionWatcher();
  }

  aboutToDisappear(): void {
    this.clearAllTimers();
  }

  private clearAllTimers(): void {
    if (this.expressionWatcherTimer !== -1) {
      clearInterval(this.expressionWatcherTimer);
      this.expressionWatcherTimer = -1;
    }
    if (this.retryTimer !== -1) {
      clearTimeout(this.retryTimer);
      this.retryTimer = -1;
    }
  }

  private scheduleRetry(): void {
    if (this.retryCount < this.MAX_RETRIES) {
      this.retryCount++;
      this.retryTimer = setTimeout(() => {
        this.imageLoadError = false;
        this.retryTimer = -1;
      }, 1000 * this.retryCount);
    }
  }

  private startExpressionWatcher(): void {
    let lastExpression = '';
    this.expressionWatcherTimer = setInterval(() => {
      try {
        const eyeOpen = AppStorage.get<number>('eyeOpen');
        const mouthOpen = AppStorage.get<number>('mouthOpen');
        const cheek = AppStorage.get<number>('cheek');

        let expression = 'idle';
        if (mouthOpen && mouthOpen > 0.7) {
          expression = cheek && cheek > 0.4 ? 'excited' : 'happy';
        } else if (cheek && cheek > 0.5) {
          expression = 'shy';
        } else if (eyeOpen !== undefined && eyeOpen < 0.5) {
          expression = eyeOpen < 0.3 ? 'shy' : 'idle';
        }

        if (expression !== lastExpression) {
          lastExpression = expression;
          this.transitionTo(expression);
        }
      } catch (e) {
        // 静默处理，避免崩溃
      }
    }, 300);
  }

  private transitionTo(expression: string): void {
    const targetFrame = this.frameMap[expression] || 'airi_idle';
    if (targetFrame === this.currentFrame && !this.isTransitioning) return;

    this.prevFrame = this.currentFrame;
    this.currentFrame = targetFrame;
    this.isTransitioning = true;
    this.frameOpacity = 0.0;

    setTimeout(() => {
      this.frameOpacity = 1.0;
      setTimeout(() => {
        this.isTransitioning = false;
        this.prevFrame = '';
      }, 250);
    }, 80);
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      if (this.imageLoadError) {
        this.buildFallbackAvatar()
      } else {
        // 使用动态构建减少重复代码
        this.buildFrame(this.currentFrame, this.frameOpacity)

        if (this.isTransitioning && this.prevFrame) {
          this.buildFrame(this.prevFrame, 1.0 - this.frameOpacity)
        }
      }

      this.buildGlowEffect();
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor(Color.Transparent);
  }

  @Builder
  buildFrame(frameName: string, opacity: number) {
    const config = L2DCharacterAnimation.FRAME_CONFIGS.find(f => f.name === frameName);
    if (config) {
      Image($rawfile(config.file))
        .width(220)
        .height(380)
        .objectFit(ImageFit.Contain)
        .opacity(opacity)
        .transform(this.getTransform())
        .animation({
          duration: 200,
          easing: 'easeOutCubic'
        })
        .onError(() => {
          this.scheduleRetry();
          this.imageLoadError = true;
        })
    }
  }

  private getTransform(): object {
    return {
      rotateX: this.bodyAngleX * 15,
      rotateY: this.bodyAngleY * 15,
      rotateZ: this.bodyAngleZ * 15,
      scaleX: 1 + this.bodyAngleY * 0.08 + this.hairSwing * 0.03,
      scaleY: 1 + this.bodyAngleX * 0.04,
      translateX: this.hairSwing * 5,
      translateY: this.clothingSwing * 3
    };
  }

  @Builder
  buildFallbackAvatar() {
    Column({ space: 8 }) {
      Text('🌸')
        .fontSize(80)
      Text('星空愛莉')
        .fontColor('#9B64DC')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
    }
    .width(220)
    .height(380)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#FFF5F8')
    .borderRadius(20)
    .transform({
      rotateX: this.bodyAngleX * 15,
      rotateY: this.bodyAngleY * 15,
      rotateZ: this.bodyAngleZ * 15,
    })
    .animation({
      duration: 200,
      easing: 'easeOutCubic'
    });
  }

  @Builder
  buildGlowEffect() {
    Stack({ alignContent: Alignment.Center }) {
      Circle()
        .width(80)
        .height(80)
        .fill('#FFB6C1')
        .opacity(0.2)
        .blur(30)
        .animation({
          duration: 800,
          easing: 'easeInOut',
          iterations: -1,
          direction: 'alternate'
        });
    }
    .position({ x: 205, y: 160 })
    .transform({
      scale: 1 + Math.sin(Date.now() / 500) * 0.15
    });
  }
}
