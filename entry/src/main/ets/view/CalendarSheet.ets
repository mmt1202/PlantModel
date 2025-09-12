import { PlantTask, _DayCell } from "../model/PlantModel"

// 日历内部使用的数据模型（仅本组件内部，不暴露）


@ComponentV2
export struct CalendarSheet {
  /** 传入需要展示的年月（例如 2025 / 9），父层可给当前日期 */
  @Param @Require year: number
  @Param @Require month: number // 1~12
  /** 全量养护任务（PlantTask），父层提供 */
  @Param @Require tasks: Array<PlantTask>
  /** 事件：切换完成状态、删除、关闭 */
  @Event onToggle: (t: PlantTask) => void
  @Event onDelete: (id: number) => void
  @Event onClose: () => void

  // —— 本地状态 —— //
  @Local y: number = 1970
  @Local m: number = 1
  @Local selectedISO: string = ''       // 当前选中日期
  @Local typeFilter: string = '全部'     // 全部/浇水/施肥/修剪
  @Local pressedCellISO: string = ''    // 按压态（用于缩放）

  aboutToAppear(): void {
    // 初始化显示年月与选中日期
    this.y = this.year; this.m = this.month
    this.selectedISO = this.todayISO()
  }

  build() {
    Column() {
      // 蒙层
      Blank().width('100%').height('100%').backgroundColor(0x66000000).onClick(() => { this.onClose() })

      // 抽屉
      Column() {
        // —— 标题：月份切换 —— //
        Row() {
          Text('‹').fontSize(20).fontColor(0xFF1565C0)
            .onClick(() => { this.prevMonth() })
          Text(this.monthTitle(this.y, this.m))
            .fontSize(16).fontWeight(FontWeight.Medium).fontColor(0xFF263238)
            .margin({ left: 10, right: 10 })
          Text('›').fontSize(20).fontColor(0xFF1565C0)
            .onClick(() => { this.nextMonth() })
          Blank()
          Text('✕').fontSize(18).onClick(() => { this.onClose() })
        }.padding({ left: 16, right: 16, top: 12, bottom: 6 })

        // —— 周标题 —— //
        Row() {
          this.WeekLabel('日'); this.WeekLabel('一'); this.WeekLabel('二'); this.WeekLabel('三'); this.WeekLabel('四'); this.WeekLabel('五'); this.WeekLabel('六')
        }.padding({ left: 12, right: 12, bottom: 4 })

        // —— 日历网格（6×7） —— //
        Column() {
          ForEach(this.rows(), (row: Array<_DayCell>) => {
            Row() {
              ForEach(row, (d: _DayCell) => {
                this.DayCell(d)
              }, (d: _DayCell) => d.key)
            }.padding({ left: 10, right: 10, top: 4, bottom: 4 })
          }, (_: Array<_DayCell>, idx: number) => `r${idx}`)
        }

        // —— 类型筛选 —— //
        Row() {
          this.TypeChip('全部')
          this.TypeChip('浇水')
          this.TypeChip('施肥')
          this.TypeChip('修剪')
        }.padding({ left: 16, right: 16, top: 6, bottom: 6 })

        // —— 当日清单 —— //
        Column() {
          Text(this.selectedTitle()).fontSize(12).fontColor(0xFF607D8B).margin({ bottom: 6 })
          if (this.filteredTasksBySelected().length === 0) {
            Text('这一天暂无记录').fontSize(13).fontColor(0xFF90A4AE)
          } else {
            List({ space: 8 }) {
              ForEach(this.filteredTasksBySelected(), (t: PlantTask) => {
                ListItem() { this.TaskRow(t) }
              }, (t: PlantTask) => t.id.toString())
            }.edgeEffect(EdgeEffect.Spring)
          }
        }
        .padding({ left: 16, right: 16, bottom: 16, top: 6 })
      }
      .width('100%').backgroundColor(0xFFFFFFFF)
      .borderRadius({ topLeft: 20, topRight: 20, bottomLeft: 0, bottomRight: 0 })
      .position({ x: 0, y: 'calc(100% - 82%)' })
      .shadow({ radius: 24, color: 0x33000000, offsetX: 0, offsetY: -6 })
      .animation({ duration: 200, curve: Curve.Sharp })
    }
    .width('100%').height('100%')
  }

  /** —— 子区域：周标题 —— */
  @Builder
  WeekLabel(t: string) {
    Text(t)
      .width('14.28%')
      .fontSize(12).fontColor(0xFF78909C)
      .textAlign(TextAlign.Center)
  }

