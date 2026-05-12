import { promptAction } from '@kit.ArkUI';
import { observe } from '@ohos.arkui.observable';
import { ChatViewModel } from '../viewmodel/ChatViewModel';
import { ThemeManager, ThemeMode } from '../utils/ThemeManager';
import { MessageBubble } from '../components/MessageBubble';
import { TypingIndicator } from '../components/TypingIndicator';
import { ActionBtn } from '../components/ActionBtn';
import { BottomNav } from '../components/BottomNav';

const chatViewModel = new ChatViewModel();

@Entry
@Component
struct Index {
  scroller: Scroller = new Scroller();
  inputController: TextInputController = new TextInputController();
  isEmojiOpen: boolean = false;
  
  @State inputText: string = '';
  @State showThemeMenu: boolean = false;
  @State currentTheme: ThemeMode = 'light';

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
        .padding({ top: 24 + env.safeAreaTop, left: 16, right: 16, bottom: 16 })
        
        if (this.showThemeMenu) {
          Column({ space: 8 }) {
            MenuItem({ content: '浅色模式', action: () => this.setTheme('light') })
            MenuItem({ content: '深色模式', action: () => this.setTheme('dark') })
            MenuItem({ content: '跟随系统', action: () => this.setTheme('system') })
          }
          .width(120)
          .backgroundColor('#ffffff')
          .borderRadius(12)
          .padding(8)
          .position({ right: 16, top: 60 + env.safeAreaTop })
          .shadow({ radius: 12, color: 'rgba(0,0,0,0.2)', offsetY: 4 })
        }
      }
      .width('100%')
      .backgroundColor('#ffb6c1')

      Column({ space: 16 }) {
        Scroll(this.scroller) {
          Column({ space: 16 }) {
            ForEach(chatViewModel.messages, (msg) => {
              MessageBubble({ message: msg })
            })
            
            if (chatViewModel.isTyping) {
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
            onClick: () => chatViewModel.handleAction('write')
          })
          
          ActionBtn({
            icon: '📅',
            label: '日程',
            onClick: () => chatViewModel.handleAction('schedule')
          })
          
          ActionBtn({
            icon: '🖼️',
            label: '图片',
            onClick: () => chatViewModel.handleAction('image')
          })
          
          ActionBtn({
            icon: '🎵',
            label: '音乐',
            onClick: () => chatViewModel.handleAction('music')
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

      BottomNav({
        currentTab: chatViewModel.currentTab,
        onTabChange: (tab: string) => chatViewModel.switchTab(tab)
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(colors.bg)
    .onAppear(() => this.onAppear())
  }

  async onAppear(): Promise<void> {
    await ThemeManager.init();
    await chatViewModel.init();
    this.currentTheme = ThemeManager.getCurrentTheme();
    
    ThemeManager.addListener(() => {
      this.currentTheme = ThemeManager.getCurrentTheme();
    });
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
    await chatViewModel.sendMessage(value);
    this.inputText = '';
    this.inputController.clear();
    
    setTimeout(() => {
      this.scroller.scrollTo({ yOffset: 99999 });
    }, 100);
  }
}