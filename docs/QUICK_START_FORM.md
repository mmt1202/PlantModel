# 🚀 桌面卡片功能 - 快速开始指南

## ⚡ 5 分钟快速上手

### 第一步：同步项目依赖

在 DevEco Studio 中执行：

```bash
# 方式 1：使用菜单
File -> Sync Project with Gradle Files

# 方式 2：使用命令行
cd entry
ohpm install
```

### 第二步：检查配置文件

确保以下文件已正确配置：

✅ `entry/src/main/module.json5` - 已添加 `PlantFormExtension`
✅ `entry/src/main/resources/base/profile/form_config.json` - 卡片配置
✅ `entry/src/main/resources/base/element/string.json` - 已添加卡片描述

### 第三步：编译构建

```bash
# 清理并构建项目
Build -> Clean Project
Build -> Rebuild Project

# 或直接点击运行按钮
```

### 第四步：运行应用

1. **连接设备或启动模拟器**
   - 真机：通过 USB 连接并开启开发者模式
   - 模拟器：DevEco Studio -> Device Manager -> 启动模拟器

2. **运行应用**
   - 点击运行按钮（绿色三角形）
   - 或使用快捷键：`Shift + F10`

### 第五步：添加卡片到桌面

1. **进入桌面编辑模式**
   - 在设备桌面长按空白处

2. **添加窗口小工具**
   - 点击底部的「窗口小工具」或「服务卡片」按钮

3. **找到植物日记**
   - 在列表中下滑找到「PlantDiary」或「植物日记」

4. **选择卡片尺寸**
   - 选择 2×2 尺寸的任务卡片

5. **添加到桌面**
   - 拖动卡片到桌面合适位置
   - 松手即可看到卡片显示

---

## 🧪 测试功能

### 测试场景 1：查看任务

1. 确保数据库中有今日任务
2. 观察卡片显示：
   - ✅ 显示今日任务总数
   - ✅ 显示待完成数量
   - ✅ 进度环显示完成率
   - ✅ 列出前 3 个待办任务

### 测试场景 2：完成任务

1. **点击单个任务**
   - 观察任务是否标记为完成
   - 卡片数据是否刷新

2. **点击「全部完成」按钮**
   - 所有今日任务应标记为完成
   - 卡片显示「全部完成」状态

### 测试场景 3：打开应用

1. **点击卡片空白处**
   - 应用应该启动并进入首页
   - 首页数据应该刷新

---

## 🔍 调试技巧

### 查看日志

在 DevEco Studio 中：

```
View -> Tool Windows -> Device Monitor

# 过滤日志
Tag: PlantFormExtension
```

### 关键日志信息

成功时应看到：

```
I/PlantFormExtension: Form onCreate called
I/PlantFormExtension: Fetching tasks for date: 2026-04-28
I/PlantFormExtension: Form data fetched: total=5, completed=2, pending=3
I/PlantFormExtension: Form updated successfully
```

### 常见问题排查

#### 问题 1：卡片不显示

**可能原因：**
- 扩展能力未正确注册
- 配置文件路径错误

**解决方法：**
1. 检查 `module.json5` 中 `PlantFormExtension` 配置
2. 确认 `form_config.json` 路径正确
3. 重新构建项目

#### 问题 2：卡片显示空白

**可能原因：**
- 数据库无数据
- 数据查询失败

**解决方法：**
1. 打开应用，添加一些植物和任务
2. 查看日志确认数据查询是否成功
3. 检查数据库表名是否正确

#### 问题 3：点击无响应

**可能原因：**
- `onCast` 方法未正确处理
- want 参数传递错误

**解决方法：**
1. 查看日志确认点击事件是否触发
2. 检查 `onCast` 方法实现
3. 确认任务 ID 正确传递

---

## 📊 数据准备

如果卡片显示「今天没有待办任务」，需要先添加任务数据：

### 方法 1：通过应用添加

1. 打开应用
2. 添加植物
3. 为植物创建养护任务
4. 设置任务日期为今天

### 方法 2：直接插入数据库（开发调试用）

```typescript
// 在 EntryAbility 或调试页面中执行
await store.executeSql(
  `INSERT INTO task (plantId, type, planDate, done, doneAt) 
   VALUES (?, ?, ?, ?, ?)`,
  [1, '浇水', '2026-04-28', 0, 0]
);
```

---

## 🎨 自定义样式

### 修改卡片配色

编辑 `TaskCard2x2.ets`：

```typescript
// 主色调（进度环、按钮）
const PRIMARY_COLOR = '#4CAF50'  // 绿色

// 背景色
const BG_COLOR = '#FFFFFF'       // 白色

// 文字颜色
const TEXT_PRIMARY = '#263238'   // 深灰
const TEXT_SECONDARY = '#757575' // 中灰
const TEXT_HINT = '#BDBDBD'      // 浅灰
```

### 修改卡片尺寸

编辑 `form_config.json`：

```json
{
  "type": "2x4",              // 改为 2x4 或 4x2
  "defaultDimension": "2x4",
  "supportDimensions": [
    "2x2",
    "2x4"
  ]
}
```

---

## 📱 多设备适配

### 手机

- 默认尺寸：2×2
- 推荐位置：桌面第一屏

### 平板

- 支持多尺寸：2×2, 2×4, 4×2
- 可以添加多个卡片展示不同信息

---

## 🔧 高级配置

### 修改刷新频率

编辑 `form_config.json` 的 `metaData`：

```json
{
  "refreshInterval": 900,      // 改为 15 分钟（900 秒）
  "updateDuration": 900,
  "scheduledUpdateTime": "07:00"  // 改为早上 7 点
}
```

**注意：** 系统限制最短刷新间隔为 30 分钟，设置更短时间可能不会生效。

### 禁用定时刷新

```json
{
  "updateEnabled": false
}
```

---

## 📞 获取帮助

### 官方文档

- [Form Kit 开发指南](https://developer.harmonyos.com/cn/docs/documentation/doc-guides-V3/form-extensionability-0000001778179122-V3)
- [ArkTS 卡片语法](https://developer.harmonyos.com/cn/docs/documentation/doc-references-V3/arkts-form-syntax-0000001778139042-V3)

### 社区支持

- 鸿蒙开发者论坛
- GitHub Issues
- 开发者微信群/QQ 群

---

## ✅ 检查清单

在提交代码或上架前，请确认：

- [ ] 所有配置文件已正确修改
- [ ] 包名与实际项目一致
- [ ] 数据库表名和字段正确
- [ ] 卡片能在真机/模拟器上正常显示
- [ ] 点击交互功能正常
- [ ] 数据刷新机制正常
- [ ] 日志输出正常
- [ ] 无编译错误和警告
- [ ] 已完成功能测试
- [ ] 已更新文档

---

**祝你开发顺利！** 🎉

如有问题，请查看 `docs/FORM_CARD_GUIDE.md` 获取详细文档。
