import { Plant, PlantTask } from "../model/PlantModel";

@ObservedV2
export
class DayInfo {
  @Trace dateISO: string
  @Trace inMonth: number     // 1=本月, 0=前后月补位
  @Trace total: number
  @Trace done: number
  constructor(dateISO: string, inMonth: number, total: number, done: number) {
    this.dateISO = dateISO; this.inMonth = inMonth; this.total = total; this.done = done
  }
}

/** ====================== 日历面板（含当日任务列表） ====================== */
@ComponentV2
export
struct CalendarSheet1 {
  // 外部数据
  @Param @Require year: number
  @Param @Require month: number
  @Param @Require tasks: Array<PlantTask>
  @Param @Require plants: Array<Plant>

  // 事件
  @Event onChangeMonth: (year: number, month: number) => void
  @Event onQuickAdd: (plantId: number, type: string, dateISO: string) => void
  @Event onToggle: (t: PlantTask) => void
  @Event onClose: () => void

  // —— 筛选 —— //
  @Local showDone: 'all' | 'undone' | 'done' = 'all'
  @Local fWater: boolean = true
  @Local fFertilize: boolean = true
  @Local fPrune: boolean = true

  // —— 选择/专注 —— //
  @Local focusDate: string = ''   // 长按进入，仅看当天
  @Local quickDate: string = ''   // 点击用于快速添加

  // —— 快速添加表单 —— //
  @Local pickPlantId: number = 0
  @Local pickType: string = '浇水'

  aboutToAppear(): void {
    if (this.plants.length > 0) { this.pickPlantId = this.plants[0].id }
  }

  // ================== 视图 ================== //
  build() {
    Column() {
      // 背景
      Blank().width('100%').height('100%').backgroundColor(0x66000000).onClick(() => { this.onClose() })

      // 抽屉
      Column() {
        // 头部
        Row() {
          Row() {
            Text('◀').fontSize(18)
              .padding({ left: 8, right: 8, top: 6, bottom: 6 }).borderRadius(12).backgroundColor(0x10A0A0A0)
              .onClick(() => { const p = this.prevMonth(this.year, this.month); this.onChangeMonth(p[0], p[1]) })
            Text(this.titleOfYM(this.year, this.month)).fontSize(16).fontWeight(FontWeight.Medium).fontColor(0xFF263238).margin({ left: 10, right: 10 })
            Text('▶').fontSize(18)
              .padding({ left: 8, right: 8, top: 6, bottom: 6 }).borderRadius(12).backgroundColor(0x10A0A0A0)
              .onClick(() => { const n = this.nextMonth(this.year, this.month); this.onChangeMonth(n[0], n[1]) })
          }
          Blank()
          Text('✕').fontSize(18).onClick(() => { this.onClose() })
        }
        .padding({ left: 16, right: 16, top: 12, bottom: 6 })

        // 筛选
        Row() {
          this.FilterChip(this.showDone === 'all', '全部', () => { this.showDone = 'all' })
          this.FilterChip(this.showDone === 'undone', '未完成', () => { this.showDone = 'undone' })
          this.FilterChip(this.showDone === 'done', '已完成', () => { this.showDone = 'done' })
          Blank()
          this.TypeChip('浇水', this.fWater, () => { this.fWater = !this.fWater })
          this.TypeChip('施肥', this.fFertilize, () => { this.fFertilize = !this.fFertilize })
          this.TypeChip('修剪', this.fPrune, () => { this.fPrune = !this.fPrune })
        }
        .padding({ left: 16, right: 16, bottom: 8 })

        // 星期抬头
        Row() { this.WeekHead('一'); this.WeekHead('二'); this.WeekHead('三'); this.WeekHead('四'); this.WeekHead('五'); this.WeekHead('六'); this.WeekHead('日') }
        .padding({ left: 10, right: 10, bottom: 6 })

        // 日历网格（用分片方法避免在 Builder 内声明变量）
        this.DaysGrid()

        // 专注状态/提示
        Row() {
          if (this.focusDate.length > 0) {
            Text(`仅看：${this.focusDate}`).fontSize(12).fontColor(0xFF1565C0)
              .padding({ left: 10, right: 10, top: 6, bottom: 6 }).borderRadius(14).backgroundColor(0x102196F3)
              .onClick(() => { this.focusDate = '' })
          } else {
            Text('提示：点某天快速添加，长按某天仅看当天。').fontSize(12).fontColor(0x80607278)
          }
          Blank()
        }
        .padding({ left: 16, right: 16, top: 8, bottom: 4 })

        // 快速添加（选中日期显示）
        if (this.quickDate.length > 0) {
          this.QuickAddBar()
        }

        // —— 当日任务列表（专注当天 or 选中当天） —— //
        if (this.currentDateForList().length > 0) {
          Column() {
            Row() {
              Text(`当日任务 · ${this.currentDateForList()}`).fontSize(13).fontColor(0xFF263238)
              Blank()
              Text(this.dayTasks(this.currentDateForList()).length.toString() + ' 条').fontSize(12).fontColor(0xFF607D8B)
            }
            .padding({ left: 16, right: 16, top: 6, bottom: 4 })

            List({ space: 6 }) {
              ForEach(this.dayTasks(this.currentDateForList()), (t: PlantTask) => {
                ListItem() { this.DayTaskRow(t) }
              }, (t: PlantTask) => t.id.toString())
            }
            .padding({ left: 16, right: 16, bottom: 12 })
            .edgeEffect(EdgeEffect.Spring)
          }
          .padding({ top: 4 })
        }
      }
      .width('100%').backgroundColor(0xFFFFFFFF)
      .borderRadius({ topLeft: 20, topRight: 20, bottomLeft: 0, bottomRight: 0 })
      .position({ x: 0, y: 'calc(100% - 86%)' })
      .shadow({ radius: 24, color: 0x33000000, offsetX: 0, offsetY: -6 })
      .animation({ duration: 200, curve: Curve.Sharp })
    }
    .width('100%').height('100%')
  }

