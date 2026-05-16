import { ThemeManager } from '../utils/ThemeManager';

interface TabItemProps {
  icon: string;
  label: string;
  isActive: boolean;
  onClick: () => void;
}

@Component
struct TabItem {
  props: TabItemProps;

  build() {
    const colors = ThemeManager.getThemeColors();

    Button({ type: ButtonType.Normal }) {
      Column({ space: 2 }) {
        Text(this.props.icon)
          .fontSize(22)
        
        Text(this.props.label)
          .fontSize(10)
      }
    }
    .width('100%')
    .height(56)
    .backgroundColor(Color.Transparent)
    .fontColor(this.props.isActive ? '#e91e63' : colors.textSecondary)
    .onClick(() => this.props.onClick())
  }
}

@Component
export struct BottomNav {
  @Prop currentTab: string = '';
  @Prop onTabChange: (tab: string) => void = () => {};

  build() {
    const colors = ThemeManager.getThemeColors();

    Row({ space: 0 }) {
      TabItem({
        icon: '💬',
        label: '聊天',
        isActive: this.currentTab === 'chat',
        onClick: () => this.onTabChange('chat')
      })
      
      TabItem({
        icon: '📋',
        label: '任务',
        isActive: this.currentTab === 'tasks',
        onClick: () => this.onTabChange('tasks')
      })
      
      TabItem({
        icon: '🎨',
        label: '创作',
        isActive: this.currentTab === 'create',
        onClick: () => this.onTabChange('create')
      })
      
      TabItem({
        icon: '👤',
        label: '我的',
        isActive: this.currentTab === 'profile',
        onClick: () => this.onTabChange('profile')
      })
    }
    .width('100%')
    .backgroundColor(colors.bgCard)
    .borderTop({ width: 1, color: colors.border })
  }
}