import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { LifecycleManager } from './core/LifecycleManager';

const TAG = 'EntryAbility';
const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam) {
    hilog.info(DOMAIN, TAG, 'EntryAbility onCreate');

    try {
      await LifecycleManager.getInstance().init();
      hilog.info(DOMAIN, TAG, 'LifecycleManager 初始化成功');
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'LifecycleManager 初始化失败: %{public}s', JSON.stringify(error));
    }
  }

  onDestroy() {
    hilog.info(DOMAIN, TAG, 'EntryAbility onDestroy');

    try {
      LifecycleManager.getInstance().destroy();
      hilog.info(DOMAIN, TAG, 'LifecycleManager 已清理');
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'LifecycleManager 清理失败: %{public}s', JSON.stringify(error));
    }
  }

  onWindowStageCreate(windowStage: window.WindowStage) {
    hilog.info(DOMAIN, TAG, 'EntryAbility onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err) {
        hilog.error(DOMAIN, TAG, 'Failed to load content: %{public}s', JSON.stringify(err));
      }
    });
  }

  onWindowStageDestroy() {
    hilog.info(DOMAIN, TAG, 'EntryAbility onWindowStageDestroy');
  }

  onForeground() {
    hilog.info(DOMAIN, TAG, 'EntryAbility onForeground');

    try {
      LifecycleManager.getInstance().onForeground();
      hilog.info(DOMAIN, TAG, 'LifecycleManager 已恢复前台');
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'LifecycleManager 恢复前台失败: %{public}s', JSON.stringify(error));
    }
  }

  onBackground() {
    hilog.info(DOMAIN, TAG, 'EntryAbility onBackground');

    try {
      LifecycleManager.getInstance().onBackground();
      hilog.info(DOMAIN, TAG, 'LifecycleManager 已进入后台');
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'LifecycleManager 进入后台失败: %{public}s', JSON.stringify(error));
    }
  }
}