  // ================== 子区块 ================== //
  @Builder
  FilterChip(active: boolean, text: string, onTap: () => void) {
    Text(text)
      .fontSize(12).fontColor(active ? 0xFFFFFFFF : 0xFF263238)
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .borderRadius(14).backgroundColor(active ? 0xFF1565C0 : 0x11000000)
      .onClick(() => { onTap() })
      .margin({ right: 8 })
  }

  @Builder
  TypeChip(text: string, active: boolean, onTap: () => void) {
    Text(text)
      .fontSize(12).fontColor(active ? 0xFFFFFFFF : 0xFF263238)
      .padding({ left: 10, right: 10, top: 6, bottom: 6 })
      .borderRadius(14).backgroundColor(active ? this.typeColor(text) : 0x11000000)
      .onClick(() => { onTap() })
      .margin({ left: 6 })
  }

  @Builder
  WeekHead(t: string) {
    Text(t).width('14.28%').fontSize(12).fontColor(0xFF607D8B).textAlign(TextAlign.Center)
  }

  @Builder
  DaysGrid() {
    Row() { ForEach(this.cellsAtRow(0), (d: DayInfo) => { this.DayCell(d) }, (d: DayInfo) => d.dateISO + '_0') }
    .padding({ left: 10, right: 10, top: 4, bottom: 4 })
    Row() { ForEach(this.cellsAtRow(1), (d: DayInfo) => { this.DayCell(d) }, (d: DayInfo) => d.dateISO + '_1') }
    .padding({ left: 10, right: 10, top: 4, bottom: 4 })
    Row() { ForEach(this.cellsAtRow(2), (d: DayInfo) => { this.DayCell(d) }, (d: DayInfo) => d.dateISO + '_2') }
    .padding({ left: 10, right: 10, top: 4, bottom: 4 })
    Row() { ForEach(this.cellsAtRow(3), (d: DayInfo) => { this.DayCell(d) }, (d: DayInfo) => d.dateISO + '_3') }
    .padding({ left: 10, right: 10, top: 4, bottom: 4 })
    Row() { ForEach(this.cellsAtRow(4), (d: DayInfo) => { this.DayCell(d) }, (d: DayInfo) => d.dateISO + '_4') }
    .padding({ left: 10, right: 10, top: 4, bottom: 4 })
    Row() { ForEach(this.cellsAtRow(5), (d: DayInfo) => { this.DayCell(d) }, (d: DayInfo) => d.dateISO + '_5') }
    .padding({ left: 10, right: 10, top: 4, bottom: 4 })
  }

  @Builder
  DayCell(d: DayInfo) {
    Column() {
      Text(this.dayNumber(d.dateISO))
        .fontSize(14).fontColor(d.inMonth === 1 ? 0xFF263238 : 0x80607278)
        .textAlign(TextAlign.Center)
      if (d.total > 0) {
        Row() {
          Blank().width(6).height(6).borderRadius(3).backgroundColor(0xFF2E7D32)
          Text(`${d.done}/${d.total}`).fontSize(10).fontColor(0xFF607D8B).margin({ left: 4 })
        }.justifyContent(FlexAlign.Center).margin({ top: 6 })
      }
    }
    .width('14.28%').height(56).borderRadius(10).backgroundColor(this.cellBg(d))
    .onClick(() => {
      if (d.inMonth === 1) { this.quickDate = d.dateISO } else {
        const ymd = this.yearMonthOf(d.dateISO); this.onChangeMonth(ymd[0], ymd[1]); this.quickDate = d.dateISO
      }
    })
    .onTouch((e: TouchEvent) => { if (e.type === TouchType.Down) { this.focusDate = d.dateISO } })
  }

