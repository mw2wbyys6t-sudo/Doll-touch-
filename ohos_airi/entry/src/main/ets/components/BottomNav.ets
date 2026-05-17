import { ThemeManager } from '../utils/ThemeManager';

interface TabItemProps {
  icon: string;
  label: string;
  isActive: boolean;
  onClick: () => void;
}

@Component
struct TabItem {
  @Prop props: TabItemProps = { icon: '', label: '', isActive: false, onClick: () => {} };

  build() {
    Column() {
      Image(this.props.icon)
        .width(24)
        .height(24)
        .fillColor(this.props.isActive ? '#FF69B4' : '#999999');
      Text(this.props.label)
        .fontSize(12)
        .fontColor(this.props.isActive ? '#FF69B4' : '#999999')
        .margin({ top: 4 });
    }
    .width('25%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.props.onClick();
    });
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