  /** —— 子区域：日单元 —— */
  @Builder
  DayCell(d: _DayCell) {
    // 视觉：非当月弱化，选中描边、今日圆点、按压缩放
    Column() {
      // 数字 + 今日点
      Row() {
        if (d.day > 0) {
          Text(d.day.toString())
            .fontSize(14)
            .fontColor(this.cellNumberColor(d))
            .fontWeight(this.isSelected(d) ? FontWeight.Medium : FontWeight.Regular)
        } else {
          Text('').fontSize(14)
        }
        if (d.isToday === 1) {
          Text('•').fontSize(14).fontColor(0xFF2E7D32).margin({ left: 4 })
        }
      }.justifyContent(FlexAlign.Center)

      // 当日任务计数（小圆点组）
      Row() {
        ForEach(this.indicatorDots(d.iso), (_: number, idx: number) => {
          // 最多 3 个点
          if (idx < 3) {
            Blank().width(6).height(6).borderRadius(3).backgroundColor(0xFF66BB6A).margin({ left: idx === 0 ? 0 : 4 })
          }
        }, (_: number, idx: number) => `dot${idx}`)
      }
      .margin({ top: 6 })
      .justifyContent(FlexAlign.Center)
    }
    .width('14.28%').height(50)
    .borderRadius(10)
    .backgroundColor(this.isSelected(d) ? 0xFFE8F5E9 : 0xFFFFFFFF)
    .shadow({ radius: this.isSelected(d) ? 8 : 0, color: 0x12000000, offsetX: 0, offsetY: this.isSelected(d) ? 2 : 0 })
    .scale(this.pressedCellISO === d.iso && d.iso.length > 0 ? { x: 0.96, y: 0.96 } : { x: 1, y: 1 })
    .onTouch((e: TouchEvent) => {
      if (d.iso.length === 0) { return }
      if (e.type === TouchType.Down) { this.pressedCellISO = d.iso }
      if (e.type === TouchType.Up || e.type === TouchType.Cancel) { this.pressedCellISO = '' }
    })
    .onClick(() => {
      if (d.iso.length === 0) { return }
      this.selectedISO = d.iso
    })
    .animation({ duration: 100, curve: Curve.EaseInOut })
  }

  /** —— 子区域：类型筛选 Chip —— */
  @Builder
  TypeChip(label: string) {
    Text(label)
      .fontSize(12)
      .fontColor(this.typeFilter === label ? 0xFF2E7D32 : 0xFF607D8B)
      .padding({ left: 10, right: 10, top: 6, bottom: 6 })
      .borderRadius(12)
      .backgroundColor(this.typeFilter === label ? 0xFFE8F5E9 : 0xFFFFFFFF)
      .onClick(() => { this.typeFilter = label })
      .margin({ right: 8 })
  }

  /** —— 子区域：当日条目行 —— */
  @Builder
  TaskRow(t: PlantTask) {
    Row() {
      Text(t.done === 1 ? '✅' : '⬜').fontSize(20).onClick(() => { this.onToggle(t) })
      Column() {
        Text(`${t.type} · ${this.dateTitle(t.planDate)}`)
          .fontSize(15).fontWeight(FontWeight.Medium).fontColor(0xFF263238)
        if (t.done === 1) {
          Text('已完成').fontSize(12).fontColor(0xFF607D8B).margin({ top: 2 })
        } else {
          Text('未完成').fontSize(12).fontColor(0xFF607D8B).margin({ top: 2 })
        }
      }.margin({ left: 10 })
      Blank()
      Text('删除').fontSize(12).fontColor(0xFFE53935).onClick(() => { this.onDelete(t.id) })
    }
    .padding(12).borderRadius(12).backgroundColor(0xFFFFFFFF)
    .shadow({ radius: 10, color: 0x14000000, offsetX: 0, offsetY: 3 })
  }

  // ================= 逻辑（非 UI） =================

  private monthTitle(y: number, m: number): string {
    return `${y} 年 ${m.toString().padStart(2, '0')} 月`
  }

  private dateTitle(iso: string): string {
    return iso.length > 0 ? iso : ''
  }

  private isSelected(d: _DayCell): boolean {
    if (d.iso.length === 0) { return false }
    return this.selectedISO === d.iso
  }

  private cellNumberColor(d: _DayCell): ResourceColor {
    if (d.iso.length === 0) { return 0xFFCFD8DC }
    if (this.isSelected(d)) { return 0xFF1B5E20 }
    if (d.inMonth === 1) { return 0xFF263238 }
    return 0xFFB0BEC5
  }

