// entry/src/main/ets/pages/Index.ets
import common from '@ohos.app.ability.common'
import relationalStore from '@ohos.data.relationalStore'
import { LogEntry, Metric, Plant, PlantDraft, PlanTpl, PlantTask, TaskDraft } from '../model/PlantModel'
import { CalendarSheet } from '../view/CalendarView'
import { CareTemplateSheet } from '../view/CareTemplateSheet'
import { ConfirmDialogSheet } from '../view/ConfirmDialogSheet'
import { EditPlantSheet } from '../view/EditPlantSheet'
import { PlantListPage } from '../view/PlantListPage'
import { LogPhoto, PlantLogSheet } from '../view/PlantLogSheet'
import { StatsPage } from '../view/StatsPage'
import { TaskCalendarGate } from '../view/TaskCalendarGate'
import { TaskListPage } from '../view/TaskListPage'
import { TemplateManagerSheet } from '../view/TemplateManagerSheet'
import { MetricSheet } from '../view/MetricSheet'
import { CalendarSheet1 } from '../view/CalendarSheet'
import { PlantTaskFilter, PlantTaskFilterSheet } from '../view/PlantTaskFilterSheet'
import picker from '@ohos.file.picker'
import fs from '@ohos.file.fs'
import fileAccess from '@ohos.file.fileAccess'

/** -------- 入口页面（V2） -------- */
@Entry
@ComponentV2
struct Index {
  // @StorageProp('topRectHeight')topRectHeight:number=0
  // @StorageProp('bottomRectHeight') bottomRectHeight: number = 0
  private ctx: common.UIAbilityContext = getContext(this) as common.UIAbilityContext
  // DB
  private store?: relationalStore.RdbStore
  private static readonly DB_NAME: string = 'plantdiary.db'
  private static readonly T_PLANT: string = 'plant'
  private static readonly T_TASK: string = 'task'
  private static readonly T_TPL: string = 'tpl' // 周期模板
  private static readonly T_LOG: string = 'log' // ← 新增：日志表
  private static readonly T_METRIC: string = 'metric'
  private static readonly T_LOG_PHOTO: string = 'log_photo'
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
  // ← 新增：日志抽屉
  @Local logSheetVisible: boolean = false
  @Local logPlantId: number = 0
  @Local logList: Array<LogEntry> = []
  @Local logInput: string = ''

  // —— 日志抽屉状态 —— //
  @Local logVisible: boolean = false
  // @Local logPlantId: number = 0
  @Local logPlantName: string = ''
  @Local currentPlantName: string = ''
  @Local currentPlantId: string = ''
  @Local logs: Array<LogEntry> = []
  @Local logPhotos:Array<LogPhoto> =[]
  @Local logInputText: string = ''
  @Local picking: boolean = false   // 防连点


  // —— 指标抽屉状态 —— //
  @Local metricVisible: boolean = false
  @Local metricPlantId: number = 0
  @Local metricPlantName: string = ''
  @Local metrics: Array<Metric> = []
  // —— 日历入口状态 ——
  @Local calendarVisible: boolean = false
  @Local calYear: number = 1970
  @Local calMonth: number = 1
  @Local calendarYear: number = new Date().getFullYear()
  @Local calendarMonth: number = new Date().getMonth() + 1

  // —— 养护模板入口 ——
  @Local careVisible: boolean = false
  @Local carePlantId: number = 0
  @Local carePlantName: string = ''

  // @Local logPhotos: Array<LogPhoto> = []

  /** ---- 生命周期 ---- */
  aboutToAppear(): void {
    this.initDb().then(() => {
      this.initialized = true
      this.showBanner('已初始化本地数据库', 'ok')
    }).catch((e: Error) => {
      this.showBanner('数据库初始化失败', 'warn')
      console.error(e.message)
    })
    const __now = new Date()
    this.calYear = __now.getFullYear()
    this.calMonth = __now.getMonth() + 1
  }

