import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { PreferencesUtil } from '../utils/PreferencesUtil';
import { NotificationManager } from '../utils/NotificationManager';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam) {
    hilog.info(0x0000, 'AiriAI', 'EntryAbility onCreate');
    
    PreferencesUtil.init(this.context);
    NotificationManager.init(this.context);
    
    this.setShowOnLockScreen(true);
  }

  onDestroy() {
    hilog.info(0x0000, 'AiriAI', 'EntryAbility onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage) {
    hilog.info(0x0000, 'AiriAI', 'EntryAbility onWindowStageCreate');
    
    windowStage.loadContent('pages/Index', (err, data) => {
      if (err) {
        hilog.error(0x0000, 'AiriAI', 'Failed to load content: %{public}s', JSON.stringify(err));
      }
    });
  }

  onWindowStageDestroy() {
    hilog.info(0x0000, 'AiriAI', 'EntryAbility onWindowStageDestroy');
  }

  onForeground() {
    hilog.info(0x0000, 'AiriAI', 'EntryAbility onForeground');
  }

  onBackground() {
    hilog.info(0x0000, 'AiriAI', 'EntryAbility onBackground');
  }
}