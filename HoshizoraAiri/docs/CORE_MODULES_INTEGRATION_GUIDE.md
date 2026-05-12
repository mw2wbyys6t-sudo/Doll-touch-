# 星空爱莉 - 工程基础模块接入指南

**文档版本**: 1.0.0  
**创建日期**: 2026-05-12  
**模块版本**: ArkTS Native v1.0

---

## 📋 目录结构

```
ohos_airi/
└── entry/src/main/ets/
    ├── core/                           # 核心模块目录
    │   ├── Dispatcher.ets             # 事件分发器
    │   ├── EmotionStore.ets           # 情绪存储
    │   ├── EmotionalFSM.ets           # 情绪状态机
    │   ├── LifecycleManager.ets       # 生命周期管理器
    │   └── DebugPanelViewModel.ets    # 调试面板 ViewModel
    ├── components/                    # UI 组件目录
    │   └── DebugPanel.ets             # 调试面板组件
    └── pages/                         # 页面目录
        └── Index.ets                  # 主页（待修改）
```

---

## 📁 生成的文件清单

### 1. Dispatcher.ets
**路径**: `entry/src/main/ets/core/Dispatcher.ets`

**功能**: 事件分发器，用于模块间通信

**主要方法**:
```typescript
// 订阅事件
subscribe(event: string, callback: EventCallback): string

// 取消订阅
unsubscribe(id: string): void

// 发送事件（同步）
emit(event: string, data?: Object): void

// 发送事件（异步）
emitAsync(event: string, data?: Object): void
```

**依赖**: 无

**被依赖**: EmotionStore, EmotionalFSM, LifecycleManager, DebugPanelViewModel

---

### 2. EmotionStore.ets
**路径**: `entry/src/main/ets/core/EmotionStore.ets`

**功能**: 情绪存储管理器，管理角色情绪状态和权重

**主要方法**:
```typescript
// 设置情绪
setEmotion(emotion: EmotionType, weight?: number, force?: boolean): void

// 获取当前情绪
currentEmotion: EmotionType

// 获取情绪权重
getEmotionWeight(emotion: EmotionType): number

// 开始衰减
startDecay(rate?: number, interval?: number): void

// 停止衰减
stopDecay(): void

// 锁定情绪
lock(reason: string, timeout?: number): void

// 解锁情绪
unlock(): void
```

**依赖**: Dispatcher

**被依赖**: EmotionalFSM, DebugPanelViewModel

---

### 3. EmotionalFSM.ets
**路径**: `entry/src/main/ets/core/EmotionalFSM.ets`

**功能**: 情绪有限状态机，管理角色状态转换

**状态枚举**:
```typescript
enum FSMState {
  IDLE = 'idle',
  TALKING = 'talking',
  THINKING = 'thinking',
  HAPPY = 'happy',
  SAD = 'sad',
  ANGRY = 'angry',
  EXCITED = 'excited',
  SCARED = 'scared',
  CONFUSED = 'confused',
  SLEEPING = 'sleeping'
}
```

**主要方法**:
```typescript
// 转换到目标状态
transitionTo(targetState: FSMState, force?: boolean, context?: Object): boolean

// 添加状态锁
addLock(state: FSMState, reason: string, timeout?: number): void

// 移除状态锁
removeLock(state?: FSMState): void

// 获取当前状态
currentState: FSMState
```

**依赖**: Dispatcher, EmotionStore

**被依赖**: LifecycleManager, DebugPanelViewModel

---

### 4. LifecycleManager.ets
**路径**: `entry/src/main/ets/core/LifecycleManager.ets`

**功能**: 生命周期管理器，管理应用和页面生命周期

**主要方法**:
```typescript
// 初始化
init(): Promise<void>

// 销毁
destroy(): void

// 页面出现
onAppear(pageName: string, onAppearCallback?: () => void, onDisappearCallback?: () => void): void

// 页面消失
onDisappear(pageName: string): void

// 进入前台
onForeground(): void

// 进入后台
onBackground(): void

// 注册资源
registerResource(id: string, type: ResourceType, name: string, cleanup: () => void): void

// 注销资源
unregisterResource(id: string): void
```

