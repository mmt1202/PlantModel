# PlantDiary (植物养护) Code Wiki

## 1. 项目概述

**PlantDiary** 是一款基于 **HarmonyOS / ArkTS** 开发的本地植物养护和记录应用。项目致力于帮助用户管理植物、规划养护任务（浇水、施肥、修剪等）、记录生长日志和环境指标，并提供丰富的可视化及日历视图。

- **应用包名**: `com.example.plantdiary`
- **目标平台**: HarmonyOS (API 12/13, SDK 版本 5.0.5)
- **开发语言**: ArkTS
- **UI 框架**: ArkUI (V2 状态管理机制)
- **数据持久化**: 关系型数据库 (SQLite / `@ohos.data.relationalStore`)

---

## 2. 项目整体架构

项目采用类似 **MVVM** (Model-View-ViewModel) 的分层架构设计，确保 UI 与数据逻辑分离：

- **Model层 (`entry/src/main/ets/model/`)**
  定义了所有的业务数据实体，利用 `@ObservedV2` 和 `@Trace` 实现细粒度的状态响应。包含了诸如 `Plant` (植物)、`PlantTask` (任务)、`Metric` (指标) 等核心实体。
- **ViewModel层 (`entry/src/main/ets/viewmodel/`)**
  负责具体业务逻辑的处理以及数据库的 CRUD 操作。其中 `RdbManager` 是管理整个应用 SQLite 数据库和初始化数据的核心单例。
- **View层 (`entry/src/main/ets/view/` & `component/`)**
  存放可复用的 UI 视图组件，如卡片 (`PlantCard`)、弹层 (`EditPlantSheet`, `MetricChartSheet`) 等。
- **Pages层 (`entry/src/main/ets/pages/`)**
  应用的页面级组件。其中 `Index.ets` 作为全局的导航中枢和状态管理中心，通过 `@Provider` 将全局状态（植物列表、任务列表等）提供给子页面和弹层。
- **App/Ability层 (`entry/src/main/ets/entryability/`)**
  `EntryAbility.ets` 管理应用生命周期和窗口配置（沉浸式全屏、状态栏/导航栏避让等）。

---

## 3. 主要模块职责

### 3.1 数据与存储模块
负责本地数据的存取和初始化，支持表结构升级和多表联查。
- **表结构**: 包含 `plant` (植物信息)、`task` (单次/周期养护任务)、`tpl` / `care_template` / `care_rule` (养护模板)、`log` / `log_photo` (带图日志)、`metric` (生长指标)、`light_profile` / `exposure_session` (光照与曝光记录) 等表。

### 3.2 导航与全局状态中心 (Index)
首页组件不只是一个 UI 页面，更是应用的数据中心。
- 负责初始化数据库，并在内存中缓存全局所需的数据列表（`plants`, `tasks`）。
- 控制 4 个主 Tab（植物、任务、日历、统计）的切换。
- 管理各类全局 Sheet（新建植物、模板应用、删除确认等）的挂载与显示。

### 3.3 植物与任务管理
- **植物 CRUD**: 添加、编辑和删除植物（级联删除任务、日志、照片等）。
- **任务管理**: 基于日历或列表的任务排期、批量生成周期任务（支持按固定天数生成未来范围的排期）、标记完成状态。
- **养护模板**: 提供诸如“多肉”、“龟背竹”、“月季”等预设的养护规则（包含浇水、施肥频率），一键应用到指定植物上。

### 3.4 扩展功能模块
- **生长指标与图表**: 记录身高、冠幅和健康分，通过 `@mcui/mccharts` 渲染趋势图 (`GrowthIndicatorPage`, `MetricChartSheet`)。
- **光照与配土计算**: 提供配土比例计算 (`MixPlannerPage`)、光照时长统计 (`LightExposurePage`) 以及水分预估 (`WaterEstimatorPage`) 等进阶园艺工具。

---

## 4. 关键类与函数说明

### 4.1 `RdbManager` (`viewmodel/RdbManager.ets`)
应用的数据库管家（单例模式）。
- **`initDb(context: common.Context)`**: 创建各张数据表并建立联合索引以优化查询。
- **`ensureCareTemplates()`**: 应用首次启动时，向数据库插入内置的默认养护模板及规则（如绿萝、常春藤等）。
- **`getActiveLightSessions()`**: 查询所有当前正在进行（未结束）的光照会话。

### 4.2 `Index` (`pages/Index.ets`)
应用的主入口组件。
- **`initDb() & reloadAll()`**: 组件挂载时调用，先完成数据库初始化，接着一次性加载 `plants`、`tasks` 并刷新光照状态。
- **`deletePlant(id: number)`**: 使用事务级联删除功能。先删除日志及照片表记录、删除任务表记录、删除植物记录，并在事务提交后统一清理本地磁盘上的照片文件，确保数据和文件不成为孤儿。
- **`cleanupOrphanPhotos()`**: 定期守护任务，清理因异常断电等原因导致的数据库孤儿照片记录或丢失了文件的照片记录。
- **`applyTemplateToPlant(templateId, startISO)`**: 将所选养护模板的规则实例化为具体日期的任务，插入任务表中（通过唯一索引拦截防止重复生成）。

### 4.3 `Plant` / `PlantTask` (`model/PlantModel.ets`)
使用 `@ObservedV2` 和 `@Trace` 装饰器修饰的数据模型。
- ArkUI V2 的深度响应式模型。实体字段被修改时，绑定的 UI 组件将自动触发重绘，降低了深层级组件状态同步的成本。

---

## 5. 依赖关系

本项目的依赖主要记录在根目录和 `entry` 目录下的 `oh-package.json5` 文件中。

### 5.1 核心三方依赖
- **`@mcui/mccharts`**: 版本 `2.8.8`。用于渲染应用中的各类生长趋势图表及统计图。

### 5.2 HarmonyOS 原生依赖
- **`@kit.ArkUI` / `@kit.AbilityKit` / `@kit.ArkData`**: 提供基础 UI 控件、生命周期管理和关系型数据库能力。
- **`@ohos.file.fs`**: 用于处理日志图片文件的保存、读取与删除操作。
- **DevDependencies**: 包含测试套件 `@ohos/hypium` (v1.0.23) 和 `@ohos/hamock` (v1.0.0)。

---

## 6. 项目运行方式

由于本项目基于 HarmonyOS ArkTS 开发，需要在支持鸿蒙生态的环境下运行：

1. **环境准备**:
   - 下载并安装最新版 **DevEco Studio** (需支持 SDK 版本 5.0.5 / API 12+)。
   - 确保 Node.js 和 Ohpm (OpenHarmony Package Manager) 环境配置正确。
2. **导入项目**:
   - 在 DevEco Studio 中选择 `Open Project`，选中本项目根目录。
3. **同步依赖**:
   - IDE 提示时点击 `Sync Now`，或者在终端运行 `ohpm install` 以下载 `@mcui/mccharts` 等依赖。
4. **编译与运行**:
   - 打开设备管理器 (`Device Manager`)，启动一个 HarmonyOS 模拟器，或者连接已开启开发者模式的真机设备。
   - 检查右上角运行配置（Target: `entry`），点击 **Run** 按钮（绿色三角形）即可编译并在设备上安装运行。
5. **签名配置**:
   - 根目录的 `build-profile.json5` 中配置了本地调试签名和 `pulisher` 生产签名。如果在本地真机运行提示签名错误，需前往 `File -> Project Structure -> Signing Configs` 勾选 `Automatically generate signature` 重新生成本地调试签名。
