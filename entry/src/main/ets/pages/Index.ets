import common from '@ohos.app.ability.common'
import relationalStore from '@ohos.data.relationalStore'
import {
  CareRule,
  CareTemplate,
  Metric,
  Plant,
  PlantDraft,
  PlanTpl,
  PlantTask,
  TaskDraft
} from '../model/PlantModel'
import { CareTemplateSheet } from '../view/CareTemplateSheet'
import { ConfirmDialogSheet } from '../view/ConfirmDialogSheet'
import { EditPlantSheet } from '../view/EditPlantSheet'
import { PlantListPage } from './PlantListPage'
import { StatsPage } from './StatsPage'
import { TaskListPage } from './TaskListPage'
import { TemplateManagerSheet } from '../view/TemplateManagerSheet'
import { MetricSheet } from '../view/MetricSheet'
import { CalendarSheet1 } from './CalendarSheet'
import { PlantTaskFilter } from '../view/PlantTaskFilterSheet'
import fs from '@ohos.file.fs'
import { MetricChartSheet } from '../view/MetricChartSheet'
import { runInTransaction } from '../model/DbUtils'
import { TemplateApplySheet } from '../view/TemplateApplySheet'
import { RdbManager } from '../viewmodel/RdbManager'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { PlantLogPage } from './PlantLogPage'

