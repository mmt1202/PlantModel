import { Metric, Plant } from '../model/PlantModel';
import { RdbManager } from '../viewmodel/RdbManager';
import relationalStore from '@ohos.data.relationalStore';
import { McLineChart, Options } from '@mcui/mccharts';

@ComponentV2
export struct GrowthIndicatorPage {
  @Local plant: Plant | undefined = undefined;
  @Param @Require pageStack: NavPathStack;
  @Local metrics: Array<Metric> = [];
  @Local store: relationalStore.RdbStore | null = null;
  @Local hStr: string = '';
  @Local wStr: string = '';
  @Local sStr: string = '8';
  @Local dateISO: string = '';
  @Local chartKey: 'score' | 'height' | 'width' = 'score';
  @Local sortAsc: boolean = false;
  @Local showChart: boolean = false;
  @Local defOption: Options = new Options({
    title: {
      show: true,
      text: '生长指标',
      right: 16,
      top: 16
    },
    xAxis: { data: [] as Array<string> },
    yAxis: [{ name: '高度', axisLine: { show: true }, position: 'left' },
      { name: '宽度', axisLine: { show: true }, position: 'right' },
      { name: '健康度', axisLine: { show: true }, position: 'right' }
    ],
    grid: {
      left: 28,
      top: 48,
      right: 28,
      bottom: 28
    },
    tooltip: { show: true },
    legend: {
      show: true,
      itemGap: 10,
      itemTextGap: 5,
      itemWidth: 15,
      itemHeight: 15,
      textStyle: {
        fontSize: 44
      }
    },
    dataZoom: { show: true },
    series: [{ name: '高度', data: [] as Array<number> },
      { name: '宽度', data: [] as Array<number> },
      { name: '健康度', data: [] as Array<number> }
    ],
    animation: true
  });

  aboutToAppear(): void {
    // 成长指标页直接复用全局 RDB store，不额外引入 VM，逻辑集中在页面内完成。
    this.store = RdbManager.getInstance().rdbStore;
    this.dateISO = this.todayISO();
  }