  @Builder
  QuickAddBar() {
    Column() {
      Row() {
        Text(`添加任务 · ${this.quickDate}`).fontSize(13).fontColor(0xFF263238)
        Blank()
        Text('清除').fontSize(12).fontColor(0xFF607D8B)
          .padding({ left: 10, right: 10, top: 6, bottom: 6 }).borderRadius(12).backgroundColor(0x10A0A0A0)
          .onClick(() => { this.quickDate = '' })
      }.padding({ left: 16, right: 16 })

      Row() {
        Text('植物').fontSize(12).fontColor(0xFF607D8B); Blank(); this.PlantPicker()
      }.padding({ left: 16, right: 16, top: 6, bottom: 6 })

      Row() {
        this.TypeChipSel('浇水')
        this.TypeChipSel('施肥')
        this.TypeChipSel('修剪')
        Blank()
        Text('创建').fontSize(14).fontColor(0xFFFFFFFF)
          .padding({ left: 18, right: 18, top: 8, bottom: 8 }).borderRadius(18).backgroundColor(0xFF2E7D32)
          .onClick(() => {
            if (this.quickDate.length === 10 && this.pickPlantId !== 0) {
              this.onQuickAdd(this.pickPlantId, this.pickType, this.quickDate); this.quickDate = ''
            }
          })
      }.padding({ left: 16, right: 16, bottom: 10 })
    }
    .padding(12).borderRadius(16).backgroundColor(0xFFFFFFFF)
    .shadow({ radius: 14, color: 0x12000000, offsetX: 0, offsetY: 4 })
    .margin({ left: 16, right: 16, bottom: 10, top: 6 })
  }

  @Builder
  PlantPicker() {
    Row() {
      ForEach(this.plants, (p: Plant) => {
        Text(p.name)
          .fontSize(12)
          .fontColor(this.pickPlantId === p.id ? 0xFFFFFFFF : 0xFF263238)
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .borderRadius(12)
          .backgroundColor(this.pickPlantId === p.id ? 0xFF1565C0 : 0x11000000)
          .onClick(() => { this.pickPlantId = p.id })
          .margin({ right: 6 })
      }, (p: Plant) => p.id.toString())
    }
    // .scrollable(ScrollDirection.Horizontal)
  }

  @Builder
  TypeChipSel(t: string) {
    Text(t)
      .fontSize(12)
      .fontColor(this.pickType === t ? 0xFFFFFFFF : 0xFF263238)
      .padding({ left: 10, right: 10, top: 6, bottom: 6 })
      .borderRadius(12)
      .backgroundColor(this.pickType === t ? this.typeColor(t) : 0x11000000)
      .onClick(() => { this.pickType = t })
      .margin({ right: 6 })
  }

  @Builder
  DayTaskRow(t: PlantTask) {
    Row() {
      Text(t.done === 1 ? '✅' : '⬜').fontSize(20).onClick(() => { this.onToggle(t) })
      Column() {
        Text(`${t.type} · ${this.plantNameById(t.plantId)}`).fontSize(14).fontWeight(FontWeight.Medium).fontColor(0xFF263238)
        Text(t.planDate + (t.done === 1 ? ' · 已完成' : '')).fontSize(12).fontColor(0xFF607D8B).margin({ top: 2 })
      }.margin({ left: 10 })
      Blank()
    }
    .padding(10).borderRadius(12).backgroundColor(0xFFFFFFFF)
    .shadow({ radius: 10, color: 0x14000000, offsetX: 0, offsetY: 2 })
  }

  // ================== 工具（非 Builder） ================== //
  private titleOfYM(y: number, m: number): string { return `${y} 年 ${m} 月` }
  private prevMonth(y: number, m: number): [number, number] { let yy: number = y; let mm: number = m - 1; if (mm < 1) { yy = y - 1; mm = 12 } return [yy, mm] }
  private nextMonth(y: number, m: number): [number, number] { let yy: number = y; let mm: number = m + 1; if (mm > 12) { yy = y + 1; mm = 1 } return [yy, mm] }
  private firstDayISO(y: number, m: number): string { return `${y}-${m.toString().padStart(2,'0')}-01` }
  private daysInMonth(y: number, m: number): number { const d = new Date(y, m, 0); return d.getDate() }
  private weekdayOfISO(iso: string): number { const d = new Date(iso + 'T00:00:00'); let w: number = d.getDay(); if (w === 0) { return 7 } return w }
  private dayNumber(iso: string): string { return Number(iso.substring(8, 10)).toString() }
  private yearMonthOf(iso: string): [number, number] { return [Number(iso.substring(0,4)), Number(iso.substring(5,7))] }