@Entry
@ComponentV2
struct Index {
  private ctx: common.UIAbilityContext = getContext(this) as common.UIAbilityContext
  // DB
  @Provider('RdbManager') RdbManager: RdbManager = RdbManager.getInstance()
  @Provider('store') store: relationalStore.RdbStore | null = this.RdbManager.rdbStore
  @Provider('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Local tabsController: TabsController = new TabsController()
  @Local isShow: boolean = false
  // 状态
  @Local initialized: boolean = false
  @Local plants: Array<Plant> = []
  @Local tasks: Array<PlantTask> = []
  @Local bannerMsg: string = ''
  @Local bannerType: 'ok' | 'warn' | 'info' = 'info'
  // Tab 与搜索
  @Local tabBarIndex: number = 0 // 0 植物 1 任务 2 统计
  @Local keyword: string = ''
  // —— 任务筛选 ——
  @Local taskFilterVisible: boolean = false
  @Local taskFilter: PlantTaskFilter = new PlantTaskFilter()
  // 新建/编辑面板
  @Local panelVisible: boolean = false
  @Local editingPlantId: number = 0
  @Local plantDraft: PlantDraft = new PlantDraft()
  @Local taskDraft: TaskDraft = new TaskDraft()
  // 删除确认
  @Local confirmVisible: boolean = false
  @Local confirmText: string = ''
  @Local pendingDeletePlantId: number = 0
  @Local pendingDeleteTaskId: number = 0
  // 下拉刷新头
  @Local pullOffset: number = 0
  @Local pulling: boolean = false
  @Local canRefresh: boolean = false
  @Local touchStartY: number = 0
  // FAB 动画
  @Local fabPressed: boolean = false
  // 模板管理
  @Local tplMgrVisible: boolean = false
  @Local templates: Array<PlanTpl> = []
  // —— 指标抽屉状态 —— //
  @Local metricVisible: boolean = false
  @Local metricPlantId: number = 0
  @Local metricPlantName: string = ''
  @Local metrics: Array<Metric> = []
  // 日历
  @Local calendarYear: number = new Date().getFullYear()
  @Local calendarMonth: number = new Date().getMonth() + 1
  // —— 养护模板入口 ——
  @Local careVisible: boolean = false
  @Local carePlantId: number = 0
  @Local carePlantName: string = ''
  // —— 任务筛选 / 排序状态 —— //
  @Local filterVisible: boolean = false
  @Local filterStatus: number = 0 // 0=全部 1=未完成 2=已完成
  @Local filterType: string = '' // '' | '浇水' | '施肥' | '修剪' ...
  @Local filterFrom: string = '' // 'YYYY-MM-DD' 或空
  @Local filterTo: string = '' // 同上
  @Local filterKeyword: string = ''
  @Local sortKey: string = 'date' // 'date' | 'type' | 'status' | 'plant'
  @Local sortAsc: boolean = false
  // —— 趋势图状态 —— //
  @Local metricChartVisible: boolean = false
  @Local metricChartPlantName: string = ''
  @Local metricChartData: Array<Metric> = []
  @Local taskStatsVisible: boolean = false
  @Local tplVisible: boolean = false
  @Local tplTargetPlantId: number = 0
  @Local tplTargetPlantName: string = ''
  @Local tplList: Array<CareTemplate> = []
  @Local ruleList: Array<CareRule> = []

  // @Local logPhotos: Array<LogPhoto> = []

  /** ---- 生命周期 ---- */
  aboutToAppear(): void {
    this.initDb().then(() => {
      this.initialized = true

      this.showBanner('已初始化本地数据库', 'ok')
    }).catch((e: Error) => {
      this.showBanner('数据库初始化失败', 'warn')
      hilog.info(0x0000, 'Web', '%{public}s', `liheng 数据库初始化失败  ${JSON.stringify(e)}`);
    })
  }

  /** ---- DB 初始化/加载 ---- */
  private async initDb(): Promise<void> {
    await this.RdbManager.initDb(this.ctx)
    this.store = this.RdbManager.rdbStore
    await this.RdbManager.ensureCareTemplates()
    await this.reloadAll()
    await this.loadTemplates()
  }

  private async reloadAll(): Promise<void> {
    await this.loadPlants();
    await this.loadTasks()
  }

  private async loadPlants(): Promise<void> {
    if (!this.store) {
      return
    }
    const rs =
      await this.store.querySql(`SELECT id,name,species,location,createdAt FROM ${RdbManager.T_PLANT} ORDER BY createdAt DESC`,
        [])
    const items: Array<Plant> = []
    while (rs.goToNextRow()) {
      items.push(new Plant(rs.getLong(0), rs.getString(1), rs.getString(2) ?? '', rs.getString(3) ?? '', rs.getLong(4)))
    }
    rs.close()
    this.plants = items
  }

  private async loadTasks(): Promise<void> {
    if (!this.store) {
      return
    }
    const rs =
      await this.store.querySql(`SELECT id,plantId,type,planDate,done,doneAt FROM ${RdbManager.T_TASK} ORDER BY planDate DESC,id DESC`,
        [])
    const items: Array<PlantTask> = []
    while (rs.goToNextRow()) {
      items.push(new PlantTask(rs.getLong(0), rs.getLong(1), rs.getString(2), rs.getString(3), rs.getLong(4),
        rs.getLong(5)))
    }
    rs.close()
    this.tasks = items
  }

  private plantNameById(id: number): string {
    let i: number = 0
    while (i < this.plants.length) {
      if (this.plants[i].id === id) {
        return this.plants[i].name
      }
      i = i + 1
    }
    return ''
  }

  // 打开趋势图（外部只需传 plantId）
  private async openMetricChart(plantId: number): Promise<void> {
    // 假设你已有 loadMetricsByPlant(plantId) 并把结果放到 this.metrics
    await this.loadMetricsByPlant(plantId)
    this.metricChartData = this.metrics // 若你的字段名不是 this.metrics，请替换为你的实际数组
    this.metricChartPlantName = this.plantNameById(plantId)
    this.metricChartVisible = true
  }

  // 模板
  private async loadTemplates(): Promise<void> {
    if (!this.store) {
      return
    }
    const rs =
      await this.store.querySql(`SELECT id,name,type,everyDays,times,createdAt FROM ${RdbManager.T_TPL} ORDER BY createdAt DESC,id DESC`,
        [])
    const items: Array<PlanTpl> = []
    while (rs.goToNextRow()) {
      items.push(new PlanTpl(rs.getLong(0), rs.getString(1), rs.getString(2), rs.getLong(3), rs.getLong(4),
        rs.getLong(5)))
    }
    rs.close()
    this.templates = items
  }

  /** ---- 指标 DB ---- */
  private async loadMetricsByPlant(plantId: number): Promise<void> {
    if (!this.store) {
      return
    }
    const rs = await this.store.querySql(
      `SELECT id, plantId, height, width, score, createdAt
     FROM ${RdbManager.T_METRIC}
     WHERE plantId = ?
     ORDER BY createdAt ASC`, [plantId]
    )
    const arr: Array<Metric> = []
    while (rs.goToNextRow()) {
      arr.push(new Metric(
        rs.getLong(0), rs.getLong(1),
        rs.getDouble(2), rs.getDouble(3), rs.getLong(4), rs.getLong(5)
      ))
    }
    rs.close()
    this.metrics = arr
  }

  private async createMetric(plantId: number, height: number, width: number, score: number,
    dateISO: string): Promise<void> {
    if (!this.store) {
      return
    }
    const ts: number = this.isoToTs(dateISO)
    const v: relationalStore.ValuesBucket = {
      plantId: plantId,
      height: height,
      width: width,
      score: score,
      createdAt: ts
    }
    await this.store.insert(RdbManager.T_METRIC, v)
    await this.loadMetricsByPlant(plantId)
  }

  private isoToTs(iso: string): number {
    // 简单解析 YYYY-MM-DD -> 本地 00:00:00
    if (iso.length !== 10) {
      return Date.now()
    }
    const y: number = Number(iso.substring(0, 4))
    const m: number = Number(iso.substring(5, 7)) - 1
    const d: number = Number(iso.substring(8, 10))
    const dt = new Date(y, m, d, 0, 0, 0, 0)
    return dt.getTime()
  }

  private async deleteMetric(id: number): Promise<void> {
    if (!this.store) {
      return
    }
    const p = new relationalStore.RdbPredicates(RdbManager.T_METRIC);
    p.equalTo('id', id)
    await this.store.delete(p)
    if (this.metricPlantId !== 0) {
      await this.loadMetricsByPlant(this.metricPlantId)
    }
  }

  /** ---- 植物 CRUD ---- */
  private async createPlant(draft: PlantDraft): Promise<void> {
    if (!this.store) {
      hilog.info(0x0000, 'web', '%{public}s', `liheng 没有this.store${JSON.stringify(this.store)}`);
      return
    }
    const values: relationalStore.ValuesBucket = {
      name: draft.name.trim(),
      species: draft.species.trim(),
      location: draft.location.trim(),
      createdAt: Date.now()
    }
    hilog.info(0x0000, 'web', '%{public}s', `liheng 2 item.id${JSON.stringify(values)}`);
    await this.store.insert(RdbManager.T_PLANT, values)
    await this.loadPlants()
    this.showBanner('已添加植物', 'ok')
  }

  private async updatePlant(id: number, draft: PlantDraft): Promise<void> {
    if (!this.store) {
      return
    }
    const values: relationalStore.ValuesBucket = {
      name: draft.name.trim(), species: draft.species.trim(), location: draft.location.trim()
    }
    const p = new relationalStore.RdbPredicates(RdbManager.T_PLANT);
    p.equalTo('id', id)
    await this.store.update(values, p)
    await this.loadPlants()
    this.showBanner('已更新植物信息', 'ok')
  }

  private async deletePlant(id: number): Promise<void> {
    if (!this.store) {
      return
    }

    // 1) 找出该植物的所有日志ID
    const logIds: Array<number> = []
    {
      const rs = await this.store.querySql(
        `SELECT id FROM ${RdbManager.T_LOG} WHERE plantId = ? ORDER BY id ASC`, [id]
      )
      while (rs.goToNextRow()) {
        logIds.push(rs.getLong(0))
      }
      rs.close()
    }

    // 2) 批量查出这些日志关联的所有图片路径（一次性）
    const allFiles: Array<string> = []
    if (logIds.length > 0) {
      const placeholders: string = Array(logIds.length).fill('?').join(',')
      const rs2 = await this.store.querySql(
        `SELECT filePath, thumbPath FROM ${RdbManager.T_LOG_PHOTO} WHERE logId IN (${placeholders}) ORDER BY id ASC`,
        logIds as Array<number>
      )
      while (rs2.goToNextRow()) {
        const p1: string = rs2.getString(0)
        const p2: string = rs2.getString(1)
        if (p1 && p1.length > 0) {
          allFiles.push(p1)
        }
        if (p2 && p2.length > 0) {
          allFiles.push(p2)
        }
      }
      rs2.close()
    }

    // 3) —— 单个事务内完成所有“表数据”删除 —— //
    await runInTransaction(this.store, async () => {
      // 3.1 删日志照片子表
      if (logIds.length > 0) {
        const placeholders: string = Array(logIds.length).fill('?').join(',')
        await this.store!.executeSql(
          `DELETE FROM ${RdbManager.T_LOG_PHOTO} WHERE logId IN (${placeholders})`,
          logIds as Array<number>
        )
      }

      // 3.2 删日志表
      const pLog = new relationalStore.RdbPredicates(RdbManager.T_LOG)
      pLog.equalTo('plantId', id)
      await this.store!.delete(pLog)

      // 3.3 删任务表
      const pTask = new relationalStore.RdbPredicates(RdbManager.T_TASK)
      pTask.equalTo('plantId', id)
      await this.store!.delete(pTask)

      // 3.4 删植物表
      const pPlant = new relationalStore.RdbPredicates(RdbManager.T_PLANT)
      pPlant.equalTo('id', id)
      await this.store!.delete(pPlant)
    })

    // 4) 事务提交成功后，统一删除所有本地图片文件
    let i: number = 0
    while (i < allFiles.length) {
      try {
        await fs.unlink(allFiles[i])
      } catch (_e) { /* 忽略单文件错误 */
      }
      i = i + 1
    }

    await this.reloadAll()
    this.showBanner('已删除植物及其任务、日志与照片', 'ok')
  }

  /** ---- 任务 CRUD ---- */
  private async createTask(draft: TaskDraft): Promise<void> {
    if (!this.store) {
      return
    }
    const values: relationalStore.ValuesBucket = {
      plantId: draft.plantId,
      type: draft.type.trim(),
      planDate: draft.planDate.trim(),
      done: 0,
      doneAt: 0
    }
    try {
      await this.store.insert(RdbManager.T_TASK, values)
      await this.reloadAll()
      this.showBanner('已添加养护任务', 'ok')

    } catch (e) {
      this.showBanner('同日同类型任务已存在', 'info')
    }

  }

  private async toggleTaskDone(task: PlantTask): Promise<void> {
    if (!this.store) {
      return
    }
    const nd = task.done === 1 ? 0 : 1
    const values: relationalStore.ValuesBucket = { done: nd, doneAt: nd === 1 ? Date.now() : 0 }
    const p = new relationalStore.RdbPredicates(RdbManager.T_TASK);
    p.equalTo('id', task.id)
    await this.store.update(values, p)
    await this.reloadAll()
  }

  // —— 守护：清理孤儿记录/文件 —— //
  private async cleanupOrphanPhotos(): Promise<void> {
    if (!this.store) {
      return
    }

    let delDbCount: number = 0
    let delFsCount: number = 0

    // 1) 照片记录的 logId 不存在 → 删记录 & 尝试删文件
    const rs1 = await this.store.querySql(
      `SELECT p.id, p.path, p.thumbPath
     FROM ${RdbManager.T_LOG_PHOTO} p
     LEFT JOIN ${RdbManager.T_LOG} l ON p.logId = l.id
     WHERE l.id IS NULL`, []
    )
    const orphanPhotoIds: Array<number> = []
    const orphanFiles: Array<string> = []
    while (rs1.goToNextRow()) {
      orphanPhotoIds.push(rs1.getLong(0))
      const p1: string = rs1.getString(1);
      const p2: string = rs1.getString(2)
      if (p1 && p1.length > 0) {
        orphanFiles.push(p1)
      }
      if (p2 && p2.length > 0) {
        orphanFiles.push(p2)
      }
    }
    rs1.close()

    if (orphanPhotoIds.length > 0) {
      await this.store.beginTransaction()
      try {
        let i: number = 0
        while (i < orphanPhotoIds.length) {
          const pp = new relationalStore.RdbPredicates(RdbManager.T_LOG_PHOTO)
          pp.equalTo('id', orphanPhotoIds[i])
          await this.store.delete(pp)
          delDbCount = delDbCount + 1
          i = i + 1
        }
        await this.store.commit()
      } catch (_e) {
        await this.store.rollBack()
        // 记录仍在，先不删文件
      }
    }

    // 尝试删除对应文件
    let f: number = 0
    while (f < orphanFiles.length) {
      try {
        await fs.unlink(orphanFiles[f]);
        delFsCount = delFsCount + 1
      } catch (_e) {
      }
      f = f + 1
    }

    // 2) 记录存在但文件已丢失 → 删记录
    const rs2 = await this.store.querySql(
      `SELECT id, path, thumbPath FROM ${RdbManager.T_LOG_PHOTO}`, []
    )
    const missIds: Array<number> = []
    while (rs2.goToNextRow()) {
      const pid: number = rs2.getLong(0)
      const p1: string = rs2.getString(1)
      const p2: string = rs2.getString(2)
      let missing: boolean = false
      try {
        fs.accessSync(p1)
      } catch (_e1) {
        missing = true
      }
      if (!missing) {
        try {
          fs.accessSync(p2)
        } catch (_e2) { /* thumb 丢失也视为缺失 */
          missing = true
        }
      }
      if (missing) {
        missIds.push(pid)
      }
    }
    rs2.close()

    if (missIds.length > 0) {
      await this.store.beginTransaction()
      try {
        let m: number = 0
        while (m < missIds.length) {
          const pp = new relationalStore.RdbPredicates(RdbManager.T_LOG_PHOTO);
          pp.equalTo('id', missIds[m])
          await this.store.delete(pp)
          delDbCount = delDbCount + 1
          m = m + 1
        }
        await this.store.commit()
      } catch (_e) {
        await this.store.rollBack()
      }
    }

    this.showBanner(`清理完成：删记录 ${delDbCount}，删文件 ${delFsCount}`, 'ok')
  }

  private async deleteTask(id: number): Promise<void> {
    if (!this.store) {
      return
    }
    const p = new relationalStore.RdbPredicates(RdbManager.T_TASK);
    p.equalTo('id', id)
    await this.store.delete(p)
    await this.reloadAll()
    this.showBanner('已删除任务', 'ok')
  }

  /** ---- 批量生成周期任务 ---- */
  private async bulkCreateRecurringTasks(plantId: number, type: string, everyDays: number,
    times: number): Promise<void> {
    if (!this.store) {
      return
    }
    let i: number = 0
    while (i < times) {
      const d: string = this.dateAfterDaysISO(this.todayISO(), everyDays * i)
      this.taskDraft = new TaskDraft()
      this.taskDraft.plantId = plantId
      this.taskDraft.type = type
      this.taskDraft.planDate = d
      await this.createTask(this.taskDraft)
      i = i + 1
    }
    this.showBanner('已生成周期任务', 'ok')
  }

  // 模板 CRUD & 应用
  private async createTpl(name: string, type: string, everyDays: number, times: number): Promise<void> {
    if (!this.store) {
      return
    }
    if (name.trim().length === 0 || everyDays <= 0 || times <= 0) {
      this.showBanner('模板参数不合法', 'warn');
      return
    }
    const values: relationalStore.ValuesBucket = {
      name: name.trim(),
      type: type.trim(),
      everyDays: everyDays,
      times: times,
      createdAt: Date.now()
    }
    await this.store.insert(RdbManager.T_TPL, values)
    await this.loadTemplates()
    this.showBanner('已创建模板', 'ok')
  }

  private async updateTpl(id: number, name: string, type: string, everyDays: number, times: number): Promise<void> {
    if (!this.store) {
      return
    }
    if (id === 0 || name.trim().length === 0 || everyDays <= 0 || times <= 0) {
      this.showBanner('模板参数不合法', 'warn');
      return
    }
    const values: relationalStore.ValuesBucket = {
      name: name.trim(),
      type: type.trim(),
      everyDays: everyDays,
      times: times
    }
    const p = new relationalStore.RdbPredicates(RdbManager.T_TPL);
    p.equalTo('id', id)
    await this.store.update(values, p)
    await this.loadTemplates()
    this.showBanner('已更新模板', 'ok')
  }

  private async deleteTpl(id: number): Promise<void> {
    if (!this.store) {
      return
    }
    const p = new relationalStore.RdbPredicates(RdbManager.T_TPL);
    p.equalTo('id', id)
    await this.store.delete(p)
    await this.loadTemplates()
    this.showBanner('已删除模板', 'ok')
  }

  private async applyTplToPlant(tplId: number): Promise<void> {
    if (this.editingPlantId === 0) {
      this.showBanner('请先选择/保存植物', 'info');
      return
    }
    let i: number = 0
    while (i < this.templates.length) {
      if (this.templates[i].id === tplId) {
        await this.bulkCreateRecurringTasks(this.editingPlantId, this.templates[i].type, this.templates[i].everyDays,
          this.templates[i].times)
        return
      }
      i = i + 1
    }
    this.showBanner('未找到模板', 'warn')
  }

  //
  private async createTaskDirect(plantId: number, type: string, dateISO: string): Promise<void> {
    if (!this.store) {
      return
    }
    const v: relationalStore.ValuesBucket = {
      plantId: plantId,
      type: type,
      planDate: dateISO.trim(),
      done: 0,
      doneAt: 0
    }
    await this.store.insert(RdbManager.T_TASK, v)
  }

  private async generateTemplateTasks(plantId: number, waterInt: number, fertInt: number, pruneInt: number,
    startISO: string, days: number): Promise<void> {
    if (plantId === 0) {
      return
    }
    // 逐日生成：对每个非 0 的间隔，在范围内按步长生成日期
    const base = this.isoToTs(startISO)
    if (days <= 0) {
      return
    }
    let offset: number = 0
    while (offset < days) {
      const d = new Date(base + offset * 24 * 3600 * 1000)
      const y = d.getFullYear()
      const m = (d.getMonth() + 1).toString().padStart(2, '0')
      const day = d.getDate().toString().padStart(2, '0')
      const iso = `${y}-${m}-${day}`
      if (waterInt > 0 && (offset % waterInt === 0)) {
        await this.createTaskDirect(plantId, '浇水', iso)
      }
      if (fertInt > 0 && (offset % fertInt === 0)) {
        await this.createTaskDirect(plantId, '施肥', iso)
      }
      if (pruneInt > 0 && (offset % pruneInt === 0)) {
        await this.createTaskDirect(plantId, '修剪', iso)
      }
      offset = offset + 1
    }
  }

  /** ---- 辅助 ---- */
  private todayISO(): string {
    const d = new Date();
    const y = d.getFullYear()
    const m = (d.getMonth() + 1).toString().padStart(2, '0');
    const day = d.getDate().toString().padStart(2, '0')
    return `${y}-${m}-${day}`
  }

  private dateAfterDaysISO(startISO: string, addDays: number): string {
    const parts: Array<string> = startISO.split('-')
    const y = Number.parseInt(parts[0]);
    const m = Number.parseInt(parts[1]);
    const d = Number.parseInt(parts[2])
    const base = new Date(y, m - 1, d);
    base.setDate(base.getDate() + addDays)
    const ny = base.getFullYear()
    const nm = (base.getMonth() + 1).toString().padStart(2, '0')
    const nd = base.getDate().toString().padStart(2, '0')
    return `${ny}-${nm}-${nd}`
  }

  private showBanner(text: string, type: 'ok' | 'warn' | 'info' = 'info'): void {
    this.bannerMsg = text;
    this.bannerType = type
    setTimeout(() => {
      animateTo({ duration: 180, curve: Curve.EaseInOut }, () => {
        this.bannerMsg = ''
      })
    }, 2800)
  }

  private openPanel(editId: number, preset?: Plant): void {
    this.editingPlantId = editId
    if (preset) {
      this.plantDraft = new PlantDraft()
      this.plantDraft.name = preset.name;
      this.plantDraft.species = preset.species;
      this.plantDraft.location = preset.location
    } else {
      this.plantDraft = new PlantDraft()
    }
    this.panelVisible = true
  }

  private closePanel(): void {
    this.panelVisible = false
  }

  private filteredPlants(): Array<Plant> {
    const kw = this.keyword.trim().toLowerCase()
    if (kw.length === 0) {
      return this.plants
    }
    const out: Array<Plant> = []
    let i: number = 0
    while (i < this.plants.length) {
      const p: Plant = this.plants[i]
      if (p.name.toLowerCase().includes(kw) || p.species.toLowerCase().includes(kw) ||
      p.location.toLowerCase().includes(kw)) {
        out.push(p)
      }
      i = i + 1
    }
    return out
  }

  private two(n: number): string {
    const s: string = n.toString();
    if (s.length === 1) {
      return '0' + s
    }
    ;
    return s
  }

  private addDays(iso: string, delta: number): string {
    const ps: Array<string> = iso.split('-')
    const d = new Date(parseInt(ps[0]), parseInt(ps[1]) - 1, parseInt(ps[2]));
    d.setDate(d.getDate() + delta)
    return `${d.getFullYear()}-${this.two(d.getMonth() + 1)}-${this.two(d.getDate())}`
  }

  private async loadCareTemplateData(): Promise<void> {
    if (!this.store) {
      return
    }
    // templates
    const r1 = await this.store.querySql(`SELECT id,name,desc FROM ${RdbManager.T_TEMPLATE} ORDER BY id ASC`, [])
    const ts: Array<CareTemplate> = []
    while (r1.goToNextRow()) {
      ts.push({ id: r1.getLong(0), name: r1.getString(1), desc: r1.getString(2) ?? '' })
    }
    r1.close()
    this.tplList = ts
    // rules
    const r2 =
      await this.store.querySql(`SELECT id,templateId,type,intervalDays,horizonDays FROM ${RdbManager.T_RULE} ORDER BY templateId ASC,id ASC`,
        [])
    const rs: Array<CareRule> = []
    while (r2.goToNextRow()) {
      rs.push({
        id: r2.getLong(0),
        templateId: r2.getLong(1),
        type: r2.getString(2),
        intervalDays: r2.getLong(3),
        horizonDays: r2.getLong(4)
      })
    }
    r2.close()
    this.ruleList = rs
  }

  private openTemplateSheet(plantId: number): void {
    this.tplTargetPlantId = plantId
    this.tplTargetPlantName = this.plants.find(p => p.id === plantId)?.name ?? ''
    this.tplVisible = true
  }

  // 事务落库：根据 templateId + startISO 生成任务，命中唯一索引自动跳过
  private async applyTemplateToPlant(templateId: number, startISO: string): Promise<void> {
    if (!this.store) {
      return
    }
    await this.store.beginTransaction()
    let inserted: number = 0
    let skipped: number = 0

    // 拿该模板的规则
    let i: number = 0
    while (i < this.ruleList.length) {
      const r: CareRule = this.ruleList[i]
      if (r.templateId === templateId) {
        let day: number = 0
        while (day <= r.horizonDays) {
          const plan: string = this.addDays(startISO, day)
          try {
            await this.store.insert(RdbManager.T_TASK, {
              plantId: this.tplTargetPlantId,
              type: r.type,
              planDate: plan,
              done: 0,
              doneAt: 0
            })
            inserted = inserted + 1
          } catch (_e) {
            // 命中唯一索引（plantId+type+planDate）→ 跳过
            skipped = skipped + 1
          }
          day = day + r.intervalDays
        }
      }
      i = i + 1
    }

    await this.store.commit()
    await this.loadTasks()
    this.showBanner(`模板复制完成：新增 ${inserted} 条，跳过 ${skipped} 条`, 'ok')
  }

  /** ---- 视图 ---- */
  build() {
    Navigation(this.pageStack) {
      Stack({ alignContent: Alignment.Center }) {
        Tabs({
          barPosition: BarPosition.End,
          index: this.tabBarIndex,
          controller: this.tabsController
        }) {
          TabContent() {
            PlantListPage({
              plants: this.filteredPlants(),
              allTasks: this.tasks,
              onQuickAdd: (pid: number, type: string) => {
                this.taskDraft = new TaskDraft();
                this.taskDraft.plantId = pid;
                this.taskDraft.type = type;
                this.taskDraft.planDate = this.todayISO()
                this.createTask(this.taskDraft)
              },
              onEdit: (p: Plant) => {
                this.openPanel(p.id, p)
              },
              onOpenLogs: async (p: Plant) => {
                this.pageStack.pushPathByName('PlantLogPage', p.id,(PopInfo)=>{
                  this.reloadAll()
                })
              },
              onDeleteAsk: (pid: number) => {
                this.pendingDeletePlantId = pid;
                this.pendingDeleteTaskId = 0
                this.confirmText = '删除该植物及其任务？'
                this.confirmVisible = true
              },
              onOpenMetrics: async (p: Plant) => {
                this.metricPlantId = p.id;
                this.metricPlantName = p.name
                await this.loadMetricsByPlant(p.id)
                this.isShow = true
                this.metricVisible = true
              },
              onOpenTemplate: (p: Plant) => {
                this.carePlantId = p.id
                this.carePlantName = p.name
                this.careVisible = true

              },
              onOpenTemplatenew: async (pid: number) => {
                await this.loadCareTemplateData()
                this.openTemplateSheet(pid)
              },
              onOpenMetric: async (pid: number) => {
                await this.openMetricChart(pid)
              },
              Header: () => {
                this.Header()
              },
            })
          }.tabBar(this.TabChip('植物', 0))

          TabContent() {
            TaskListPage({
              tasks: this.tasks,
              plants: this.plants,
              onToggle: (pt: PlantTask) => {
                this.toggleTaskDone(pt)
              },
              onDeleteAsk: (tid: number) => {
                this.pendingDeleteTaskId = tid;
                this.pendingDeletePlantId = 0;
                this.confirmText = '删除这个任务？';
                this.confirmVisible = true
              }
            })
          }.tabBar(this.TabChip('任务', 1))

          TabContent() {
          }.tabBar(this.Fab(() => {
            this.openPanel(0)
          }))

          TabContent() {
            CalendarSheet1({
              year: this.calendarYear,
              month: this.calendarMonth,
              tasks: this.tasks, // 这里的 tasks 请确保是 PlantTask[]
              plants: this.plants,
              onChangeMonth: (y: number, m: number) => {
                this.calendarYear = y;
                this.calendarMonth = m
              },
              onQuickAdd: async (pid: number, type: string, iso: string) => {
                this.taskDraft = new TaskDraft();
                this.taskDraft.plantId = pid;
                this.taskDraft.type = type;
                this.taskDraft.planDate = iso
                await this.createTask(this.taskDraft); // 你现有的方法
              },
              onToggle: async (t: PlantTask) => {
                await this.toggleTaskDone(t)
              },
              onDeleteAsk: (tid: number) => {
                this.pendingDeleteTaskId = tid;
                this.pendingDeletePlantId = 0;
                this.confirmText = '删除这个任务？';
                this.confirmVisible = true
              }
            })
          }.tabBar(this.TabChip('日历', 3))

          TabContent() {
            StatsPage({
              plants: this.plants,
              tasks: this.tasks,
              onReloadAll: async () => {
                try {
                  await this.reloadAll()
                  await this.loadTemplates()
                  this.showBanner('刷新数据成功', 'ok')
                } catch (e) {
                }

              }
            })
          }.tabBar(this.TabChip('统计', 4))

        }
        .barWidth('100%')
        .barHeight(54)
        .height('100%')
        .scrollable(false)
        .onChange((index: number) => {
          if (index === 2) {
            this.tabsController.changeIndex(this.tabBarIndex)
          } else {
            this.tabBarIndex = index;
            this.tabsController.changeIndex(this.tabBarIndex)
          }
        })
        .onContentWillChange((currentIndex: number, comingIndex: number) => {
          if (comingIndex === 2) {
            return false;
          }
          return true;
        })


        // Banner
        if (this.bannerMsg.length > 0) {
          this.Banner(this.bannerMsg, this.bannerType)
        }

        if (this.careVisible) {
          CareTemplateSheet({
            plantName: this.carePlantName,
            onClose: () => {
              this.careVisible = false
            },
            onApply: async (waterInt: number, fertInt: number, pruneInt: number, startISO: string, days: number) => {
              await this.generateTemplateTasks(this.carePlantId, waterInt, fertInt, pruneInt, startISO, days)
              this.careVisible = false
              this.showBanner('已按模板生成任务', 'ok')
              await this.loadTasks()
            }
          })
        }

        if (this.metricVisible) {
          MetricSheet({
            plantName: this.metricPlantName,
            metrics: this.metrics,
            onClose: () => {
              this.metricVisible = false
            },
            onAdd: async (h: number, w: number, s: number, iso: string) => {
              await this.createMetric(this.metricPlantId, h, w, s, iso)
            },
            onDelete: async (id: number) => {
              await this.deleteMetric(id)
            }
          })
        }

        // 表的抽屉
        if (this.metricChartVisible) {
          MetricChartSheet({
            plantName: this.metricChartPlantName,
            metrics: this.metricChartData,
            onClose: () => {
              this.metricChartVisible = false
            }
          })
        }

        // 删除确认
        if (this.confirmVisible) {
          ConfirmDialogSheet({
            text: this.confirmText,
            onCancel: () => {
              this.confirmVisible = false
            },
            onConfirm: async () => {
              if (this.pendingDeletePlantId !== 0) {
                await this.deletePlant(this.pendingDeletePlantId)
              }
              if (this.pendingDeleteTaskId !== 0) {
                await this.deleteTask(this.pendingDeleteTaskId)
              }
              this.confirmVisible = false
            }
          })
        }

        // 编辑抽屉
        if (this.panelVisible) {
          EditPlantSheet({
            title: this.editingPlantId === 0 ? '添加植物' : '编辑植物',
            draft: this.plantDraft,
            editingId: this.editingPlantId,
            onSave: async () => {
              if (this.plantDraft.name.trim().length === 0) {
                this.showBanner('名称不能为空', 'warn');
                return
              }
              hilog.info(0x0000, 'web', '%{public}s',
                `liheng 2 EditPlantSheet${this.editingPlantId} ${JSON.stringify(this.plantDraft)}`);

              if (this.editingPlantId === 0) {
                await this.createPlant(this.plantDraft)
              } else {
                await this.updatePlant(this.editingPlantId, this.plantDraft)
              }
              this.closePanel()
            },
            onDelete: async () => {
              if (this.editingPlantId !== 0) {
                await this.deletePlant(this.editingPlantId)
              }
              this.closePanel()
            },
            onClose: () => {
              this.closePanel()
            },
            onQuickWater: async () => {
              if (this.editingPlantId === 0) {
                this.showBanner('请先保存植物再添加任务', 'info');
                return
              }
              this.taskDraft = new TaskDraft();
              this.taskDraft.plantId = this.editingPlantId;
              this.taskDraft.type = '浇水';
              this.taskDraft.planDate = this.todayISO()
              await this.createTask(this.taskDraft)
            },
            onBulkSchedule: async (type: string, everyDays: number, times: number) => {
              if (this.editingPlantId === 0) {
                this.showBanner('请先保存植物再批量生成', 'info');
                return
              }
              await this.bulkCreateRecurringTasks(this.editingPlantId, type, everyDays, times)
            },
            onOpenTpl: async () => {
              await this.loadTemplates()
              this.tplMgrVisible = true
            },
            // ← 新增：打开日志
            onOpenLogs: async () => {
              // if (this.editingPlantId === 0) {
              //   this.showBanner('请先保存植物再写日志', 'info');
              //   return
              // }
              // await this.openLogSheetFor(this.editingPlantId)
            }
          })
        }

        // 模板管理
        if (this.tplMgrVisible) {
          TemplateManagerSheet({
            templates: this.templates,
            editingPlantId: this.editingPlantId,
            onClose: () => {
              this.tplMgrVisible = false
            },
            onCreate: async (n: string, t: string, d: number, times: number) => {
              await this.createTpl(n, t, d, times)
            },
            onUpdate: async (id: number, n: string, t: string, d: number, times: number) => {
              await this.updateTpl(id, n, t, d, times)
            },
            onDelete: async (id: number) => {
              await this.deleteTpl(id)
            },
            onApply: async (id: number) => {
              await this.applyTplToPlant(id)
            }
          })
        }
        if (this.tplVisible) {
          TemplateApplySheet({
            plantId: this.tplTargetPlantId,
            plantName: this.tplTargetPlantName,
            templates: this.tplList,
            rules: this.ruleList,
            onApply: async (tid: number, startISO: string) => {
              await this.applyTemplateToPlant(tid, startISO)
              this.tplVisible = false
            },
            onClose: () => {
              this.tplVisible = false
            }
          })
        }
      }
      .width('100%').height('100%')
      .linearGradient({
        direction: GradientDirection.Top,
        colors: [[0xFFF1F8E9, 0], [0xFFE8F5E9, 0.5], [0xFFE3F2FD, 1.0]]
      }).padding({
        top: AppStorage.get<number>('topRectHeight'),
        bottom: AppStorage.get<number>('bottomRectHeight')
      })
    }.hideTitleBar(true)
    .navDestination(this.pageMap)
    .mode(NavigationMode.Stack)
  }

  @Builder
  pageMap(name: string) {
    if (name === "PlantLogPage") {
      PlantLogPage()
    }
  }

  // 字符串比较（避免 locale 差异）
  cmpStr(x: string, y: string): number {
    if (x < y) {
      return -1
    }
    if (x > y) {
      return 1
    }
    return 0
  }

  @Builder
  Header() {
    Column() {
      Column() {
        Row() {
          Text('PlantDiary 植物养护').fontSize(22).fontWeight(FontWeight.Medium).fontColor(0xFF263238)
          Blank()
          Text('清理日志/照片孤儿')
            .fontSize(12)
            .fontColor(0xFF1565C0)
            .padding({
              left: 10,
              right: 10,
              top: 6,
              bottom: 6
            })
            .borderRadius(12)
            .backgroundColor(0x102196F3)
            .onClick(async () => {
              await this.cleanupOrphanPhotos()
            })
          // Text(this.initialized ? '离线 · 本地数据库' : '初始化中…').fontSize(12).fontColor(0x80263238)
        }.width('100%')
        .justifyContent(FlexAlign.Start)
        .padding({
          left: 20,
          right: 20,
          top: 16,
          bottom: 8
        })

        Row() {
          Text('🔎').fontSize(18).margin({ right: 8 })
          TextInput({ placeholder: '搜索植物/品种/位置', text: this.keyword })
            .onChange((v: string) => {
              this.keyword = v
            })
            .width('calc(100% - 24vp)')
            .height(36)
            .fontSize(14)
            .borderRadius(12)
            .backgroundColor(0xFFFFFFFF)
            .padding({ left: 12, right: 12 })
        }
        .height(44).width('100%').padding({ left: 20, right: 20, bottom: 2 })
      }
      .padding({ bottom: 4 })
    }.width('100%')
  }

  @Builder
  TabChip(text: string, idx: number) {
    Text(text)
      .fontSize(14)
      .fontWeight(this.tabBarIndex === idx ? FontWeight.Medium : FontWeight.Regular)
      .fontColor(this.tabBarIndex === idx ? 0xFF1B5E20 : 0xFF607D8B)
      .padding({
        left: 14,
        right: 14,
        top: 8,
        bottom: 8
      })
      .borderRadius(16)
      .backgroundColor(this.tabBarIndex === idx ? 0xFFE8F5E9 : 0xFFFFFFFF)
      .onClick(() => {
        animateTo({ duration: 160, curve: Curve.EaseInOut }, () => {
          if (idx !== 2) {
            this.tabBarIndex = idx
            this.tabsController.changeIndex(this.tabBarIndex)
          }
        })
      })
  }

  @Builder
  Fab(onTap: () => void) {
    Row() {
      Text('＋')
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .fontColor(0xFFFFFFFF)
        .onClick(() => {
          onTap()
        })
        .onTouch((e: TouchEvent) => {
          if (e.type === TouchType.Down) {
            this.fabPressed = true;
            animateTo({ duration: 90, curve: Curve.EaseOut }, () => {
            })
          } else if (e.type === TouchType.Up || e.type === TouchType.Cancel) {
            this.fabPressed = false;
            animateTo({ duration: 120, curve: Curve.EaseInOut }, () => {
            })
          }
        })
    }
    .width(56)
    .height(56)
    .borderRadius(28)
    .backgroundColor(0xFF2E7D32)
    .shadow({
      radius: 18,
      color: 0x33000000,
      offsetX: 0,
      offsetY: 6
    })
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .scale(this.fabPressed ? { x: 0.94, y: 0.94 } : { x: 1, y: 1 })
    .animation({ duration: 120, curve: Curve.EaseInOut })
  }

  @Builder
  Banner(text: string, type: 'ok' | 'warn' | 'info') {
    Row() {
      if (type === 'ok') {
        Text('✓').fontSize(14).fontWeight(FontWeight.Medium).fontColor(0xFF2E7D32).margin({ right: 8 })
      }
      if (type === 'warn') {
        Text('!').fontSize(14).fontWeight(FontWeight.Medium).fontColor(0xFFEF6C00).margin({ right: 8 })
      }
      if (type === 'info') {
        Text('i').fontSize(14).fontWeight(FontWeight.Medium).fontColor(0xFF1565C0).margin({ right: 8 })
      }
      Text(text).fontSize(13).fontColor(type === 'ok' ? 0xFF2E7D32 : (type === 'warn' ? 0xFFEF6C00 : 0xFF1565C0))
    }
    .padding({
      left: 14,
      right: 14,
      top: 10,
      bottom: 10
    })
    .layoutWeight(100)
    .zIndex(1000)
    .borderRadius(16)
    .backgroundColor(type === 'ok' ? 0xFFE8F5E9 : (type === 'warn' ? 0xFFFFF3E0 : 0xFFE3F2FD))
    .position({ x: 12, y: 70 })
    .shadow({
      radius: 12,
      color: 0x18000000,
      offsetX: 0,
      offsetY: 4
    })
    .animation({ duration: 220, curve: Curve.EaseInOut })
  }
}
