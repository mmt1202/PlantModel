import { McLineChart, Options } from '@mcui/mccharts'
import { Metric } from '../model/PlantModel'

/** Metric 大图趋势（全屏抽屉） */
@ComponentV2
export
struct MetricChartSheet {
  /** 植物名（仅用于标题展示） */
  @Param @Require plantName: string
  /** 指标数据（请传入某一植物的全部 Metric 列表） */
  @Param @Require metrics: Array<Metric>
  /** 关闭 */
  @Event onClose: () => void

  /** 当前序列：'height' | 'width' | 'score' */
  @Local seriesKey: string = 'height'
  /** 时间范围：'30' | '90' | 'all' */
  @Local rangeKey: string = '90'
  /** 图表配置 */
  @Local defOption: Options = new Options({
    title: { show: true, text: '', right: 16, top: 16 },
    xAxis: { data: [] as Array<string> },
    yAxis: { name: '' },
    grid: { left: 28, top: 48, right: 16, bottom: 28 },
    tooltip: { show: true },
    legend: { show: false },
    dataZoom: { show: true },   // 区域缩放
    series: [{ name: '', data: [] as Array<number> }]
  })

  aboutToAppear(): void {
    // 初始化标题与默认序列
    this.refreshOptions()
  }

  // ===== 工具：字符串/时间 =====
  private two(n: number): string {
    const s: string = n.toString()
    if (s.length === 1) { return '0' + s }
    return s
  }

  private labelOf(ts: number): string {
    const d = new Date(ts)
    return `${this.two(d.getMonth() + 1)}-${this.two(d.getDate())}`
  }

  private yName(): string {
    if (this.seriesKey === 'height') { return '高度 (cm)' }
    if (this.seriesKey === 'width') { return '宽度 (cm)' }
    return '健康分 (0-100)'
  }

  private seriesTitle(): string {
    if (this.seriesKey === 'height') { return '高度' }
    if (this.seriesKey === 'width') { return '宽度' }
    return '健康分'
  }

  private rangeDays(): number {
    if (this.rangeKey === '30') { return 30 }
    if (this.rangeKey === '90') { return 90 }
    return -1 // all
  }

  // 过滤 + 排序（时间升序）
  private filteredSorted(): Array<Metric> {
    const days: number = this.rangeDays()
    const now: number = Date.now()
    const out: Array<Metric> = []
    let i: number = 0
    while (i < this.metrics.length) {
      const m: Metric = this.metrics[i]
      if (days > 0) {
        const delta: number = now - m.createdAt
        const limit: number = days * 24 * 60 * 60 * 1000
        if (delta > limit) { i = i + 1; continue }
      }
      out.push(m)
      i = i + 1
    }
    out.sort((a: Metric, b: Metric) => a.createdAt - b.createdAt)
    return out
  }

  private toXAxis(ms: Array<Metric>): Array<string> {
    const x: Array<string> = []
    let i: number = 0
    while (i < ms.length) {
      x.push(this.labelOf(ms[i].createdAt))
      i = i + 1
    }
    return x
  }

  private toYSeries(ms: Array<Metric>): Array<number> {
    const y: Array<number> = []
    let i: number = 0
    if (this.seriesKey === 'height') {
      while (i < ms.length) { y.push(ms[i].height); i = i + 1 }
      return y
    }
    if (this.seriesKey === 'width') {
      while (i < ms.length) { y.push(ms[i].width); i = i + 1 }
      return y
    }
    while (i < ms.length) { y.push(ms[i].score); i = i + 1 }
    return y
  }

  private refreshOptions(): void {
    const arr: Array<Metric> = this.filteredSorted()
    const x: Array<string> = this.toXAxis(arr)
    const y: Array<number> = this.toYSeries(arr)

    // 更新配置（保持 Options 实例，替换字段）
    this.defOption.title = { show: true, text: `${this.plantName} · ${this.seriesTitle()}`, right: 16, top: 16 }
    this.defOption.xAxis = { data: x }
    this.defOption.yAxis = { name: this.yName() }
    this.defOption.series = [{ name: this.seriesTitle(), data: y }]
    // 颜色/动画等如需定制可追加：this.defOption.color = [...]
  }

  // ===== UI =====
  build() {
    Column() {
      // 蒙层
      Blank().width('100%').height('100%').backgroundColor(0x66000000).onClick(() => { this.onClose() })

      // 抽屉
      Column() {
        // 顶部：标题 + 操作
        Row() {
          Text('生长趋势图').fontSize(16).fontWeight(FontWeight.Medium).fontColor(0xFF263238)
          Blank()
          Text('✕').fontSize(18).onClick(() => { this.onClose() })
        }
        .padding({ left: 16, right: 16, top: 12, bottom: 8 })

        // 序列选择
        Row() {
          this.Chip(this.seriesKey === 'height' ? '✓ 高度' : '高度', () => { this.seriesKey = 'height'; this.refreshOptions() })
          this.Chip(this.seriesKey === 'width' ? '✓ 宽度' : '宽度', () => { this.seriesKey = 'width'; this.refreshOptions() })
          this.Chip(this.seriesKey === 'score' ? '✓ 健康分' : '健康分', () => { this.seriesKey = 'score'; this.refreshOptions() })
        }
        .padding({ left: 16, right: 16, bottom: 6 })
        // .wrapContent(true)

        // 时间范围
        Row() {
          this.Chip(this.rangeKey === '30' ? '✓ 近30天' : '近30天', () => { this.rangeKey = '30'; this.refreshOptions() })
          this.Chip(this.rangeKey === '90' ? '✓ 近90天' : '近90天', () => { this.rangeKey = '90'; this.refreshOptions() })
          this.Chip(this.rangeKey === 'all' ? '✓ 全部' : '全部', () => { this.rangeKey = 'all'; this.refreshOptions() })
        }
        .padding({ left: 16, right: 16, bottom: 8 })

        // 折线图
        Row() {
          McLineChart({
            options: this.defOption
          })
        }
        .height('62%')  // 让图可见区域更大
        .width('100%')
        .padding({ left: 8, right: 8 })
      }
      .width('100%').backgroundColor(0xFFFFFFFF)
      .borderRadius({ topLeft: 20, topRight: 20, bottomLeft: 0, bottomRight: 0 })
      .position({ x: 0, y: 'calc(100% - 76%)' })
      .shadow({ radius: 24, color: 0x33000000, offsetX: 0, offsetY: -6 })
    }
    .width('100%').height('100%')
  }

  @Builder
  Chip(text: string, onTap: () => void) {
    Text(text)
      .fontSize(12).fontColor(0xFF263238)
      .padding({ left: 10, right: 10, top: 6, bottom: 6 })
      .borderRadius(12).backgroundColor(0xFFECEFF1).margin({ right: 8, bottom: 8 })
      .onClick(() => { onTap() })
  }
}
