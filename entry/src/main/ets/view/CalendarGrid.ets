import { Plant, PlantTask } from "../model/PlantModel"

/** -------- 子组件：月历网格（V2） -------- */
@ComponentV2
export struct CalendarGrid {
  @Param @Require monthISO: string // YYYY-MM
  @Param @Require tasks: Array<PlantTask>
  @Param @Require plants: Array<Plant>
  @Event onPrev: () => void
  @Event onNext: () => void
  @Event onToggle: (t: PlantTask) => void
  @Event onDeleteAsk: (taskId: number) => void

  @Local selectedDateISO: string = ''

  aboutToAppear(): void {
    if (this.selectedDateISO.length === 0) {
      const arr: Array<string> = this.monthISO.split('-')
      const y: number = Number.parseInt(arr[0]); const m: number = Number.parseInt(arr[1])
      const first = new Date(y, m - 1, 1)
      const y0: number = first.getFullYear()
      const m0: string = (first.getMonth() + 1).toString().padStart(2, '0')
      this.selectedDateISO = `${y0}-${m0}-01`
    }
  }

  // ---------- 非 @Builder 计算逻辑 ----------
  private daysInMonth(): number {
    const arr: Array<string> = this.monthISO.split('-')
    const y: number = Number.parseInt(arr[0]); const m: number = Number.parseInt(arr[1])
    return new Date(y, m, 0).getDate()
  }

  private weekdayOfFirst(): number {
    const arr: Array<string> = this.monthISO.split('-')
    const y: number = Number.parseInt(arr[0]); const m: number = Number.parseInt(arr[1])
    return new Date(y, m - 1, 1).getDay() // 0~6
  }

  // 生成 6x7 的日期矩阵（用 0 代表空白），供 ForEach 渲染
  private monthMatrix(): Array<Array<number>> {
    const lead: number = this.weekdayOfFirst()
    const days: number = this.daysInMonth()
    const out: Array<Array<number>> = []
    let r: number = 0
    while (r < 6) {
      const row: Array<number> = []
      let c: number = 0
      while (c < 7) {
        const idx: number = r * 7 + c
        if (idx < lead || idx >= lead + days) { row.push(0) } else { row.push(idx - lead + 1) }
        c = c + 1
      }
      out.push(row)
      r = r + 1
    }
    return out
  }

  private monthTitle(): string {
    const arr: Array<string> = this.monthISO.split('-')
    return `${arr[0]}年${Number.parseInt(arr[1])}月`
  }

  private dateISOOfDay(day: number): string {
    const arr: Array<string> = this.monthISO.split('-')
    const dd: string = day.toString().padStart(2, '0')
    return `${arr[0]}-${arr[1]}-${dd}`
  }

  private isSelectedDay(day: number): boolean {
    return this.selectedDateISO === this.dateISOOfDay(day)
  }

  private countTasksAt(day: number): number {
    const d: string = this.dateISOOfDay(day)
    let i: number = 0; let cnt: number = 0
    while (i < this.tasks.length) {
      if (this.tasks[i].planDate === d) { cnt = cnt + 1 }
      i = i + 1
    }
    return cnt
  }

  private plantNameById(id: number): string {
    let i: number = 0
    while (i < this.plants.length) {
      if (this.plants[i].id === id) { return this.plants[i].name }
      i = i + 1
    }
    return '未知植物'
  }

