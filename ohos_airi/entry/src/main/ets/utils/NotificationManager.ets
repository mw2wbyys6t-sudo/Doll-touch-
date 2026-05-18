import { notificationManager, NotificationRequest, NotificationSlot, NotificationConstant } from '@kit.NotificationKit';
import { abilityAccessCtrl } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { Context } from '@kit.AbilityKit';

export class NotificationManager {
  private static isInitialized = false;

  static async init(context: Context): Promise<void> {
    if (this.isInitialized) {
      return;
    }

    try {
      // 请求通知权限
      try {
        const atManager = abilityAccessCtrl.createAtManager();
        const authResult = await atManager.requestPermissionsFromUser(context, ['ohos.permission.NOTIFICATION_AGENT']);
        console.info(`Notification权限请求结果: ${JSON.stringify(authResult)}`);
      } catch (permErr) {
        console.warn('Notification权限请求失败(非致命):', permErr);
      }

      const slot = new NotificationSlot('airi_slot', 'Airi Notifications', NotificationConstant.SlotLevel.LEVEL_HIGH);
      slot.description = '星空爱莉消息通知';
      slot.enableVibration = true;
      slot.vibrationStyle = NotificationConstant.VibrationStyle.DEFAULT;
      
      notificationManager.createNotificationSlot(slot);
      this.isInitialized = true;
    } catch (err) {
      console.error('NotificationManager init failed:', err);
    }
  }

  static async showNotification(title: string, content: string, notificationId: number = 1): Promise<void> {
    try {
      const request = new NotificationRequest(notificationId);
      request.content = {
        title: title,
        text: content,
        additionalText: '星空爱莉'
      };
      
      request.slotId = 'airi_slot';
      request.isOngoing = false;
      request.isReminder = true;
      
      await notificationManager.publish(request);
    } catch (err) {
      console.error('NotificationManager showNotification failed:', err);
    }
  }

  static async cancelNotification(notificationId: number): Promise<void> {
    try {
      await notificationManager.cancel(notificationId);
    } catch (err) {
      console.error('NotificationManager cancelNotification failed:', err);
    }
  }

  static async cancelAllNotifications(): Promise<void> {
    try {
      await notificationManager.cancelAll();
    } catch (err) {
      console.error('NotificationManager cancelAllNotifications failed:', err);
    }
  }

  static async scheduleNotification(title: string, content: string, triggerTime: number): Promise<void> {
    try {
      const request = new NotificationRequest(Date.now());
      request.content = {
        title: title,
        text: content,
        additionalText: '星空爱莉'
      };
      
      request.slotId = 'airi_slot';
      request.trigger = {
        type: NotificationConstant.TriggerType.TIME_TRIGGER,
        triggerTime: triggerTime
      };
      
      await notificationManager.publish(request);
    } catch (err) {
      console.error('NotificationManager scheduleNotification failed:', err);
    }
  }
}