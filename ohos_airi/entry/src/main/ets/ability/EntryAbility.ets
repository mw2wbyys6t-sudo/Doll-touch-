import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { PreferencesUtil } from '../utils/PreferencesUtil';
import { NotificationManager } from '../utils/NotificationManager';
import { LifecycleManager } from '../core/LifecycleManager';

// 特性开关：启用 LifecycleManager
const ENABLE_LIFECYCLE_MANAGER = true;

export default class EntryAbility extends UIAbility {
  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam) {
    hilog.info(0x0000, 'AiriAI', 'EntryAbility onCreate');
    
    PreferencesUtil.init(this.context);
    NotificationManager.init(this.context);
    
    // 并行接入 LifecycleManager - 初始化核心模块
    if (ENABLE_LIFECYCLE_MANAGER) {
      try {
        const lifecycleManager = LifecycleManager.getInstance();
        await lifecycleManager.init();
        hilog.info(0x0000, 'AiriAI', 'LifecycleManager 初始化成功');
      } catch (error) {
        hilog.error(0x0000, 'AiriAI', 'LifecycleManager 初始化失败：%{public}s', JSON.stringify(error));
      }
    }
    
    this.setShowOnLockScreen(true);
  }

  onDestroy() {
    hilog.info(0x0000, 'AiriAI', 'EntryAbility onDestroy');
    
    // 并行接入 LifecycleManager - 清理全局资源
    if (ENABLE_LIFECYCLE_MANAGER) {
      try {
        const lifecycleManager = LifecycleManager.getInstance();
        lifecycleManager.destroy();
        hilog.info(0x0000, 'AiriAI', 'LifecycleManager 已清理');
      } catch (error) {
        hilog.error(0x0000, 'AiriAI', 'LifecycleManager 清理失败：%{public}s', JSON.stringify(error));
      }
    }
  }

  async onWindowStageCreate(windowStage: window.WindowStage) {
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
    
    // 并行接入 LifecycleManager - 恢复前台资源
    if (ENABLE_LIFECYCLE_MANAGER) {
      try {
        const lifecycleManager = LifecycleManager.getInstance();
        lifecycleManager.onForeground();
        hilog.info(0x0000, 'AiriAI', 'LifecycleManager 已恢复前台');
      } catch (error) {
        hilog.error(0x0000, 'AiriAI', 'LifecycleManager 恢复前台失败：%{public}s', JSON.stringify(error));
      }
    }
  }

  onBackground() {
    hilog.info(0x0000, 'AiriAI', 'EntryAbility onBackground');
    
    // 并行接入 LifecycleManager - 暂停后台资源
    if (ENABLE_LIFECYCLE_MANAGER) {
      try {
        const lifecycleManager = LifecycleManager.getInstance();
        lifecycleManager.onBackground();
        hilog.info(0x0000, 'AiriAI', 'LifecycleManager 已进入后台');
      } catch (error) {
        hilog.error(0x0000, 'AiriAI', 'LifecycleManager 进入后台失败：%{public}s', JSON.stringify(error));
      }
    }
  }
}