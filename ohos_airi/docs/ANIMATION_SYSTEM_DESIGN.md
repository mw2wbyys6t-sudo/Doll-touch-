# 星空爱莉 - 动画系统设计文档

**版本**: v1.0  
**日期**: 2026-05-12  
**目标**: 实现角色表情和动作动画

---

## 一、动画系统架构

### 1.1 系统架构图

```
┌─────────────────────────────────────────────────────────────────┐
│                        动画系统架构                            │
├─────────────────────────────────────────────────────────────────┤
│                                                               │
│   ┌──────────────────┐       ┌──────────────────┐              │
│   │  ExpressionManager│       │BodyActionManager │              │
│   │   (表情管理器)    │       │   (动作管理器)    │              │
│   └────────┬─────────┘       └────────┬─────────┘              │
│            │                          │                        │
│            ▼                          ▼                        │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │              AppStorage (状态共享)                      │   │
│   │  ┌─────────────────────────────────────────────────┐   │   │
│   │  │ 表情参数: eyeOpen, eyeBrowY, mouthOpen, cheek  │   │   │
│   │  │ 头部参数: headAngleX/Y/Z                      │   │   │
│   │  │ 身体参数: bodyAngleX/Y/Z                     │   │   │
│   │  │ 动作参数: armAngle, hairSwing, clothingSwing │   │   │
│   │  └─────────────────────────────────────────────────┘   │   │
│   └──────────────────────┬────────────────────────────────┘   │
│                          │                                  │
│                          ▼                                  │
│              ┌──────────────────────┐                       │
│              │ CharacterAnimation   │                       │
│              │    (角色动画组件)     │                       │
│              └──────────────────────┘                       │
│                                                               │
└─────────────────────────────────────────────────────────────────┘
```

### 1.2 核心组件说明

| 组件 | 职责 | 文件路径 |
|------|------|----------|
| **ExpressionManager** | 管理面部表情动画 | `utils/ExpressionManager.ets` |
| **BodyActionManager** | 管理身体动作动画 | `utils/BodyActionManager.ets` |
| **CharacterAnimation** | 渲染角色动画 | `components/CharacterAnimation.ets` |

---

## 二、表情系统设计

### 2.1 表情类型

```typescript
type ExpressionType = 'idle' | 'happy' | 'sad' | 'surprised' | 'angry' | 'shy' | 'excited' | 'sleepy';
```

### 2.2 表情参数映射

| 表情 | 眼睛开合 | 眉毛位置 | 嘴巴开合 | 脸颊红晕 | 说明 |
|------|----------|----------|----------|----------|------|
| **idle** | 1.0 | 0.0 | 0.2 | 0.0 | 放松状态 |
| **happy** | 1.0 | 0.3 | 0.8 | 0.4 | 开心微笑 |
| **sad** | 0.6 | -0.3 | 0.1 | 0.0 | 难过 |
| **surprised** | 1.2 | 0.5 | 1.0 | 0.3 | 惊讶 |
| **angry** | 0.8 | -0.2 | 0.4 | -0.2 | 生气 |
| **shy** | 0.5 | -0.1 | 0.2 | 0.6 | 害羞脸红 |
| **excited** | 1.1 | 0.4 | 0.9 | 0.5 | 兴奋 |
| **sleepy** | 0.3 | -0.1 | 0.1 | 0.0 | 困倦 |

### 2.3 表情触发场景

| 场景 | 触发表情 | 触发条件 |
|------|----------|----------|
| 应用启动 | idle | 初始化时 |
| 用户点击角色 | happy | 点击角色区域 |
| 用户发送消息 | excited | 消息输入时 |
| AI回复中 | happy | 回复完成后 |
| 自动眨眼 | - | 每隔3-5秒 |

---

## 三、动作系统设计

### 3.1 动作类型

```typescript
type BodyActionType = 'wave' | 'dance' | 'idle_sway' | 'jump' | 'sit' | 'stand' | 'point';
```

### 3.2 动作参数

| 动作 | 身体倾斜 | 手臂动作 | 头发摆动 | 服装摆动 |
|------|----------|----------|----------|----------|
| **idle_sway** | 轻微摇摆 | 轻微摆动 | 自然摆动 | 轻微摆动 |
| **wave** | 轻微倾斜 | 挥手动作 | 轻微摆动 | 轻微摆动 |
| **dance** | 明显摆动 | 舞动动作 | 明显摆动 | 明显摆动 |
| **jump** | 垂直跳跃 | 向上伸展 | 大幅摆动 | 大幅摆动 |
| **sit** | 前倾 | 放松状态 | 静止 | 轻微摆动 |
| **stand** | 直立 | 自然下垂 | 静止 | 静止 |
| **point** | 轻微倾斜 | 指向动作 | 轻微摆动 | 轻微摆动 |

