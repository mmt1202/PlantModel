# 核心文件注释索引

## 📖 说明

本文档为项目的核心文件提供详细的中文注释和学习指南。每个文件都包含：
- 文件功能说明
- 核心代码解析
- 关键知识点
- 学习建议

---

## 📁 Model 层（数据模型）

### 1. LightTypes.ets
**路径：** `model/LightTypes.ets`

**功能：** 光照记录模块的类型定义和工具函数

**核心内容：**
- `LightLevel` 枚举：光照级别（弱光/中光/强光）
- `LightStatus` 枚举：光照状态（不足/适中/过强）
- 工具函数：日期格式化、ID 生成等

**关键代码解析：**

```typescript
// 光照级别枚举 - 用于表示植物所需的光照强度偏好
export enum LightLevel {
  LOW = 0,   // 弱光：适合耐阴植物
  MID = 1,   // 中光：适合大多数室内植物
  HIGH = 2   // 强光：适合喜阳植物
}

// 日期格式化工具 - 将日期转换为 YYYY-MM-DD 格式
export function ymd(d: Date): string {
  const y: number = d.getFullYear();
  const m: number = d.getMonth() + 1; // getMonth() 返回 0-11，需要 +1
  const dd: number = d.getDate();
  // 月份和日期补零，确保格式统一
  const mmStr: string = m < 10 ? '0' + m : '' + m;
  const ddStr: string = dd < 10 ? '0' + dd : '' + dd;
  return `${y}-${mmStr}-${ddStr}`;
}
```

**知识点：**
1. 枚举类型的使用
2. 日期对象的操作
3. 字符串格式化

---

### 2. ExposureSession.ets
**路径：** `model/ExposureSession.ets`

**功能：** 光照会话记录模型

**核心内容：**
- 记录一次完整的光照过程
- 支持开始/结束模式和即时记录模式

**关键代码解析：**

```typescript
@ObservedV2
export default class ExposureSession {
  @Trace id: string = '';           // 会话唯一标识
  @Trace plantId: number = 0;       // 关联的植物 ID
  @Trace startAt: number = 0;       // 开始时间戳（毫秒）
  @Trace endAt: number = 0;         // 结束时间戳（毫秒）
  @Trace durationMin: number = 0;   // 持续时间（分钟）
  @Trace level: LightLevel = LightLevel.MID; // 光照级别
  @Trace luxMinutes: number = 0;    // 等效光照量（lux-min）
  
  // 创建一个已开始的会话 - 当用户点击"开始光照"时调用
  static createStarted(plantId: number, level: LightLevel, startAt: number): ExposureSession {
    const s: ExposureSession = new ExposureSession(plantId);
    s.level = level;
    s.startAt = startAt;
    return s;
  }
  
  // 结束会话 - 当用户点击"结束光照"时调用
  finishWith(endAt: number, luxMinutes: number): void {
    this.endAt = endAt;
    // 计算持续时间（分钟），至少为 1 分钟
    const dur: number = Math.max(1, Math.floor((this.endAt - this.startAt) / 60000));
    this.durationMin = dur;
    this.luxMinutes = luxMinutes;
  }
}
```

**知识点：**
1. `@ObservedV2` 装饰器：使类支持响应式更新
2. `@Trace` 装饰器：标记需要追踪的属性
3. 静态方法：工厂模式创建对象
4. 时间戳计算：毫秒转分钟

---

### 3. PlantModel.ets
**路径：** `model/PlantModel.ets`

**功能：** 植物、任务、日志等基础模型

**核心类：**
- `Plant`: 植物基本信息
- `PlanTpl`: 养护计划模板
- `PlantTask`: 植物任务
- `LogEntry`: 日志条目
- `Metric`: 生长指标

**关键代码解析：**

```typescript
@ObservedV2
export class Plant {
  @Trace id: number              // 植物唯一 ID（数据库自增）
  @Trace name: string            // 植物名称（用户自定义）
  @Trace species: string         // 物种名称（学名）
  @Trace location: string        // 摆放位置
  @Trace createdAt: number       // 添加时间戳
  
  constructor(id: number, name: string, species: string, location: string, createdAt: number) {
    this.id = id;
    this.name = name;
    this.species = species;
    this.location = location;
    this.createdAt = createdAt
  }
}
```

**知识点：**
1. 数据模型设计规范
2. 构造函数参数传递
3. 响应式属性标记

---

## 📁 ViewModel 层（业务逻辑）

### 1. LightExposureViewModel.ets
**路径：** `viewmodel/LightExposureViewModel.ets`

**功能：** 光照记录的业务逻辑处理

**核心职责：**
- 管理光照会话（开始/结束）
- 计算光照量
- 统计每日/每周数据
- 数据库操作

**关键方法解析：**

```typescript
// 开始光照会话
startSession(level: LightLevel): void {
  const now: number = Date.now();
  this.activeSession = ExposureSession.createStarted(this.plantId, level, now);
  this.hasActive = true;
  // UI 会自动更新，因为使用了 @Trace 装饰器
}

// 结束光照会话
async finishSession(): Promise<void> {
  if (!this.activeSession) { return; }
  const now: number = Date.now();
  // 计算光照量 = 光照级别权重 × 时长（分钟）
  const lux: number = levelWeight(this.activeSession.level) * this.activeSession.durationMin;
  this.activeSession.finishWith(now, lux);
  // 保存到数据库
  await this.saveSession(this.activeSession);
  // 更新 UI
  this.hasActive = false;
  this.sessions.unshift(this.activeSession);
  this.activeSession = null;
}

// 获取今日达标率（0-100）
get todayRatePercent(): number {
  const key: string = ymd(new Date());
  // 查找今日的统计数据
  for (let i: number = 0; i < this.dailyStats.length; i++) {
    const s: DailyLightStat = this.dailyStats[i];
    if (s.date === key) {
      return Math.floor(s.rate * 100);
    }
  }
  return 0;
}
```

