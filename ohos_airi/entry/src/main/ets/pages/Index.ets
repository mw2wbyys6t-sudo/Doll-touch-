import { promptAction } from '@kit.ArkUI';
import { ChatViewModel } from '../viewmodel/ChatViewModel';
import { ThemeManager, ThemeMode } from '../utils/ThemeManager';
import { MessageBubble } from '../components/MessageBubble';
import { TypingIndicator } from '../components/TypingIndicator';
import { ActionBtn } from '../components/ActionBtn';
import { BottomNav } from '../components/BottomNav';
import { CharacterAnimation } from '../components/CharacterAnimation';
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

@Entry
@Component
struct Index {
  scroller: Scroller = new Scroller();
  inputController: TextInputController = new TextInputController();
  isEmojiOpen: boolean = false;

  @State inputText: string = '';
  @State showThemeMenu: boolean = false;
  @State currentTheme: ThemeMode = 'light';
  @State safeAreaTop: number = 0;
  @State messages: Message[] = [];
  @State isTyping: boolean = false;
  @State currentTab: string = 'chat';
  private messageVersion: number = 0;

  build() {
    const colors = ThemeManager.getThemeColors();

    Column({ space: 0 }) {
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
      }
      .width('100%')
      .backgroundColor('#ffb6c1')

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
              ForEach(this.messages, (msg: Message, index: number) => {
                MessageBubble({ message: msg })
              })

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

          Row({ space: 8 }) {
            ActionBtn({
              icon: '📝',
              label: '写文案',
              onClick: async () => {
                await chatViewModel.handleAction('write');
                this.syncFromViewModel();
                setTimeout(() => this.scroller.scrollTo({ yOffset: 99999 }), 100);
              }
            })
            ActionBtn({
              icon: '📅',
              label: '日程',
              onClick: async () => {
                await chatViewModel.handleAction('schedule');
                this.syncFromViewModel();
                setTimeout(() => this.scroller.scrollTo({ yOffset: 99999 }), 100);
              }
            })
            ActionBtn({
              icon: '🖼️',
              label: '图片',
              onClick: async () => {
                await chatViewModel.handleAction('image');
                this.syncFromViewModel();
                setTimeout(() => this.scroller.scrollTo({ yOffset: 99999 }), 100);
              }
            })
            ActionBtn({
              icon: '🎵',
              label: '音乐',
              onClick: async () => {
                await chatViewModel.handleAction('music');
                this.syncFromViewModel();
                setTimeout(() => this.scroller.scrollTo({ yOffset: 99999 }), 100);
              }
            })
          }
          .width('100%')
          .padding({ left: 16, right: 16 })

          Row({ space: 8 }) {
            Button('😊')
              .width(44)
              .height(44)
              .backgroundColor('#f5f5f5')
              .borderRadius(22)
              .fontSize(18)
              .onClick(() => {
                this.isEmojiOpen = !this.isEmojiOpen;
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

  // 页面生命周期回调 ID
  private blinkTimerId: number | null = null;
  private themeListener: (() => void) | null = null;

  async onAppear(): Promise<void> {
    console.log('Index 页面：开始初始化');

    // 先获取 safeAreaTop，避免在 build 中直接访问
    this.safeAreaTop = safeGetAppStorageNumber('safeAreaTop', 0);

    try {
      await ThemeManager.init();
      await chatViewModel.init();
      this.currentTheme = ThemeManager.getCurrentTheme();

      // 同步 chatViewModel 状态到本地 @State
      this.syncFromViewModel();

      console.log('Index 页面：基础模块初始化完成');
    } catch (error) {
      console.error('Index 页面：基础模块初始化失败:', error);
    }

    // 并行接入 LifecycleManager - 注册页面生命周期
    if (ENABLE_LIFECYCLE_MANAGER) {
      try {
        lifecycleManager.onAppear('Index', () => {
          console.log('Index 页面 onAppear 回调');
          lifecycleManager.markUserActivity();
          this.syncFromViewModel();
        }, () => {
          console.log('Index 页面 onDisappear 回调');
        });
        console.log('LifecycleManager 已注册 Index 页面');
      } catch (error) {
        console.error('LifecycleManager 注册页面失败:', error);
      }
    }

    // 延迟启动动画，避免竞态条件
    setTimeout(() => {
      try {
        bodyActionManager.startIdleAnimation();
        console.log('Index 页面：动画启动完成');
      } catch (error) {
        console.error('Index 页面：动画启动失败:', error);
      }
    }, 300);

    // 延迟启动眨眼定时器
    setTimeout(() => {
      try {
        this.blinkTimerId = setInterval(async () => {
          try {
            await expressionManager.playBlink();
          } catch (error) {
            console.error('Index 页面：眨眼动画失败:', error);
          }
        }, 3000 + Math.random() * 2000) as unknown as number;
        console.log('Index 页面：眨眼定时器启动完成');
      } catch (error) {
        console.error('Index 页面：眨眼定时器启动失败:', error);
      }
    }, 500);

    // 保存监听器引用以便清理
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
    
    // 并行接入 LifecycleManager - 通知页面消失
    if (ENABLE_LIFECYCLE_MANAGER) {
      try {
        lifecycleManager.onDisappear('Index');
        console.log('LifecycleManager 已处理 Index 页面消失');
      } catch (error) {
        console.error('LifecycleManager 处理页面消失失败:', error);
      }
    }
    
    // 修复定时器泄漏 - 清理眨眼定时器
    if (this.blinkTimerId) {
      clearInterval(this.blinkTimerId);
      this.blinkTimerId = null;
      console.log('Index 页面：眨眼定时器已清理');
    }
    
    // 修复监听器泄漏 - 移除主题监听器
    if (this.themeListener) {
      ThemeManager.removeListener(this.themeListener);
      this.themeListener = null;
      console.log('Index 页面：主题监听器已清理');
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

    // 同步状态到UI
    this.syncFromViewModel();

    setTimeout(() => {
      this.scroller.scrollTo({ yOffset: 99999 });
    }, 100);

    setTimeout(async () => {
      await expressionManager.playExpression('happy');
      // 再次同步（AI回复到达）
      this.syncFromViewModel();
    }, 1000);
  }
}
