import { ThemeManager } from '../utils/ThemeManager';

@Component
export struct TypingIndicator {
  build() {
    const colors = ThemeManager.getThemeColors();

    Column({ space: 8 }) {
      Text('爱莉')
        .fontColor(colors.primaryDarkPurple)
        .fontWeight(FontWeight.Bold)
        .fontSize(14)
      
      Row({ space: 4 }) {
        Circle({ width: 8, height: 8 })
          .fill('#dda0dd')
          .animate([
            { opacity: 0.4, scale: 1 },
            { opacity: 1, scale: 1.2 },
            { opacity: 0.4, scale: 1 }
          ], {
            duration: 1400,
            iterations: -1,
            curve: Curve.EaseInOut,
            delay: 0
          })
        
        Circle({ width: 8, height: 8 })
          .fill('#dda0dd')
          .animate([
            { opacity: 0.4, scale: 1 },
            { opacity: 1, scale: 1.2 },
            { opacity: 0.4, scale: 1 }
          ], {
            duration: 1400,
            iterations: -1,
            curve: Curve.EaseInOut,
            delay: 200
          })
        
        Circle({ width: 8, height: 8 })
          .fill('#dda0dd')
          .animate([
            { opacity: 0.4, scale: 1 },
            { opacity: 1, scale: 1.2 },
            { opacity: 0.4, scale: 1 }
          ], {
            duration: 1400,
            iterations: -1,
            curve: Curve.EaseInOut,
            delay: 400
          })
      }
      .padding({ left: 12, right: 12, top: 9, bottom: 9 })
    }
    .width('100%')
    .maxWidth('90%')
    .padding(16)
    .backgroundColor(colors.bgCard)
    .borderRadius(20)
    .shadow({ radius: 12, color: colors.shadow, offsetY: 2 })
    .alignSelf(ItemAlign.Start)
  }
}