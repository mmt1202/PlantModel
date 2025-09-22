import { PlantMetric } from "../model/PlantModel"


/** ====================== 指标抽屉 ====================== */
@ComponentV2
export struct MetricSheet {
  @Param @Require plantName: string
  @Param @Require metrics: Array<PlantMetric>
  @Event onAdd: (height: number, width: number, score: number, dateISO: string) => void
  @Event onDelete: (id: number) => void
  @Event onClose: () => void

  // —— 本地表单状态 —— //
  @Local hStr: string = ''           // 身高
  @Local wStr: string = ''           // 冠幅
  @Local sStr: string = '8'         // 健康分
  @Local dateISO: string = ''        // YYYY-MM-DD

  // —— 视图控制 —— //
  @Local chartKey: 'score' | 'height' | 'width' = 'score'  // 迷你图维度
  @Local sortAsc: boolean = false                          // 列表排序（默认时间新→旧）

  aboutToAppear(): void {
    this.dateISO = this.todayISO()
  }

  // ================== 视图 ================== //
  build() {
    Stack() {
      // 蒙层
      Column(){
        Blank().width('100%').height('100%').backgroundColor(0x66000000).onClick(() => { this.onClose() })
      }

      // 抽屉
      Column() {
        // 头部
        Row() {
          Text(`${this.plantName} · 生长指标`)
            .fontSize(16).fontWeight(FontWeight.Medium).fontColor(0xFF263238)
          Blank()
          Text('✕').fontSize(18).onClick(() => { this.onClose() })
        }
        .padding({ left: 16, right: 16, top: 12, bottom: 6 })

        // 维度切换 + 排序
        Row() {
          this.TabChip('健康分', 'score')
          this.TabChip('身高',   'height')
          this.TabChip('冠幅',   'width')

          Blank()

          // 排序按钮
          Text(this.sortAsc ? '时间 ↑' : '时间 ↓')
            .fontSize(12).fontColor(0xFF1565C0)
            .padding({ left: 10, right: 10, top: 6, bottom: 6 })
            .borderRadius(14).backgroundColor(0x102196F3)
            .onClick(() => { this.sortAsc = !this.sortAsc })
        }
        .padding({ left: 16, right: 16, bottom: 8 })

        // 迷你趋势图
        this.MiniChart()

        // 表单：新增指标
        Column() {
          this.NumField('身高（cm）', this.hStr, (v: string) => { this.hStr = v })
          this.NumField('冠幅（cm）', this.wStr, (v: string) => { this.wStr = v })
          this.NumField('健康分（0~100）', this.sStr, (v: string) => { this.sStr = v })

          Row({space:5}) {
            Text('今天')
              .fontSize(12)
              .fontColor(0xFF1565C0)
              .padding({
                left: 12,
                right: 12,
                top: 6,
                bottom: 6
              })
              .borderRadius(14)
              .backgroundColor(0x102196F3)
              .onClick(() => {
                this.dateISO = this.todayISO()
              })

            Text(this.dateISO).fontSize(13).fontColor(0xFF263238).margin({ top: 4 })


          }.padding({ top: 6, bottom: 6 }).height(40).justifyContent(FlexAlign.Center).alignItems(VerticalAlign.Center)

          Row() {
            Text('添加记录').fontSize(14).fontColor(0xFFFFFFFF)
              .padding({ left: 18, right: 18, top: 8, bottom: 8 })
              .borderRadius(18).backgroundColor(0xFF2E7D32)
              .onClick(() => {
                const hv: number = this.safeNum(this.hStr)
                const wv: number = this.safeNum(this.wStr)
                const sv: number = this.clampScore(this.safeNum(this.sStr))
                if (this.dateISO.length !== 10) { return }
                this.onAdd(hv, wv, sv, this.dateISO)
                this.hStr = ''; this.wStr = ''  // 清空数值，分数保留
              })

            Text('清空').fontSize(14).fontColor(0xFF1565C0)
              .padding({ left: 14, right: 14, top: 8, bottom: 8 })
              .borderRadius(18).backgroundColor(0x102196F3)
              .margin({ left: 8 })
              .onClick(() => { this.hStr = ''; this.wStr = ''; this.sStr = '8' })
          }
          .margin({ top: 6 })
        }
        .padding({ left: 16, right: 16, bottom: 8 })

        // 列表
        if (this.sorted().length === 0) {
          Column() {
            Text('暂无指标记录').fontSize(12).fontColor(0xFF90A4AE)
          }
          .padding({ left: 16, right: 16, bottom: 18 })
        } else {
          List({ space: 8 }) {
            ForEach(this.sorted(), (m: PlantMetric) => {
              ListItem() { this.MetricRow(m) }
            }, (m: PlantMetric) => m.id.toString())
          }.height('40%')
          .padding({ left: 16, right: 16, bottom: 16 })

          .edgeEffect(EdgeEffect.Spring)
        }
      }
      .width('100%').height('100%').backgroundColor(0xFFFFFFFF)
      .borderRadius({ topLeft: 20, topRight: 20, bottomLeft: 0, bottomRight: 0 })
      // .position({ x: 0, y: 'calc(100% - 82%)' })
      .shadow({ radius: 24, color: 0x33000000, offsetX: 0, offsetY: -6 })
      .animation({ duration: 200, curve: Curve.Sharp })
    }
    .width('100%').height('100%').alignContent(Alignment.Bottom)
  }

