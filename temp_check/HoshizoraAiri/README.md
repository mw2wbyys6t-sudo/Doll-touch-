# 星空爱莉 AI助手 - 鸿蒙应用

## 项目概述

基于星空爱莉角色设定的鸿蒙（HarmonyOS）AI助手应用，包含聊天交互、数据持久化、深色模式和推送通知功能。

## 项目结构

```
HoshizoraAiri/
├── package.json                    # 项目配置
├── build-profile.json5            # 构建配置
├── hvigor-config.json5            # Hvigor配置
├── hvigorfile.ts                  # 构建脚本
└── entry/                         # 主入口模块
    ├── package.json
    ├── oh-package.json5
    ├── build-profile.json5
    ├── hvigorfile.ts
    └── src/main/
        ├── ets/
        │   ├── ability/
        │   │   └── EntryAbility.ets      # 应用入口
        │   ├── components/
        │   │   └── DebugPanel.ets        # 调试面板
        │   ├── core/
        │   │   ├── Dispatcher.ets        # 事件分发器
        │   │   ├── EmotionStore.ets     # 情绪存储
        │   │   ├── EmotionalFSM.ets     # 情绪状态机
        │   │   └── LifecycleManager.ets  # 生命周期管理
        │   ├── model/
        │   │   └── MessageModel.ets     # 消息数据模型
        │   ├── pages/
        │   │   └── Index.ets            # 主页面
        │   ├── utils/
        │   │   ├── BodyActionManager.ets    # 身体动作管理
        │   │   ├── EmotionUnderstanding.ets # 情感理解
        │   │   ├── ExpressionManager.ets    # 表情管理
        │   │   ├── MemoryManager.ets        # 记忆管理
        │   │   ├── NotificationManager.ets  # 推送通知管理
        │   │   ├── PreferencesUtil.ets      # 数据持久化
        │   │   ├── SpeechRecognitionManager.ets # 语音识别
        │   │   ├── TextToSpeechManager.ets # 语音合成
        │   │   ├── ThemeManager.ets        # 主题管理
        │   │   └── ThinkingEngine.ets      # AI思考引擎
        │   └── viewmodel/
        │       └── ChatViewModel.ets       # 聊天视图模型
        ├── module.json5                   # 模块配置
        └── resources/
            └── base/
                ├── element/
                │   ├── color.json         # 颜色资源
                │   └── string.json        # 字符串资源
                ├── profile/
                │   └── main_pages.json    # 页面路由
                └── media/
                    └── icon.png           # 应用图标
```

## 功能特性

### 1. 聊天交互
- 文字消息发送和接收
- AI自动回复（爱莉风格）
- 输入中动画指示器
- 消息时间显示

### 2. 数据持久化
- 使用 Preferences 存储聊天记录
- 自动保存会话状态
- 支持重启后恢复聊天

### 3. 深色模式
- 浅色模式 / 深色模式 / 跟随系统
- 主题切换动画
- 全局状态管理

### 4. 推送通知
- 消息到达通知
- 定时通知支持
- 自定义通知样式

### 5. 快捷功能
- 写文案
- 日程管理
- 图片生成
- 音乐推荐

## 设计风格

- 粉色渐变主题（#ffb6c1 → #dda0dd）
- 圆角卡片设计
- 响应式布局
- 符合星空爱莉偶像设定

## 技术栈

- **框架**: HarmonyOS NEXT
- **语言**: TypeScript (ETS)
- **UI框架**: ArkUI
- **构建工具**: Hvigor
- **数据存储**: Preferences

## 构建与运行

### 环境要求

- DevEco Studio 5.0+
- HarmonyOS SDK 12+
- Node.js 18+

### 构建命令

```bash
# 构建HAP包
npm run build:ohos

# 清理构建
npm run clean
```

### 运行方式

1. 打开 DevEco Studio
2. 导入项目：File → Open → 选择 HoshizoraAiri 目录
3. 连接鸿蒙设备或启动模拟器
4. 点击运行按钮

## 权限配置

在 module.json5 中配置以下权限：

```json
{
  "requestPermissions": [
    {
      "name": "ohos.permission.INTERNET",
      "reason": "用于网络请求"
    },
    {
      "name": "ohos.permission.POST_NOTIFICATION",
      "reason": "用于推送通知"
    }
  ]
}
```

## 界面预览

### 主界面
- 顶部导航栏（角色名称、设置按钮、主题切换）
- 聊天消息区域（消息气泡、输入指示器）
- 快捷功能入口（四个功能按钮）
- 输入栏（表情选择、文本输入、语音输入）
- 底部导航（聊天、任务、创作、我的）

### 深色模式
- 暗色背景（#1a1a2e）
- 深色卡片（#2d2d44）
- 粉色强调色保持不变

## 开发说明

### 状态管理

使用 @ohos.arkui.observable 进行响应式状态管理：

```typescript
@observable
class ChatViewModel {
  messages: Message[] = [];
  isTyping: boolean = false;
}
```

### 主题切换

```typescript
const theme = ThemeManager.getCurrentTheme();
await ThemeManager.setTheme('dark');
```

### 数据持久化

```typescript
await PreferencesUtil.putString('key', 'value');
const value = await PreferencesUtil.getString('key', 'default');
```

### 推送通知

```typescript
await NotificationManager.showNotification('标题', '内容');
```

## 待办事项

- [ ] 语音输入功能
- [ ] 真实AI后端集成
- [ ] 任务管理页面
- [ ] 创作工具页面
- [ ] 用户个人中心

## 许可证

MIT License

---

**星空爱莉 AI助手** - 让每一天都充满魔法
