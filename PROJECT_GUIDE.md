# 植物日记项目 - 开发指南

## 📚 项目概述

这是一个基于 HarmonyOS 5.0.5 + ArkTS 开发的植物养护管理应用。项目采用 MVVM 架构模式，包含完整的植物管理、光照记录、浇水估算、生长指标跟踪等功能。

## 🏗️ 项目架构

### 目录结构说明

```
entry/src/main/ets/
├── model/           # 数据模型层
│   ├── PlantModel.ets         # 植物、任务、日志等基础模型
│   ├── LightTypes.ets         # 光照相关枚举和工具函数
│   ├── ExposureSession.ets    # 光照会话模型
│   ├── DailyLightStat.ets     # 每日光照统计模型
│   ├── LightProfile.ets       # 光照配置档案模型
│   ├── WaterEstimatorTypes.ets # 浇水估算类型定义
│   └── ...
├── viewmodel/       # 业务逻辑层（ViewModel）
│   ├── LightExposureViewModel.ets   # 光照记录业务逻辑
│   ├── WaterEstimatorViewModel.ets  # 浇水估算业务逻辑
│   ├── RdbManager.ets              # 数据库管理器
│   └── ...
├── view/            # UI 组件层（可复用组件）
│   ├── PlantCard.ets         # 植物卡片组件
│   ├── CalendarGrid.ets      # 日历网格组件
│   └── ...
├── pages/           # 页面层
│   ├── Index.ets             # 首页（植物列表）
│   ├── PlantDetail.ets       # 植物详情页
│   ├── LightExposurePage.ets # 光照记录页
│   ├── WaterEstimatorPage.ets # 浇水估算页
│   └── ...
├── component/       # 基础组件
└── entryability/    # 应用入口
```

## 📖 核心概念

### 1. 数据模型（Model）

所有数据模型都使用 `@ObservedV2` 装饰器，支持响应式更新。

**核心模型：**
- `Plant`: 植物基本信息（名称、物种、位置等）
- `ExposureSession`: 一次完整的光照记录
- `DailyLightStat`: 每日光照统计数据
- `LightProfile`: 植物的光照偏好配置
- `Metric`: 生长指标（身高、冠幅、健康分）

### 2. 视图模型（ViewModel）

ViewModel 负责处理业务逻辑和数据持久化：

**核心 ViewModel：**
- `LightExposureViewModel`: 光照记录管理
  - 开始/结束光照会话
  - 计算光照量（lux-min）
  - 统计每日/每周数据
  
- `WaterEstimatorViewModel`: 浇水用量估算
  - 根据盆径、深度、介质等计算用水量
  - 保存浇水记录
  
- `RdbManager`: 数据库管理
  - 初始化数据库
  - 提供 CRUD 操作

### 3. 状态管理

项目使用 ArkTS 的状态管理装饰器：

- `@State`: 组件内部状态
- `@Prop`: 父组件传递给子组件
- `@Link`: 子组件与父组件双向绑定
- `@Local`: 本地状态（用于页面间共享）
- `@Consumer`: 消费全局状态
- `@ObservedV2`: 类级别的响应式装饰器
- `@Trace`: 属性级别的响应式装饰器

## 🔧 开发规范

### 1. 类型安全

**必须遵守的规则：**
```typescript
// ❌ 错误：对象字面量缺少类型声明
return items.map((item) => ({
  id: item.id,
  name: item.name
}));

// ✅ 正确：明确指定返回类型
return items.map((item): ResultInterface => {
  return {
    id: item.id,
    name: item.name
  };
});
```

### 2. 组件规范

- 所有页面组件必须使用 `@ComponentV2` 装饰
- 自定义组件必须包含 `build()` 函数
- 组件命名使用大驼峰，以 "Component" 或 "Page" 结尾

### 3. 资源规范

**颜色资源：**
- 必须使用十六进制格式：`#RRGGBB` 或 `#AARRGGBB`
- 禁止使用 `rgba()`、`rgb()` 等 CSS 颜色格式

