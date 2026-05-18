# 植物日记 - 桌面卡片功能开发文档

## 📋 功能概述

为植物日记应用添加了桌面卡片（Form）功能，用户可以在桌面快速查看今日养护任务并完成打卡。

## 🎯 已实现功能

### 2×2 任务速览卡片

**功能特性：**
- ✅ 显示今日任务总数和待完成数量
- ✅ 进度环可视化展示完成率
- ✅ 列出前 3 个待办任务
- ✅ 点击任务项快速完成
- ✅ 一键完成所有任务按钮
- ✅ 点击卡片打开应用
- ✅ 自动定时刷新（30 分钟）
- ✅ 应用进入前台时自动刷新

**卡片尺寸：** 128vp × 128vp

---

## 📁 文件结构

```
entry/src/main/
├── ets/
│   ├── formextensionability/
│   │   └── PlantFormExtension.ets      # 卡片扩展能力（核心）
│   ├── model/
│   │   └── FormData.ets                # 卡片数据模型
│   ├── view/
│   │   └── card/
│   │       └── TaskCard2x2.ets         # 卡片 UI 组件
│   └── entryability/
│       └── EntryAbility.ets            # 主 Ability（已添加刷新逻辑）
└── resources/
    └── base/
        ├── element/
        │   └── string.json             # 字符串资源（已添加卡片描述）
        └── profile/
            └── form_config.json        # 卡片配置文件
```

---

## 🔧 配置文件说明

### 1. module.json5

添加了 `PlantFormExtension` 扩展能力：

```json5
{
  "name": "PlantFormExtension",
  "srcEntry": "./ets/formextensionability/PlantFormExtension.ets",
  "type": "form",
  "exported": true,
  "metadata": [
    {
      "name": "ohos.extension.form",
      "resource": "$profile:form_config"
    }
  ],
  "permissions": [
    "ohos.permission.INTERNET"
  ]
}
```

### 2. form_config.json

卡片配置：

```json
{
  "forms": [
    {
      "name": "task_card_2x2",
      "description": "$string:form_task_card_desc",
      "src": "./ets/view/card/TaskCard2x2.ets",
      "uiSyntax": "arkts",
      "type": "2x2",
      "defaultDimension": "2x2",
      "supportDimensions": ["2x2"],
      "metaData": {
        "description": "今日任务速览卡片",
        "apiVersion": "API 23",
        "source": "PlantDiary",
        "refreshInterval": 1800,
        "updateEnabled": true,
        "updateDuration": 1800,
        "scheduledUpdateTime": "08:00"
      }
    }
  ]
}
```

**关键配置项：**
- `refreshInterval`: 1800 秒（30 分钟）自动刷新
- `scheduledUpdateTime`: 每天早上 8:00 定时刷新
- `updateEnabled`: 启用定时更新

---

## 💡 使用方法

### 添加卡片到桌面

1. **长按桌面空白处**，进入桌面编辑模式
2. **点击「窗口小工具」**或「服务卡片」按钮
3. **找到「植物日记」**应用
4. **选择 2×2 尺寸**的任务卡片
5. **拖动到桌面**合适位置
6. 卡片会自动显示今日任务数据

### 卡片交互

| 操作 | 响应 |
|------|------|
| 点击任务项 | 完成该任务 |
| 点击「全部完成」按钮 | 完成今日所有任务 |
| 点击卡片空白处 | 打开植物日记应用 |

---

## 🔄 数据刷新机制

### 自动刷新
- **定时刷新**：每 30 分钟自动更新一次
- **定点刷新**：每天早上 8:00 自动刷新
- **应用触发**：应用进入前台时刷新所有卡片

### 手动刷新
- 目前鸿蒙系统不支持用户手动下拉刷新卡片
- 用户可以通过打开应用来触发刷新

---

## 🛠️ 技术实现要点

### 1. FormExtensionAbility

```typescript
// 核心生命周期方法
- onCreate(): 卡片创建时初始化数据
- onUpdate(): 定时刷新时更新数据
- onCast(): 处理用户点击事件
- onDelete(): 卡片删除时清理资源
```

### 2. 数据流

```
数据库 (task 表) 
    ↓
FormExtensionAbility.fetchFormData()
    ↓
FormData 对象
    ↓
updateForm() → 卡片 UI 组件
    ↓
TaskCard2x2.ets 渲染
```

### 3. 点击事件处理

```typescript
// 1. 卡片发送事件
this.completeTask(task.id);

// 2. FormExtensionAbility 接收
onCast(want, formData) {
  const taskId = want.parameters['taskId'];
  // 执行任务完成逻辑
}
```

---

## ⚠️ 注意事项

### 1. 包名修改