### 3.3 动作触发场景

| 场景 | 触发动作 | 触发条件 |
|------|----------|----------|
| 应用启动 | idle_sway | 初始化时循环播放 |
| 用户点击角色 | wave | 点击角色区域 |
| 特殊活动 | dance | 音乐播放时 |
| 用户交互 | point | 指向按钮时 |

---

## 四、动画组件实现

### 4.1 面部动画组件

```typescript
// CharacterAnimation.ets

@StorageProp('eyeOpen') eyeOpen: number = 1.0;
@StorageProp('eyeBrowY') eyeBrowY: number = 0.0;
@StorageProp('mouthOpen') mouthOpen: number = 0.2;
@StorageProp('cheek') cheek: number = 0.0;
@StorageProp('headAngleX') headAngleX: number = 0.0;
@StorageProp('headAngleY') headAngleY: number = 0.0;
@StorageProp('headAngleZ') headAngleZ: number = 0.0;
```

### 4.2 身体动画组件

```typescript
// CharacterAnimation.ets

@StorageProp('bodyAngleX') bodyAngleX: number = 0.0;
@StorageProp('bodyAngleY') bodyAngleY: number = 0.0;
@StorageProp('bodyAngleZ') bodyAngleZ: number = 0.0;
@StorageProp('armLeftAngleX') armLeftAngleX: number = 0.0;
@StorageProp('armRightAngleX') armRightAngleX: number = 0.0;
@StorageProp('hairSwing') hairSwing: number = 0.0;
@StorageProp('clothingSwing') clothingSwing: number = 0.0;
```

---

## 五、交互设计

### 5.1 用户交互流程

```
用户点击角色
      │
      ▼
┌──────────────┐
│ 触发happy表情 │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ 触发wave动作 │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ 播放眨眼动画 │
└──────────────┘
```

### 5.2 自动动画流程

```
应用启动
    │
    ▼
┌──────────────────────────────┐
│ 启动idle_sway循环动画       │
└───────────┬────────────────┘
            │
            ▼ (每隔3-5秒)
┌──────────────────────────────┐
│ 播放blink眨眼动画           │
└──────────────────────────────┘
```

---

## 六、动画参数配置

### 6.1 动画时间配置

| 动画类型 | 持续时间 | 缓动函数 | 循环次数 |
|----------|----------|----------|----------|
| 表情切换 | 300ms | easeOutCubic | 1 |
| 眨眼动画 | 200ms | easeInOut | 1 |
| 挥手动作 | 600ms | easeOutCubic | 3次循环 |
| 空闲摇摆 | 持续循环 | sine | 无限 |
| 跳舞动作 | 2000ms | easeOutCubic | 1 |

### 6.2 缓动函数说明

```typescript
// easeOutCubic 缓动函数
easeOutCubic(t: number): number {
  return 1 - Math.pow(1 - t, 3);
}

// 特点: 开始快，结束慢，适合表情和动作过渡
```

---

## 七、性能优化

### 7.1 优化策略

| 策略 | 实现方式 | 效果 |
|------|----------|------|
| **状态合并** | 使用AppStorage共享状态 | 减少重复渲染 |
| **动画节流** | 使用requestAnimationFrame | 60fps流畅 |
| **条件渲染** | 只在需要时渲染 | 减少资源消耗 |
| **缓存机制** | 缓存动画参数 | 提高响应速度 |

### 7.2 注意事项

- 避免同时播放多个复杂动画
- 眨眼动画与其他表情动画互斥
- 空闲动画使用低消耗的循环

---

## 八、扩展计划

### 8.1 短期目标

- [x] 基础表情系统
- [x] 基础动作系统
- [x] 自动眨眼机制
- [x] 空闲摇摆动画

### 8.2 中期目标

- [ ] 更多表情类型
- [ ] 更多动作类型
- [ ] 语音同步口型动画
- [ ] 触摸交互反馈

### 8.3 长期目标

- [ ] 基于AI的表情生成
- [ ] 实时面部捕捉支持
- [ ] Live2D模型集成

---

**文档状态**: ✅ 完成  
**最后更新**: 2026-05-12
