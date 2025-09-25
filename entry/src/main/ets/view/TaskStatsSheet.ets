import { McBarChart, McLineChart, Options } from '@mcui/mccharts'
import { PlantTask } from '../model/PlantModel'

@ComponentV2
export struct TaskStatsSheet {
  @Param @Require items: Array<PlantTask> // 全量任务（或筛选后的也行）
  @Event onClose: () => void
  @Local rangeKey: string = '30' // '30' | '90' | 'all'
  @Local lineOpt: Options = new Options({
    title: {
      show: true,
      text: '完成率趋势',
      right: 16,
      top: 16
    },
    xAxis: { data: [] as Array<string> },
    yAxis: { name: '完成率(%)' },
    grid: {
      left: 30,
      top: 48,
      right: 12,
      bottom: 28
    },
    tooltip: { show: true },
    legend: { show: false },
    series: [{ name: '完成率', data: [] as Array<number> }]
  })
  @Local barOpt: Options = new Options({
    title: {
      show: true,
      text: '类型占比',
      right: 16,
      top: 16
    },
    xAxis: { data: ['浇水', '施肥', '修剪', '其他'] },
    yAxis: { name: '次数' },
    grid: {
      left: 30,
      top: 48,
      right: 12,
      bottom: 28
    },
    tooltip: { show: true },
    legend: { show: false },
    series: [{ name: '占比', data: [0, 0, 0, 0] as Array<number> }]
  })

  aboutToAppear(): void {
    this.refreshAll()
  }

  // —— 工具：日期 —— //
  private two(n: number): string {
    const s: string = n.toString();
    if (s.length === 1) {
      return '0' + s
    }
    ;
    return s
  }

  private isoOf(d: Date): string {
    return `${d.getFullYear()}-${this.two(d.getMonth() + 1)}-${this.two(d.getDate())}`
  }

  private addDays(iso: string, delta: number): string {
    const parts: Array<string> = iso.split('-')
    const d = new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]))
    d.setDate(d.getDate() + delta)
    return this.isoOf(d)
  }

  private rangeDays(): number {
    if (this.rangeKey === '30') {
      return 30
    }
    if (this.rangeKey === '90') {
      return 90
    }
    return -1
  }

  // —— 聚合：完成率曲线 —— //
  private collectDatesAsc(): Array<string> {
    // 取 items 中出现过的 planDate，并升序；若选 30/90，则只保留最近 N 天的日期序列（补齐无任务的天为 0/0）
    const set: Record<string, number> = {}
    let i: number = 0
    while (i < this.items.length) {
      set[this.items[i].planDate] = 1
      i = i + 1
    }
    // const arr: Array<string> = []

    const arr: Array<string> = Object.keys(set)
    arr.sort((a: string, b: string) => a < b ? -1 : (a > b ? 1 : 0))

    const nd: number = this.rangeDays()
    if (nd > 0) {
      const todayISO: string = this.isoOf(new Date())
      const days: Array<string> = []
      let d: number = nd - 1
      while (d >= 0) {
        days.push(this.addDays(todayISO, -d));
        d = d - 1
      }
      return days
    }
    return arr
  }

  private doneOfDay(iso: string): number {
    let i: number = 0;
    let c: number = 0
    while (i < this.items.length) {
      if (this.items[i].planDate === iso && this.items[i].done === 1) {
        c = c + 1
      }
      i = i + 1
    }
    return c
  }

  private totalOfDay(iso: string): number {
    let i: number = 0;
    let c: number = 0
    while (i < this.items.length) {
      if (this.items[i].planDate === iso) {
        c = c + 1
      }
      i = i + 1
    }
    return c
  }

  private refreshLine(): void {
    const xs: Array<string> = this.collectDatesAsc()
    const ys: Array<number> = []
    let i: number = 0
    while (i < xs.length) {
      const tot: number = this.totalOfDay(xs[i])
      const dn: number = this.doneOfDay(xs[i])
      const pct: number = tot > 0 ? Math.round(dn * 100 / tot) : 0
      ys.push(pct)
      i = i + 1
    }
    this.lineOpt.xAxis = { data: xs }
    this.lineOpt.series = [{ name: '完成率', data: ys }]
  }

  // —— 聚合：类型占比（区间内） —— //
  private refreshBar(): void {
    const nd: number = this.rangeDays()
    const nowISO: string = this.isoOf(new Date())
    let lboundISO: string = ''
    if (nd > 0) {
      lboundISO = this.addDays(nowISO, -(nd - 1))
    }

    let w: number = 0;
    let f: number = 0;
    let p: number = 0;
    let o: number = 0
    let i: number = 0
    while (i < this.items.length) {
      const it: PlantTask = this.items[i]
      if (nd > 0) {
        if (it.planDate < lboundISO || it.planDate > nowISO) {
          i = i + 1;
          continue
        }
      }
      if (it.type === '浇水') {
        w = w + 1
      } else if (it.type === '施肥') {
        f = f + 1
      } else if (it.type === '修剪') {
        p = p + 1
      } else {
        o = o + 1
      }
      i = i + 1
    }
    this.barOpt.series = [{ name: '占比', data: [w, f, p, o] }]
  }

  private refreshAll(): void {
    this.refreshLine()
    this.refreshBar()
  }

  // —— UI —— //
  build() {
    Column() {
      // 蒙层
      Blank().width('100%').height('100%').backgroundColor(0x66000000).onClick(() => {
        this.onClose()
      })
      // 抽屉
      Column() {
        Row() {
          Text('任务统计').fontSize(16).fontWeight(FontWeight.Medium).fontColor(0xFF263238)
          Blank()
          this.Chip(this.rangeKey === '30' ? '✓ 近30天' : '近30天', () => {
            this.rangeKey = '30';
            this.refreshAll()
          })
          this.Chip(this.rangeKey === '90' ? '✓ 近90天' : '近90天', () => {
            this.rangeKey = '90';
            this.refreshAll()
          })
          this.Chip(this.rangeKey === 'all' ? '✓ 全部' : '全部', () => {
            this.rangeKey = 'all';
            this.refreshAll()
          })
          Text('✕').fontColor('#000000').fontSize(18).onClick(() => {
            this.onClose()
          }).margin({ left: 8 })
        }
        .padding({
          left: 16,
          right: 16,
          top: 12,
          bottom: 8
        })

        // 完成率折线
        Row() {
          McLineChart({ options: this.lineOpt })
        }.height('42%').width('100%').padding({ left: 8, right: 8 })

        // 类型占比柱状
        Row() {
          McBarChart({ options: this.barOpt })
        }.height('42%').width('100%').padding({ left: 8, right: 8, top: 8 })
      }
      .width('100%')
      .backgroundColor(0xFFFFFFFF)
      .borderRadius({
        topLeft: 20,
        topRight: 20,
        bottomLeft: 0,
        bottomRight: 0
      })
      .position({ x: 0, y: 'calc(100% - 84%)' })
      .shadow({
        radius: 24,
        color: 0x33000000,
        offsetX: 0,
        offsetY: -6
      })
    }.width('100%').height('100%')
  }

  @Builder
  Chip(text: string, onTap: () => void) {
    Text(text)
      .fontSize(12)
      .fontColor(0xFF263238)
      .padding({
        left: 10,
        right: 10,
        top: 6,
        bottom: 6
      })
      .borderRadius(12)
      .backgroundColor(0xFFECEFF1)
      .margin({ left: 8 })
      .onClick(() => {
        onTap()
      })
  }
}