**依赖**: Dispatcher, EmotionalFSM

**被依赖**: DebugPanelViewModel

---

### 5. DebugPanelViewModel.ets
**路径**: `entry/src/main/ets/core/DebugPanelViewModel.ets`

**功能**: 调试面板 ViewModel，提供调试数据

**主要方法**:
```typescript
// 开始更新
startUpdates(): void

// 停止更新
stopUpdates(): void

// 显示面板
show(): void

// 隐藏面板
hide(): void

// 切换可见性
toggle(): void
```

**依赖**: Dispatcher, EmotionStore, EmotionalFSM, LifecycleManager

---

### 6. DebugPanel.ets
**路径**: `entry/src/main/ets/components/DebugPanel.ets`

**功能**: 调试面板 UI 组件

**显示内容**:
- FSM 状态
- 情绪权重
- 活动锁
- 应用状态
- 性能信息（FPS、内存）

**依赖**: DebugPanelViewModel

---

## 🔗 Import 关系图

```
EntryAbility.ets
    │
    ├──> LifecycleManager.init()
    │        │
    │        ├──> Dispatcher (初始化)
    │        │
    │        ├──> EmotionalFSM (初始化)
    │        │        │
    │        │        └──> EmotionStore (初始化)
    │        │                 │
    │        │                 └──> Dispatcher (事件通信)
    │        │
    │        └──> DebugPanelViewModel (初始化)
    │                 │
    │                 ├──> Dispatcher (订阅事件)
    │                 ├──> EmotionStore (获取数据)
    │                 ├──> EmotionalFSM (获取数据)
    │                 └──> LifecycleManager (获取数据)

Index.ets
    │
    ├──> LifecycleManager.onAppear() / onDisappear()
    │
    ├──> DebugPanel (组件)
    │        │
    │        └──> DebugPanelViewModel (数据源)
    │
    └──> EmotionalFSM.transitionTo() (可选)
```

---

## 🚀 接入步骤

### 步骤 1：复制文件

将以下文件复制到项目对应目录：

```
从下载的源码复制到:
    entry/src/main/ets/core/
    
✅ Dispatcher.ets
✅ EmotionStore.ets
✅ EmotionalFSM.ets
✅ LifecycleManager.ets
✅ DebugPanelViewModel.ets

复制到:
    entry/src/main/ets/components/

✅ DebugPanel.ets
```

### 步骤 2：修改 EntryAbility.ets

在 `entry/src/main/ets/ability/EntryAbility.ets` 中添加：

```typescript
import { LifecycleManager } from '../core/LifecycleManager';

export default class EntryAbility extends UIAbility {
  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam) {
    // ... 现有代码保持不变 ...

    // 添加：初始化 LifecycleManager
    await LifecycleManager.getInstance().init();
  }

  onDestroy() {
    // ... 现有代码保持不变 ...

    // 添加：销毁 LifecycleManager
    LifecycleManager.getInstance().destroy();
  }

  onForeground() {
    // ... 现有代码保持不变 ...

    // 添加：应用进入前台
    LifecycleManager.getInstance().onForeground();
  }

  onBackground() {
    // ... 现有代码保持不变 ...

    // 添加：应用进入后台
    LifecycleManager.getInstance().onBackground();
  }
}
```

### 步骤 3：修改 Index.ets

在 `entry/src/main/ets/pages/Index.ets` 中添加：

```typescript
import { LifecycleManager } from '../core/LifecycleManager';
import { EmotionalFSM, FSMState } from '../core/EmotionalFSM';
import { EmotionStore, EmotionType } from '../core/EmotionStore';
import { DebugPanel } from '../components/DebugPanel';

@Entry
@Component
struct Index {
  // ... 现有代码保持不变 ...

  aboutToAppear() {
    // 添加：注册页面生命周期
    LifecycleManager.getInstance().onAppear('Index');
  }

  aboutToDisappear() {
    // 添加：注销页面生命周期
    LifecycleManager.getInstance().onDisappear('Index');
  }

  build() {
    Stack() {
      // ... 现有布局保持不变 ...

      // 添加：调试面板（放在最上层）
      DebugPanel()
        .position({ x: 10, y: 100 })
    }
  }

  // 添加：页面交互时标记用户活动
  private handleUserActivity() {
    LifecycleManager.getInstance().markUserActivity();
  }
}
```