当前代码中使用的包名是 `com.example.plantdiary`，请根据你的实际包名修改：

**需要修改的文件：**
- `PlantFormExtension.ets` 中的 `openApp()` 方法
- `EntryAbility.ets` 中的 `refreshFormCards()` 方法

**修改位置：**
```typescript
const want: Want = {
  bundleName: '你的实际包名',  // ← 修改这里
  abilityName: 'PlantFormExtension',
  // ...
};
```

### 2. 数据库表名

代码中使用的表名：
- `task` - 任务表
- `plant` - 植物表

确保这些表在你的数据库中存在且字段匹配。

### 3. 权限配置

卡片扩展需要以下权限：
- `ohos.permission.INTERNET` - 网络访问（可选，用于未来扩展）

### 4. 兼容性要求

- **最低系统版本**：HarmonyOS 6.1.0 (API 23)
- **开发工具**：DevEco Studio 最新版

---

## 🧪 测试建议

### 1. 功能测试

- [ ] 添加卡片到桌面
- [ ] 验证卡片显示数据正确
- [ ] 测试点击任务完成功能
- [ ] 测试「全部完成」按钮
- [ ] 测试点击卡片打开应用
- [ ] 验证定时刷新（等待 30 分钟或修改系统时间）

### 2. 边界测试

- [ ] 无任务时的空状态显示
- [ ] 任务超过 3 个时的列表显示
- [ ] 数据库为空时的处理
- [ ] 应用卸载后卡片自动移除

### 3. 性能测试

- [ ] 卡片刷新时的电量消耗
- [ ] 大量任务数据时的加载速度
- [ ] 多次快速点击的响应

---

## 🚀 后续优化建议

### 短期优化（P0）

1. **完善错误处理**：添加更详细的错误日志和异常捕获
2. **优化 UI 细节**：调整字体大小、间距、颜色等
3. **添加加载状态**：数据加载时显示 loading 动画
4. **暗黑模式适配**：根据系统主题自动切换卡片配色

### 中期优化（P1）

1. **多尺寸支持**：开发 2×4、4×2 等其他尺寸卡片
2. **自定义刷新**：支持用户配置刷新频率
3. **快捷操作**：添加更多快捷完成选项
4. **数据统计**：在卡片上显示周/月完成任务统计

### 长期优化（P2）

1. **智能推荐**：根据天气、季节推荐养护建议
2. **植物状态**：显示植物健康度、生长天数等
3. **照片轮播**：在卡片上轮播植物照片
4. **交互增强**：支持滑动切换不同植物视图

---

## 📚 参考资料

### 官方文档
- [HarmonyOS Form Kit 开发指南](https://developer.harmonyos.com/cn/docs/documentation/doc-guides-V3/form-extensionability-0000001778179122-V3)
- [ArkTS 卡片开发范式](https://developer.harmonyos.com/cn/docs/documentation/doc-references-V3/arkts-form-syntax-0000001778139042-V3)
- [FormExtensionAbility 参考](https://developer.harmonyos.com/cn/docs/documentation/doc-references-V3/js-formextensionability-0000001778139046-V3)

### 设计规范
- [鸿蒙桌面卡片设计规范](https://developer.harmonyos.com/cn/docs/design/des-guides/overview-0000001679511637)
- [卡片尺寸与布局](https://developer.harmonyos.com/cn/docs/design/des-guides/form-0000001679513681)

---

## 🆘 常见问题

### Q1: 卡片不显示数据？
**A:** 检查以下几点：
1. 数据库是否有今日任务数据
2. `module.json5` 配置是否正确
3. 查看 DevEco Studio 的日志输出
4. 确保 `FormExtensionAbility` 已正确注册

### Q2: 点击卡片没反应？
**A:** 可能的原因：
1. `onCast` 方法未正确实现
2. want 参数传递有误
3. 查看日志确认点击事件是否触发

### Q3: 卡片刷新不及时？
**A:** 刷新机制说明：
1. 定时刷新间隔最短为 30 分钟（系统限制）
2. 应用进入前台时会主动刷新
3. 可以手动调用 `requestFormReady` 触发刷新

### Q4: 如何调试卡片？
**A:** 调试方法：
1. 使用 DevEco Studio 的日志工具查看输出
2. 在真机或模拟器上添加卡片
3. 使用 `hilog` 打印关键信息

---

## 📝 更新日志

### v1.0.0 (2026-04-28)
- ✅ 初始版本发布
- ✅ 实现 2×2 任务卡片
- ✅ 支持任务完成交互
- ✅ 定时刷新机制
- ✅ 应用前台自动刷新

---

**开发者**：植物日记开发团队  
**最后更新**：2026 年 4 月 28 日
