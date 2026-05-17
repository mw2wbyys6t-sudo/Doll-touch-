import { Message } from '../model/MessageModel';
import { ThemeManager } from '../utils/ThemeManager';

@Component
export struct MessageBubble {
  @Prop message: Message = new Message();

  build() {
    const colors = ThemeManager.getThemeColors();
    const isAI = this.message.sender === 'ai';

    Column({ space: 8 }) {
      if (isAI) {
        Text('爱莉')
          .fontColor(colors.primaryDarkPurple)
          .fontWeight(FontWeight.Bold)
          .fontSize(14)
      }

      Text(this.message.content)
        .fontColor(isAI ? colors.textPrimary : '#ffffff')
        .fontSize(14)
        .lineHeight(1.5)
        .padding(isAI ? 0 : { left: 12, right: 12, top: 9, bottom: 9 })
        .backgroundColor(isAI ? 'transparent' : '#667eea')
        .borderRadius(isAI ? 0 : { topLeft: 16, topRight: 16, bottomLeft: 4, bottomRight: 16 })
        .maxLines(100)
        .textAlign(TextAlign.Start)

      Text(this.formatTime(this.message.timestamp))
        .fontColor(colors.textTertiary)
        .fontSize(11)
    }
    .width('100%')
    .maxWidth('90%')
    .padding(16)
    .backgroundColor(colors.bgCard)
    .borderRadius(20)
    .shadow({ radius: 12, color: colors.shadow, offsetY: 2 })
    .alignSelf(isAI ? ItemAlign.Start : ItemAlign.End)
  }

  private formatTime(timestamp: number): string {
    const date = new Date(timestamp);
    const h = date.getHours();
    const m = date.getMinutes();
    const hours = h < 10 ? '0' + h.toString() : h.toString();
    const minutes = m < 10 ? '0' + m.toString() : m.toString();
    return `${hours}:${minutes}`;
  }
}