import { McBarChart, Options } from '@mcui/mccharts'
import { Plant, PlantTask } from '../model/PlantModel'

@ComponentV2
export struct StatsPage {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Param @Require plants: Array<Plant>
  @Param @Require tasks: Array<PlantTask>
  @Event onReloadAll: () => void
  @Event onOpenMixPlanner: (p:Plant)=>void
  @Local weekOption: Options = new Options({
    title: {
      show: true,
      text: '近7天完成数',
      right: 16,
      top: 16
    },
    grid: {
      left: 28,
      top: 48,
      right: 16,
      bottom: 28
    },
    xAxis: { data: [] as Array<string> },
    yAxis: { name: '次数' },
    legend: { show: true },
    tooltip: { show: true },
    animation: true,
    series: [{ name: '完成', data: [] as Array<number> }]
  })

  aboutToAppear(): void {
    this.refreshWeekOption()
  }

  aboutToRender(): void {
    this.refreshWeekOption()
  }

  private two(n: number): string {
    const s: string = n.toString()
    if (s.length === 1) {
      return '0' + s
    }
    return s
  }

  private todayISO(): string {
    const d = new Date()
    return `${d.getFullYear()}-${this.two(d.getMonth() + 1)}-${this.two(d.getDate())}`
  }

  private isoNDaysAgo(n: number): string {
    const d = new Date()
    d.setDate(d.getDate() - n)
    return `${d.getFullYear()}-${this.two(d.getMonth() + 1)}-${this.two(d.getDate())}`
  }

  private isoFromMs(ms: number): string {
    const d = new Date(ms)
    return `${d.getFullYear()}-${this.two(d.getMonth() + 1)}-${this.two(d.getDate())}`
  }

  private plantCount(): number {
    return this.plants.length
  }

  private taskCount(): number {
    return this.tasks.length
  }

  private doneCount(): number {
    let i: number = 0;
    let c: number = 0
    while (i < this.tasks.length) {
      if (this.tasks[i].done === 1) {
        c = c + 1
      }
      i = i + 1
    }
    return c
  }

  private inProgressCount(): number {
    return this.taskCount() - this.doneCount()
  }

  private overdueCount(): number {
    const td: string = this.todayISO()
    let i: number = 0;
    let c: number = 0
    while (i < this.tasks.length) {
      const t = this.tasks[i]
      if (t.done === 0 && t.planDate < td) {
        c = c + 1
      }
      i = i + 1
    }
    return c
  }

  private next7Count(): number {
    const td: string = this.todayISO()
    const up: string = this.isoNDaysAgo(-7)
    let i: number = 0;
    let c: number = 0
    while (i < this.tasks.length) {
      const t = this.tasks[i]
      if (t.done === 0 && t.planDate >= td && t.planDate <= up) {
        c = c + 1
      }
      i = i + 1
    }
    return c
  }

  private doneLast7(): number {
    const from: string = this.isoNDaysAgo(6)
    const to: string = this.todayISO()
    let i: number = 0;
    let c: number = 0
    while (i < this.tasks.length) {
      const t = this.tasks[i]
      if (t.done === 1) {
        const iso: string = this.isoFromMs(t.doneAt)
        if (iso >= from && iso <= to) {
          c = c + 1
        }
      }
      i = i + 1
    }
    return c
  }

  private streakDays(): number {
    const hasDone = (iso: string): boolean => {
      let i: number = 0
      while (i < this.tasks.length) {
        const t = this.tasks[i]
        if (t.done === 1 && this.isoFromMs(t.doneAt) === iso) {
          return true
        }
        i = i + 1
      }
      return false
    }
    let days: number = 0
    let n: number = 0
    while (n < 365) {
      const iso: string = this.isoNDaysAgo(n)
      if (hasDone(iso)) {
        days = days + 1
      } else {
        break
      }
      n = n + 1
    }
    return days
  }

