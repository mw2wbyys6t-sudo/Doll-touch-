/**
 * Index - 主页面
 * HarmonyOS NEXT ArkUI 标准实现
 */

import { LifecycleManager } from '../core/LifecycleManager';
import { EmotionalFSM, FSMState } from '../core/EmotionalFSM';
import { EmotionStore, EmotionType } from '../core/EmotionStore';
import { Dispatcher } from '../core/Dispatcher';

@Entry
@Component
struct Index {
  @State private currentState: FSMState = FSMState.IDLE;
  @State private currentEmotion: EmotionType = EmotionType.IDLE;
  @State private emotionWeights: Array<{ emotion: string; weight: number }> = [];
  @State private message: string = '';
  @State private showDebugPanel: boolean = true;

  private fsm: EmotionalFSM = EmotionalFSM.getInstance();
  private emotionStore: EmotionStore = EmotionStore.getInstance();
  private lifecycleManager: LifecycleManager = LifecycleManager.getInstance();
  private dispatcher: Dispatcher = Dispatcher.getInstance();

  private subscriberIds: string[] = [];

  aboutToAppear(): void {
    this.lifecycleManager.onAppear('Index');
    this.subscribeToEvents();
    this.updateState();
  }

  aboutToDisappear(): void {
    this.unsubscribeFromEvents();
    this.lifecycleManager.onDisappear('Index');
  }

  private subscribeToEvents(): void {
    const fsmId = this.dispatcher.subscribe('fsm:stateChanged', () => {
      this.updateState();
    });
    this.subscriberIds.push(fsmId);

    const emotionId = this.dispatcher.subscribe('emotion:changed', () => {
      this.updateState();
    });
    this.subscriberIds.push(emotionId);
  }

  private unsubscribeFromEvents(): void {
    for (const id of this.subscriberIds) {
      this.dispatcher.unsubscribe(id);
    }
    this.subscriberIds = [];
  }

  private updateState(): void {
    this.currentState = this.fsm.currentState;
    this.currentEmotion = this.emotionStore.currentEmotion;

    const topEmotions = this.emotionStore.getTopEmotions(5);
    this.emotionWeights = topEmotions.map(item => ({
      emotion: item.emotion,
      weight: item.weight
    }));
  }

