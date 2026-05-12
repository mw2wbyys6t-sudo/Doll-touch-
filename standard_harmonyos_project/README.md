# 星空爱莉 AI助手 - DevEco Studio 标准项目

**版本**: 1.0.0  
**平台**: HarmonyOS NEXT  
**开发语言**: ArkTS  
**日期**: 2026-05-12

---

## 📦 项目概述

这是一个完全符合 **DevEco Studio 标准** 的 HarmonyOS NEXT 项目，包含：

- ✅ 标准项目结构
- ✅ ArkTS 核心模块
- ✅ 完整生命周期管理
- ✅ 情绪状态机
- ✅ 事件分发系统
- ✅ 调试面板

---

## 🏗️ 项目结构

```
standard_harmonyos_project/
├── AppScope/                          # 应用全局配置
│   ├── app.json5                     # 应用配置
│   └── resources/base/element/        # 全局资源
│       └── string.json               # 全局字符串
│
├── entry/                            # 主模块
│   └── src/main/
│       ├── module.json5              # 模块配置
│       ├── config.json               # 构建配置
│       ├── ets/
│       │   ├── ability/             # 应用入口
│       │   │   └── EntryAbility.ets
│       │   ├── core/                 # 核心模块
│       │   │   ├── Dispatcher.ets     # 事件分发器
│       │   │   ├── EmotionStore.ets   # 情绪存储
│       │   │   ├── EmotionalFSM.ets   # 情绪状态机
│       │   │   └── LifecycleManager.ets # 生命周期管理
│       │   └── pages/               # 页面
│       │       └── Index.ets         # 主页面
│       └── resources/               # 资源文件
│           └── base/
│               ├── element/          # 元素资源
│               │   ├── color.json
│               │   └── string.json
│               └── profile/          # 配置文件
│                   └── main_pages.json
│
├── build-profile.json5               # 构建配置
└── settings.gradle                  # Gradle 设置
```

---

## 🚀 快速开始

### 方式一：在 DevEco Studio 中打开

1. **打开 DevEco Studio**

2. **创建新项目**
   ```
   File → New → Create Project
   → 选择 Empty Ability
   → 填写项目名称: AiriAI
   → Bundle Name: com.airiai.assistant
   → Finish
   ```

3. **复制源码**
   - 删除自动生成的文件
   - 将 `standard_harmonyos_project/entry/src/main/ets/` 下的所有文件复制到新项目
   - 将 `standard_harmonyos_project/entry/src/main/resources/` 下的所有文件复制到新项目
   - 复制 `AppScope/` 目录

4. **配置签名**
   ```
   File → Project Structure
   → Modules → entry
   → Signing Configs
   → 勾选 Automatically generate signature
   → Apply → OK
   ```

5. **编译运行**
   ```
   Build → Build Hap(s) → Build Hap(s)
   Run → Run 'entry'
   ```

### 方式二：直接打开

如果 DevEco Studio 支持直接打开现有项目：

1. `File → Open`
2. 选择 `standard_harmonyos_project` 文件夹
3. 等待同步完成
4. 配置签名并运行

---

## 📱 核心模块说明

### 1. Dispatcher.ets - 事件分发器

```typescript
// 订阅事件
const id = Dispatcher.getInstance().subscribe('event:name', (data) => {
  console.info('收到事件:', data);
});

// 发送事件
Dispatcher.getInstance().emit('event:name', { key: 'value' });

// 取消订阅
Dispatcher.getInstance().unsubscribe(id);
```

### 2. EmotionStore.ets - 情绪存储

```typescript
// 设置情绪
EmotionStore.getInstance().setEmotion(EmotionType.HAPPY, 100);

// 获取权重
const weight = EmotionStore.getInstance().getEmotionWeight(EmotionType.HAPPY);

// 开始衰减
EmotionStore.getInstance().startDecay(5, 1000);

// 锁定情绪
EmotionStore.getInstance().lock('对话中', 5000);
```

### 3. EmotionalFSM.ets - 情绪状态机

```typescript
// 状态转换
const success = EmotionalFSM.getInstance().transitionTo(FSMState.TALKING);

// 添加状态锁
EmotionalFSM.getInstance().addLock(FSMState.TALKING, '用户对话中', 5000);

// 获取可用转换
const available = EmotionalFSM.getInstance().getAvailableTransitions();
```

### 4. LifecycleManager.ets - 生命周期管理

```typescript
// 初始化（在 EntryAbility.onCreate 中调用）
await LifecycleManager.getInstance().init();

// 页面出现
LifecycleManager.getInstance().onAppear('Index');

// 页面消失
LifecycleManager.getInstance().onDisappear('Index');

// 标记用户活动
LifecycleManager.getInstance().markUserActivity();

// 进入睡眠
LifecycleManager.getInstance().enterSleep();

// 唤醒
LifecycleManager.getInstance().wakeup();
```

---

## 🎯 功能演示

### 状态机状态

