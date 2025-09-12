// entry/src/main/ets/pages/Index.ets
import common from '@ohos.app.ability.common'
import relationalStore from '@ohos.data.relationalStore'
import { LogEntry, Plant, PlantDraft, PlanTpl, PlantTask, TaskDraft } from '../model/PlantModel'
import { ConfirmDialogSheet } from '../view/ConfirmDialogSheet'
import { EditPlantSheet } from '../view/EditPlantSheet'
import { PlantListPage } from '../view/PlantListPage'
import { StatsPage } from '../view/StatsPage'
import { TaskListPage } from '../view/TaskListPage'
import { TemplateManagerSheet } from '../view/TemplateManagerSheet'

/** -------- 入口页面（V2） -------- */
@Entry
@ComponentV2
struct Index {
  private ctx: common.UIAbilityContext = getContext(this) as common.UIAbilityContext
  // DB
  private store?: relationalStore.RdbStore
  private static readonly DB_NAME: string = 'plantdiary.db'
  private static readonly T_PLANT: string = 'plant'
  private static readonly T_TASK: string = 'task'
  private static readonly T_TPL: string = 'tpl'
  private static readonly T_LOG: string = 'log'   // ← 新增：日志表
  // 状态
  @Local initialized: boolean = false
  @Local plants: Array<Plant> = []
  @Local tasks: Array<PlantTask> = []
  @Local bannerMsg: string = ''
  @Local bannerType: 'ok' | 'warn' | 'info' = 'info'
  // Tab 与搜索
  @Local tabBarIndex: number = 0 // 0 植物 1 任务 2 统计
  @Local keyword: string = ''
  // 新建/编辑面板
  @Local panelVisible: boolean = false
  @Local editingPlantId: number = 0
  @Local plantDraft: PlantDraft = new PlantDraft()
  @Local taskDraft: TaskDraft = new TaskDraft()
  // 自定义弹窗（删除确认）
  @Local confirmVisible: boolean = false
  @Local confirmText: string = ''
  @Local pendingDeletePlantId: number = 0
  @Local pendingDeleteTaskId: number = 0
  // 下拉刷新（页头区域）
  @Local pullOffset: number = 0 // 0~80
  @Local pulling: boolean = false
  @Local canRefresh: boolean = false
  @Local touchStartY: number = 0
  // FAB 动画
  @Local fabPressed: boolean = false
  // —— 新增：模板管理面板状态 —— //
  @Local tplMgrVisible: boolean = false
  @Local templates: Array<PlanTpl> = []
  // ← 新增：日志抽屉
  @Local logSheetVisible: boolean = false
  @Local logPlantId: number = 0
  @Local logList: Array<LogEntry> = []
  @Local logInput: string = ''

