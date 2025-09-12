// ================== 内部日格数据模型 ==================
import { _DayCell, PlantTask } from '../model/PlantModel'


// ================== 核心：CalendarView（两种模式共用） ==================
@ComponentV2
export struct CalendarView {
  /** 模式：true = 抽屉（带蒙层），false = 内嵌 */
  @Param showAsSheet: boolean = false
  /** 传入需要展示的年月（例如 2025 / 9） */
  @Param @Require year: number
  @Param @Require month: number // 1~12
  /** 全量养护条目（PlantTask），由父层提供 */
  @Param @Require tasks: Array<PlantTask>
  /** 事件：完成切换、删除，sheet 模式下还需 onClose */
  @Event onToggle: (t: PlantTask) => void
  @Event onDelete: (id: number) => void
  @Event onClose: () => void
  // —— 本地状态 —— //
  @Local y: number = 1970
  @Local m: number = 1
  @Local selectedISO: string = ''
  @Local typeFilter: string = ''
  @Local pressedCellISO: string = ''

  aboutToAppear(): void {
    this.y = this.year
    this.m = this.month
    this.selectedISO = this.todayISO()
  }

  build() {
    if (this.showAsSheet) {
      // ===== 抽屉模式：有蒙层、底部弹出 =====
      Column() {
        Blank().width('100%').height('100%').backgroundColor(0x66000000).onClick(() => {
          this.onClose()
        })
        Column(){
          this.SheetBody()
        }
          .width('100%')
          .backgroundColor(0xFFFFFFFF)
          .borderRadius({
            topLeft: 20,
            topRight: 20,
            bottomLeft: 0,
            bottomRight: 0
          })
          .position({ x: 0, y: 'calc(100% - 82%)' })
          .shadow({
            radius: 24,
            color: 0x33000000,
            offsetX: 0,
            offsetY: -6
          })
          .animation({ duration: 200, curve: Curve.Sharp })
      }
      .width('100%').height('100%')
    } else {
      // ===== 内嵌模式：直接铺在父级布局里 =====
      Column(){
        this.SheetBody()
      }
        .width('100%')
        .backgroundColor(0xFFFFFFFF)
        .borderRadius(16)
        .shadow({
          radius: 16,
          color: 0x14000000,
          offsetX: 0,
          offsetY: 4
        })
        .padding({ bottom: 6 })
    }
  }

  /** ======== 公用主体：标题/网格/筛选/当日清单 ======== */
  @Builder
  SheetBody() {
    Column() {
      // 标题与切月（内嵌/抽屉共用）
      Row() {
        Text('‹').fontSize(20).fontColor(0xFF1565C0).onClick(() => {
          this.prevMonth()
        })
        Text(this.monthTitle(this.y, this.m))
          .fontSize(16).fontWeight(FontWeight.Medium).fontColor(0xFF263238)
          .margin({ left: 10, right: 10 })
        Text('›').fontSize(20).fontColor(0xFF1565C0).onClick(() => {
          this.nextMonth()
        })
        Blank()
        if (this.showAsSheet) {
          Text('✕').fontSize(18).onClick(() => {
            this.onClose()
          })
        }
      }
      .padding({
        left: 16,
        right: 16,
        top: 12,
        bottom: 6
      })

      // 周标题
      Row() {
        this.WeekLabel('日');
        this.WeekLabel('一');
        this.WeekLabel('二');
        this.WeekLabel('三');
        this.WeekLabel('四');
        this.WeekLabel('五');
        this.WeekLabel('六')
      }.padding({ left: 12, right: 12, bottom: 4 })

      // 6×7 网格
      Column() {
        ForEach(this.rows(), (row: Array<_DayCell>) => {
          Row() {
            ForEach(row, (d: _DayCell) => {
              this.DayCell(d)
            }, (d: _DayCell) => d.key)
          }
          .padding({
            left: 10,
            right: 10,
            top: 4,
            bottom: 4
          })
        }, (_: Array<_DayCell>, idx: number) => `r${idx}`)
      }

      // 类型筛选
      Row() {
        this.TypeChip('全部');
        this.TypeChip('浇水');
        this.TypeChip('施肥');
        this.TypeChip('修剪')
      }
      .padding({
        left: 16,
        right: 16,
        top: 6,
        bottom: 6
      })

      // 当日清单
      Column() {
        Text(this.selectedTitle()).fontSize(12).fontColor(0xFF607D8B).margin({ bottom: 6 })
        if (this.filteredTasksBySelected().length === 0) {
          Text('这一天暂无记录').fontSize(13).fontColor(0xFF90A4AE)
        } else {
          List({ space: 8 }) {
            ForEach(this.filteredTasksBySelected(), (t: PlantTask) => {
              ListItem() {
                this.TaskRow(t)
              }
            }, (t: PlantTask) => t.id.toString())
          }.edgeEffect(EdgeEffect.Spring)
        }
      }
      .padding({
        left: 16,
        right: 16,
        bottom: 16,
        top: 6
      })
    }
  }

