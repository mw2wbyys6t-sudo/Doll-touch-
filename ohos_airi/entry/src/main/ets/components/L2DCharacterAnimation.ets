/**
 * L2DCharacterAnimation - Live2D风格多帧角色动画组件
 * 基于 Seedream AI 生成的6帧高质量角色图片实现平滑表情切换
 */
import { AppStorage } from '@kit.ArkUI';

@Component
export struct L2DCharacterAnimation {
  @StorageProp('bodyAngleX') bodyAngleX: number = 0.0;
  @StorageProp('bodyAngleY') bodyAngleY: number = 0.0;
  @StorageProp('bodyAngleZ') bodyAngleZ: number = 0.0;
  @StorageProp('hairSwing') hairSwing: number = 0.0;
  @StorageProp('clothingSwing') clothingSwing: number = 0.0;

  @State currentFrame: string = 'airi_idle';
  @State frameOpacity: number = 1.0;
  @State prevFrame: string = 'airi_idle';
  @State isTransitioning: boolean = false;
  @State imageLoadError: boolean = false;

  private frameMap: Record<string, string> = {
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

  private expressionWatcherTimer: number = -1;

  aboutToAppear(): void {
    this.startExpressionWatcher();
  }

  aboutToDisappear(): void {
    if (this.expressionWatcherTimer !== -1) {
      clearInterval(this.expressionWatcherTimer);
      this.expressionWatcherTimer = -1;
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
      }
    }, 300);
  }

  private transitionTo(expression: string): void {
    const targetFrame = this.frameMap[expression] || 'airi_idle';
    if (targetFrame === this.currentFrame && !this.isTransitioning) return;

    this.prevFrame = this.currentFrame;
    this.currentFrame = targetFrame;
    this.isTransitioning = true;

    // 新图片先设为透明，让 ArkUI 开始加载
    this.frameOpacity = 0.0;

    // 延迟淡入，给图片加载时间
    setTimeout(() => {
      this.frameOpacity = 1.0;
      // 过渡完成后清理 prevFrame
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
        this.buildCharacterImage(this.currentFrame, this.frameOpacity)

        if (this.isTransitioning) {
          this.buildCharacterImage(this.prevFrame, 1.0 - this.frameOpacity)
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
  buildCharacterImage(frameName: string, opacity: number) {
    if (frameName === 'airi_idle') {
      Image($rawfile('airi_idle.png'))
        .width(220)
        .height(380)
        .objectFit(ImageFit.Contain)
        .opacity(opacity)
        .transform({
          rotateX: this.bodyAngleX * 15,
          rotateY: this.bodyAngleY * 15,
          rotateZ: this.bodyAngleZ * 15,
          scaleX: 1 + this.bodyAngleY * 0.08 + this.hairSwing * 0.03,
          scaleY: 1 + this.bodyAngleX * 0.04,
          translateX: this.hairSwing * 5,
          translateY: this.clothingSwing * 3
        })
        .animation({
          duration: 200,
          easing: 'easeOutCubic'
        })
        .onError(() => {
          this.imageLoadError = true;
        })
    } else if (frameName === 'airi_happy') {
      Image($rawfile('airi_happy.png'))
        .width(220)
        .height(380)
        .objectFit(ImageFit.Contain)
        .opacity(opacity)
        .transform({
          rotateX: this.bodyAngleX * 15,
          rotateY: this.bodyAngleY * 15,
          rotateZ: this.bodyAngleZ * 15,
          scaleX: 1 + this.bodyAngleY * 0.08 + this.hairSwing * 0.03,
          scaleY: 1 + this.bodyAngleX * 0.04,
          translateX: this.hairSwing * 5,
          translateY: this.clothingSwing * 3
        })
        .animation({
          duration: 200,
          easing: 'easeOutCubic'
        })
        .onError(() => {
          this.imageLoadError = true;
        })
    } else if (frameName === 'airi_shy') {
      Image($rawfile('airi_shy.png'))
        .width(220)
        .height(380)
        .objectFit(ImageFit.Contain)
        .opacity(opacity)
        .transform({
          rotateX: this.bodyAngleX * 15,
          rotateY: this.bodyAngleY * 15,
          rotateZ: this.bodyAngleZ * 15,
          scaleX: 1 + this.bodyAngleY * 0.08 + this.hairSwing * 0.03,
          scaleY: 1 + this.bodyAngleX * 0.04,
          translateX: this.hairSwing * 5,
          translateY: this.clothingSwing * 3
        })
        .animation({
          duration: 200,
          easing: 'easeOutCubic'
        })
        .onError(() => {
          this.imageLoadError = true;
        })
    } else if (frameName === 'airi_excited') {
      Image($rawfile('airi_excited.png'))
        .width(220)
        .height(380)
        .objectFit(ImageFit.Contain)
        .opacity(opacity)
        .transform({
          rotateX: this.bodyAngleX * 15,
          rotateY: this.bodyAngleY * 15,
          rotateZ: this.bodyAngleZ * 15,
          scaleX: 1 + this.bodyAngleY * 0.08 + this.hairSwing * 0.03,
          scaleY: 1 + this.bodyAngleX * 0.04,
          translateX: this.hairSwing * 5,
          translateY: this.clothingSwing * 3
        })
        .animation({
          duration: 200,
          easing: 'easeOutCubic'
        })
        .onError(() => {
          this.imageLoadError = true;
        })
    } else if (frameName === 'airi_surprised') {
      Image($rawfile('airi_surprised.png'))
        .width(220)
        .height(380)
        .objectFit(ImageFit.Contain)
        .opacity(opacity)
        .transform({
          rotateX: this.bodyAngleX * 15,
          rotateY: this.bodyAngleY * 15,
          rotateZ: this.bodyAngleZ * 15,
          scaleX: 1 + this.bodyAngleY * 0.08 + this.hairSwing * 0.03,
          scaleY: 1 + this.bodyAngleX * 0.04,
          translateX: this.hairSwing * 5,
          translateY: this.clothingSwing * 3
        })
        .animation({
          duration: 200,
          easing: 'easeOutCubic'
        })
        .onError(() => {
          this.imageLoadError = true;
        })
    } else if (frameName === 'airi_sing') {
      Image($rawfile('airi_sing.png'))
        .width(220)
        .height(380)
        .objectFit(ImageFit.Contain)
        .opacity(opacity)
        .transform({
          rotateX: this.bodyAngleX * 15,
          rotateY: this.bodyAngleY * 15,
          rotateZ: this.bodyAngleZ * 15,
          scaleX: 1 + this.bodyAngleY * 0.08 + this.hairSwing * 0.03,
          scaleY: 1 + this.bodyAngleX * 0.04,
          translateX: this.hairSwing * 5,
          translateY: this.clothingSwing * 3
        })
        .animation({
          duration: 200,
          easing: 'easeOutCubic'
        })
        .onError(() => {
          this.imageLoadError = true;
        })
    }
  }

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