  /** ---- 生命周期 ---- */
  aboutToAppear(): void {
    this.initDb().then(() => {
      this.initialized = true
      this.showBanner('已初始化本地数据库', 'ok')
    }).catch((e: Error) => {
      this.showBanner('数据库初始化失败', 'warn')
      console.error(e.message)
    })
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
    // ← 新增模板表
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
      items.push(new PlantTask(rs.getLong(0), rs.getLong(1), rs.getString(2), rs.getString(3), rs.getLong(4),
        rs.getLong(5)))
    }
    rs.close()
    this.tasks = items
  }

  // —— 新增：模板加载 —— //
  private async loadTemplates(): Promise<void> {
    if (!this.store) {
      return
    }
    const rs =
      await this.store.querySql(`SELECT id,name,type,everyDays,times,createdAt FROM ${Index.T_TPL} ORDER BY createdAt DESC, id DESC`,
        [])
    const items: Array<PlanTpl> = []
    while (rs.goToNextRow()) {
      items.push(new PlanTpl(
        rs.getLong(0),
        rs.getString(1),
        rs.getString(2),
        rs.getLong(3),
        rs.getLong(4),
        rs.getLong(5)
      ))
    }
    rs.close()
    this.templates = items
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
    const pt = new relationalStore.RdbPredicates(Index.T_TASK);
    pt.equalTo('plantId', id)
    await this.store.delete(pt)
    const pp = new relationalStore.RdbPredicates(Index.T_PLANT);
    pp.equalTo('id', id)
    await this.store.delete(pp)
    await this.reloadAll()
    this.showBanner('已删除植物及其任务', 'ok')
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

  /** ---- 批量生成周期任务（每N天×次数） ---- */
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

  // —— 模板 CRUD & 应用 —— //
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
    // 查模板
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
    if (!this.store) { return }
    const rs = await this.store.querySql(`SELECT id,plantId,note,createdAt FROM ${Index.T_LOG} WHERE plantId=? ORDER BY createdAt DESC, id DESC`, [plantId])
    const arr: Array<LogEntry> = []
    while (rs.goToNextRow()) {
      arr.push(new LogEntry(rs.getLong(0), rs.getLong(1), rs.getString(2), rs.getLong(3)))
    }
    rs.close()
    this.logList = arr
  }

  private async createLog(plantId: number, note: string): Promise<void> {
    if (!this.store) { return }
    const txt: string = note.trim()
    if (txt.length === 0) { this.showBanner('日志内容不能为空', 'warn'); return }
    const values: relationalStore.ValuesBucket = { plantId: plantId, note: txt, createdAt: Date.now() }
    await this.store.insert(Index.T_LOG, values)
    await this.loadLogsByPlant(plantId)
    this.showBanner('已添加日志', 'ok')
  }

  private async deleteLog(id: number): Promise<void> {
    if (!this.store) { return }
    const p = new relationalStore.RdbPredicates(Index.T_LOG); p.equalTo('id', id)
    await this.store.delete(p)
    await this.loadLogsByPlant(this.logPlantId)
    this.showBanner('已删除日志', 'ok')
  }

  private async openLogSheetFor(plantId: number): Promise<void> {
    this.logPlantId = plantId
    await this.loadLogsByPlant(plantId)
    this.logInput = ''
    this.logSheetVisible = true
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
    const base = new Date(y, m - 1, d)
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
    if (kw.length === 0) { return this.plants }
    const out: Array<Plant> = []
    let i: number = 0
    while (i < this.plants.length) {
      const p: Plant = this.plants[i]
      if (p.name.toLowerCase().includes(kw) || p.species.toLowerCase().includes(kw) || p.location.toLowerCase().includes(kw)) {
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

  /** ---- 下拉刷新手势（页头区域） ---- */
  private onHeaderTouch(e: TouchEvent): void {
    if (e.type === TouchType.Down) {
      this.touchStartY = e.touches[0].y;
      this.pulling = true;
      this.canRefresh = false
    } else if (e.type === TouchType.Move && this.pulling) {
      const dy: number = e.touches[0].y - this.touchStartY
      if (dy > 0) {
        let v: number = dy
        if (v > 80) {
          v = 80
        }
        this.pullOffset = v
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
    await this.reloadAll()
    this.showBanner('已刷新数据', 'ok')
  }

  /** ---- 视图 ---- */
  build() {
    Column() {
      // 顶部栏 + 下拉刷新头
      this.Header()

      // 内容区
      if (this.tabBarIndex === 0) {
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
          onDeleteAsk: (pid: number) => {
            this.pendingDeletePlantId = pid;
            this.pendingDeleteTaskId = 0
            this.confirmText = '删除该植物及其任务？'
            this.confirmVisible = true
          }
        })
      } else if (this.tabBarIndex === 1) {
        TaskListPage({
          tasks: this.tasks,
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
      } else {
        StatsPage({
          plantCount: this.plants.length,
          taskCount: this.tasks.length,
          doneCount: this.statDoneCount()
        })
      }

      // FAB（仅植物页显示）
      if (this.tabBarIndex === 0) {
        this.Fab(() => {
          this.openPanel(0)
        })
      }

      // 顶部 Banner
      if (this.bannerMsg.length > 0) {
        this.Banner(this.bannerMsg, this.bannerType)
      }

      // 自定义弹窗：删除确认
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

      // 新建/编辑面板（增加：周期任务批量生成）
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
          }
        })
      }

      if (this.tplMgrVisible) {
        TemplateManagerSheet({
          templates: this.templates,
          editingPlantId: this.editingPlantId,
          onClose: () => { this.tplMgrVisible = false },
          onCreate: async (n: string, t: string, d: number, times: number) => { await this.createTpl(n, t, d, times) },
          onUpdate: async (id: number, n: string, t: string, d: number, times: number) => { await this.updateTpl(id, n, t, d, times) },
          onDelete: async (id: number) => { await this.deleteTpl(id) },
          onApply: async (id: number) => { await this.applyTplToPlant(id) }
        })
      }
    }
    .width('100%').height('100%')
    .linearGradient({
      direction: GradientDirection.Top,
      colors: [[0xFFF1F8E9, 0], [0xFFE8F5E9, 0.5], [0xFFE3F2FD, 1.0]]
    })
  }

  /** ---- Header：搜索 / Tabs / 下拉刷新 ---- */
  @Builder
  Header() {
    Column() {
      // 可下拉的头部刷新区
      Column() {
        Row() {
          Text('PlantDiary 植物养护').fontSize(22).fontWeight(FontWeight.Medium).fontColor(0xFF263238)
          Blank()
          Text(this.initialized ? '离线 · 本地数据库' : '初始化中…').fontSize(12).fontColor(0x80263238)
        }
        .padding({
          left: 20,
          right: 20,
          top: 16,
          bottom: 8
        })

        // 搜索
        Row() {
          Text('🔎').fontSize(18).margin({ right: 8 })
          TextInput({ placeholder: '搜索植物/品种/位置', text: this.keyword })
            .onChange((v: string) => {
              this.keyword = v
            })
            .width('100%')
            .height(36)
            .fontSize(14)
            .borderRadius(12)
            .backgroundColor(0xFFFFFFFF)
            .padding({ left: 12, right: 12 })
        }
        .height(44).width('100%').padding({ left: 20, right: 20, bottom: 2 })

        // Tabs
        Row() {
          this.TabChip('植物', 0)
          this.TabChip('任务', 1)
          this.TabChip('统计', 2)
        }
        .padding({
          left: 16,
          right: 16,
          top: 6,
          bottom: 8
        })
        .justifyContent(FlexAlign.SpaceAround)
      }
      .padding({ bottom: 4 })
      .onTouch((e: TouchEvent) => {
        this.onHeaderTouch(e)
      })

      // 下拉刷新提示条（根据 pullOffset 显示）
      if (this.pullOffset > 0) {
        Row() {
          if (this.canRefresh) {
            Text('释放刷新').fontSize(12).fontColor(0xFF2E7D32)
          } else {
            Text('下拉刷新').fontSize(12).fontColor(0xFF607D8B)
          }
        }
        .width('100%')
        .height(24)
        .justifyContent(FlexAlign.Center)
        .opacity(0.9)
        .padding({ bottom: 4 })
      }
    }
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

  /** ---- FAB（带按压缩放波纹感） ---- */
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
            this.fabPressed = true
            animateTo({ duration: 90, curve: Curve.EaseOut }, () => {
            })
          } else if (e.type === TouchType.Up || e.type === TouchType.Cancel) {
            this.fabPressed = false
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
    .scale(this.fabPressed ? { x: 0.94, y: 0.94 } : { x: 1, y: 1 })
    .position({ x: 'calc(100% - 76vp)', y: 'calc(100% - 96vp)' })
    .animation({ duration: 120, curve: Curve.EaseInOut })
  }

  /** ---- 顶部提示条 ---- */
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















