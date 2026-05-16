/**
 * DebugPanel - 调试面板组件
 * HarmonyOS NEXT ArkUI 实现
 * 用于实时显示系统状态
 */

import {
  DebugPanelViewModel,
  debugPanelViewModel
} from './DebugPanelViewModel';
import { FSMState } from './EmotionalFSM';
import { EmotionType } from './EmotionStore';

// 状态颜色映射
function getStateColor(state: FSMState): string {
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

// 情绪颜色映射
function getEmotionColor(emotion: EmotionType): string {
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

@Component
export struct DebugPanel {
  @State private viewModel: DebugPanelViewModel = debugPanelViewModel;
  @State private isExpanded: boolean = true;

  build() {
    if (this.viewModel.isVisible) {
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
                Text(this.viewModel.currentState)
                  .fontSize(12)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(getStateColor(this.viewModel.currentState))
              }
              .width('100%')

              if (this.viewModel.activeLocks.length > 0) {
                ForEach(this.viewModel.activeLocks, (lock: {
                  state: string;
                  reason: string;
                  timeout: number;
                }) => {
                  Row() {
                    Text('🔒 ' + lock.state)
                      .fontSize(11)
                      .fontColor('#FF6B6B')
                    Text(' - ' + lock.reason)
                      .fontSize(11)
                      .fontColor('#AAAAAA')
                  }
                  .width('100%')
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
                Text(this.viewModel.currentEmotion)
                  .fontSize(12)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(getEmotionColor(this.viewModel.currentEmotion))
              }
              .width('100%')

              Divider()
                .color('#444444')
                .margin({ top: 5, bottom: 5 })

              ForEach(this.viewModel.emotionWeights, (item: {
                emotion: string;
                weight: number;
              }) => {
                Row() {
                  Text(item.emotion)
                    .fontSize(11)
                    .fontColor('#CCCCCC')
                    .width('50%')

                  Progress({ value: item.weight, total: 100 })
                    .color(getEmotionColor(item.emotion as EmotionType))
                    .width('30%')

                  Text(`${item.weight}`)
                    .fontSize(11)
                    .fontColor('#888888')
                    .width('20%')
                    .textAlign(TextAlign.End)
                }
                .width('100%')
              })
            }
          })

          // 应用状态
          this.buildSection('应用状态', () => {
            Column() {
              Row() {
                this.buildStatusIndicator('初始化', this.viewModel.isInitialized)
              }

              Row() {
                this.buildStatusIndicator('前台', this.viewModel.isInForeground)
              }

              Row() {
                this.buildStatusIndicator('睡眠', this.viewModel.isSleeping)
              }

              Divider()
                .color('#444444')
                .margin({ top: 5, bottom: 5 })

              Row() {
                Text('页面数:')
                  .fontSize(11)
                  .fontColor('#AAAAAA')
                Text(`${this.viewModel.pageCount}`)
                  .fontSize(11)
                  .fontColor('#50C878')
              }
              .width('100%')

              Row() {
                Text('资源数:')
                  .fontSize(11)
                  .fontColor('#AAAAAA')
                Text(`${this.viewModel.resourceCount}`)
                  .fontSize(11)
                  .fontColor('#50C878')
              }
              .width('100%')
            }
          })

          // 性能信息
          this.buildSection('性能监控', () => {
            Column() {
              Row() {
                Text('FPS:')
                  .fontSize(11)
                  .fontColor('#AAAAAA')
                Text(`${this.viewModel.fps}`)
                  .fontSize(11)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.viewModel.fps >= 50 ? '#50C878' : '#FF6B6B')
              }
              .width('100%')

              Row() {
                Text('内存:')
                  .fontSize(11)
                  .fontColor('#AAAAAA')
                Text(this.viewModel.memoryUsage)
                  .fontSize(11)
                  .fontColor('#50C878')
              }
              .width('100%')
            }
          })
        }
      }
      .width(this.viewModel.config.width)
      .padding(10)
      .backgroundColor('rgba(30, 30, 30, 0.95)')
      .borderRadius(12)
      .border({
        width: 1,
        color: '#555555',
        radius: 12
      })
      .shadow({
        radius: 10,
        color: 'rgba(0, 0, 0, 0.5)',
        offsetX: 2,
        offsetY: 2
      })
      .position({
        x: this.viewModel.config.positionX,
        y: this.viewModel.config.positionY
      })
    }
  }

  @Builder
  buildSection(title: string, content: () => void) {
    Column() {
      Text(title)
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
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

      Text(isActive ? '●' : '○')
        .fontSize(11)
        .fontColor(isActive ? '#50C878' : '#FF6B6B')
        .margin({ left: 4 })
    }
    .width('100%')
  }
}