  /** ---- DB 初始化/加载 ---- */
  private async initDb(): Promise<void> {
    const config: relationalStore.StoreConfig = { name: Index.DB_NAME, securityLevel: relationalStore.SecurityLevel.S1 }
    this.store = await relationalStore.getRdbStore(this.ctx, config)
    await this.store.executeSql(
      `CREATE TABLE IF NOT EXISTS ${Index.T_PLANT}(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        species TEXT,
        location TEXT,
        createdAt INTEGER
      )`)
    await this.store.executeSql(
      `CREATE TABLE IF NOT EXISTS ${Index.T_TASK}(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plantId INTEGER NOT NULL,
        type TEXT NOT NULL,
        planDate TEXT NOT NULL,
        done INTEGER DEFAULT 0,
        doneAt INTEGER DEFAULT 0
      )`)
    await this.store.executeSql(
      `CREATE TABLE IF NOT EXISTS ${Index.T_TPL}(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        everyDays INTEGER NOT NULL,
        times INTEGER NOT NULL,
        createdAt INTEGER
      )`)
    // ← 新增日志表
    await this.store.executeSql(
      `CREATE TABLE IF NOT EXISTS ${Index.T_LOG}(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plantId INTEGER NOT NULL,
        note TEXT NOT NULL,
        createdAt INTEGER
      )`)
    await this.store.executeSql(
      `CREATE TABLE IF NOT EXISTS ${Index.T_METRIC}(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plantId INTEGER NOT NULL,
        height REAL DEFAULT 0,
        width REAL DEFAULT 0,
        score INTEGER DEFAULT 0,
        createdAt INTEGER NOT NULL
      )`)
    // —— 日志图片表 ——
    await this.store.executeSql(
      `CREATE TABLE IF NOT EXISTS ${Index.T_LOG_PHOTO}(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        logId INTEGER NOT NULL,
        path TEXT NOT NULL,
        thumbPath TEXT NOT NULL,
        createdAt INTEGER NOT NULL
      )`)
    // // 任务唯一：同一植物 + 类型 + 计划日 不重复
    // await this.store.executeSql(`CREATE UNIQUE INDEX IF NOT EXISTS idx_task_unique ON ${Index.T_TASK}(plantId, type, planDate)`)
    // // 任务查询索引
    // await this.store.executeSql(`CREATE INDEX IF NOT EXISTS idx_task_planDate ON ${Index.T_TASK}(planDate)`)
    // await this.store.executeSql(`CREATE INDEX IF NOT EXISTS idx_task_plantId  ON ${Index.T_TASK}(plantId)`)
    // // 日志/指标查询索引
    // await this.store.executeSql(`CREATE INDEX IF NOT EXISTS idx_log_plantId   ON ${Index.T_LOG}(plantId)`)
    // await this.store.executeSql(`CREATE INDEX IF NOT EXISTS idx_metric_plantId ON ${Index.T_METRIC}(plantId)`)
    // await this.store.executeSql(`CREATE INDEX IF NOT EXISTS idx_logphoto_logId ON ${Index.T_LOG_PHOTO}(logId)`)

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
      await this.store.querySql(`SELECT id,name,species,location,createdAt FROM ${Index.T_PLANT} ORDER BY createdAt DESC`,
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
      await this.store.querySql(`SELECT id,plantId,type,planDate,done,doneAt FROM ${Index.T_TASK} ORDER BY planDate DESC,id DESC`,
        [])
    const items: Array<PlantTask> = []
    while (rs.goToNextRow()) {
      items.push(new PlantTask(rs.getLong(0), rs.getLong(1), rs.getString(2), rs.getString(3), rs.getLong(4), rs.getLong(5)))
    }
    rs.close()
    this.tasks = items
  }

  private async loadLogPhotos(logId: number): Promise<void> {
    if (!this.store) { return }
    // const predicates1 = new relationalStore.RdbPredicates(tableName);
    const rs = await this.store.querySql(
      `SELECT id, logId, filePath, createdAt FROM log_photo WHERE logId = ? ORDER BY id DESC`, [logId]
    )
    const items: Array<LogPhoto> = []
    while (rs.goToNextRow()) {
      items.push(new LogPhoto(rs.getLong(0), rs.getLong(1), rs.getString(2), rs.getString(3),rs.getLong(4)))
    }
    rs.close()
    this.logPhotos = items
  }

  private async pickPhotosForLog(logId: number): Promise<void> {
    if (this.picking) { return }
    this.picking = true
    try {
      const selected = await this.selectImagesFromAlbum(12) // 最多 12 张，可改
      if (selected.length === 0) { return }

      // 确保目录存在
      const dir = await this.ensurePhotosDir()

      let i: number = 0
      while (i < selected.length) {
        const srcUri: string = selected[i]
        const dstPath: string = await this.copyImageToAppFiles(srcUri, dir)
        // await this.insertLogPhoto(logId, this.ensureFileUri(dstPath))
        i = i + 1
      }
      await this.loadLogPhotos(logId)
      this.showBanner('已添加照片', 'ok')
    } catch (e) {
      console.error(`pickPhotosForLog error: ${(e as Error).message}`)
      this.showBanner('添加照片失败', 'warn')
    } finally {
      this.picking = false
    }
  }

  // —— 打开相册多选 —— //
  private async selectImagesFromAlbum(maxCount: number): Promise<Array<string>> {
    const photoPicker = new picker.PhotoViewPicker()
    const opt = new picker.PhotoSelectOptions()
    opt.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE
    opt.maxSelectNumber = maxCount

    // 兼容不同版本的返回结构（有的叫 photoUris，有的叫 uris）
    const res = await photoPicker.select(opt)
    const out: Array<string> = []
    // const urisA: Array<string> = (res && (res.photoUris as Array<string>)) ? (res.photoUris as Array<string>) : []
    // const urisB: Array<string> = (res && (res.uris as Array<string>)) ? (res.uris as Array<string>) : []
    // if (urisA.length > 0) { return urisA }
    // if (urisB.length > 0) { return urisB }
    return out
  }
  private async ensurePhotosDir(): Promise<string> {
    const base: string = (this.ctx as common.UIAbilityContext).filesDir
    const dir: string = `${base}/photos`
    try {
      await fs.mkdir(dir)   // 若存在会抛错，交由 catch 吞掉
    } catch (e) {
      // ignore if exists
    }
    return dir
  }

  // 确保以 file:// 前缀返回，便于 Image 显示
  private ensureFileUri(path: string): string {
    if (path.startsWith('file://')) { return path }
    return `file://${path}`
  }

  // 生成文件名：时间戳_随机数.jpg
  private genPhotoName(): string {
    const now: number = Date.now()
    const rnd: number = Math.floor(Math.random() * 100000)
    return `p_${now}_${rnd}.jpg`
  }

  // 从 URI 复制到 app filesDir/photos/xxx.jpg
  private async copyImageToAppFiles(srcUri: string, dstDir: string): Promise<string> {
    const name: string = this.genPhotoName()
    const dstPath: string = `${dstDir}/${name}`
    //
    // // 1) file:// 直拷
    // if (srcUri.startsWith('file://')) {
    //   const srcPath: string = srcUri.substring(7)
    //   await fs.copyFile(srcPath, dstPath)
    //   return dstPath
    // }
    //
    // // 2) 走文件访问助手拷贝 datashare:// 等 URI
    // const helper = fileAccess.createFileAccessHelper(this.ctx)
    // const rdFd: number = await helper.openFile(srcUri, fileAccess.OpenMode.READ)
    // const wrFd: number = fs.openSync(dstPath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY)
    //
    // try {
    //   // 小块读写，避免大图 OOM（64KB 缓冲）
    //   const buf = new ArrayBuffer(64 * 1024)
    //   let n: number = 0
    //   // 注意：readSync 返回读入的字节数
    //   n = fs.readSync(rdFd, buf)
    //   while (n > 0) {
    //     fs.writeSync(wrFd, buf, { length: n })
    //     n = fs.readSync(rdFd, buf)
    //   }
    // } finally {
    //   try { fs.closeSync(wrFd) } catch (_) {}
    //   try { await helper.closeFile(rdFd) } catch (_) {}
    // }
    return dstPath
  }

  // 批量为某植物在一组日期创建若干类型的 PlantTask（幂等，受唯一索引保护）
  private async createTemplateTasksWithTx(plantId: number, datesISO: Array<string>, types: Array<string>): Promise<boolean> {
    if (!this.store) { return false }
    try {
      const tx = await this.store.createTransaction()
      // 循环插入；违反唯一索引时忽略错误继续（你也可以先 SELECT 再 INSERT）
      let di: number = 0
      while (di < datesISO.length) {
        let ti: number = 0
        while (ti < types.length) {
          try {
            await tx.insert(Index.T_TASK, {
              plantId: plantId, type: types[ti], planDate: datesISO[di], done: 0, doneAt: 0
            })
          } catch (_) { /* ignore duplicate */ }
          ti = ti + 1
        }
        di = di + 1
      }
      await tx.commit()
      return true
    } catch (e) {
      console.error('createTemplateTasksWithTx error: ' + (e as Error).message)
      return false
    }
  }


  // 模板
  private async loadTemplates(): Promise<void> {
    if (!this.store) {
      return
    }
    const rs =
      await this.store.querySql(`SELECT id,name,type,everyDays,times,createdAt FROM ${Index.T_TPL} ORDER BY createdAt DESC,id DESC`,
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
    if (!this.store) { return }
    const rs = await this.store.querySql(
      `SELECT id,plantId,height,width,score,createdAt FROM ${Index.T_METRIC} WHERE plantId=? ORDER BY createdAt DESC`, [plantId])
    const arr: Array<Metric> = []
    while (rs.goToNextRow()) {
      arr.push(new Metric(rs.getLong(0), rs.getLong(1), rs.getDouble(2), rs.getDouble(3), rs.getLong(4), rs.getLong(5)))
    }
    rs.close()
    this.metrics = arr
  }

  private async createMetric(plantId: number, height: number, width: number, score: number, dateISO: string): Promise<void> {
    if (!this.store) { return }
    const ts: number = this.isoToTs(dateISO)
    const v: relationalStore.ValuesBucket = { plantId: plantId, height: height, width: width, score: score, createdAt: ts }
    await this.store.insert(Index.T_METRIC, v)
    await this.loadMetricsByPlant(plantId)
  }

  private isoToTs(iso: string): number {
    // 简单解析 YYYY-MM-DD -> 本地 00:00:00
    if (iso.length !== 10) { return Date.now() }
    const y: number = Number(iso.substring(0, 4))
    const m: number = Number(iso.substring(5, 7)) - 1
    const d: number = Number(iso.substring(8, 10))
    const dt = new Date(y, m, d, 0, 0, 0, 0)
    return dt.getTime()
  }

  private async deleteMetric(id: number): Promise<void> {
    if (!this.store) { return }
    const p = new relationalStore.RdbPredicates(Index.T_METRIC); p.equalTo('id', id)
    await this.store.delete(p)
    if (this.metricPlantId !== 0) { await this.loadMetricsByPlant(this.metricPlantId) }
  }

  /** ---- 植物 CRUD ---- */
  private async createPlant(draft: PlantDraft): Promise<void> {
    if (!this.store) {
      return
    }
    const values: relationalStore.ValuesBucket = {
      name: draft.name.trim(),
      species: draft.species.trim(),
      location: draft.location.trim(),
      createdAt: Date.now()
    }
    await this.store.insert(Index.T_PLANT, values)
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
    const p = new relationalStore.RdbPredicates(Index.T_PLANT);
    p.equalTo('id', id)
    await this.store.update(values, p)
    await this.loadPlants()
    this.showBanner('已更新植物信息', 'ok')
  }

  private async deletePlant(id: number): Promise<void> {
    if (!this.store) {
      return
    }
    // 级联删除任务与日志
    const pt = new relationalStore.RdbPredicates(Index.T_TASK);
    pt.equalTo('plantId', id)
    await this.store.delete(pt)
    const pl = new relationalStore.RdbPredicates(Index.T_LOG);
    pl.equalTo('plantId', id)
    await this.store.delete(pl)
    const pp = new relationalStore.RdbPredicates(Index.T_PLANT);
    pp.equalTo('id', id)
    await this.store.delete(pp)
    await this.reloadAll()
    this.showBanner('已删除植物及其任务/日志', 'ok')
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
    await this.store.insert(Index.T_TASK, values)
    await this.loadTasks()
    this.showBanner('已添加养护任务', 'ok')
  }

  private async toggleTaskDone(task: PlantTask): Promise<void> {
    if (!this.store) {
      return
    }
    const nd = task.done === 1 ? 0 : 1
    const values: relationalStore.ValuesBucket = { done: nd, doneAt: nd === 1 ? Date.now() : 0 }
    const p = new relationalStore.RdbPredicates(Index.T_TASK);
    p.equalTo('id', task.id)
    await this.store.update(values, p)
    await this.loadTasks()
  }

  private async deleteTask(id: number): Promise<void> {
    if (!this.store) {
      return
    }
    const p = new relationalStore.RdbPredicates(Index.T_TASK);
    p.equalTo('id', id)
    await this.store.delete(p)
    await this.loadTasks()
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
    await this.store.insert(Index.T_TPL, values)
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
    const p = new relationalStore.RdbPredicates(Index.T_TPL);
    p.equalTo('id', id)
    await this.store.update(values, p)
    await this.loadTemplates()
    this.showBanner('已更新模板', 'ok')
  }

  private async deleteTpl(id: number): Promise<void> {
    if (!this.store) {
      return
    }
    const p = new relationalStore.RdbPredicates(Index.T_TPL);
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

  /** ---- 日志 CRUD ---- */
  private async loadLogsByPlant(plantId: number): Promise<void> {
    if (!this.store) {
      return
    }
    const rs =
      await this.store.querySql(`SELECT id,plantId,note,createdAt FROM ${Index.T_LOG} WHERE plantId=? ORDER BY createdAt DESC, id DESC`,
        [plantId])
    const arr: Array<LogEntry> = []
    while (rs.goToNextRow()) {
      arr.push(new LogEntry(rs.getLong(0), rs.getLong(1), rs.getString(2), rs.getLong(3)))
    }
    rs.close()
    this.logList = arr
  }

  private async createLog(plantId: number, note: string): Promise<void> {
    if (!this.store) {
      return
    }
    const txt: string = note.trim()
    if (txt.length === 0) {
      this.showBanner('日志内容不能为空', 'warn');
      return
    }
    const values: relationalStore.ValuesBucket = { plantId: plantId, note: txt, createdAt: Date.now() }
    await this.store.insert(Index.T_LOG, values)
    await this.loadLogsByPlant(plantId)
    this.showBanner('已添加日志', 'ok')
  }

  private async deleteLog(id: number): Promise<void> {
    if (!this.store) {
      return
    }
    const p = new relationalStore.RdbPredicates(Index.T_LOG);
    p.equalTo('id', id)
    await this.store.delete(p)
    await this.loadLogsByPlant(this.logPlantId)
    this.showBanner('已删除日志', 'ok')
  }

  // 删除一条日志及其关联照片（含本地文件），并自动刷新当前植物的日志列表
  private async deleteLogAndPhotos(logId: number): Promise<void> {
    if (!this.store) { return }

    // 1) 取该日志的 plantId（用于刷新）
    let plantId: number = 0
    {
      const rs = await this.store.querySql(`SELECT plantId FROM ${Index.T_LOG} WHERE id=?`, [logId])
      if (rs.goToNextRow()) { plantId = rs.getLong(0) }
      rs.close()
    }

    // 2) 收集所有照片路径（优先 filePath，兼容老字段 path）
    const paths: Array<string> = []
    try {
      const rs1 = await this.store.querySql(`SELECT filePath FROM ${Index.T_LOG_PHOTO} WHERE logId=?`, [logId])
      while (rs1.goToNextRow()) {
        const p: string = rs1.getString(0)
        if (p.length > 0) { paths.push(p) }
      }
      rs1.close()
    } catch (_) {
      // 兼容老列名 path（如你的历史库是 path/thumbPath）
      try {
        const rs2 = await this.store.querySql(`SELECT path FROM ${Index.T_LOG_PHOTO} WHERE logId=?`, [logId])
        while (rs2.goToNextRow()) {
          const p2: string = rs2.getString(0)
          if (p2.length > 0) { paths.push(p2) }
        }
        rs2.close()
      } catch (_) {}
    }

    // 3) 先删图片表，再删日志表（确保外键语义顺序）
    const pp = new relationalStore.RdbPredicates(Index.T_LOG_PHOTO); pp.equalTo('logId', logId)
    await this.store.delete(pp)

    const pl = new relationalStore.RdbPredicates(Index.T_LOG); pl.equalTo('id', logId)
    await this.store.delete(pl)

    // 4) 删除本地文件（忽略不存在或权限错误）
    let i: number = 0
    while (i < paths.length) {
      const uriOrPath: string = paths[i]
      let realPath: string = uriOrPath
      if (realPath.startsWith('file://')) { realPath = realPath.substring(7) }

      let removed: number = 0
      try {
        await fs.unlink(realPath)
        removed = 1
      } catch (_) { /* 尝试用 FileAccess 助手按 URI 删除 */ }

      // if (removed === 0) {
      //   try {
      //     const helper = fileAccess.createFileAccessHelper(this.ctx)
      //     const uri: string = uriOrPath.startsWith('file://') ? uriOrPath : `file://${realPath}`
      //     await helper.deleteFile(uri)
      //   } catch (_) {}
      // }
      i = i + 1
    }

    // 5) 刷新 UI（若能定位到 plantId）
    if (plantId !== 0) { await this.loadLogsByPlant(plantId) }
    this.showBanner('已删除日志及照片', 'ok')
  }


  private async openLogSheetFor(plantId: number): Promise<void> {
    this.logPlantId = plantId
    await this.loadLogsByPlant(plantId)
    this.logInput = ''
    this.logSheetVisible = true
  }

  // 1) 加载「日志 +（按需）照片」
  // 说明：这里先只加载日志列表；照片仍按你当前交互在选择某条日志后，调用 loadLogPhotos(logId) 单独加载。
  // 这样不会影响你把 logPhotos 用作“当前编辑日志照片”的语义。
  private async loadLogsWithPhotos(plantId: number): Promise<void> {
    await this.loadLogsByPlant(plantId)
    // 如果你希望预取最近一条日志的照片，可解开下面两行：
    // if (this.logs.length > 0) {
    //   await this.loadLogPhotos(this.logs[0].id)
    // }
  }

  // 2) 相册多选并保存到本地（复用你已有的选择/拷贝/入库逻辑）
  private async pickAndSavePhotos(logId: number): Promise<void> {
    // 你工程里已有 pickPhotosForLog（会走 selectImagesFromAlbum → ensurePhotosDir → copyImageToAppFiles → insertLogPhoto → loadLogPhotos）
    await this.pickPhotosForLog(logId)
  }

  // 3) 拍照保存（按你之前要求“暂不做拍照”）
  // 为了不让外部调用报错，这里给出占位实现，可随时替换为真实拍照流程。
  private async captureAndSavePhoto(logId: number): Promise<void> {
    this.showBanner('当前版本未启用拍照功能', 'info')
    // 若后续需要接入：调用相机 → 保存到 filesDir/photos → insertLogPhoto(logId, fileUri) → loadLogPhotos(logId)
  }

  //
  private async createTaskDirect(plantId: number, type: string, dateISO: string): Promise<void> {
    if (!this.store) { return }
    const v: relationalStore.ValuesBucket = { plantId: plantId, type: type, planDate: dateISO.trim(), done: 0, doneAt: 0 }
    await this.store.insert(Index.T_TASK, v)
  }

  private async generateTemplateTasks(plantId: number, waterInt: number, fertInt: number, pruneInt: number, startISO: string, days: number): Promise<void> {
    if (plantId === 0) { return }
    // 逐日生成：对每个非 0 的间隔，在范围内按步长生成日期
    const base = this.isoToTs(startISO)
    if (days <= 0) { return }
    let offset: number = 0
    while (offset < days) {
      const d = new Date(base + offset * 24 * 3600 * 1000)
      const y = d.getFullYear()
      const m = (d.getMonth() + 1).toString().padStart(2, '0')
      const day = d.getDate().toString().padStart(2, '0')
      const iso = `${y}-${m}-${day}`
      if (waterInt > 0 && (offset % waterInt === 0)) { await this.createTaskDirect(plantId, '浇水', iso) }
      if (fertInt  > 0 && (offset % fertInt  === 0)) { await this.createTaskDirect(plantId, '施肥', iso) }
      if (pruneInt > 0 && (offset % pruneInt === 0)) { await this.createTaskDirect(plantId, '修剪', iso) }
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

  private statDoneCount(): number {
    let cnt: number = 0
    let i: number = 0
    while (i < this.tasks.length) {
      if (this.tasks[i].done === 1) {
        cnt = cnt + 1
      }
      i = i + 1
    }
    return cnt
  }

  /** ---- 下拉刷新头手势 ---- */
  private onHeaderTouch(e: TouchEvent): void {
    if (e.type === TouchType.Down) {
      this.touchStartY = e.touches[0].y;
      this.pulling = true;
      this.canRefresh = false
    } else if (e.type === TouchType.Move && this.pulling) {
      const dy: number = e.touches[0].y - this.touchStartY
      if (dy > 0) {
        let v: number = dy;
        if (v > 80) {
          v = 80
        }
        this.pullOffset = v;
        this.canRefresh = v > 60
      }
    } else if (e.type === TouchType.Up || e.type === TouchType.Cancel) {
      if (this.canRefresh) {
        this.refreshAll()
      }
      animateTo({ duration: 180, curve: Curve.EaseInOut }, () => {
        this.pullOffset = 0;
        this.pulling = false;
        this.canRefresh = false
      })
    }
  }

  private async refreshAll(): Promise<void> {
    await this.reloadAll();
    await this.loadTemplates()
    if (this.logSheetVisible && this.logPlantId !== 0) {
      await this.loadLogsByPlant(this.logPlantId)
    }
    this.showBanner('已刷新数据', 'ok')
  }

  /** ---- 视图 ---- */
  build() {
    Stack({alignContent:Alignment.Bottom}) {
      // 头部
      // this.Header()
      Tabs({
        barPosition: BarPosition.End,
        index: this.tabBarIndex
      }){
        TabContent(){
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
              this.logPlantId = p.id; this.logPlantName = p.name; this.logInputText = ''
              await this.loadLogsByPlant(p.id)
              this.logVisible = true
            },
            onDeleteAsk: (pid: number) => {
              this.pendingDeletePlantId = pid;
              this.pendingDeleteTaskId = 0
              this.confirmText = '删除该植物及其任务？'
              this.confirmVisible = true
            },
            onOpenMetrics: async (p: Plant) => {
              this.metricPlantId = p.id; this.metricPlantName = p.name
              await this.loadMetricsByPlant(p.id)
              this.metricVisible = true
            },
            onOpenTemplate: (p: Plant) => {
              this.carePlantId = p.id
              this.carePlantName = p.name
              this.careVisible = true
            },
            Header: ()=>{this.Header()}
          })
        }.tabBar(this.TabChip('植物', 0))
        TabContent(){
          // TaskCalendarGate({
          //   tasks: this.tasks,
          //   onToggle: (t: PlantTask) => { this.toggleTaskDone(t) },
          //   onDelete: (id: number) => { this.deleteTask(id) }
          // })
          TaskListPage({
            tasks: this.filteredTasks() || this.tasks,
            plants: this.plants,
            onToggle: (t: PlantTask) => {
              this.toggleTaskDone(t)
            },
            onDeleteAsk: (tid: number) => {
              this.pendingDeleteTaskId = tid;
              this.pendingDeletePlantId = 0;
              this.confirmText = '删除这个任务？';
              this.confirmVisible = true
            }
          })
        }.tabBar(this.TabChip('任务', 1))
        TabContent(){

        }.tabBar(this.Fab(() => {
          this.openPanel(0)
        }))
        TabContent(){
          CalendarSheet({
            year: this.calYear,
            month: this.calMonth,
            tasks: this.tasks, // Array<PlantTask>
            onToggle: (it: PlantTask) => { this.toggleTaskDone(it) },
            onDelete: (id: number) => { this.deleteTask(id) },
            onClose: () => { this.calendarVisible = false }
          })
        }.tabBar(this.TabChip('日历', 3))
        TabContent(){
          StatsPage({
            plantCount: this.plants.length,
            taskCount: this.tasks.length,
            doneCount: this.statDoneCount()
          })
        }.tabBar(this.TabChip('统计', 4))

      }.barWidth('100%').barHeight(54).height('100%').scrollable(false)
      .onChange((index: number) => {
        this.tabBarIndex = index;
      })

      // 内容

      // FAButton
      // if (this.tabBarIndex === 0) {
      //   this.Fab(() => {
      //     this.openPanel(0)
      //   })
      // }

      // Banner
      if (this.bannerMsg.length > 0) {
        this.Banner(this.bannerMsg, this.bannerType)
      }

      if (this.careVisible) {
        CareTemplateSheet({
          plantName: this.carePlantName,
          onClose: () => { this.careVisible = false },
          onApply: async (waterInt: number, fertInt: number, pruneInt: number, startISO: string, days: number) => {
            await this.generateTemplateTasks(this.carePlantId, waterInt, fertInt, pruneInt, startISO, days)
            this.careVisible = false
            this.showBanner('已按模板生成任务', 'ok')
            await this.loadTasks()
          }
        })
      }

      // —— 日志抽屉 ——（使用你已有的 PlantLogSheet）
      if (this.logVisible) {
        PlantLogSheet({
          plantName: this.currentPlantName,
          logs: this.logs,                  // ← 你已有的日志数组
          photos: this.logPhotos,           // ← 你维护的 LogPhoto 数组（可在加载日志时一并查询）
          keyword: this.keyword,         // ← 来自搜索框
          onAddLog: async (note: string, iso: string) => {
            if (!this.store) { return }
            await this.store.insert(Index.T_LOG, { plantId: this.logPlantId, note: note, createdAt: Date.now() })
            await this.loadLogsWithPhotos(this.logPlantId) // 重新加载
            // await this.loadLogsByPlant(this.currentPlantId)
          },
          onDeleteLog: async (logId: number) => {
            if (!this.store) { return }
            const p = new relationalStore.RdbPredicates(Index.T_LOG); p.equalTo('id', logId)
            await this.store.delete(p)
            const pp = new relationalStore.RdbPredicates(Index.T_LOG_PHOTO); pp.equalTo('logId', logId)
            await this.store.delete(pp)
            await this.loadLogsWithPhotos(this.logPlantId)
          },
          onBatchDeleteLogs: async (ids: Array<number>) => {
            if (!this.store) { return }
            // 删除日志本体
            const p = new relationalStore.RdbPredicates(Index.T_LOG); p.in('id', ids)
            await this.store.delete(p)
            // 删除关联图片
            const pp = new relationalStore.RdbPredicates(Index.T_LOG_PHOTO); pp.in('logId', ids)
            await this.store.delete(pp)
            await this.loadLogsWithPhotos(this.logPlantId)
          },
          onPickPhotos: async (logId: number) => {
            // 在这里用你现有的封装（file.picker / photoAccessHelper），复制到 filesDir，
            // 生成缩略图（可选），然后批量 insert 到 ${Index.T_LOG_PHOTO}，最后刷新。
            await this.pickAndSavePhotos(logId) // 你已有/将实现的方法
            await this.loadLogsWithPhotos(this.logPlantId)
          },
          onCapturePhoto: async (logId: number) => {
            await this.captureAndSavePhoto(logId) // 你已有/将实现的方法
            await this.loadLogsWithPhotos(this.logPlantId)
          },
          onDeletePhoto: async (pid: number) => {
            if (!this.store) { return }
            const p = new relationalStore.RdbPredicates(Index.T_LOG_PHOTO); p.equalTo('id', pid)
            await this.store.delete(p)
            await this.deleteLogAndPhotos(pid)
            await this.loadLogsWithPhotos(this.logPlantId)
          },
          onClose: () => { this.logSheetVisible = false }
        })
      }

      if (this.taskFilterVisible) {
        PlantTaskFilterSheet({
          filter: this.taskFilter,
          plants: this.plants,
          onApply: (f: PlantTaskFilter) => { this.taskFilter = f; this.taskFilterVisible = false },
          onReset: () => { this.taskFilter = new PlantTaskFilter() },
          onClose: () => { this.taskFilterVisible = false }
        })
      }

      // —— 指标抽屉 ——（新增组件 MetricSheet）
      if (this.metricVisible) {
        MetricSheet({
          plantName: this.metricPlantName,
          metrics: this.metrics,
          onClose: () => { this.metricVisible = false },
          onAdd: async (h: number, w: number, s: number, iso: string) => {
            await this.createMetric(this.metricPlantId, h, w, s, iso)
          },
          onDelete: async (id: number) => { await this.deleteMetric(id) }
        })
      }

      if (this.calendarVisible) {
        CalendarSheet1({
          year: this.calendarYear,
          month: this.calendarMonth,
          tasks: this.tasks,          // 这里的 tasks 请确保是 PlantTask[]
          plants: this.plants,
          onChangeMonth: (y: number, m: number) => { this.calendarYear = y; this.calendarMonth = m },
          onQuickAdd: async (pid: number, type: string, iso: string) => {
            this.taskDraft = new TaskDraft();
            this.taskDraft.plantId = pid;
            this.taskDraft.type = type;
            this.taskDraft.planDate = iso
            await this.createTask(this.taskDraft);  // 你现有的方法
          },
          onToggle: async (t: PlantTask) => { await this.toggleTaskDone(t) },
          onClose: () => { this.calendarVisible = false }
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
            if (this.editingPlantId === 0) {
              this.showBanner('请先保存植物再写日志', 'info');
              return
            }
            await this.openLogSheetFor(this.editingPlantId)
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

      // ← 新增：日志抽屉
      if (this.logSheetVisible) {
        // PlantLogSheet({
        //   logs: this.logList,
        //   plantName: this.findPlantName(this.logPlantId),
        //   inputText: this.logInput,
        //   onChangeInput: (v: string) => {
        //     this.logInput = v
        //   },
        //   onAdd: async () => {
        //     await this.createLog(this.logPlantId, this.logInput);
        //     this.logInput = ''
        //   },
        //   onDelete: async (id: number) => {
        //     await this.deleteLog(id)
        //   },
        //   onClose: () => {
        //     this.logSheetVisible = false
        //   }
        // })
      }
    }
    .width('100%').height('100%')
    .linearGradient({
      direction: GradientDirection.Top,
      colors: [[0xFFF1F8E9, 0], [0xFFE8F5E9, 0.5], [0xFFE3F2FD, 1.0]]
    }).padding({
      top:AppStorage.get<number>('topRectHeight'),
      bottom:AppStorage.get<number>('bottomRectHeight')
    })
  }


  private findPlantName(id: number): string {
    let i: number = 0
    while (i < this.plants.length) {
      if (this.plants[i].id === id) {
        return this.plants[i].name
      }
      i = i + 1
    }
    return '植物'
  }


  private filteredTasks(): Array<PlantTask> {
    const out: Array<PlantTask> = []
    const f = this.taskFilter
    const kw = f.keyword.trim().toLowerCase()

    let i: number = 0
    while (i < this.tasks.length) {
      const t = this.tasks[i]
      // 状态
      if (f.status === 'done' && t.done !== 1) { i = i + 1; continue }
      if (f.status === 'undone' && t.done !== 0) { i = i + 1; continue }
      // 类型
      if (t.type === '浇水' && !f.typeWater) { i = i + 1; continue }
      if (t.type === '施肥' && !f.typeFertilize) { i = i + 1; continue }
      if (t.type === '修剪' && !f.typePrune) { i = i + 1; continue }
      // 日期范围
      if (f.dateFromISO.length === 10 && t.planDate < f.dateFromISO) { i = i + 1; continue }
      if (f.dateToISO.length === 10 && t.planDate > f.dateToISO) { i = i + 1; continue }
      // 关键词（植物名 / 类型）
      if (kw.length > 0) {
        const pn = this.plantNameById(t.plantId).toLowerCase()
        const hit = pn.indexOf(kw) >= 0 || t.type.toLowerCase().indexOf(kw) >= 0
        if (!hit) { i = i + 1; continue }
      }
      out.push(t)
      i = i + 1
    }

    // 排序
    out.sort((a: PlantTask, b: PlantTask) => {
      if (f.sortKey === 'date') {
        return f.sortAsc ? this.cmpStr(a.planDate, b.planDate) : this.cmpStr(b.planDate, a.planDate)
      }
      if (f.sortKey === 'type') {
        return f.sortAsc ? this.cmpStr(a.type, b.type) : this.cmpStr(b.type, a.type)
      }
      // plant
      const pa = this.plantNameById(a.plantId)
      const pb = this.plantNameById(b.plantId)
      return f.sortAsc ? this.cmpStr(pa, pb) : this.cmpStr(pb, pa)
    })
    return out
  }

  // 字符串比较（避免 locale 差异）
  cmpStr(x: string, y: string): number {
    if (x < y) { return -1 }
    if (x > y) { return 1 }
    return 0
  }

  private plantNameById(id: number): string {
    let i: number = 0
    while (i < this.plants.length) { if (this.plants[i].id === id) { return this.plants[i].name } i = i + 1 }
    return ''
  }
  /** ---- Header / TabChip / Fab / Banner（保持与你现有实现一致） ---- */
  @Builder
  Header() {
    Column() {
      Column() {
        Row() {
          Text('PlantDiary 植物养护').fontSize(22).fontWeight(FontWeight.Medium).fontColor(0xFF263238)
          Blank()
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
        Text('📅 日历').fontSize(12).fontColor(0xFF1565C0)
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .borderRadius(12).backgroundColor(0x102196F3)
          .onClick(() => { this.calendarVisible = true })
      }
      .padding({ bottom: 4 })
      .onTouch((e: TouchEvent) => {
        this.onHeaderTouch(e)
      })

      // if (this.pullOffset > 0) {
      //   Row() {
      //     if (this.canRefresh) {
      //       Text('释放刷新').fontSize(12).fontColor(0xFF2E7D32)
      //     } else {
      //       Text('下拉刷新').fontSize(12).fontColor(0xFF607D8B)
      //     }
      //   }
      //   .width('100%')
      //   .height(24)
      //   .justifyContent(FlexAlign.Center)
      //   .opacity(0.9)
      //   .padding({ bottom: 4 })
      // }
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
          this.tabBarIndex = idx
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
















