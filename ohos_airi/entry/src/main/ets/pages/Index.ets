import { promptAction } from '@kit.ArkUI';
import { ChatViewModel } from '../viewmodel/ChatViewModel';
import { ThemeManager, ThemeMode } from '../utils/ThemeManager';
import { MessageBubble } from '../components/MessageBubble';
import { TypingIndicator } from '../components/TypingIndicator';
import { ActionBtn } from '../components/ActionBtn';
import { BottomNav } from '../components/BottomNav';
import { L2DCharacterAnimation } from '../components/L2DCharacterAnimation';
import { ExpressionManager } from '../utils/ExpressionManager';
import { BodyActionManager } from '../utils/BodyActionManager';
import { LifecycleManager } from '../core/LifecycleManager';
import { safeGetAppStorageNumber } from '../utils/AppStorageHelper';
import { Message } from '../model/MessageModel';

const ENABLE_LIFECYCLE_MANAGER = true;

const chatViewModel = new ChatViewModel();
const expressionManager = ExpressionManager.getInstance();
const bodyActionManager = BodyActionManager.getInstance();
const lifecycleManager = LifecycleManager.getInstance();

// 消息显示上限，避免性能问题
const MAX_DISPLAY_MESSAGES = 50;

@Entry
@Component
struct Index {
  scroller: Scroller = new Scroller();
  inputController: TextInputController = new TextInputController();

  @State inputText: string = '';
  @State showThemeMenu: boolean = false;
  @State currentTheme: ThemeMode = 'light';
  @State safeAreaTop: number = 0;
  @State messages: Message[] = [];
  @State isTyping: boolean = false;
  @State currentTab: string = 'chat';
  @State hasError: boolean = false;
  @State errorMessage: string = '';
  private messageVersion: number = 0;

  // 使用 number = -1 替代 number | null，避免 ArkTS 严格模式问题
  private blinkTimerId: number = -1;
  private themeListener: (() => void) | null = null;
  private isDisposed: boolean = false;

