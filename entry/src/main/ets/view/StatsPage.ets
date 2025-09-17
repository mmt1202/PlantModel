import { McBarChart, Options } from '@mcui/mccharts'
import { Plant, PlantTask } from '../model/PlantModel'

@ComponentV2
export struct StatsPage {
  @Param @Require plants: Array<Plant>
  @Param @Require tasks: Array<PlantTask>

  // 小图配置
  @Local weekOption: Options = new Options({
    title: { show: true, text: '近7天完成数', right: 16, top: 16 },
    grid: { left: 28, top: 48, right: 16, bottom: 28 },
    xAxis: { data: [] as Array<string> },
    yAxis: { name: '次数' },
    legend: { show: false },
    tooltip: { show: true },
    animation: true,
    series: [{ name: '完成', data: [] as Array<number> }]
  })

  aboutToAppear(): void {
    this.refreshWeekOption()
  }

  aboutToRender(): void {
    // 当父组件传入 tasks 变化时，重算小图
    this.refreshWeekOption()
  }

  // ======= 工具：日期字符串 =======
  private two(n: number): string {
    const s: string = n.toString()
    if (s.length === 1) { return '0' + s }
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

  // ======= 基础统计 =======
  private plantCount(): number {
    return this.plants.length
  }

  private taskCount(): number {
    return this.tasks.length
  }

  private doneCount(): number {
    let i: number = 0; let c: number = 0
    while (i < this.tasks.length) { if (this.tasks[i].done === 1) { c = c + 1 }; i = i + 1 }
    return c
  }

  private inProgressCount(): number {
    return this.taskCount() - this.doneCount()
  }

  // 逾期（计划日 < 今天 且 未完成）
  private overdueCount(): number {
    const td: string = this.todayISO()
    let i: number = 0; let c: number = 0
    while (i < this.tasks.length) {
      const t = this.tasks[i]
      if (t.done === 0 && t.planDate < td) { c = c + 1 }
      i = i + 1
    }
    return c
  }

  // 未来7天（含今天，未完成）
  private next7Count(): number {
    const td: string = this.todayISO()
    const up: string = this.isoNDaysAgo(-7) // 往后7天
    let i: number = 0; let c: number = 0
    while (i < this.tasks.length) {
      const t = this.tasks[i]
      if (t.done === 0 && t.planDate >= td && t.planDate <= up) { c = c + 1 }
      i = i + 1
    }
    return c
  }

  // 近7天完成数（按 doneAt 统计）
  private doneLast7(): number {
    const from: string = this.isoNDaysAgo(6) // 含今天，共7天
    const to: string = this.todayISO()
    let i: number = 0; let c: number = 0
    while (i < this.tasks.length) {
      const t = this.tasks[i]
      if (t.done === 1) {
        const iso: string = this.isoFromMs(t.doneAt)
        if (iso >= from && iso <= to) { c = c + 1 }
      }
      i = i + 1
    }
    return c
  }

  // 连续打卡天数（从今天往回，连续有完成）
  private streakDays(): number {
    // 先做一个 hasDone(iso) 判定
    const hasDone = (iso: string): boolean => {
      let i: number = 0
      while (i < this.tasks.length) {
        const t = this.tasks[i]
        if (t.done === 1 && this.isoFromMs(t.doneAt) === iso) { return true }
        i = i + 1
      }
      return false
    }
    let days: number = 0
    let n: number = 0
    // 最多从今天往回数 365 天以防长循环
    while (n < 365) {
      const iso: string = this.isoNDaysAgo(n)
      if (hasDone(iso)) { days = days + 1 } else { break }
      n = n + 1
    }
    return days
  }

  // 类型分布（按任务总数统计）
  private typeCount(tn: string): number {
    let i: number = 0; let c: number = 0
    while (i < this.tasks.length) { if (this.tasks[i].type === tn) { c = c + 1 } i = i + 1 }
    return c
  }

  // Top 植物（近30天完成最多）
  private topPlantName(): string {
    const from: string = this.isoNDaysAgo(29)
    // 先统计每个 plantId 的近30天完成数
    let maxCnt: number = 0; let maxPid: number = 0
    // 遍历每个植物
    let p: number = 0
    while (p < this.plants.length) {
      const pid: number = this.plants[p].id
      let i: number = 0; let c: number = 0
      while (i < this.tasks.length) {
        const t = this.tasks[i]
        if (t.plantId === pid && t.done === 1) {
          const iso: string = this.isoFromMs(t.doneAt)
          if (iso >= from) { c = c + 1 }
        }
        i = i + 1
      }
      if (c > maxCnt) { maxCnt = c; maxPid = pid }
      p = p + 1
    }
    // 映射名字
    let j: number = 0
    while (j < this.plants.length) { if (this.plants[j].id === maxPid) { return this.plants[j].name } j = j + 1 }
    return maxCnt > 0 ? '活跃植物' : '—'
  }

  private topPlantCount(): string {
    const name: string = this.topPlantName()
    if (name === '—') { return '0' }
    // 重新算一次 count（为了避免在 Builder 里做变量复用）
    const from: string = this.isoNDaysAgo(29)
    let j: number = 0; let pid: number = 0
    while (j < this.plants.length) { if (this.plants[j].name === name) { pid = this.plants[j].id }; j = j + 1 }
    let i: number = 0; let c: number = 0
    while (i < this.tasks.length) {
      const t = this.tasks[i]
      if (t.plantId === pid && t.done === 1) {
        const iso: string = this.isoFromMs(t.doneAt)
        if (iso >= from) { c = c + 1 }
      }
      i = i + 1
    }
    return c.toString()
  }

  // 近7天完成柱状图数据
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
    // 生成近7天 iso 列表
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
        if (t.done === 1 && this.isoFromMs(t.doneAt) === iso) { c = c + 1 }
        k = k + 1
      }
      out.push(c)
      idx = idx + 1
    }
    return out
  }

  private refreshWeekOption(): void {
    this.weekOption.title = { show: true, text: '近7天完成数', right: 16, top: 16 }
    this.weekOption.xAxis = { data: this.weekLabels() }
    this.weekOption.yAxis = { name: '次数' }
    this.weekOption.series = [{ name: '完成', data: this.weekDoneCounts() }]
  }

  // ======= UI =======
  build() {
    Column() {
      // 第一行：总览
      Row() {
        this.Card('植物数', this.plantCount().toString(), 0xFF1B5E20)
        this.Card('任务数', this.taskCount().toString(), 0xFF1565C0)
      }
      .justifyContent(FlexAlign.SpaceAround)

      Row() {
        // const rate: string =
        this.Card('完成率', this.taskCount() > 0 ? `${Math.round(this.doneCount() * 100 / this.taskCount())}%` : '0%', 0xFFE65100)
        this.Card('进行中', this.inProgressCount().toString(), 0xFF6A1B9A)
      }
      .justifyContent(FlexAlign.SpaceAround)

      // 第二行：风险与计划
      Row() {
        this.Card('逾期未完成', this.overdueCount().toString(), 0xFFD32F2F)
        this.Card('未来7天待办', this.next7Count().toString(), 0xFF1976D2)
      }
      .justifyContent(FlexAlign.SpaceAround)
      .margin({ top: 8 })

      // 第三行：近期活跃
      Row() {
        this.Card('近7天完成', this.doneLast7().toString(), 0xFF2E7D32)
        this.Card('连续打卡(天)', this.streakDays().toString(), 0xFF00897B)
      }
      .justifyContent(FlexAlign.SpaceAround)
      .margin({ top: 8 })

      // 类型分布
      this.SectionTitle('类型分布')
      Row() {
        this.Chip(`浇水 ${this.typeCount('浇水')}`)
        this.Chip(`施肥 ${this.typeCount('施肥')}`)
        this.Chip(`修剪 ${this.typeCount('修剪')}`)
      }
      .padding({ left: 12, right: 12, bottom: 4 })

      // 近30天 Top 植物
      this.SectionTitle('近30天最活跃植物')
      Row() {
        this.BigBadge(this.topPlantName(), this.topPlantCount())
      }
      .padding({ left: 12, right: 12, bottom: 6 })

      // 近7天完成柱状图
      Row() {
        McBarChart({ options: this.weekOption })
      }
      .height(220)
      .padding({ left: 8, right: 8, top: 6 })

    }
    .padding({ left: 12, right: 12, top: 12, bottom: 16 })
  }

  @Builder
  SectionTitle(text: string) {
    Row() { Text(text).fontSize(12).fontColor(0xFF607D8B) }
    .padding({ left: 12, right: 12, top: 10, bottom: 6 })
  }

  @Builder
  Card(title: string, value: string, color: ResourceColor) {
    Column() {
      Text(title).fontSize(12).fontColor(0xFF607D8B)
      Text(value).fontSize(22).fontWeight(FontWeight.Medium).fontColor(color)
    }
    .width('46%')
    .padding(16)
    .borderRadius(16)
    .backgroundColor(0xFFFFFFFF)
    .shadow({ radius: 14, color: 0x12000000, offsetX: 0, offsetY: 4 })
    .animation({ duration: 240, curve: Curve.EaseInOut })
  }

  @Builder
  Chip(text: string) {
    Text(text)
      .fontSize(12).fontColor(0xFF263238)
      .padding({ left: 10, right: 10, top: 6, bottom: 6 })
      .borderRadius(12)
      .backgroundColor(0xFFECEFF1)
      .margin({ right: 8 })
  }

  @Builder
  BigBadge(name: string, count: string) {
    Row() {
      Text('📈').fontSize(20).margin({ right: 8 })
      Column() {
        Text(name).fontSize(14).fontWeight(FontWeight.Medium).fontColor(0xFF263238)
        Text(`${count} 次完成`).fontSize(12).fontColor(0xFF607D8B).margin({ top: 2 })
      }
      Blank()
    }
    .padding(14)
    .borderRadius(16)
    .backgroundColor(0xFFFFFFFF)
    .shadow({ radius: 14, color: 0x12000000, offsetX: 0, offsetY: 4 })
  }
}