  /** —— 子区域 —— */
  @Builder
  WeekLabel(t: string) {
    Text(t).width('14.28%').fontSize(12).fontColor(0xFF78909C).textAlign(TextAlign.Center)
  }

  @Builder
  DayCell(d: _DayCell) {
    Column() {
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

      Row() {
        ForEach(this.indicatorDots(d.iso), (_: number, idx: number) => {
          if (idx < 3) {
            Blank()
              .width(6)
              .height(6)
              .borderRadius(3)
              .backgroundColor(0xFF66BB6A)
              .margin({ left: idx === 0 ? 0 : 4 })
          }
        }, (_: number, idx: number) => `dot${idx}`)
      }
      .margin({ top: 6 }).justifyContent(FlexAlign.Center)
    }
    .width('14.28%')
    .height(50)
    .borderRadius(10)
    .backgroundColor(this.isSelected(d) ? 0xFFE8F5E9 : 0xFFFFFFFF)
    .shadow({
      radius: this.isSelected(d) ? 8 : 0,
      color: 0x12000000,
      offsetX: 0,
      offsetY: this.isSelected(d) ? 2 : 0
    })
    .scale(this.pressedCellISO === d.iso && d.iso.length > 0 ? { x: 0.96, y: 0.96 } : { x: 1, y: 1 })
    .onTouch((e: TouchEvent) => {
      if (d.iso.length === 0) {
        return
      }
      if (e.type === TouchType.Down) {
        this.pressedCellISO = d.iso
      }
      if (e.type === TouchType.Up || e.type === TouchType.Cancel) {
        this.pressedCellISO = ''
      }
    })
    .onClick(() => {
      if (d.iso.length > 0) {
        this.selectedISO = d.iso
      }
    })
    .animation({ duration: 100, curve: Curve.EaseInOut })
  }

  @Builder
  TypeChip(label: string) {
    Text(label)
      .fontSize(12)
      .fontColor(this.typeFilter === label ? 0xFF2E7D32 : 0xFF607D8B)
      .padding({
        left: 10,
        right: 10,
        top: 6,
        bottom: 6
      })
      .borderRadius(12)
      .backgroundColor(this.typeFilter === label ? 0xFFE8F5E9 : 0xFFFFFFFF)
      .onClick(() => {
        animateTo({ duration: 120, curve: Curve.EaseInOut }, () => { this.typeFilter = label})

      })
      .margin({ right: 8 })
  }

  @Builder
  TaskRow(t: PlantTask) {
    Row() {
      Text(t.done === 1 ? '✅' : '⬜').fontSize(20).onClick(() => {
        this.onToggle(t)
      })
      Column() {
        Text(`${t.type} · ${this.dateTitle(t.planDate)}`)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(0xFF263238)
        if (t.done === 1) {
          Text('已完成').fontSize(12).fontColor(0xFF607D8B).margin({ top: 2 })
        } else {
          Text('未完成').fontSize(12).fontColor(0xFF607D8B).margin({ top: 2 })
        }
      }.margin({ left: 10 })

      Blank()
      Text('删除').fontSize(12).fontColor(0xFFE53935).onClick(() => {
        this.onDelete(t.id)
      })
    }
    .padding(12).borderRadius(12).backgroundColor(0xFFFFFFFF)
    .shadow({
      radius: 10,
      color: 0x14000000,
      offsetX: 0,
      offsetY: 3
    })
  }

  /** —— 逻辑 —— */
  private monthTitle(y: number, m: number): string {
    return `${y} 年 ${m.toString().padStart(2, '0')} 月`
  }

  private dateTitle(iso: string): string {
    return iso
  }

  private isSelected(d: _DayCell): boolean {
    return d.iso.length > 0 && this.selectedISO === d.iso
  }

  private cellNumberColor(d: _DayCell): ResourceColor {
    if (d.iso.length === 0) {
      return 0xFFCFD8DC
    }
    if (this.isSelected(d)) {
      return 0xFF1B5E20
    }
    if (d.inMonth === 1) {
      return 0xFF263238
    }
    return 0xFFB0BEC5
  }

  private rows(): Array<Array<_DayCell>> {
    const arr: Array<_DayCell> = this.buildFlatGrid(this.y, this.m)
    const rows: Array<Array<_DayCell>> = []
    let i: number = 0
    while (i < 6) {
      const start: number = i * 7
      const row: Array<_DayCell> = []
      let j: number = 0
      while (j < 7) {
        row.push(arr[start + j]);
        j = j + 1
      }
      rows.push(row)
      i = i + 1
    }
    return rows
  }

