# 星空爱莉 (Hoshizora Airi) ArkTS 模块化修复计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 全面审查并修复星空爱莉项目的 ArkTS 语法兼容性问题，确保项目能在 HarmonyOS NEXT / DevEco Studio 中正常编译和运行。

**Architecture:** 项目采用分层架构，分为 UI 层（components/pages）、业务层（core）、工具层（utils）、数据层（model/viewmodel）。本次修复重点关注 ArkTS 装饰器使用规范、API 导入路径、状态管理机制等核心问题。

**Tech Stack:** ArkTS + HarmonyOS NEXT Stage模型 + ArkUI声明式UI + DevEco Studio 5.0.0

---

## 一、项目模块分析

### 1.1 模块结构总览

```
ohos_airi/entry/src/main/ets/
├── ability/          # 应用入口 (1个文件)
├── components/       # UI组件层 (6个文件)
├── core/            # 核心业务层 (12个文件)
├── model/           # 数据模型层 (1个文件)
├── pages/           # 页面层 (1个文件)
├── utils/           # 工具类层 (10个文件)
└── viewmodel/       # 视图模型层 (1个文件)
```

### 1.2 各模块功能说明

| 模块 | 文件数 | 核心功能 | 问题严重程度 |
|------|--------|---------|-------------|
| ability | 1 | 应用生命周期管理 | 🟡 中 |
| components | 6 | UI展示与动画 | 🔴 高 |
| core | 12 | 情绪/记忆/事件分发 | 🔴 高 |
| model | 1 | 数据结构定义 | 🟡 中 |
| pages | 1 | 主页面入口 | 🔴 高 |
| utils | 10 | 辅助工具 | 🟡 中 |
| viewmodel | 1 | 视图状态管理 | 🔴 高 |

---

## 二、已识别的问题

### 2.1 高优先级问题 (🔴 必须修复)

| # | 问题描述 | 涉及文件 | 根本原因 |
|---|---------|---------|----------|
| 1 | `@ohos.arkui.observable` API已废弃 | Index.ets, ChatViewModel.ets | API路径变更 |
| 2 | `@Entry` 装饰器滥用 | CharacterAnimation.ets | 只能在页面入口使用 |
| 3 | 缺少 `@ObjectLink`/`@Observed` | MessageBubble.ets, MessageModel.ets | 状态装饰器配对使用 |
| 4 | `@Track`/`@Observed` 在单例类中滥用 | EmotionStore.ets, LifecycleManager.ets, EmotionalFSM.ets | 装饰器作用域错误 |
| 5 | `@ohos.animator` API已变更 | ExpressionManager.ets | API路径变更 |

### 2.2 中优先级问题 (🟡 建议修复)

| # | 问题描述 | 涉及文件 | 说明 |
|---|---------|---------|------|
| 6 | Map泛型序列化问题 | MemoryManager.ets | Map无法直接序列化到Preferences |
| 7 | Date对象观察问题 | MessageModel.ets | Date需要特殊处理 |
| 8 | TTS API版本兼容性 | TextToSpeechManager.ets | 需确认最新API |
| 9 | 权限配置名称 | module.json5 | 部分权限名称可能错误 |

---

## 三、修复策略

### 3.1 装饰器使用规范

**规则1: `@Observed` + `@ObjectLink` 配对使用**
- `@Observed` 用于被观察的类（必须用 `new` 创建）
- `@ObjectLink` 用于接收观察对象的组件属性
- 仅在UI组件和被UI组件观察的类中使用

**规则2: `@Track` 必须在 `@Observed` 类中使用**
- `@Track` 只能追踪类的属性变化
- 必须在 `@Observed` 装饰的类中使用
- 普通业务类（单例）不使用装饰器

**规则3: `@Entry` 仅用于页面入口**
- `@Entry` 只能在 `main_pages.json` 中注册的页面组件使用
- 子组件不能使用 `@Entry`

### 3.2 API导入规范

| 旧API | 新API | 说明 |
|-------|-------|------|
| `@ohos.arkui.observable` | `@kit.ArkUI` | 状态管理统一入口 |
| `@ohos.animator` | `@kit.ArkUI` 或 `animateTo` | 动画API整合 |
| `@ohos.preferences` | `@kit.ArkData` | 数据存储API |

---

## 四、预期成果

### 4.1 修复后的验证标准

- [ ] DevEco Studio Sync Project 成功
- [ ] Build HAP 编译成功
- [ ] 所有 ArkTS 装饰器使用规范
- [ ] 所有 API 导入路径正确
- [ ] 无编译警告或错误

### 4.2 影响范围

- **配置影响**: build-profile.json5, module.json5, hvigor-config.json5
- **UI影响**: components/*, pages/*
- **业务影响**: core/*, utils/*, viewmodel/*
- **数据影响**: model/*

---

## 五、风险与注意事项

1. **单例类状态观察**: 单例类不能使用装饰器，状态变化需通过事件分发或 AppStorage 通知UI
2. **Map序列化**: 内存中的Map需转换为JSON对象后再存储
3. **异步状态**: 异步操作中的状态更新需注意线程安全