  private typeCount(tn: string): number {
    let i: number = 0;
    let c: number = 0
    while (i < this.tasks.length) {
      if (this.tasks[i].type === tn) {
        c = c + 1
      }
      i = i + 1
    }
    return c
  }

  private topPlantName(): string {
    const from: string = this.isoNDaysAgo(29)
    let maxCnt: number = 0;
    let maxPid: number = 0
    let p: number = 0
    while (p < this.plants.length) {
      const pid: number = this.plants[p].id
      let i: number = 0;
      let c: number = 0
      while (i < this.tasks.length) {
        const t = this.tasks[i]
        if (t.plantId === pid && t.done === 1) {
          const iso: string = this.isoFromMs(t.doneAt)
          if (iso >= from) {
            c = c + 1
          }
        }
        i = i + 1
      }
      if (c > maxCnt) {
        maxCnt = c;
        maxPid = pid
      }
      p = p + 1
    }
    let j: number = 0
    while (j < this.plants.length) {
      if (this.plants[j].id === maxPid) {
        return this.plants[j].name
      }
      j = j + 1
    }
    return maxCnt > 0 ? '活跃植物' : '—'
  }

  private topPlantCount(): string {
    const name: string = this.topPlantName()
    if (name === '—') {
      return '0'
    }
    const from: string = this.isoNDaysAgo(29)
    let j: number = 0;
    let pid: number = 0
    while (j < this.plants.length) {
      if (this.plants[j].name === name) {
        pid = this.plants[j].id
      }
      j = j + 1
    }
    let i: number = 0;
    let c: number = 0
    while (i < this.tasks.length) {
      const t = this.tasks[i]
      if (t.plantId === pid && t.done === 1) {
        const iso: string = this.isoFromMs(t.doneAt)
        if (iso >= from) {
          c = c + 1
        }
      }
      i = i + 1
    }
    return c.toString()
  }

  private weekLabels(): Array<string> {
    const arr: Array<string> = []
    let i: number = 6
    while (i >= 0) {
      const d = new Date()
      d.setDate(d.getDate() - i)
      arr.push(`${this.two(d.getMonth() + 1)}-${this.two(d.getDate())}`)
      i = i - 1
    }
    return arr
  }

  private weekDoneCounts(): Array<number> {
    const isoArr: Array<string> = []
    let i: number = 6
    while (i >= 0) {
      isoArr.push(this.isoNDaysAgo(i))
      i = i - 1
    }
    const out: Array<number> = []
    let idx: number = 0
    while (idx < isoArr.length) {
      const iso: string = isoArr[idx]
      let c: number = 0
      let k: number = 0
      while (k < this.tasks.length) {
        const t = this.tasks[k]
        if (t.done === 1 && this.isoFromMs(t.doneAt) === iso) {
          c = c + 1
        }
        k = k + 1
      }
      out.push(c)
      idx = idx + 1
    }
    return out
  }