  // ---------- 视图 ----------
  build() {
    Column() {
      // 月份标题与切换
      Row() {
        Text('〈').fontSize(18).onClick(() => { this.onPrev() })
        Text(this.monthTitle()).fontSize(16).fontWeight(FontWeight.Medium).fontColor(0xFF263238).margin({ left: 10, right: 10 })
        Text('〉').fontSize(18).onClick(() => { this.onNext() })
      }
      .justifyContent(FlexAlign.Center)
      .padding({ top: 6, bottom: 6 })

      // 星期标题
      Row() {
        this.WeekCell('日'); this.WeekCell('一'); this.WeekCell('二'); this.WeekCell('三'); this.WeekCell('四'); this.WeekCell('五'); this.WeekCell('六')
      }.padding({ left: 10, right: 10, bottom: 4 })

      // ✅ 用 ForEach 渲染 6 行周视图；Builder 里不出现 let/while
      this.WeeksGrid()

      // 选中日的任务列表
      Column() {
        Text('当日任务').fontSize(14).fontWeight(FontWeight.Medium).fontColor(0xFF263238).margin({ bottom: 6 })
        // const list: Array<PlantTask> = this.tasks // 这里只是引用，不做计算
        if (this.countTasksAtDayISO(this.selectedDateISO) === 0) {
          Text('这一天没有任务').fontSize(12).fontColor(0xFF90A4AE)
        } else {
          List({ space: 6 }) {
            ForEach(this.tasksOfISO(this.selectedDateISO), (t: PlantTask) => {
              ListItem() {
                Row() {
                  Text(t.done === 1 ? '✅' : '⬜').fontSize(18).onClick(() => { this.onToggle(t) })
                  Text(`${t.type} · ${this.plantNameById(t.plantId)}`).fontSize(13).fontColor(0xFF263238).margin({ left: 8 })
                  Blank()
                  Text('删').fontSize(13).fontColor(0xFFE53935).onClick(() => { this.onDeleteAsk(t.id) })
                }
                .padding(8).borderRadius(10).backgroundColor(0xFFFFFFFF).shadow({ radius: 10, color: 0x12000000, offsetX: 0, offsetY: 2 })
              }
            }, (t: PlantTask) => t.id.toString())
          }
        }
      }
      .padding({ left: 12, right: 12, top: 10, bottom: 8 })
    }
    .padding({ left: 8, right: 8 })
  }

  // 供上面“当日任务”使用的纯计算方法（非 Builder）
  private tasksOfISO(dateISO: string): Array<PlantTask> {
    let res: Array<PlantTask> = []
    let i: number = 0
    while (i < this.tasks.length) {
      if (this.tasks[i].planDate === dateISO) { res.push(this.tasks[i]) }
      i = i + 1
    }
    return res
  }
  private countTasksAtDayISO(dateISO: string): number {
    let i: number = 0; let cnt: number = 0
    while (i < this.tasks.length) { if (this.tasks[i].planDate === dateISO) { cnt = cnt + 1 } i = i + 1 }
    return cnt
  }

  @Builder
  WeeksGrid() {
    // 在 Builder 中只做 UI：对 monthMatrix() 的结果用 ForEach 渲染
    ForEach(this.monthMatrix(), (week: Array<number>, r?: number) => {
      Row() {
        ForEach(week, (d: number, c?: number) => {
          if (d === 0) {
            Blank().width('14.28%').height(42).borderRadius(8).backgroundColor(0x00FFFFFF)
          } else {
            this.DayCell(d)
          }
        }, (d: number, c?: number) => `cell-${r ?? 0}-${c ?? 0}`)
      }
      .padding({ left: 10, right: 10, top: 4, bottom: 4 })
    }, (week: Array<number>, r?: number) => `row-${r ?? 0}`)
  }

  @Builder
  WeekCell(text: string) {
    Row() {
      Text(text).fontSize(12).fontColor(0xFF607D8B)
    }.width('14.28%').justifyContent(FlexAlign.Center)
  }

  @Builder
  DayCell(day: number) {
    // Builder 内不声明变量，所有判断通过方法调用完成
    Column() {
      Text(day.toString())
        .fontSize(13)
        .fontColor(this.isSelectedDay(day) ? 0xFFFFFFFF : 0xFF263238)
      if (this.countTasksAt(day) > 0) {
        Text(this.countTasksAt(day).toString())
          .fontSize(10)
          .fontColor(this.isSelectedDay(day) ? 0xFFFFFFFF : 0xFF1565C0)
      }
    }
    .width('14.28%').height(42).borderRadius(8)
    .backgroundColor(this.isSelectedDay(day) ? 0xFF2E7D32 : 0xFFFFFFFF)
    .shadow({ radius: this.isSelectedDay(day) ? 10 : 6, color: 0x11000000, offsetX: 0, offsetY: 2 })
    .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
    .onClick(() => { this.selectedDateISO = this.dateISOOfDay(day) })
  }
}