  private typeColor(type: string): ResourceColor {
    if (type === '浇水') { return 0xFF3AAFA9 }
    if (type === '施肥') { return 0xFF8E7CC3 }
    if (type === '修剪') { return 0xFFE57373 }
    return 0xFF607D8B
  }

  private filterTypesOk(t: string): boolean {
    if (t === '浇水') { return this.fWater }
    if (t === '施肥') { return this.fFertilize }
    if (t === '修剪') { return this.fPrune }
    return true
  }
  private matchDoneState(done: number): boolean {
    if (this.showDone === 'all') { return true }
    if (this.showDone === 'done') { return done === 1 }
    return done === 0
  }
  private focusOk(dateISO: string): boolean {
    if (this.focusDate.length === 0) { return true }
    return dateISO === this.focusDate
  }

  private countForDate(dateISO: string): [number, number] {
    let total: number = 0; let done: number = 0; let i: number = 0
    while (i < this.tasks.length) {
      const t = this.tasks[i]
      if (t.planDate === dateISO && this.filterTypesOk(t.type) && this.focusOk(dateISO)) {
        if (this.showDone === 'all' || (this.showDone === 'done' && t.done === 1) || (this.showDone === 'undone' && t.done === 0)) {
          total = total + 1; if (t.done === 1) { done = done + 1 }
        }
      }
      i = i + 1
    }
    return [total, done]
  }

  private buildCells(): Array<DayInfo> {
    const cells: Array<DayInfo> = []
    const first: string = this.firstDayISO(this.year, this.month)
    const wd: number = this.weekdayOfISO(first) // 1~7
    const dim: number = this.daysInMonth(this.year, this.month)
    const lead: number = wd - 1

    const prev = this.prevMonth(this.year, this.month)
    const prevDays: number = this.daysInMonth(prev[0], prev[1])
    let i: number = 0
    while (i < lead) {
      const day = prevDays - (lead - 1 - i)
      const iso = `${prev[0]}-${prev[1].toString().padStart(2,'0')}-${day.toString().padStart(2,'0')}`
      const cnt = this.countForDate(iso)
      cells.push(new DayInfo(iso, 0, cnt[0], cnt[1])); i = i + 1
    }
    let d: number = 1
    while (d <= dim) {
      const iso = `${this.year}-${this.month.toString().padStart(2,'0')}-${d.toString().padStart(2,'0')}`
      const cnt = this.countForDate(iso)
      cells.push(new DayInfo(iso, 1, cnt[0], cnt[1])); d = d + 1
    }
    const remain: number = 42 - cells.length
    const next = this.nextMonth(this.year, this.month)
    let nd: number = 1; let r: number = 0
    while (r < remain) {
      const iso = `${next[0]}-${next[1].toString().padStart(2,'0')}-${nd.toString().padStart(2,'0')}`
      const cnt = this.countForDate(iso)
      cells.push(new DayInfo(iso, 0, cnt[0], cnt[1])); nd = nd + 1; r = r + 1
    }
    return cells
  }

  private cellsAtRow(row: number): Array<DayInfo> {
    const all: Array<DayInfo> = this.buildCells()
    const out: Array<DayInfo> = []
    let i: number = row * 7
    while (i < row * 7 + 7) { out.push(all[i]); i = i + 1 }
    return out
  }

  private plantNameById(id: number): string {
    let i: number = 0
    while (i < this.plants.length) { if (this.plants[i].id === id) { return this.plants[i].name } i = i + 1 }
    return ''
  }

  private currentDateForList(): string {
    if (this.focusDate.length > 0) { return this.focusDate }
    if (this.quickDate.length > 0) { return this.quickDate }
    return ''
  }

  private dayTasks(dateISO: string): Array<PlantTask> {
    const out: Array<PlantTask> = []
    let i: number = 0
    while (i < this.tasks.length) {
      const t = this.tasks[i]
      if (t.planDate === dateISO && this.filterTypesOk(t.type) && this.matchDoneState(t.done)) {
        out.push(t)
      }
      i = i + 1
    }
    // 简单排序：未完成在前、已完成在后，同类按 id 逆序
    out.sort((a: PlantTask, b: PlantTask) => {
      if (a.done !== b.done) { return a.done - b.done } // 0 在前
      return b.id - a.id
    })
    return out
  }

  private cellBg(d: DayInfo): ResourceColor {
    if (this.focusDate.length > 0) {
      if (d.dateISO === this.focusDate) { return 0xFFE3F2FD }
      return 0x00FFFFFF
    }
    if (d.inMonth === 0) { return 0x00FFFFFF }
    if (d.total > 0) { return 0x10A5D6A7 }
    return 0x00FFFFFF
  }
}