```typescript
// ✅ 正确
backgroundColor('#FF0000')

// ❌ 错误
backgroundColor('rgba(255, 0, 0, 0.5)')
```

## 📝 功能模块说明

### 1. 光照记录模块

**文件位置：** `pages/LightExposurePage.ets`

**功能：**
- 开始/结束光照记录
- 手动补记光照
- 实时进度圆环图
- 7 天光照统计
- 光照偏好设置

**核心流程：**
1. 用户选择光照级别（弱光/中光/强光）
2. 点击"开始光照"创建会话
3. 点击"结束光照"计算光照量
4. 数据保存到数据库
5. 更新 UI 显示

### 2. 浇水估算模块

**文件位置：** `pages/WaterEstimatorPage.ets`

**功能：**
- 输入盆径、深度
- 选择介质类型、浇水策略、植株类型
- 计算推荐用水量
- 保存浇水记录

**计算公式：**
```
基础体积 = π × (半径)² × 深度 × 策略系数
最终用量 = 基础体积 × 介质系数 × 植株系数
```

### 3. 急救与转盆模块

**文件位置：** `pages/EmergencyAndRotatePage.ets`

**功能：**
- 急救流程指引
- 转盆提醒（每 7 天转盆 90°）
- 打卡记录

### 4. 生长对比模块

**文件位置：** `pages/GrowthComparePage.ets`

**功能：**
- 添加植物照片
- 滑动对比不同时期的照片
- 显示时间跨度

### 5. 生长指标模块

**文件位置：** `pages/GrowthIndicatorPage.ets`

**功能：**
- 记录身高、冠幅、健康分
- 查看生长趋势图表
- 支持列表/图表两种视图

## 🗄️ 数据库设计

### 主要数据表

1. **T_PLANT**: 植物信息表
   - id, name, species, location, createdAt

2. **T_LIGHT_SESSION**: 光照会话表
   - id, plantId, startAt, endAt, durationMin, level, luxMinutes

3. **T_LIGHT_PROFILE**: 光照档案表
   - plantId, targetLuxMinLow, targetLuxMinHigh, preferredLevel

4. **T_WATER_LOG**: 浇水记录表
   - plantId, volumeMl, note, createdAt

5. **T_METRIC**: 生长指标表
   - plantId, height, width, score, createdAt

## 🎯 开发建议

### 1. 新增功能步骤

1. 在 `model/` 目录创建数据模型
2. 在 `viewmodel/` 目录创建业务逻辑
3. 在 `pages/` 目录创建页面
4. 在 `Index.ets` 中注册路由

### 2. 调试技巧

- 使用 `hilog.info()` 输出日志
- 使用 `console.error()` 输出错误
- 使用 `prompt.showToast()` 显示用户提示

### 3. 性能优化

- 避免在 `build()` 函数中执行复杂计算
- 使用 `@ObservedV2` 精确跟踪数据变化
- 大数据列表使用 `LazyForEach`

## 📚 学习资源

- [HarmonyOS 官方文档](https://developer.harmonyos.com/)
- [ArkTS 语言基础](https://developer.harmonyos.com/cn/docs/documentation/doc-guides-V3/arkts-get-started-0000001775281952-V3)
- [ArkUI 组件参考](https://developer.harmonyos.com/cn/docs/documentation/doc-references-V3/arkui-overview-0000001775342948-V3)

## 🔍 常见问题

### Q: 如何添加新的数据表？
A: 在 `RdbManager.ets` 中的 `onCreate` 方法里添加 SQL 建表语句。

### Q: 如何在页面间传递数据？
A: 使用 `@Param` 装饰器接收参数，通过 `NavPathStack` 进行导航。

### Q: 如何实现实时数据更新？
A: 使用 `@Trace` 装饰属性，数据变化时 UI 会自动更新。

---

**最后更新：** 2024-03-14
**版本：** 1.0.0
