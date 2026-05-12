/**
 * DebugPanel - 调试面板组件
 * HarmonyOS NEXT ArkUI 标准实现
 */

import { Dispatcher } from '../core/Dispatcher';
import { EmotionStore, EmotionType } from '../core/EmotionStore';
import { EmotionalFSM, FSMState } from '../core/EmotionalFSM';
import { LifecycleManager } from '../core/LifecycleManager';

@Component
export struct DebugPanel {
  @State private currentState: FSMState = FSMState.IDLE;
  @State private currentEmotion: EmotionType = EmotionType.IDLE;
  @State private emotionWeights: Array<{ emotion: string; weight: number }> = [];
  @State private isInForeground: boolean = true;
  @State private isSleeping: boolean = false;
  @State private isExpanded: boolean = true;
  @State private stateDuration: number = 0;

  private fsm: EmotionalFSM = EmotionalFSM.getInstance();
  private emotionStore: EmotionStore = EmotionStore.getInstance();
  private lifecycleManager: LifecycleManager = LifecycleManager.getInstance();
  private dispatcher: Dispatcher = Dispatcher.getInstance();

  private subscriberIds: string[] = [];

  aboutToAppear(): void {
    this.subscribeToEvents();
    this.updateState();
  }

  aboutToDisappear(): void {
    this.unsubscribeFromEvents();
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

    const lockId = this.dispatcher.subscribe('fsm:lockAdded', () => {
      this.updateState();
    });
    this.subscriberIds.push(lockId);
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
    this.stateDuration = this.fsm.stateDuration;
    this.isInForeground = this.lifecycleManager.isInForeground;
    this.isSleeping = this.lifecycleManager.isSleeping;

    const topEmotions = this.emotionStore.getTopEmotions(5);
    this.emotionWeights = topEmotions.map(item => ({
      emotion: item.emotion,
      weight: item.weight
    }));
  }

  aboutToRender(): void {
    this.updateState();
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('🔧 调试面板')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')

        Blank()

        Text(this.isExpanded ? '▼' : '▶')
          .fontSize(12)
          .fontColor('#FFFFFF')
          .onClick(() => {
            this.isExpanded = !this.isExpanded;
          })
      }
      .width('100%')
      .padding(10)
      .backgroundColor('#333333')
      .borderRadius(8)

      if (this.isExpanded) {
        // FSM 状态
        this.buildSection('状态机 (FSM)', () => {
          Column() {
            Row() {
              Text('当前状态:')
                .fontSize(12)
                .fontColor('#AAAAAA')
                .width('40%')

              Text(this.currentState)
                .fontSize(12)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.getStateColor(this.currentState))
                .width('60%')
            }
            .width('100%')

            Row() {
              Text('持续时间:')
                .fontSize(11)
                .fontColor('#AAAAAA')
                .width('40%')

              Text(`${Math.floor(this.stateDuration / 1000)}s`)
                .fontSize(11)
                .fontColor('#50C878')
                .width('60%')
            }
            .width('100%')
            .margin({ top: 4 })

            if (this.fsm.activeLocks.length > 0) {
              ForEach(this.fsm.activeLocks, (lock: { state: FSMState; reason: string; timeout: number }) => {
                Row() {
                  Text('🔒 ' + lock.state)
                    .fontSize(11)
                    .fontColor('#FF6B6B')
                  Text(' - ' + lock.reason)
                    .fontSize(11)
                    .fontColor('#AAAAAA')
                }
                .width('100%')
                .margin({ top: 4 })
              })
            }
          }
        })