  build() {
    if (this.hasError) {
      return this.buildErrorFallback();
    }

    const colors = ThemeManager.getThemeColors();

    Column({ space: 0 }) {
      this.buildHeader(colors)

      Stack({ alignContent: Alignment.TopCenter }) {
        Column({ space: 16 }) {
          L2DCharacterAnimation()
            .width(220)
            .height(380)
            .margin({ top: -60 })
            .onClick(() => {
              this.handleCharacterClick();
            })

          Scroll(this.scroller) {
            Column({ space: 16 }) {
              // 限制显示消息数量，优化性能
              const displayMessages = this.messages.slice(-MAX_DISPLAY_MESSAGES);
              ForEach(displayMessages, (msg: Message, index: number) => {
                MessageBubble({ message: msg })
              }, (msg: Message) => msg.id)

              if (this.isTyping) {
                TypingIndicator()
              }
            }
            .width('100%')
            .padding({ top: 16, bottom: 16 })
          }
          .width('100%')
          .flexGrow(1)
          .scrollable(ScrollDirection.Vertical)
          .scrollBar(BarState.Off)

          this.buildActionButtons()

          this.buildInputArea(colors)
        }
        .width('100%')
        .flexGrow(1)
        .backgroundColor(colors.bg)
      }
      .width('100%')
      .flexGrow(1)

      BottomNav({
        currentTab: this.currentTab,
        onTabChange: (tab: string) => this.handleTabChange(tab)
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(colors.bg)
    .onAppear(() => this.onAppear())
  }

  @Builder
  buildHeader(colors: Record<string, string>) {
    Stack({ alignContent: Alignment.TopStart }) {
      Row({ space: 12 }) {
        Row({ space: 8 }) {
          Circle({ width: 36, height: 36 })
            .fill('rgba(255,255,255,0.2)')
            .overlay(Text('🎤').fontSize(16), { align: Alignment.Center })

          Text('星空爱莉')
            .fontColor('#ffffff')
            .fontWeight(FontWeight.Bold)
            .fontSize(18)
            .accessibilityText('星空爱莉，你的AI偶像助手')
        }

        Row({ space: 12 }) {
          Button('✨')
            .width(36)
            .height(36)
            .backgroundColor(Color.Transparent)
            .fontColor('#ffffff')
            .fontSize(18)
            .onClick(() => {
              this.showThemeMenu = !this.showThemeMenu;
            })

          Button('⚙️')
            .width(36)
            .height(36)
            .backgroundColor(Color.Transparent)
            .fontColor('#ffffff')
            .fontSize(18)
        }
      }
      .width('100%')
      .padding({
        top: px2vp(this.safeAreaTop) + 24,
        left: 16,
        right: 16,
        bottom: 16
      })

      if (this.showThemeMenu) {
        this.buildThemeMenu()
      }
    }
    .width('100%')
    .backgroundColor('#ffb6c1')
  }

  @Builder
  buildThemeMenu() {
    Column() {
      Column({ space: 8 }) {
        Text('浅色模式')
          .fontSize(14)
          .fontColor('#333333')
          .width('100%')
          .padding({ top: 8, bottom: 8 })
          .onClick(() => {
            this.setTheme('light');
            this.showThemeMenu = false;
          })

        Divider()
          .strokeWidth(0.5)
          .color('#f0f0f0')

        Text('深色模式')
          .fontSize(14)
          .fontColor('#333333')
          .width('100%')
          .padding({ top: 8, bottom: 8 })
          .onClick(() => {
            this.setTheme('dark');
            this.showThemeMenu = false;
          })

        Divider()
          .strokeWidth(0.5)
          .color('#f0f0f0')

        Text('跟随系统')
          .fontSize(14)
          .fontColor('#333333')
          .width('100%')
          .padding({ top: 8, bottom: 8 })
          .onClick(() => {
            this.setTheme('system');
            this.showThemeMenu = false;
          })
      }
      .width(140)
      .backgroundColor('#ffffff')
      .borderRadius(12)
      .padding(8)
      .position({ right: 16, top: px2vp(this.safeAreaTop) + 60 })
      .shadow({ radius: 12, color: 'rgba(0,0,0,0.2)', offsetY: 4 })
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })
    .zIndex(100)
    .onClick(() => {
      this.showThemeMenu = false;
    })
  }

  @Builder
  buildActionButtons() {
    Row({ space: 8 }) {
      ActionBtn({
        icon: '📝',
        label: '写文案',
        onClick: async () => {
          await this.handleAction('write');
        }
      })
      ActionBtn({
        icon: '📅',
        label: '日程',
        onClick: async () => {
          await this.handleAction('schedule');
        }
      })
      ActionBtn({
        icon: '🖼️',
        label: '图片',
        onClick: async () => {
          await this.handleAction('image');
        }
      })
      ActionBtn({
        icon: '🎵',
        label: '音乐',
        onClick: async () => {
          await this.handleAction('music');
        }
      })
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
  }

  @Builder
  buildInputArea(colors: Record<string, string>) {
    Row({ space: 8 }) {
      Button('😊')
        .width(44)
        .height(44)
        .backgroundColor('#f5f5f5')
        .borderRadius(22)
        .fontSize(18)
        .onClick(() => {
          promptAction.showToast({ message: '表情功能开发中', duration: 1500 });
        })

      TextInput({
        placeholder: '和爱莉聊天…',
        controller: this.inputController,
        onSubmit: (value: string) => this.sendMessage(value)
      })
        .width('100%')
        .height(44)
        .backgroundColor(Color.Transparent)
        .placeholderColor('#cccccc')
        .fontColor(colors.textPrimary)
        .fontSize(14)
        .accessibilityDescription('输入框，可以在这里和爱莉聊天')
        .onChange((value: string) => {
          this.inputText = value;
        })

      Button('🎤')
        .width(44)
        .height(44)
        .backgroundColor('#ffb6c1')
        .borderRadius(22)
        .fontSize(18)
        .fontColor('#ffffff')
        .onClick(() => {
          promptAction.showToast({
            message: '语音输入功能开发中',
            duration: 2000
          });
        })
    }
    .width('100%')
    .backgroundColor(colors.bgCard)
    .padding(12)
    .margin({ left: 16, right: 16 })
    .borderRadius(25)
    .shadow({ radius: 12, color: colors.shadow, offsetY: 2 })
  }

  @Builder
  buildErrorFallback() {
    Column({ space: 16 }) {
      Text('⚠️')
        .fontSize(64)
        .margin({ top: 120 })

      Text('遇到一点小问题')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')

      Text(this.errorMessage || '页面加载异常，请尝试重新启动应用')
        .fontSize(14)
        .fontColor('#666666')
        .textAlign(TextAlign.Center)
        .padding({ left: 32, right: 32 })

      Button('重新加载')
        .width(160)
        .height(44)
        .backgroundColor('#ffb6c1')
        .fontColor('#ffffff')
        .borderRadius(22)
        .onClick(() => {
          this.hasError = false;
          this.errorMessage = '';
          this.onAppear();
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f8f8f8')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  async onAppear(): Promise<void> {
    if (this.isDisposed) return;
    console.log('Index 页面：开始初始化');

    this.safeAreaTop = safeGetAppStorageNumber('safeAreaTop', 0);

    try {
      await ThemeManager.init();
      await chatViewModel.init();
      this.currentTheme = ThemeManager.getCurrentTheme();
      this.syncFromViewModel();
      console.log('Index 页面：基础模块初始化完成');
    } catch (error) {
      console.error('Index 页面：基础模块初始化失败:', error);
      this.hasError = true;
      this.errorMessage = '初始化失败，请检查应用权限';
      return;
    }

    if (ENABLE_LIFECYCLE_MANAGER) {
      try {
        lifecycleManager.onAppear('Index', () => {
          console.log('Index 页面 onAppear 回调');
          lifecycleManager.markUserActivity();
          this.syncFromViewModel();
        }, () => {
          console.log('Index 页面 onDisappear 回调');
        });
      } catch (error) {
        console.error('LifecycleManager 注册页面失败:', error);
      }
    }

    setTimeout(() => {
      if (!this.isDisposed) {
        try {
          bodyActionManager.startIdleAnimation();
        } catch (error) {
          console.error('Index 页面：动画启动失败:', error);
        }
      }
    }, 300);

    setTimeout(() => {
      if (!this.isDisposed) {
        try {
          this.blinkTimerId = setInterval(async () => {
            if (!this.isDisposed) {
              try {
                await expressionManager.playBlink();
              } catch (error) {
                console.error('Index 页面：眨眼动画失败:', error);
              }
            }
          }, 3000 + Math.random() * 2000);
        } catch (error) {
          console.error('Index 页面：眨眼定时器启动失败:', error);
        }
      }
    }, 500);

    this.themeListener = () => {
      this.currentTheme = ThemeManager.getCurrentTheme();
    };
    ThemeManager.addListener(this.themeListener);

    console.log('Index 页面：初始化完成');
  }

  private syncFromViewModel(): void {
    this.messages = [...chatViewModel.messages];
    this.isTyping = chatViewModel.isTyping;
    this.currentTab = chatViewModel.currentTab;
    this.messageVersion++;
  }

  private handleTabChange(tab: string): void {
    this.currentTab = tab;
    chatViewModel.switchTab(tab);
  }

  aboutToDisappear(): void {
    console.log('Index 页面 aboutToDisappear - 开始清理资源');
    this.isDisposed = true;

    if (ENABLE_LIFECYCLE_MANAGER) {
      try {
        lifecycleManager.onDisappear('Index');
      } catch (error) {
        console.error('LifecycleManager 处理页面消失失败:', error);
      }
    }

    if (this.blinkTimerId !== -1) {
      clearInterval(this.blinkTimerId);
      this.blinkTimerId = -1;
    }

    if (this.themeListener) {
      ThemeManager.removeListener(this.themeListener);
      this.themeListener = null;
    }

    console.log('Index 页面：资源清理完成');
  }

  async handleCharacterClick(): Promise<void> {
    await expressionManager.playExpression('happy');
    await bodyActionManager.playWave();
  }

  async setTheme(theme: ThemeMode): Promise<void> {
    await ThemeManager.setTheme(theme);
    this.showThemeMenu = false;

    promptAction.showToast({
      message: `已切换到${this.getThemeName(theme)}`,
      duration: 2000
    });
  }

  getThemeName(theme: ThemeMode): string {
    const names: Record<ThemeMode, string> = {
      'light': '浅色模式',
      'dark': '深色模式',
      'system': '跟随系统'
    };
    return names[theme];
  }

  async sendMessage(value: string): Promise<void> {
    if (!value.trim()) return;

    await expressionManager.playExpression('excited');
    await chatViewModel.sendMessage(value);

    this.inputText = '';
    this.inputController.clear();
    this.syncFromViewModel();

    setTimeout(() => {
      this.scroller.scrollTo({ yOffset: 99999 });
    }, 100);

    setTimeout(async () => {
      await expressionManager.playExpression('happy');
      this.syncFromViewModel();
    }, 1000);
  }

  async handleAction(actionType: string): Promise<void> {
    const actionMessages: Record<string, string> = {
      'write': '我想写文案，请帮我',
      'schedule': '帮我管理一下日程',
      'image': '我想生成一张图片',
      'music': '推荐一些好听的歌曲'
    };

    const message = actionMessages[actionType];
    if (message) {
      await this.sendMessage(message);
    }
  }
}
