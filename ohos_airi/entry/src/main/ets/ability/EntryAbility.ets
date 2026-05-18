import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window, AppStorage } from '@kit.ArkUI';
import { PreferencesUtil } from '../utils/PreferencesUtil';
import { NotificationManager } from '../utils/NotificationManager';
import { LifecycleManager } from '../core/LifecycleManager';

const ENABLE_LIFECYCLE_MANAGER = true;

function initAppStorage(): void {
  const entries: Array<[string, number]> = [
    ['safeAreaTop', 0], ['safeAreaBottom', 0],
    ['eyeOpen', 1.0], ['eyeBrowY', 0.0], ['mouthOpen', 0.2], ['mouthForm', 0.0],
    ['cheek', 0.0], ['headAngleX', 0.0], ['headAngleY', 0.0], ['headAngleZ', 0.0],
    ['bodyAngleX', 0.0], ['bodyAngleY', 0.0], ['bodyAngleZ', 0.0],
    ['armLeftAngleX', 0.0], ['armLeftAngleY', 0.0],
    ['armRightAngleX', 0.0], ['armRightAngleY', 0.0],
    ['legAngleX', 0.0], ['legAngleY', 0.0],
    ['hairSwing', 0.0], ['clothingSwing', 0.0],
  ];
  for (const [key, value] of entries) {
    try {
      AppStorage.setOrCreate<number>(key, value);
    } catch (e) {
      hilog.error(0x0000, 'AiriAI', 'AppStorage setOrCreate %{public}s failed', key);
    }
  }
  hilog.info(0x0000, 'AiriAI', 'AppStorage 初始化完成');
}

export default class EntryAbility extends UIAbility {
  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam) {
    hilog.info(0x0000, 'AiriAI', 'EntryAbility onCreate');
    
    // 先初始化 AppStorage
    initAppStorage();
    
    try {
      PreferencesUtil.init(this.context);
      hilog.info(0x0000, 'AiriAI', 'PreferencesUtil 初始化成功');
    } catch (error) {
      hilog.error(0x0000, 'AiriAI', 'PreferencesUtil 初始化失败：%{public}s', JSON.stringify(error));
    }

    try {
      NotificationManager.init(this.context);
      hilog.info(0x0000, 'AiriAI', 'NotificationManager 初始化成功');
    } catch (error) {
      hilog.error(0x0000, 'AiriAI', 'NotificationManager 初始化失败：%{public}s', JSON.stringify(error));
    }
    
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
    
    // setShowOnLockScreen not available in HarmonyOS NEXT, skip
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