        // 情绪状态
        this.buildSection('情绪系统', () => {
          Column() {
            Row() {
              Text('当前情绪:')
                .fontSize(12)
                .fontColor('#AAAAAA')
                .width('40%')

              Text(this.currentEmotion)
                .fontSize(12)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.getEmotionColor(this.currentEmotion))
                .width('60%')
            }
            .width('100%')

            Divider()
              .color('#444444')
              .margin({ top: 8, bottom: 8 })

            ForEach(this.emotionWeights, (item: { emotion: string; weight: number }) => {
              Row() {
                Text(item.emotion)
                  .fontSize(11)
                  .fontColor('#CCCCCC')
                  .width('40%')

                Progress({ value: item.weight, total: 100 })
                  .color(this.getEmotionColor(item.emotion as EmotionType))
                  .width('40%')

                Text(`${item.weight}`)
                  .fontSize(11)
                  .fontColor('#888888')
                  .width('20%')
                  .textAlign(TextAlign.End)
              }
              .width('100%')
              .margin({ bottom: 4 })
            })
          }
        })

        // 应用状态
        this.buildSection('应用状态', () => {
          Column() {
            Row() {
              this.buildStatusIndicator('初始化', this.lifecycleManager.isInitialized)
            }
            .width('100%')

            Row() {
              this.buildStatusIndicator('前台', this.isInForeground)
            }
            .width('100%')

            Row() {
              this.buildStatusIndicator('睡眠', this.isSleeping)
            }
            .width('100%')

            Divider()
              .color('#444444')
              .margin({ top: 8, bottom: 8 })

            Row() {
              Text('页面数:')
                .fontSize(11)
                .fontColor('#AAAAAA')
                .width('50%')

              Text(`${this.lifecycleManager.registeredPages.size}`)
                .fontSize(11)
                .fontColor('#50C878')
                .width('50%')
            }
            .width('100%')

            Row() {
              Text('资源数:')
                .fontSize(11)
                .fontColor('#AAAAAA')
                .width('50%')

              Text(`${this.lifecycleManager.registeredResources.length}`)
                .fontSize(11)
                .fontColor('#50C878')
                .width('50%')
            }
            .width('100%')
          }
        })
      }
    }
    .width(250)
    .padding(10)
    .backgroundColor('rgba(30, 30, 30, 0.95)')
    .borderRadius(12)
    .border({
      width: 1,
      color: '#555555',
      radius: 12
    })
  }

  @Builder
  buildSection(title: string, content: () => void) {
    Column() {
      Text(title)
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .width('100%')
        .textAlign(TextAlign.Start)
        .margin({ bottom: 8 })

      content()
    }
    .width('100%')
    .padding(10)
    .backgroundColor('#2A2A2A')
    .borderRadius(6)
    .margin({ top: 8 })
  }

  @Builder
  buildStatusIndicator(label: string, isActive: boolean) {
    Row() {
      Circle()
        .size({ width: 8, height: 8 })
        .fill(isActive ? '#50C878' : '#FF6B6B')
        .margin({ right: 8 })

      Text(label)
        .fontSize(11)
        .fontColor('#CCCCCC')
        .width('60%')

      Text(isActive ? '●' : '○')
        .fontSize(11)
        .fontColor(isActive ? '#50C878' : '#FF6B6B')
        .width('40%')
    }
    .width('100%')
  }

  private getStateColor(state: FSMState): string {
    switch (state) {
      case FSMState.IDLE:
        return '#4A90D9';
      case FSMState.TALKING:
        return '#50C878';
      case FSMState.THINKING:
        return '#FFD700';
      case FSMState.HAPPY:
        return '#FF69B4';
      case FSMState.SAD:
        return '#6495ED';
      case FSMState.ANGRY:
        return '#FF4500';
      case FSMState.EXCITED:
        return '#FF1493';
      case FSMState.SCARED:
        return '#8A2BE2';
      case FSMState.CONFUSED:
        return '#FFA500';
      case FSMState.SLEEPING:
        return '#808080';
      default:
        return '#CCCCCC';
    }
  }

  private getEmotionColor(emotion: EmotionType): string {
    switch (emotion) {
      case EmotionType.IDLE:
        return '#4A90D9';
      case EmotionType.HAPPY:
        return '#50C878';
      case EmotionType.SAD:
        return '#6495ED';
      case EmotionType.ANGRY:
        return '#FF4500';
      case EmotionType.FEARFUL:
        return '#8A2BE2';
      case EmotionType.SURPRISED:
        return '#FFD700';
      case EmotionType.EXCITED:
        return '#FF1493';
      case EmotionType.ANXIOUS:
        return '#FFA500';
      case EmotionType.SHY:
        return '#FF69B4';
      case EmotionType.EMBARRASSED:
        return '#DA70D6';
      case EmotionType.TIRED:
        return '#808080';
      case EmotionType.CONFUSED:
        return '#9370DB';
      case EmotionType.NEUTRAL:
        return '#CCCCCC';
      default:
        return '#CCCCCC';
    }
  }
}
