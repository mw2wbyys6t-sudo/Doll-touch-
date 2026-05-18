import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { AppStorage } from '@kit.ArkUI';
import { PreferencesUtil } from '../utils/PreferencesUtil';
import { NotificationManager } from '../utils/NotificationManager';
import { LifecycleManager } from '../core/LifecycleManager';

// 特性开关：启用 LifecycleManager
const ENABLE_LIFECYCLE_MANAGER = true;

// 初始化 AppStorage 中的所有需要使用的值
function initAppStorage(): void {
  // 安全区域相关
  AppStorage.setOrCreate('safeAreaTop', 0);
  AppStorage.setOrCreate('safeAreaBottom', 0);
  
  // 表情相关
  AppStorage.setOrCreate('eyeOpen', 1.0);
  AppStorage.setOrCreate('eyeBrowY', 0.0);
  AppStorage.setOrCreate('mouthOpen', 0.2);
  AppStorage.setOrCreate('mouthForm', 0.0);
  AppStorage.setOrCreate('cheek', 0.0);
  AppStorage.setOrCreate('headAngleX', 0.0);
  AppStorage.setOrCreate('headAngleY', 0.0);
  AppStorage.setOrCreate('headAngleZ', 0.0);
  
  // 身体动作相关
  AppStorage.setOrCreate('bodyAngleX', 0.0);
  AppStorage.setOrCreate('bodyAngleY', 0.0);
  AppStorage.setOrCreate('bodyAngleZ', 0.0);
  AppStorage.setOrCreate('armLeftAngleX', 0.0);
  AppStorage.setOrCreate('armLeftAngleY', 0.0);
  AppStorage.setOrCreate('armRightAngleX', 0.0);
  AppStorage.setOrCreate('armRightAngleY', 0.0);
  AppStorage.setOrCreate('legAngleX', 0.0);
  AppStorage.setOrCreate('legAngleY', 0.0);
  AppStorage.setOrCreate('hairSwing', 0.0);
  AppStorage.setOrCreate('clothingSwing', 0.0);
  
  hilog.info(0x0000, 'AiriAI', 'AppStorage 初始化完成');
}

export default class EntryAbility extends UIAbility {
  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam) {
    hilog.info(0x0000, 'AiriAI', 'EntryAbility onCreate');
    
    // 先初始化 AppStorage
    initAppStorage();
    
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