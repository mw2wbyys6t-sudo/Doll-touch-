# 如何在 DevEco Studio 中打开星空爱莉项目

**创建日期**: 2026-05-12  
**项目名称**: 星空爱莉 AI 助手  
**项目类型**: HarmonyOS NEXT 应用

---

## ⚠️ 重要说明

当前项目缺少 **DevEco Studio 项目配置文件**，需要在 DevEco Studio 中进行初始化配置后才能正常使用。

---

## 📋 第一步：创建新的 HarmonyOS 项目

### 1.1 打开 DevEco Studio

启动 DevEco Studio，等待初始化完成。

### 1.2 创建新项目

```
File → New → Create Project
```

### 1.3 选择项目模板

在模板选择页面：
1. 选择 **Empty Ability**
2. 点击 **Next**

### 1.4 配置项目

在配置页面填写：

```
Project Name: AiriAI
Bundle Name: com.airiai.assistant
Save Location: [选择你的保存目录]
```

### 1.5 点击 Finish

等待项目创建完成。

---

## 📂 第二步：替换项目文件

### 2.1 打开新创建的项目

在 DevEco Studio 中打开刚创建的项目。

### 2.2 定位项目结构

```
项目名称 (AiriAI)
├── entry
│   └── src
│       └── main
│           ├── ets
│           │   ├── ability
│           │   ├── pages
│           │   ├── components
│           │   ├── viewmodel
│           │   └── utils
│           └── resources
│           └── module.json5
└── AppScope
```

### 2.3 替换文件

**警告：以下操作会覆盖文件，请提前备份！**

#### 替换步骤 1：复制 ets 目录

1. 打开下载项目中的 `entry/src/main/ets/` 文件夹
2. 将其中的所有文件复制到新项目的 `entry/src/main/ets/` 目录
3. 覆盖所有现有文件

#### 替换步骤 2：复制 resources 目录

1. 打开下载项目中的 `entry/src/main/resources/` 文件夹
2. 将其中的所有文件复制到新项目的 `entry/src/main/resources/` 目录
3. 覆盖所有现有文件

#### 替换步骤 3：更新 module.json5

用以下内容替换 `entry/src/main/module.json5`:

```json5
{
  "module": {
    "name": "entry",
    "type": "entry",
    "description": "$string:module_desc",
    "mainElement": "EntryAbility",
    "deviceTypes": [
      "phone"
    ],
    "deliveryWithInstall": true,
    "installationFree": false,
    "pages": "$profile:main_pages",
    "abilities": [
      {
        "name": "EntryAbility",
        "srcEntry": "./ets/ability/EntryAbility.ets",
        "description": "$string:EntryAbility_desc",
        "icon": "$media:icon",
        "label": "$string:EntryAbility_label",
        "startWindowIcon": "$media:icon",
        "startWindowBackground": "$color:start_window_background",
        "exported": true,
        "skills": [
          {
            "entities": [
              "entity.system.home"
            ],
            "actions": [
              "action.system.home"
            ]
          }
        ]
      }
    ]
  }
}
```

#### 替换步骤 4：更新资源文件

用以下内容替换 `entry/src/main/resources/base/element/string.json`:

```json
{
  "string": [
    {
      "name": "module_desc",
      "value": "星空爱莉 AI助手模块"
    },
    {
      "name": "EntryAbility_desc",
      "value": "星空爱莉 AI助手主能力"
    },
    {
      "name": "EntryAbility_label",
      "value": "星空爱莉"
    },
    {
      "name": "app_name",
      "value": "星空爱莉"
    }
  ]
}
```

用以下内容替换 `entry/src/main/resources/base/element/color.json`:

```json
{
  "color": [
    {
      "name": "start_window_background",
      "value": "#FFFFFF"
    },
    {
      "name": "primary_color",
      "value": "#FF6B9D"
    },
    {
      "name": "secondary_color",
      "value": "#FFB6C1"
    },
    {
      "name": "background_light",
      "value": "#FFF5F7"
    },
    {
      "name": "background_dark",
      "value": "#1A1A2E"
    }
  ]
}
```

---

## ⚙️ 第三步：配置签名

### 3.1 打开项目结构

```
File → Project Structure
```

### 3.2 配置签名

在左侧菜单选择 **Modules → entry**

在右侧选择 **Signing Configs** 标签

勾选 **Automatically generate signature**

点击 **Apply** 和 **OK**

---

## 🔧 第四步：同步项目

### 4.1 同步项目

```
File → Sync Project with Gradle Files
```

