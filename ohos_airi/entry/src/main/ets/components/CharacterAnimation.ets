@Entry
@Component
struct CharacterAnimation {
  @StorageProp('eyeOpen') eyeOpen: number = 1.0;
  @StorageProp('eyeBrowY') eyeBrowY: number = 0.0;
  @StorageProp('mouthOpen') mouthOpen: number = 0.2;
  @StorageProp('mouthForm') mouthForm: number = 0.0;
  @StorageProp('cheek') cheek: number = 0.0;
  @StorageProp('headAngleX') headAngleX: number = 0.0;
  @StorageProp('headAngleY') headAngleY: number = 0.0;
  @StorageProp('headAngleZ') headAngleZ: number = 0.0;
  @StorageProp('bodyAngleX') bodyAngleX: number = 0.0;
  @StorageProp('bodyAngleY') bodyAngleY: number = 0.0;
  @StorageProp('bodyAngleZ') bodyAngleZ: number = 0.0;
  @StorageProp('armLeftAngleX') armLeftAngleX: number = 0.0;
  @StorageProp('armRightAngleX') armRightAngleX: number = 0.0;
  @StorageProp('hairSwing') hairSwing: number = 0.0;
  @StorageProp('clothingSwing') clothingSwing: number = 0.0;

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Image('https://neeko-copilot.bytedance.net/api/text_to_image?prompt=anime%20girl%20idol%20character%20Hoshizora%20Airi%20starry%20sky%20theme%20pink%20purple%20gradient%20hair%20cute%20idol%20outfit%20mic%20cheerful%20pose%20anime%20style%20full%20body&image_size=portrait_4_3')
        .width(200)
        .height(350)
        .objectFit(ImageFit.Contain)
        .transform({
          rotateX: this.bodyAngleX * 15,
          rotateY: this.bodyAngleY * 15,
          rotateZ: this.bodyAngleZ * 15,
          scaleX: 1 + this.bodyAngleY * 0.1,
          scaleY: 1 + this.bodyAngleX * 0.05
        })
        .animation({
          duration: 200,
          easing: 'easeOutCubic'
        });

      this.buildFaceOverlay();
      this.buildGlowEffect();
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor(Color.Transparent);
  }

  buildFaceOverlay() {
    Column({ space: 0 }) {
      Stack({ alignContent: Alignment.Center }) {
        this.buildEyes();
        this.buildEyeBrows();
      }
      .width(80)
      .height(60);

      this.buildMouth();
      this.buildCheeks();
    }
    .width(100)
    .height(120)
    .position({ x: 200, y: 120 })
    .transform({
      rotateX: this.headAngleX * 20,
      rotateY: this.headAngleY * 20,
      rotateZ: this.headAngleZ * 20,
      translateX: this.headAngleY * 10,
      translateY: this.headAngleX * 5
    })
    .animation({
      duration: 200,
      easing: 'easeOutCubic'
    });
  }

  buildEyes() {
    Row({ space: 16 }) {
      this.buildEye(true);
      this.buildEye(false);
    }
    .width('100%')
    .justifyContent(FlexAlign.Center);
  }

  buildEye(isLeft: boolean) {
    const blinkScale = Math.max(0.1, this.eyeOpen);
    return Stack({ alignContent: Alignment.Center }) {
      Ellipse()
        .width(20)
        .height(24)
        .fill('#ffffff')
        .transform({
          scaleY: blinkScale
        })
        .animation({
          duration: 100,
          easing: 'easeInOut'
        });

      Ellipse()
        .width(12)
        .height(16)
        .fill('#6B4E9E')
        .transform({
          scaleY: blinkScale
        })
        .animation({
          duration: 100,
          easing: 'easeInOut'
        });

      Circle()
        .width(4)
        .height(4)
        .fill('#ffffff')
        .position({ x: 3, y: -3 })
        .transform({
          scaleY: blinkScale
        })
        .animation({
          duration: 100,
          easing: 'easeInOut'
        });
    }
    .width(24)
    .height(28)
    .transform({
      translateY: this.eyeBrowY * 3
    });
  }

  buildEyeBrows() {
    Row({ space: 16 }) {
      this.buildEyeBrow(true);
      this.buildEyeBrow(false);
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .position({ y: -28 });
  }

  buildEyeBrow(isLeft: boolean) {
    return Row() {
      Ellipse()
        .width(18)
        .height(4)
        .fill('#4A3780')
        .transform({
          translateY: this.eyeBrowY * 5,
          rotate: isLeft ? this.eyeBrowY * 10 : -this.eyeBrowY * 10
        })
        .animation({
          duration: 200,
          easing: 'easeOutCubic'
        });
    }
    .width(20)
    .height(8);
  }

  buildMouth() {
    const mouthHeight = 8 + this.mouthOpen * 16;
    const mouthWidth = 20 + this.mouthForm * 10;
    
    return Stack({ alignContent: Alignment.Center }) {
      Ellipse()
        .width(mouthWidth)
        .height(mouthHeight)
        .fill('#E91E63')
        .animation({
          duration: 200,
          easing: 'easeOutCubic'
        });

      if (this.mouthForm > 0.3) {
        Row({ space: 4 }) {
          Circle()
            .width(4)
            .height(4)
            .fill('#FFCDD2');
          Circle()
            .width(4)
            .height(4)
            .fill('#FFCDD2');
        }
        .position({ y: -2 });
      }
    }
    .width(30)
    .height(24)
    .position({ x: 35, y: 45 });
  }

  buildCheeks() {
    Row({ space: 28 }) {
      this.buildCheek(true);
      this.buildCheek(false);
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .position({ y: 35 });
  }

  buildCheek(isLeft: boolean) {
    const opacity = Math.min(1, this.cheek);
    const scale = 1 + this.cheek * 0.3;
    
    return Circle()
      .width(12)
      .height(10)
      .fill('#FFCDD2')
      .opacity(opacity)
      .transform({
        scaleX: scale,
        scaleY: scale
      })
      .animation({
        duration: 300,
        easing: 'easeOutCubic'
      });
  }

  buildGlowEffect() {
    if (this.cheek > 0.5 || this.mouthOpen > 0.7) {
      Stack({ alignContent: Alignment.Center }) {
        Circle()
          .width(60)
          .height(60)
          .fill('#FFB6C1')
          .opacity(0.3)
          .blur(20)
          .animation({
            duration: 500,
            easing: 'easeInOut',
            iterations: -1,
            direction: 'alternate'
          });
      }
      .position({ x: 190, y: 140 })
      .transform({
        scale: 1 + Math.sin(Date.now() / 500) * 0.1
      });
    }
  }
}