  private buildFlatGrid(y: number, m: number): Array<_DayCell> {
    const days: number = this.daysInMonth(y, m)
    const wd: number = this.firstWeekday(y, m) // 0~6
    const out: Array<_DayCell> = []
    let i: number = 0
    while (i < wd) {
      out.push(new _DayCell(`lead${i}`, 0, 0, '', 0));
      i = i + 1
    }
    let d: number = 1
    while (d <= days) {
      const iso: string = this.isoFor(y, m, d)
      out.push(new _DayCell(`d${d}`, d, 1, iso, this.isTodayISO(iso) ? 1 : 0))
      d = d + 1
    }
    while (out.length < 42) {
      out.push(new _DayCell(`tail${out.length}`, 0, 0, '', 0))
    }
    return out
  }

  private firstWeekday(y: number, m: number): number {
    return new Date(y, m - 1, 1).getDay()
  }

  private daysInMonth(y: number, m: number): number {
    return new Date(y, m, 0).getDate()
  }

  private isoFor(y: number, m: number, d: number): string {
    const mm: string = m.toString().padStart(2, '0');
    const dd: string = d.toString().padStart(2, '0')
    return `${y}-${mm}-${dd}`
  }

  private todayISO(): string {
    const now = new Date()
    const y = now.getFullYear();
    const m = (now.getMonth() + 1).toString().padStart(2, '0');
    const d = now.getDate().toString().padStart(2, '0')
    return `${y}-${m}-${d}`
  }

  private isTodayISO(iso: string): boolean {
    return iso.length > 0 && iso === this.todayISO()
  }

  private indicatorDots(iso: string): Array<number> {
    if (iso.length === 0) {
      return []
    }
    const list: Array<PlantTask> = this.tasksOnDate(iso)
    const out: Array<number> = []
    let i: number = 0
    while (i < list.length) {
      out.push(i);
      i = i + 1
    }
    return out
  }

  private tasksOnDate(iso: string): Array<PlantTask> {
    const out: Array<PlantTask> = []
    let i: number = 0
    while (i < this.tasks.length) {
      const t: PlantTask = this.tasks[i]
      if (t.planDate === iso) {
        out.push(t)
      }
      i = i + 1
    }
    return out
  }

  private filteredTasksBySelected(): Array<PlantTask> {
    const list: Array<PlantTask> = this.tasksOnDate(this.selectedISO)
    if (this.typeFilter === '全部') {
      return list
    }
    const out: Array<PlantTask> = []
    let i: number = 0
    while (i < list.length) {
      if (list[i].type === this.typeFilter) {
        out.push(list[i])
      }
      i = i + 1
    }
    return out
  }

  private prevMonth(): void {
    let ny: number = this.y;
    let nm: number = this.m - 1
    if (nm < 1) {
      nm = 12;
      ny = ny - 1
    }
    this.y = ny;
    this.m = nm
    this.selectedISO = this.isoFor(this.y, this.m, 1)
  }

  private nextMonth(): void {
    let ny: number = this.y;
    let nm: number = this.m + 1
    if (nm > 12) {
      nm = 1;
      ny = ny + 1
    }
    this.y = ny;
    this.m = nm
    this.selectedISO = this.isoFor(this.y, this.m, 1)
  }

  private selectedTitle(): string {
    if (this.selectedISO.length === 0) {
      return ''
    }
    return `日期：${this.selectedISO} · 类型：${this.typeFilter}`
  }
}

// ================== 包装 1：CalendarGrid（内嵌） ==================
@ComponentV2
export struct CalendarGrid {
  @Param @Require year: number
  @Param @Require month: number
  @Param @Require tasks: Array<PlantTask>
  @Event onToggle: (t: PlantTask) => void
  @Event onDelete: (id: number) => void

  build() {
    CalendarView({
      showAsSheet: false,
      year: this.year,
      month: this.month,
      tasks: this.tasks,
      onToggle: (t: PlantTask) => {
        this.onToggle(t)
      },
      onDelete: (id: number) => {
        this.onDelete(id)
      },
      onClose: () => {
      } // 内嵌模式无需关闭
    })
  }
}

// ================== 包装 2：CalendarSheet（抽屉） ==================
@ComponentV2
export struct CalendarSheet {
  @Param @Require year: number
  @Param @Require month: number
  @Param @Require tasks: Array<PlantTask>
  @Event onToggle: (t: PlantTask) => void
  @Event onDelete: (id: number) => void
  @Event onClose: () => void

  build() {
    CalendarView({
      showAsSheet: true,
      year: this.year,
      month: this.month,
      tasks: this.tasks,
      onToggle: (t: PlantTask) => {
        this.onToggle(t)
      },
      onDelete: (id: number) => {
        this.onDelete(id)
      },
      onClose: () => {
        this.onClose()
      }
    })
  }
}