---

## 🧪 测试验证

### 测试 1：检查编译

在 DevEco Studio 中：
```
Build → Build Hap(s) → Build Hap(s)
```

**期望结果**: ✅ 编译成功，无错误

### 测试 2：检查日志

运行应用，在 HiLog 中过滤 `AiriAI`：

**期望看到的日志**:
```
[LifecycleManager] 开始初始化
[LifecycleManager] 初始化完成
[Dispatcher] 订阅成功: fsm:stateChanged
[Dispatcher] 订阅成功: emotion:changed
[LifecycleManager] 页面注册: Index
```

### 测试 3：检查调试面板

运行应用，应该能看到右上角的调试面板（半透明黑色）：

**期望内容**:
- 🔧 调试面板
- 状态机 (FSM)
- 情绪系统
- 应用状态
- 性能监控

### 测试 4：测试状态转换

在 Index.ets 中添加测试按钮：

```typescript
Button('测试状态')
  .onClick(() => {
    EmotionalFSM.getInstance().transitionTo(FSMState.HAPPY);
  })
```

**期望结果**: 调试面板中 FSM 状态从 `idle` 变为 `happy`

### 测试 5：测试情绪设置

在 Index.ets 中添加测试按钮：

```typescript
Button('测试情绪')
  .onClick(() => {
    EmotionStore.getInstance().setEmotion(EmotionType.HAPPY, 100);
  })
```

**期望结果**: 调试面板中情绪从 `idle` 变为 `happy`

### 测试 6：测试生命周期

1. 按 Home 键切换到后台
2. 查看 HiLog

**期望日志**:
```
[LifecycleManager] 应用进入后台
[LifecycleManager] 资源已暂停
```

3. 重新打开应用

**期望日志**:
```
[LifecycleManager] 应用进入前台
[LifecycleManager] 资源已恢复
```

### 测试 7：测试资源清理

1. 退出应用
2. 查看 HiLog

**期望日志**:
```
[LifecycleManager] 开始销毁
[LifecycleManager] 开始清理所有资源, 数量: X
[LifecycleManager] 所有资源已清理
[LifecycleManager] 销毁完成
```

---

## 🔧 常用 API 示例

### 示例 1：订阅事件

```typescript
import { Dispatcher } from '../core/Dispatcher';

// 订阅 FSM 状态变化
const subscriberId = Dispatcher.getInstance().subscribe('fsm:stateChanged', (data) => {
  console.info('FSM 状态变化:', data);
});

// 取消订阅
Dispatcher.getInstance().unsubscribe(subscriberId);
```

### 示例 2：设置情绪

```typescript
import { EmotionStore, EmotionType } from '../core/EmotionStore';

// 设置开心情绪，权重 100
EmotionStore.getInstance().setEmotion(EmotionType.HAPPY, 100);

// 开始情绪衰减
EmotionStore.getInstance().startDecay(5, 1000);
```

### 示例 3：状态转换

```typescript
import { EmotionalFSM, FSMState } from '../core/EmotionalFSM';

// 转换到说话状态
const success = EmotionalFSM.getInstance().transitionTo(FSMState.TALKING);
if (success) {
  console.info('状态转换成功');
} else {
  console.warn('状态转换被阻止');
}

// 添加状态锁（锁定 5 秒）
EmotionalFSM.getInstance().addLock(FSMState.TALKING, '用户对话中', 5000);
```

### 示例 4：使用调试面板

```typescript
import { debugPanelViewModel } from '../core/DebugPanelViewModel';

// 显示面板
debugPanelViewModel.show();

// 隐藏面板
debugPanelViewModel.hide();

// 切换面板
debugPanelViewModel.toggle();

// 设置更新间隔
debugPanelViewModel.setUpdateInterval(1000);
```