  private refreshWeekOption(): void {
    this.weekOption.setVal({
      title: {
        show: true,
        text: '近7天完成数',
        right: 16,
        top: 16
      },
      xAxis: { data: this.weekLabels() },
      yAxis: { name: '次数' },
      series: [{ name: '完成', data: this.weekDoneCounts() }]
    })
  }

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: 20 }) {
          this.Header()
          this.OverviewCards()
          this.TopPlantCard()
          this.WeekChartCard()
        }
        .padding({ bottom: 32 })
      }
      .layoutWeight(1)
      .edgeEffect(EdgeEffect.Spring)
    }
    .title('数据统计')
    .linearGradient({
      direction: GradientDirection.Top,
      colors: [[0xFFF3E5F5, 0], [0xFFE8EAF6, 0.5], [0xFFE3F2FD, 1.0]]
    })
    .padding({
      top: AppStorage.get<number>('topRectHeight'),
      bottom: AppStorage.get<number>('bottomRectHeight')
    })
  }

  @Builder
  Header() {
    Row() {
      Column() {
        Text('数据统计').fontSize(22).fontWeight(FontWeight.Medium).fontColor(0xFF263238)
        Text('PlantDiary 植物养护').fontSize(14).fontColor(0xFF78909C)
      }
      Blank()
      Button('刷新数据')
        .type(ButtonType.Normal)
        .fontSize(14)
        .fontColor(0xFF673AB7)
        .backgroundColor(0xFFF3E5F5)
        .height(40)
        .onClick(async () => {
          await this.onReloadAll()
          this.refreshWeekOption()
        })
    }
    .padding({ left: 16, right: 16, top: 12, bottom: 8 })
  }

  @Builder
  OverviewCards() {
    Column({ space: 12 }) {
      Row() {
        Text('总体概览').fontSize(18).fontWeight(FontWeight.Medium).fontColor(0xFF263238)
        Blank()
      }

      Grid() {
        GridItem() {
          this.StatCard('🌱 植物数', this.plantCount().toString(), 0xFF4CAF50)
        }
        GridItem() {
          this.StatCard('📋 任务数', this.taskCount().toString(), 0xFF2196F3)
        }
        GridItem() {
          this.StatCard('✅ 完成率', this.taskCount() > 0 ? `${Math.round(this.doneCount() * 100 / this.taskCount())}%` : '0%', 0xFFFF9800)
        }
        GridItem() {
          this.StatCard('⏳ 进行中', this.inProgressCount().toString(), 0xFF9C27B0)
        }
        GridItem() {
          this.StatCard('⚠️ 逾期', this.overdueCount().toString(), 0xFFF44336)
        }
        GridItem() {
          this.StatCard('📅 未来7天', this.next7Count().toString(), 0xFF00BCD4)
        }
        GridItem() {
          this.StatCard('✅ 近7天', this.doneLast7().toString(), 0xFF009688)
        }
        GridItem() {
          this.StatCard('🔥 连续打卡', this.streakDays().toString(), 0xFFFF5722)
        }
      }
      .columnsTemplate('1fr 1fr')
      .columnsGap(12)
      .rowsGap(12)
      .width('100%')
    }
    .padding({ left: 16, right: 16 })
  }

  @Builder
  StatCard(title: string, value: string, color: ResourceColor) {
    Column({ space: 6 }) {
      Text(title).fontSize(13).fontColor(0xFF78909C)
      Text(value).fontSize(24).fontWeight(FontWeight.Bold).fontColor(color)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(0xFFFFFFFF)
    .borderRadius(20)
    .shadow({ radius: 10, color: '#10000000', offsetX: 0, offsetY: 2 })
  }

  @Builder
  TopPlantCard() {
    Column({ space: 16 }) {
      Row() {
        Text('近30天最活跃').fontSize(18).fontWeight(FontWeight.Medium).fontColor(0xFF263238)
        Blank()
      }

      Row({ space: 12 }) {
        Text('🏆').fontSize(32)
        Column({ space: 4 }) {
          Text(this.topPlantName()).fontSize(18).fontWeight(FontWeight.Bold).fontColor(0xFF263238)
          Text(`${this.topPlantCount()} 次完成`).fontSize(14).fontColor(0xFF78909C)
        }
        Blank()
      }
      .width('100%')
      .padding(20)
      .backgroundColor(0xFFFFFFFF)
      .borderRadius(24)
      .shadow({ radius: 12, color: '#11000000', offsetX: 0, offsetY: 2 })
    }
    .padding({ left: 16, right: 16 })
  }

  @Builder
  WeekChartCard() {
    Column({ space: 16 }) {
      Row() {
        Text('近7天趋势').fontSize(18).fontWeight(FontWeight.Medium).fontColor(0xFF263238)
        Blank()
      }

      Column() {
        McBarChart({ options: this.weekOption })
      }
      .height(240)
      .width('100%')
      .backgroundColor(0xFFFFFFFF)
      .borderRadius(24)
      .shadow({ radius: 12, color: '#11000000', offsetX: 0, offsetY: 2 })
    }
    .padding({ left: 16, right: 16 })
  }
}
