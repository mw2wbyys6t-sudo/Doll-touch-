import { ThemeManager } from '../utils/ThemeManager';

interface ActionBtnProps {
  icon: string;
  label: string;
  onClick: () => void;
}

@Component
export struct ActionBtn {
  @Prop props: ActionBtnProps = { icon: '', label: '', onClick: () => {} };

  build() {
    const colors = ThemeManager.getThemeColors();

    Button({ type: ButtonType.Capsule }) {
      Column({ space: 4 }) {
        Text(this.props.icon)
          .fontSize(22)
        
        Text(this.props.label)
          .fontColor(colors.textSecondary)
          .fontSize(11)
      }
    }
    .width('100%')
    .height(88)
    .backgroundColor(colors.bgCard)
    .borderRadius(16)
    .shadow({ radius: 8, color: colors.shadow, offsetY: 2 })
    .onClick(() => this.props.onClick())
  }
}