### 示例 5：标记用户活动

```typescript
import { LifecycleManager } from '../core/LifecycleManager';

// 用户点击时调用，防止进入睡眠
LifecycleManager.getInstance().markUserActivity();
```

### 示例 6：注册和清理资源

```typescript
import { LifecycleManager, ResourceType } from '../core/LifecycleManager';

// 注册定时器
const timerId = setInterval(() => {
  console.info('定时任务');
}, 1000);

LifecycleManager.getInstance().registerResource(
  `timer_${Date.now()}`,
  ResourceType.TIMER,
  '定时任务',
  () => clearInterval(timerId)
);

// 注销资源
LifecycleManager.getInstance().unregisterResource(resourceId);
```

---

## ⚠️ 注意事项

### 1. 单例模式

所有管理器类都使用单例模式：
```typescript
// 正确获取实例
const manager = Dispatcher.getInstance();
const store = EmotionStore.getInstance();
const fsm = EmotionalFSM.getInstance();
const lifecycle = LifecycleManager.getInstance();

// ❌ 错误：不要 new 实例
const wrong = new Dispatcher();
```

### 2. 生命周期顺序

1. 首先初始化 Dispatcher
2. 然后初始化 EmotionStore
3. 然后初始化 EmotionalFSM
4. 最后初始化 LifecycleManager

LifecycleManager 会自动处理这个顺序。

### 3. 资源清理

页面销毁时必须调用 `onDisappear()`：
```typescript
aboutToDisappear() {
  LifecycleManager.getInstance().onDisappear('Index');
}
```

### 4. 事件命名规范

推荐的事件命名：
```
模块:事件名称

示例：
- fsm:stateChanged
- emotion:changed
- lifecycle:sleep
- user:activity
```

### 5. 定时器清理

使用 LifecycleManager 注册定时器：
```typescript
// ❌ 不推荐：直接使用 setInterval
const timerId = setInterval(...);

// ✅ 推荐：使用 LifecycleManager 注册
LifecycleManager.getInstance().registerResource(
  `interval_${timerId}`,
  ResourceType.TIMER,
  '定时器描述',
  () => clearInterval(timerId)
);
```

---

## 🎯 快速开始模板

### 最小接入（仅 LifecycleManager）

如果只想使用生命周期管理，只需修改 EntryAbility：

```typescript
import { LifecycleManager } from '../core/LifecycleManager';

export default class EntryAbility extends UIAbility {
  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam) {
    await LifecycleManager.getInstance().init();
  }

  onDestroy() {
    LifecycleManager.getInstance().destroy();
  }

  onForeground() {
    LifecycleManager.getInstance().onForeground();
  }

  onBackground() {
    LifecycleManager.getInstance().onBackground();
  }
}
```

### 完整接入（所有模块）

按照上述"接入步骤"完整修改 EntryAbility.ets 和 Index.ets。

---

## 📞 支持

如果遇到问题，请检查：

1. ✅ 文件是否正确复制到对应目录
2. ✅ import 路径是否正确
3. ✅ 是否使用了单例模式获取实例
4. ✅ 是否正确调用了生命周期方法
5. ✅ DevEco Studio 是否同步成功

---

## 📄 文件路径汇总

| 文件名 | 完整路径 |
|--------|---------|
| Dispatcher.ets | `entry/src/main/ets/core/Dispatcher.ets` |
| EmotionStore.ets | `entry/src/main/ets/core/EmotionStore.ets` |
| EmotionalFSM.ets | `entry/src/main/ets/core/EmotionalFSM.ets` |
| LifecycleManager.ets | `entry/src/main/ets/core/LifecycleManager.ets` |
| DebugPanelViewModel.ets | `entry/src/main/ets/core/DebugPanelViewModel.ets` |
| DebugPanel.ets | `entry/src/main/ets/components/DebugPanel.ets` |

---

**接入指南结束**

祝接入顺利！ 🚀