  // =============== 子区块 =============== //
  @Builder
  TabChip(label: string, key: 'score' | 'height' | 'width') {
    Text(label)
      .fontSize(12)
      .fontColor(this.chartKey === key ? 0xFFFFFFFF : 0xFF263238)
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .borderRadius(14)
      .backgroundColor(this.chartKey === key ? (key === 'score' ? 0xFF1565C0 : (key === 'height' ? 0xFF2E7D32 : 0xFFE65100)) : 0x11000000)
      .onClick(() => { this.chartKey = key })
      .margin({ right: 8 })
  }

  @Builder
  NumField(label: string, val: string, onChange: (v: string) => void) {
    Column() {
      Text(label).fontSize(12).fontColor(0xFF607D8B)
      TextInput({ placeholder: '', text: val })
        .onChange((v: string) => { onChange(v) })
        .type(InputType.Number)
        .width('100%').height(40).borderRadius(12).backgroundColor(0xFFF9F9F9)
        .padding({ left: 12, right: 12 }).margin({ top: 6 })
    }
    .margin({ top: 6 })
  }

  @Builder
  MiniChart() {
    // 外框
    Column() {
      // 标题
      Row() {
        if (this.chartKey === 'score') { Text('健康分趋势').fontSize(12).fontColor(0xFF1565C0) }
        if (this.chartKey === 'height') { Text('身高趋势（cm）').fontSize(12).fontColor(0xFF2E7D32) }
        if (this.chartKey === 'width') { Text('冠幅趋势（cm）').fontSize(12).fontColor(0xFFE65100) }
        Blank()
        Text(this.sorted().length.toString() + ' 条')
          .fontSize(12).fontColor(0xFF607D8B)
      }
      .padding({ left: 10, right: 10, top: 8, bottom: 4 })

      // 柱状迷你图（按排序结果顺序绘制）
      if (this.sorted().length>0){
        List() {
          ForEach(this.sorted(), (m: PlantMetric) => {
            // 单个柱
            ListItem() {
              Column(){
                Blank()
                  .width(14)
                  .height(this.barHeight(m))           // 由方法计算，避免在 Builder 内写 let/const
                  .borderRadius(6)
                  .backgroundColor(this.barColor())
                // x 轴标注（每隔若干显示一次）
                Text(this.tickLabel(m.createdAt))
                  .fontSize(9).fontColor(0x80607278).margin({ top: 4 })
              }
              .alignItems(HorizontalAlign.Center)
            }
            .width(18) // 含间距
          }, (m: PlantMetric) => m.id.toString())
        }.height(100).scrollBar(BarState.Off)
        .padding({ left: 10, right: 10, top: 4, bottom: 10 }).listDirection(Axis.Horizontal)
      }

    }
    .padding(8).borderRadius(14).backgroundColor(0xFFFFFFFF)
    .shadow({ radius: 12, color: 0x13000000, offsetX: 0, offsetY: 3 })
    .margin({ left: 16, right: 16, bottom: 10 })
  }

  @Builder
  MetricRow(m: PlantMetric) {
    Row() {
      Column() {
        Text(this.dateFromTs(m.createdAt))
          .fontSize(13).fontWeight(FontWeight.Medium).fontColor(0xFF263238)
        Text(`H: ${this.numStr(m.height)}  W: ${this.numStr(m.width)}  S: ${this.numStr(m.score)}`)
          .fontSize(12).fontColor(0xFF607D8B).margin({ top: 2 })
      }
      Blank()
      Text('🗑️').fontSize(16).onClick(() => { this.onDelete(m.id) })
    }.width('100%')
    .padding(12).borderRadius(12).backgroundColor(0xFFFFFFFF)
    .shadow({ radius: 12, color: 0x14000000, offsetX: 0, offsetY: 3 })
  }

  // =============== 逻辑/工具方法（非 Builder） =============== //
  private sorted(): Array<PlantMetric> {
    const arr: Array<PlantMetric> = []
    let i: number = 0
    while (i < this.metrics.length) {
      arr.push(this.metrics[i])
      i = i + 1
    }
    arr.sort((a: PlantMetric, b: PlantMetric) => {
      if (this.sortAsc) { return a.createdAt - b.createdAt }
      return b.createdAt - a.createdAt
    })
    return arr
  }

  private valOf(m: PlantMetric): number {
    if (this.chartKey === 'height') { return m.height }
    if (this.chartKey === 'width')  { return m.width }
    return m.score
  }

  private maxVal(): number {
    let max: number = 0
    let i: number = 0
    while (i < this.metrics.length) {
      const v: number = this.valOf(this.metrics[i])
      if (v > max) { max = v }
      i = i + 1
    }
    if (max <= 0) { return 1 }
    return max
  }

  private barHeight(m: PlantMetric): number {
    const v: number = this.valOf(m)
    const ratio: number = v / this.maxVal()
    const h: number = Math.floor(64 * ratio)   // 迷你图柱子高度（vp）
    if (h < 4) { return 4 }
    return h
  }

  private barColor(): ResourceColor {
    if (this.chartKey === 'score') { return 0xFF1565C0 }
    if (this.chartKey === 'height') { return 0xFF2E7D32 }
    return 0xFFE65100
  }

  private tickLabel(ts: number): string {
    // 简洁化：仅显示 MM-DD（隔 3 个刻度显示一次；由调用侧控制）
    // 这里简单返回 ''，由列表密度自行体现；如需稀疏标注，可根据 ts 做取模逻辑（避免在 Builder 里写 let/const）
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
    if (Number.isFinite(v)) { return v }
    return 0
  }

  private clampScore(v: number): number {
    if (v < 0) { return 0 }
    if (v > 100) { return 100 }
    return Math.floor(v)
  }

  private numStr(v: number): string {
    // 简洁展示，无小数
    return Math.floor(v).toString()
  }
}