**知识点：**
1. ViewModel 模式
2. 异步操作（async/await）
3. 数据库 CRUD 操作
4. 响应式数据更新

---

### 2. RdbManager.ets
**路径：** `viewmodel/RdbManager.ets`

**功能：** 数据库管理器（单例模式）

**核心职责：**
- 数据库初始化
- 表结构创建
- 索引管理
- 默认数据种子

**关键代码解析：**

```typescript
export class RdbManager {
  static instance: RdbManager | null = null  // 单例实例
  public rdbStore: relationalStore.RdbStore | null = null;  // 数据库实例
  
  // 数据库表名常量
  static readonly T_PLANT: string = 'plant'
  static readonly T_LIGHT_PROFILE: string = 'light_profile'
  static readonly T_EXPOSURE_SESSION: string = 'exposure_session'
  
  // 获取单例实例
  static getInstance(): RdbManager {
    if (!RdbManager.instance) {
      RdbManager.instance = new RdbManager()
    }
    return RdbManager.instance
  }
  
  // 初始化数据库
  async initDb(context: common.Context) {
    // 创建数据库连接
    const config: relationalStore.StoreConfig = {
      name: 'plantdiary.db',
      securityLevel: relationalStore.SecurityLevel.S1,
    }
    this.rdbStore = await relationalStore.getRdbStore(context, config)
    
    // 创建数据表
    await this.rdbStore.executeSql(
      `CREATE TABLE IF NOT EXISTS plant(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        species TEXT,
        location TEXT,
        createdAt INTEGER
      )`
    )
    
    // 创建索引优化查询性能
    await this.rdbStore.executeSql(
      `CREATE INDEX IF NOT EXISTS idx_task_planDate ON task(planDate)`
    )
  }
}
```

**知识点：**
1. 单例模式实现
2. SQLite 数据库操作
3. SQL 建表语句
4. 索引优化

---

## 📁 Pages 层（页面）

### 1. LightExposurePage.ets
**路径：** `pages/LightExposurePage.ets`

**功能：** 光照记录页面

**核心功能：**
- 显示实时光照进度
- 开始/结束光照
- 手动补记
- 查看历史记录

**页面结构：**

```typescript
@ComponentV2
export struct LightExposurePage {
  @Param plant: Plant | undefined = undefined;  // 接收的植物参数
  @State vm: LightExposureViewModel = new LightExposureViewModel(0);  // ViewModel
  
  build() {
    NavDestination() {
      Column() {
        this.Header()           // 顶部标题栏
        Scroll() {
          this.TodayProgress()  // 今日进度圆环
          this.Controls()       // 控制按钮
          this.SevenDays()      // 7 天统计
          this.SessionList()    // 会话列表
        }
      }
    }
  }
  
  // 开始光照按钮
  @Builder Controls() {
    Button(this.vm.hasActive ? '结束光照' : '开始光照')
      .onClick(() => {
        if (this.vm.hasActive) {
          this.vm.finishSession();  // 结束
        } else {
          this.vm.startSession(LightLevel.MID);  // 开始
        }
      })
  }
}
```

**知识点：**
1. `@ComponentV2` 装饰器
2. `@Param` 接收页面参数
3. `@Builder` 构建 UI 组件
4. 条件渲染

---

## 🎯 学习路线建议

### 第一阶段：基础理解
1. 阅读 `LightTypes.ets` - 了解枚举和工具函数
2. 阅读 `ExposureSession.ets` - 理解数据模型
3. 阅读 `PlantModel.ets` - 理解基础数据结构

### 第二阶段：业务逻辑
1. 阅读 `LightExposureViewModel.ets` - 理解业务处理
2. 阅读 `RdbManager.ets` - 理解数据库操作
3. 结合代码运行调试

### 第三阶段：UI 开发
1. 阅读 `LightExposurePage.ets` - 理解页面结构
2. 学习 ArkUI 组件使用
3. 尝试修改样式和布局

### 第四阶段：实战练习
1. 添加新功能（如：添加植物备注）
2. 修改现有功能（如：调整光照计算公式）
3. 优化 UI 体验

---

## 💡 开发技巧

### 1. 调试技巧
```typescript
// 在关键位置添加日志
hilog.info(0x0000, 'MyTag', '当前光照量：%{public}s', `${this.vm.currentLux}`);

// 错误处理
try {
  await this.vm.saveSession(session);
} catch (e) {
  console.error(`保存失败：${(e as Error).message}`);
}
```

### 2. 状态管理技巧
```typescript
// 使用@Trace 追踪属性变化
@Trace count: number = 0;

// 修改后 UI 会自动更新
this.count++;
```

### 3. 数据库查询技巧
```typescript
// 参数化查询防止 SQL 注入
const rs = await this.store.querySql(
  `SELECT * FROM plant WHERE id = ?`, 
  [plantId]
);
```

---

**最后更新：** 2024-03-14
**适合人群：** 初学者、HarmonyOS 开发者