  build() {
    NavDestination() {
      // 这一页同时承载“录入指标”和“查看趋势”两个场景，通过 showChart 在列表/图表间切换。
      Column() {
        this.Header()
        Scroll() {
          Column({ space: 16 }) {
            if (this.plant) {
              this.PlantInfoCard()
              if (!this.showChart) {
                this.TabSwitch()
                this.MiniChart()
                this.AddForm()
                this.MetricList()
              } else {
                this.FullChart()
              }
            }
          }
          .padding({ left: 16, right: 16, top: 8, bottom: 32 })
        }
        .layoutWeight(1)
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .title('生长指标')
    .padding({
      top: AppStorage.get<number>('topRectHeight'),
      bottom: AppStorage.get<number>('bottomRectHeight')
    })
    .linearGradient({
      direction: GradientDirection.Top,
      colors: [[0xFFF1F8E9, 0], [0xFFE8F5E9, 0.5], [0xFFE3F2FD, 1.0]]
    })
    .onReady((param) => {
      const plant = param.pathInfo.param as Plant
      this.plant = plant
      this.loadMetrics()
    })
  }

  @Builder
  Header() {
    Row() {
      Column() {
        Text('生长指标').fontSize(22).fontWeight(FontWeight.Medium).fontColor(0xFF263238)
        if (this.plant) {
          Text(this.plant.name).fontSize(14).fontColor(0xFF78909C)
        }
      }
      Blank()
      Text(this.showChart ? '📋 列表' : '📈 图表')
        .fontSize(14)
        .fontColor(0xFF1565C0)
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        .borderRadius(16)
        .backgroundColor(0x102196F3)
        .onClick(() => {
          this.showChart = !this.showChart
          if (this.showChart) {
            this.updateChartData()
          }
        })
    }
    .padding({ left: 16, right: 16, top: 12, bottom: 8 })
  }

  @Builder
  PlantInfoCard() {
    Column({ space: 12 }) {
      Row({ space: 12 }) {
        this.StatCard('📊', '记录数', this.metrics.length.toString(), 0xFF4CAF50)
        this.StatCard('📈', '最新健康', this.metrics.length > 0 ? this.metrics[this.metrics.length - 1].score.toString() : '-', 0xFF2196F3)
      }
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .shadow({ radius: 12, color: '#1A000000', offsetX: 0, offsetY: 4 })
  }

  @Builder
  StatCard(icon: string, label: string, value: string, color: ResourceColor) {
    Column({ space: 8 }) {
      Text(icon).fontSize(24)
      Text(label).fontSize(12).fontColor(0xFF78909C)
      Text(value).fontSize(20).fontWeight(FontWeight.Bold).fontColor(color)
    }
    .width('50%')
    .padding(16)
    .backgroundColor(0xFFF9F9F9)
    .borderRadius(16)
  }

  @Builder
  TabSwitch() {
    Row({ space: 8 }) {
      this.TabChip('健康分', 'score')
      this.TabChip('身高', 'height')
      this.TabChip('冠幅', 'width')
      Blank()
      Text(this.sortAsc ? '时间 ↑' : '时间 ↓')
        .fontSize(12)
        .fontColor(0xFF1565C0)
        .padding({ left: 10, right: 10, top: 6, bottom: 6 })
        .borderRadius(14)
        .backgroundColor(0x102196F3)
        .onClick(() => {
          this.sortAsc = !this.sortAsc
        })
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({ radius: 8, color: '#10000000', offsetX: 0, offsetY: 2 })
  }

  @Builder
  TabChip(label: string, key: 'score' | 'height' | 'width') {
    Text(label)
      .fontSize(14)
      .fontColor(this.chartKey === key ? 0xFFFFFFFF : 0xFF263238)
      .padding({ left: 16, right: 16, top: 10, bottom: 10 })
      .borderRadius(14)
      .backgroundColor(this.chartKey === key ?
        (key === 'score' ? 0xFF1565C0 : (key === 'height' ? 0xFF2E7D32 : 0xFFE65100)) : 0x11000000)
      .onClick(() => {
        this.chartKey = key
      })
  }

  @Builder
  MiniChart() {
    Column() {
      Row() {
        if (this.chartKey === 'score') {
          Text('健康分趋势').fontSize(16).fontWeight(FontWeight.Medium).fontColor(0xFF1565C0)
        }
        if (this.chartKey === 'height') {
          Text('身高趋势（cm）').fontSize(16).fontWeight(FontWeight.Medium).fontColor(0xFF2E7D32)
        }
        if (this.chartKey === 'width') {
          Text('冠幅趋势（cm）').fontSize(16).fontWeight(FontWeight.Medium).fontColor(0xFFE65100)
        }
        Blank()
        Text(this.sorted().length.toString() + ' 条')
          .fontSize(14).fontColor(0xFF607D8B)
      }
      .padding({ left: 12, right: 12, top: 12, bottom: 8 })

      if (this.sorted().length > 0) {
        List() {
          ForEach(this.sorted(), (m: Metric) => {
            ListItem() {
              Column() {
                Blank()
                  .width(16)
                  .height(this.barHeight(m))
                  .borderRadius(8)
                  .backgroundColor(this.barColor())
                Text(this.tickLabel(m.createdAt))
                  .fontSize(10).fontColor(0x80607278).margin({ top: 6 })
              }
              .alignItems(HorizontalAlign.Center)
            }
            .width(24)
          }, (m: Metric) => m.id.toString())
        }.height(120).scrollBar(BarState.Off)
        .padding({ left: 12, right: 12, top: 8, bottom: 12 })
        .listDirection(Axis.Horizontal)
      } else {
        Column() {
          Text('暂无数据').fontSize(14).fontColor(0xFF90A4AE)
        }
        .height(100)
      }
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .shadow({ radius: 12, color: '#13000000', offsetX: 0, offsetY: 4 })
  }

  @Builder
  AddForm() {
    Column({ space: 16 }) {
      Row() {
        Text('添加记录').fontSize(18).fontWeight(FontWeight.Medium).fontColor(0xFF263238)
        Blank()
      }
      this.NumField('身高（cm）', this.hStr, (v: string) => {
        this.hStr = v
      })
      this.NumField('冠幅（cm）', this.wStr, (v: string) => {
        this.wStr = v
      })
      this.NumField('健康分（0~100）', this.sStr, (v: string) => {
        this.sStr = v
      })
      Row({ space: 12 }) {
        Text('今天')
          .fontSize(14)
          .fontColor(0xFF1565C0)
          .padding({ left: 16, right: 16, top: 10, bottom: 10 })
          .borderRadius(14)
          .backgroundColor(0x102196F3)
          .onClick(() => {
            this.dateISO = this.todayISO()
          })
        Text(this.dateISO).fontSize(14).fontColor(0xFF263238)
      }
      .justifyContent(FlexAlign.Start)
      Row({ space: 12 }) {
        Button('添加记录')
          .fontSize(16)
          .fontColor(0xFFFFFFFF)
          .backgroundColor(0xFF2E7D32)
          .borderRadius(16)
          .height(48)
          .layoutWeight(1)
          .onClick(() => {
            this.addMetric()
          })
        Button('清空')
          .fontSize(16)
          .fontColor(0xFF1565C0)
          .backgroundColor(0x102196F3)
          .borderRadius(16)
          .height(48)
          .onClick(() => {
            this.hStr = ''
            this.wStr = ''
            this.sStr = '8'
          })
      }
    }
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .shadow({ radius: 12, color: '#13000000', offsetX: 0, offsetY: 4 })
  }

  @Builder
  NumField(label: string, val: string, onChange: (v: string) => void) {
    Column() {
      Text(label).fontSize(14).fontColor(0xFF607D8B)
      TextInput({ placeholder: '请输入', text: val })
        .placeholderColor(0xFF90A4AE)
        .fontColor(0xFF000000)
        .onChange((v: string) => {
          onChange(v)
        })
        .type(InputType.Number)
        .width('100%')
        .height(48)
        .borderRadius(12)
        .backgroundColor(0xFFF9F9F9)
        .padding({ left: 16, right: 16 })
        .margin({ top: 8 })
    }
    .width('100%')
  }

  @Builder
  MetricList() {
    Column({ space: 12 }) {
      Row() {
        Text('历史记录').fontSize(18).fontWeight(FontWeight.Medium).fontColor(0xFF263238)
        Blank()
      }
      if (this.sorted().length === 0) {
        Column() {
          Text('暂无指标记录').fontSize(14).fontColor(0xFF90A4AE)
        }
        .padding(40)
        .backgroundColor('#FFFFFF')
        .borderRadius(20)
        .shadow({ radius: 8, color: '#10000000', offsetX: 0, offsetY: 2 })
      } else {
        List({ space: 12 }) {
          ForEach(this.sorted(), (m: Metric) => {
            ListItem() {
              this.MetricRow(m)
            }
          }, (m: Metric) => m.id.toString())
        }
        .layoutWeight(1)
      }
    }
    .width('100%')
  }

  @Builder
  MetricRow(m: Metric) {
    Row() {
      Column({ space: 4 }) {
        Text(this.dateFromTs(m.createdAt))
          .fontSize(16).fontWeight(FontWeight.Medium).fontColor(0xFF263238)
        Text(`身高: ${Math.floor(m.height)}cm  冠幅: ${Math.floor(m.width)}cm  健康: ${Math.floor(m.score)}`)
          .fontSize(14).fontColor(0xFF607D8B)
      }
      .alignItems(HorizontalAlign.Start)
      Blank()
      Text('🗑️')
        .fontSize(20)
        .padding(8)
        .onClick(() => {
          this.deleteMetric(m.id)
        })
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({ radius: 8, color: '#10000000', offsetX: 0, offsetY: 2 })
  }

  @Builder
  FullChart() {
    Column() {
      Row() {
        Text('生长趋势图').fontSize(18).fontWeight(FontWeight.Medium).fontColor(0xFF263238)
        Blank()
      }
      .padding({ bottom: 12 })
      McLineChart({
        options: this.defOption
      })
      .height(400)
      .width('100%')
    }
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .shadow({ radius: 12, color: '#13000000', offsetX: 0, offsetY: 4 })
  }

  // 指标按时间升序读取，便于图表直接按采集时间展开。
  private async loadMetrics(): Promise<void> {
    if (!this.store || !this.plant) {
      return
    }
    const rs = await this.store.querySql(
      `SELECT id, plantId, height, width, score, createdAt
     FROM ${RdbManager.T_METRIC}
     WHERE plantId = ?
     ORDER BY createdAt ASC`, [this.plant.id]
    )
    const arr: Array<Metric> = []
    while (rs.goToNextRow()) {
      arr.push(new Metric(
        rs.getLong(0), rs.getLong(1),
        rs.getDouble(2), rs.getDouble(3), rs.getLong(4), rs.getLong(5)
      ))
    }
    rs.close()
    this.metrics = arr
  }

  // 新增指标时先做输入兜底和分数裁剪，再统一落到 metric 表。
  private async addMetric(): Promise<void> {
    if (!this.store || !this.plant) {
      return
    }
    const hv: number = this.safeNum(this.hStr)
    const wv: number = this.safeNum(this.wStr)
    const sv: number = this.clampScore(this.safeNum(this.sStr))
    if (this.dateISO.length !== 10) {
      return
    }
    const ts: number = this.isoToTs(this.dateISO)
    const v: relationalStore.ValuesBucket = {
      plantId: this.plant.id,
      height: hv,
      width: wv,
      score: sv,
      createdAt: ts
    }
    await this.store.insert(RdbManager.T_METRIC, v)
    await this.loadMetrics()
    this.hStr = ''
    this.wStr = ''
  }

  private async deleteMetric(id: number): Promise<void> {
    if (!this.store) {
      return
    }
    const p = new relationalStore.RdbPredicates(RdbManager.T_METRIC);
    p.equalTo('id', id)
    await this.store.delete(p)
    await this.loadMetrics()
  }

  // 图表数据只在切到大图模式时重建，避免平时列表模式下频繁更新 chart option。
  private updateChartData(): void {
    this.defOption.setVal({
      xAxis: { data: this.toXAxis(this.metrics) },
      series: [
        { name: '高度', data: this.metrics.map(i => i.height) },
        { name: '宽度', data: this.metrics.map(i => i.width) },
        { name: '健康度', data: this.metrics.map(i => i.score) }
      ]
    })
  }

  // 列表展示顺序和图表原始顺序分开处理：图表按时间，列表可切换升降序。
  private sorted(): Array<Metric> {
    const arr: Array<Metric> = []
    let i: number = 0
    while (i < this.metrics.length) {
      arr.push(this.metrics[i])
      i = i + 1
    }
    arr.sort((a: Metric, b: Metric) => {
      if (this.sortAsc) {
        return a.createdAt - b.createdAt
      }
      return b.createdAt - a.createdAt
    })
    return arr
  }

  private valOf(m: Metric): number {
    if (this.chartKey === 'height') {
      return m.height
    }
    if (this.chartKey === 'width') {
      return m.width
    }
    return m.score
  }

  private maxVal(): number {
    let max: number = 0
    let i: number = 0
    while (i < this.metrics.length) {
      const v: number = this.valOf(this.metrics[i])
      if (v > max) {
        max = v
      }
      i = i + 1
    }
    if (max <= 0) {
      return 1
    }
    return max
  }

  private barHeight(m: Metric): number {
    const v: number = this.valOf(m)
    const ratio: number = v / this.maxVal()
    const h: number = Math.floor(80 * ratio)
    if (h < 6) {
      return 6
    }
    return h
  }

  private barColor(): ResourceColor {
    if (this.chartKey === 'score') {
      return 0xFF1565C0
    }
    if (this.chartKey === 'height') {
      return 0xFF2E7D32
    }
    return 0xFFE65100
  }

  private tickLabel(ts: number): string {
    return ''
  }

  private dateFromTs(ts: number): string {
    const d = new Date(ts)
    const y = d.getFullYear()
    const m = (d.getMonth() + 1).toString().padStart(2, '0')
    const day = d.getDate().toString().padStart(2, '0')
    return `${y}-${m}-${day}`
  }

  private todayISO(): string {
    const d = new Date()
    const y = d.getFullYear()
    const m = (d.getMonth() + 1).toString().padStart(2, '0')
    const day = d.getDate().toString().padStart(2, '0')
    return `${y}-${m}-${day}`
  }

  private safeNum(s: string): number {
    const v: number = Number(s)
    if (Number.isFinite(v)) {
      return v
    }
    return 0
  }

  private clampScore(v: number): number {
    if (v < 0) {
      return 0
    }
    if (v > 100) {
      return 100
    }
    return Math.floor(v)
  }

  private isoToTs(iso: string): number {
    if (iso.length !== 10) {
      return Date.now()
    }
    const parts: Array<string> = iso.split('-')
    const y: number = Number.parseInt(parts[0])
    const m: number = Number.parseInt(parts[1])
    const d: number = Number.parseInt(parts[2])
    const dt = new Date(y, m - 1, d, 0, 0, 0, 0)
    return dt.getTime()
  }

  private two(n: number): string {
    const s: string = n.toString()
    if (s.length === 1) {
      return '0' + s
    }
    return s
  }

  private labelOf(ts: number): string {
    const d = new Date(ts)
    return `${this.two(d.getMonth() + 1)}-${this.two(d.getDate())}`
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
}