| 状态 | 说明 | 可转换到 |
|------|------|---------|
| IDLE | 空闲 | TALKING, THINKING, HAPPY, SAD, ANGRY, EXCITED, SLEEPING |
| TALKING | 说话中 | IDLE, HAPPY, SAD |
| THINKING | 思考中 | IDLE, EXCITED, CONFUSED |
| HAPPY | 开心 | IDLE, EXCITED |
| SAD | 悲伤 | IDLE, SCARED |
| ANGRY | 愤怒 | IDLE, TALKING |
| EXCITED | 兴奋 | IDLE, HAPPY |
| SCARED | 恐惧 | IDLE, SAD |
| CONFUSED | 困惑 | IDLE, THINKING |
| SLEEPING | 睡眠中 | IDLE |

### 情绪类型

| 情绪 | 权重范围 | 衰减率 |
|------|---------|--------|
| IDLE | 0-100 | 不衰减 |
| HAPPY | 0-100 | 正常 |
| SAD | 0-100 | 正常 |
| ANGRY | 0-100 | 正常 |
| FEARFUL | 0-100 | 正常 |
| SURPRISED | 0-100 | 正常 |
| EXCITED | 0-100 | 正常 |
| ANXIOUS | 0-100 | 正常 |
| SHY | 0-100 | 正常 |
| EMBARRASSED | 0-100 | 正常 |
| TIRED | 0-100 | 正常 |
| CONFUSED | 0-100 | 正常 |
| NEUTRAL | 0-100 | 正常 |

---

## 🔧 测试验证

### 1. 编译测试

```
Build → Build Hap(s) → Build Hap(s)
```

**期望结果**: ✅ BUILD SUCCESSFUL

### 2. 运行测试

```
Run → Run 'entry'
```

**期望结果**: ✅ 应用成功安装并启动

### 3. 日志测试

在 HiLog 中过滤 `AiriAI` 或 `LifecycleManager`：

**期望日志**:
```
[EntryAbility] EntryAbility onCreate
[LifecycleManager] 开始初始化
[LifecycleManager] 初始化完成
[LifecycleManager] 页面注册: Index
```

### 4. 功能测试

1. 点击 "说话" 按钮 → FSM 状态变为 TALKING
2. 点击 "开心" 按钮 → FSM 状态变为 HAPPY，情绪变为 HAPPY
3. 查看调试面板 → 显示当前状态和情绪权重
4. 输入消息 → 情绪变为 HAPPY

### 5. 生命周期测试

1. 按 Home 键 → 查看日志 "[LifecycleManager] 应用进入后台"
2. 重新打开应用 → 查看日志 "[LifecycleManager] 应用进入前台"

---

## 📋 开发指南

### 添加新页面

1. 在 `entry/src/main/ets/pages/` 创建页面文件
2. 在 `entry/src/main/resources/base/profile/main_pages.json` 中注册页面
3. 在 `module.json5` 的 abilities 中添加新 ability

### 添加新模块

1. 在 `entry/src/main/ets/core/` 创建模块文件
2. 在需要的地方 import 并使用

### 添加新资源

1. 在 `entry/src/main/resources/base/` 下创建或修改资源文件
2. 使用 `$r('app.type.name')` 引用

---

## ⚠️ 注意事项

### 1. 单例模式

所有核心模块都使用单例模式：
```typescript
// ✅ 正确
const instance = Dispatcher.getInstance();

// ❌ 错误
const instance = new Dispatcher();
```

### 2. 生命周期顺序

1. 首先初始化 Dispatcher（自动）
2. 然后初始化 EmotionStore（自动）
3. 然后初始化 EmotionalFSM（自动）
4. 最后初始化 LifecycleManager（手动调用 init()）

### 3. 资源清理

页面销毁时必须调用 `onDisappear()`：
```typescript
aboutToDisappear() {
  LifecycleManager.getInstance().onDisappear('Index');
}
```

### 4. 定时器清理

使用 LifecycleManager 注册定时器以便自动清理：
```typescript
const timerId = setInterval(...);
LifecycleManager.getInstance().registerResource(
  `interval_${Date.now()}`,
  ResourceType.TIMER,
  '定时器',
  () => clearInterval(timerId)
);
```

---

## 📞 支持

如有问题，请检查：

1. DevEco Studio 版本（推荐 5.0.3.900+）
2. HarmonyOS SDK 版本（推荐 NEXT Developer Beta1）
3. 项目是否正确同步
4. 签名是否配置

---

## 📄 文件路径

| 文件 | 路径 |
|------|------|
| EntryAbility | `entry/src/main/ets/ability/EntryAbility.ets` |
| Dispatcher | `entry/src/main/ets/core/Dispatcher.ets` |
| EmotionStore | `entry/src/main/ets/core/EmotionStore.ets` |
| EmotionalFSM | `entry/src/main/ets/core/EmotionalFSM.ets` |
| LifecycleManager | `entry/src/main/ets/core/LifecycleManager.ets` |
| Index | `entry/src/main/ets/pages/Index.ets` |
| module.json5 | `entry/src/main/module.json5` |

---

## ✅ 版本信息

- **项目版本**: 1.0.0
- **ArkTS 版本**: HarmonyOS NEXT 标准
- **构建工具**: hvigor 4.1.0
- **最低 SDK**: API 9
- **目标 SDK**: API 11

---

**项目准备就绪！** 🎉

按照上述指南即可快速启动开发！