等待同步完成，确保左下角显示 "Sync successful"

### 4.2 等待依赖下载

首次同步会自动下载依赖，等待完成。

---

## 🚀 第五步：编译项目

### 5.1 编译 Hap

```
Build → Build Hap(s) / APP(s) → Build Hap(s)
```

或使用快捷键：`Ctrl + F9`

### 5.2 查看编译结果

在 **Build** 窗口查看编译结果

**期望结果**: `BUILD SUCCESSFUL`

**如果失败**: 查看错误信息并修复

---

## ▶️ 第六步：运行应用

### 6.1 选择运行目标

在工具栏选择模拟器或真机

### 6.2 运行应用

点击工具栏的 ▶ 按钮

或使用快捷键：`Shift + F10`

---

## 📊 验证清单

### 编译验证

- [ ] 编译成功，无错误
- [ ] 无 TypeScript 类型错误
- [ ] 无资源文件缺失警告

### 运行验证

- [ ] 应用成功安装
- [ ] 应用成功启动
- [ ] Index 页面正常显示
- [ ] 角色立绘正常显示
- [ ] 聊天功能可用
- [ ] 动画正常播放

### 日志验证

在 **HiLog** 中应该看到：

```
[EntryAbility] EntryAbility onCreate
[EntryAbility] LifecycleManager 初始化成功
[Index] LifecycleManager 已注册 Index 页面
```

---

## 🐛 常见问题

### 问题 1: 项目结构不对

**现象**: 无法识别为 HarmonyOS 项目

**解决方案**:
1. 确保使用的是 DevEco Studio 最新版本
2. 创建新的空项目作为基础
3. 替换文件时保持目录结构

---

### 问题 2: 签名错误

**现象**: "Signature verification failed"

**解决方案**:
1. 打开 `File → Project Structure`
2. 选择 **Modules → entry**
3. 勾选 **Automatically generate signature**
4. 点击 **Apply** 和 **OK**
5. 重新同步和编译

---

### 问题 3: 资源文件缺失

**现象**: "Cannot find resource" 错误

**解决方案**:
1. 检查 `resources/base/` 目录是否存在
2. 检查 `element/string.json` 是否存在
3. 检查 `element/color.json` 是否存在
4. 重新复制资源文件

---

### 问题 4: 同步失败

**现象**: "Sync failed" 或 "Gradle sync failed"

**解决方案**:
1. 打开 `File → Invalidate Caches...`
2. 选择 **Invalidate and Restart**
3. 等待重启后重新同步

---

### 问题 5: 编译超时

**现象**: "Build timeout"

**解决方案**:
1. 增加 Gradle 内存配置
2. 打开 `gradle.properties`
3. 修改 `org.gradle.jvmargs=-Xmx4096m` 为 `-Xmx8192m`
4. 重新编译

---

## 📞 获取帮助

如果遇到其他问题，请提供：

1. **错误信息截图**
2. **DevEco Studio 版本号**
3. **HarmonyOS SDK 版本**
4. **操作步骤描述**

---

## 📁 项目文件清单

替换时需要复制的文件：

```
entry/src/main/ets/
├── ability/
│   └── EntryAbility.ets
├── components/
│   ├── ActionBtn.ets
│   ├── BottomNav.ets
│   ├── CharacterAnimation.ets
│   ├── MessageBubble.ets
│   └── TypingIndicator.ets
├── core/
│   ├── AnimationScheduler.ets
│   ├── CharacterSafety.ets
│   ├── ChatService.ets
│   ├── EmotionalFSM.ets
│   ├── EventDispatcher.ets
│   ├── LifecycleManager.ets
│   ├── MemoryManager.ets
│   ├── PerformanceMonitor.ets
│   ├── Store.ets
│   └── TTSManager.ets
├── model/
│   └── MessageModel.ets
├── pages/
│   └── Index.ets
├── utils/
│   ├── BodyActionManager.ets
│   ├── EmotionUnderstanding.ets
│   ├── ExpressionManager.ets
│   ├── MemoryManager.ets
│   ├── NotificationManager.ets
│   ├── PreferencesUtil.ets
│   ├── SpeechRecognitionManager.ets
│   ├── TextToSpeechManager.ets
│   ├── ThemeManager.ets
│   └── ThinkingEngine.ets
└── viewmodel/
    └── ChatViewModel.ets
```

---

## ✅ 完成

完成以上步骤后，你的项目应该可以正常编译和运行了！

如果有任何问题，请随时告诉我！