  build() {
    Stack() {
      Column() {
        // 顶部状态栏
        this.buildStatusBar()

        // 主内容区域
        this.buildContentArea()

        // 调试面板
        if (this.showDebugPanel) {
          this.buildDebugPanel()
        }

        // 底部输入区
        this.buildInputArea()
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  buildStatusBar() {
    Row() {
      Text('星空爱莉 AI助手')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')

      Blank()

      Text(this.currentState)
        .fontSize(14)
        .fontColor('#666666')
        .backgroundColor('#F0F0F0')
        .padding(8)
        .borderRadius(4)
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
  }

  @Builder
  buildContentArea() {
    Column() {
      // 角色状态
      Row() {
        Text('当前状态: ')
          .fontSize(16)
          .fontColor('#666666')

        Text(this.currentEmotion)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FF6B9D')
      }
      .width('100%')
      .padding(16)

      Divider()
        .color('#EEEEEE')

      // 操作按钮
      Column() {
        Text('状态测试')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .width('100%')
          .textAlign(TextAlign.Start)
          .margin({ bottom: 12 })

        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
          Button('说话')
            .fontSize(14)
            .onClick(() => {
              this.fsm.transitionTo(FSMState.TALKING);
            })

          Button('思考')
            .fontSize(14)
            .onClick(() => {
              this.fsm.transitionTo(FSMState.THINKING);
            })

          Button('开心')
            .fontSize(14)
            .onClick(() => {
              this.fsm.transitionTo(FSMState.HAPPY);
            })

          Button('悲伤')
            .fontSize(14)
            .onClick(() => {
              this.fsm.transitionTo(FSMState.SAD);
            })

          Button('愤怒')
            .fontSize(14)
            .onClick(() => {
              this.fsm.transitionTo(FSMState.ANGRY);
            })

          Button('睡觉')
            .fontSize(14)
            .onClick(() => {
              this.fsm.transitionTo(FSMState.SLEEPING);
            })

          Button('重置')
            .fontSize(14)
            .onClick(() => {
              this.fsm.resetToIdle();
            })
        }
        .width('100%')
      }
      .width('100%')
      .padding(16)

      Divider()
        .color('#EEEEEE')

      // 情绪权重显示
      Column() {
        Text('情绪权重')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .width('100%')
          .textAlign(TextAlign.Start)
          .margin({ bottom: 12 })

        ForEach(this.emotionWeights, (item: { emotion: string; weight: number }) => {
          Row() {
            Text(item.emotion)
              .fontSize(14)
              .fontColor('#666666')
              .width('30%')

            Progress({ value: item.weight, total: 100 })
              .width('50%')
              .color('#FF6B9D')

            Text(`${item.weight}`)
              .fontSize(14)
              .fontColor('#999999')
              .width('20%')
              .textAlign(TextAlign.End)
          }
          .width('100%')
          .margin({ bottom: 8 })
        })
      }
      .width('100%')
      .padding(16)
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  buildDebugPanel() {
    Column() {
      Row() {
        Text('🔧 调试信息')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')

        Blank()

        Text('✕')
          .fontSize(14)
          .fontColor('#FFFFFF')
          .onClick(() => {
            this.showDebugPanel = false;
          })
      }
      .width('100%')
      .padding(10)
      .backgroundColor('#333333')
      .borderRadius(8)

      Column() {
        Text(`FSM: ${this.currentState}`)
          .fontSize(12)
          .fontColor('#CCCCCC')

        Text(`情绪: ${this.currentEmotion}`)
          .fontSize(12)
          .fontColor('#CCCCCC')
          .margin({ top: 4 })

        Text(`状态持续: ${Math.floor(this.fsm.stateDuration / 1000)}s`)
          .fontSize(12)
          .fontColor('#CCCCCC')
          .margin({ top: 4 })

        Text(`前台: ${this.lifecycleManager.isInForeground ? '是' : '否'}`)
          .fontSize(12)
          .fontColor('#CCCCCC')
          .margin({ top: 4 })

        Text(`睡眠: ${this.lifecycleManager.isSleeping ? '是' : '否'}`)
          .fontSize(12)
          .fontColor('#CCCCCC')
          .margin({ top: 4 })
      }
      .width('100%')
      .padding(10)
      .backgroundColor('#2A2A2A')
      .borderRadius(6)
      .margin({ top: 8 })
    }
    .width(200)
    .padding(10)
    .backgroundColor('rgba(30, 30, 30, 0.95)')
    .borderRadius(12)
    .position({ x: 10, y: 100 })
  }

  @Builder
  buildInputArea() {
    Column() {
      Divider()
        .color('#EEEEEE')

      Row() {
        TextInput({ placeholder: '输入测试消息...' })
          .fontSize(16)
          .width('80%')
          .height(44)
          .borderRadius(22)
          .backgroundColor('#F5F5F5')
          .padding({ left: 16 })
          .onChange((value: string) => {
            this.message = value;
          })

        Button('发送')
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor('#FF6B9D')
          .borderRadius(22)
          .width('18%')
          .height(44)
          .onClick(() => {
            this.handleSend();
          })
      }
      .width('100%')
      .padding(16)
    }
    .backgroundColor('#FFFFFF')
  }

  private handleSend(): void {
    if (this.message.trim() === '') {
      return;
    }

    console.info(`[Index] 发送消息: ${this.message}`);

    // 标记用户活动
    this.lifecycleManager.markUserActivity();

    // 切换到说话状态
    this.fsm.transitionTo(FSMState.TALKING);

    // 设置情绪
    this.emotionStore.setEmotion(EmotionType.HAPPY, 80);

    // 清空输入
    this.message = '';
  }
}