  // 构造 6×7 网格（周日为 0）
  private rows(): Array<Array<_DayCell>> {
    const arr: Array<_DayCell> = this.buildFlatGrid(this.y, this.m)
    // 切成 6 行
    const rows: Array<Array<_DayCell>> = []
    let i: number = 0
    while (i < 6) {
      const start: number = i * 7
      const row: Array<_DayCell> = []
      let j: number = 0
      while (j < 7) { row.push(arr[start + j]); j = j + 1 }
      rows.push(row)
      i = i + 1
    }
    return rows
  }

  // 一维 42 个单元（包含前后月占位）
  private buildFlatGrid(y: number, m: number): Array<_DayCell> {
    const days: number = this.daysInMonth(y, m)
    const wd: number = this.firstWeekday(y, m) // 0~6 (Sun)
    const out: Array<_DayCell> = []
    // 前导空白
    let i: number = 0
    while (i < wd) { out.push(new _DayCell(`lead${i}`, 0, 0, '', 0)); i = i + 1 }
    // 本月日期
    let d: number = 1
    while (d <= days) {
      const iso: string = this.isoFor(y, m, d)
      out.push(new _DayCell(`d${d}`, d, 1, iso, this.isTodayISO(iso) ? 1 : 0))
      d = d + 1
    }
    // 尾部补齐到 42
    while (out.length < 42) { out.push(new _DayCell(`tail${out.length}`, 0, 0, '', 0)) }
    return out
  }

  private firstWeekday(y: number, m: number): number {
    // JS Date: 月份 0~11
    const dt = new Date(y, m - 1, 1)
    return dt.getDay() // 0~6 (Sun=0)
  }

  private daysInMonth(y: number, m: number): number {
    // 下月 0 号 = 本月最后一天
    return new Date(y, m, 0).getDate()
  }

  private isoFor(y: number, m: number, d: number): string {
    const mm: string = m.toString().padStart(2, '0'); const dd: string = d.toString().padStart(2, '0')
    return `${y}-${mm}-${dd}`
  }

  private todayISO(): string {
    const now = new Date()
    const y = now.getFullYear(); const m = (now.getMonth() + 1).toString().padStart(2, '0'); const d = now.getDate().toString().padStart(2, '0')
    return `${y}-${m}-${d}`
  }

  private isTodayISO(iso: string): boolean {
    if (iso.length === 0) { return false }
    return iso === this.todayISO()
  }

  // 指示点：返回一个长度 = 当日条目数的数组（仅用于 ForEach 生成 ≤3 个点）
  private indicatorDots(iso: string): Array<number> {
    if (iso.length === 0) { return [] }
    const list: Array<PlantTask> = this.tasksOnDate(iso)
    const out: Array<number> = []
    let i: number = 0
    while (i < list.length) { out.push(i); i = i + 1 }
    return out
  }

  private tasksOnDate(iso: string): Array<PlantTask> {
    const out: Array<PlantTask> = []
    let i: number = 0
    while (i < this.tasks.length) {
      const t: PlantTask = this.tasks[i]
      if (t.planDate === iso) { out.push(t) }
      i = i + 1
    }
    return out
  }

  private filteredTasksBySelected(): Array<PlantTask> {
    const list: Array<PlantTask> = this.tasksOnDate(this.selectedISO)
    if (this.typeFilter === '全部') { return list }
    const out: Array<PlantTask> = []
    let i: number = 0
    while (i < list.length) {
      if (list[i].type === this.typeFilter) { out.push(list[i]) }
      i = i + 1
    }
    return out
  }

  // 月份切换
  private prevMonth(): void {
    let ny: number = this.y; let nm: number = this.m - 1
    if (nm < 1) { nm = 12; ny = ny - 1 }
    this.y = ny; this.m = nm
    // 如果当前选中日期不在新月，默认选中该月 1 号
    const firstISO: string = this.isoFor(this.y, this.m, 1)
    this.selectedISO = firstISO
  }

  private nextMonth(): void {
    let ny: number = this.y; let nm: number = this.m + 1
    if (nm > 12) { nm = 1; ny = ny + 1 }
    this.y = ny; this.m = nm
    const firstISO: string = this.isoFor(this.y, this.m, 1)
    this.selectedISO = firstISO
  }

  private selectedTitle(): string {
    if (this.selectedISO.length === 0) { return '' }
    return `日期：${this.selectedISO} · 类型：${this.typeFilter}`
  }
}
