import { McLineChart, Options } from '@mcui/mccharts'
import { Metric } from '../model/PlantModel'

/** Metric 大图趋势（全屏抽屉） */
@ComponentV2
export struct MetricChartSheet {
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
      itemGap: 10, // 图例每项之间的间隔。横向布局时为水平间隔，纵向布局时为纵向间隔。
      itemTextGap: 5, // 图例图例之间的间隔。
      itemWidth: 15, // 图例标记的图形高度。
      itemHeight: 15, // 图例标记的图形高度。
      textStyle: {
        fontSize: 44
      }
    },
    dataZoom: { show: true }, // 区域缩放
    series: [{ name: '高度', data: [] as Array<number> },
      { name: '宽度', data: [] as Array<number> },
      { name: '健康度', data: [] as Array<number> }
    ],
    animation: true
  })

  aboutToAppear(): void {
    this.defOption.setVal({
      xAxis: { data: this.toXAxis(this.metrics) },
      series: [
        { name: '高度', data: this.metrics.map(i => i.height) },
        { name: '宽度', data: this.metrics.map(i => i.width) },
        { name: '健康度', data: this.metrics.map(i => i.score) }
      ]
    })
  }

  // ===== 工具：字符串/时间 =====
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

  // ===== UI =====
  build() {
    Stack() {
      // 蒙层
      Column() {
        Blank().width('100%').height('100%').backgroundColor(0x66000000).onClick(() => {
          this.onClose()
        })
      }

      // 抽屉
      Column() {
        // // 顶部：标题 + 操作
        Row() {
          Text('生长趋势图').fontSize(16).fontWeight(FontWeight.Medium).fontColor(0xFF263238)
          Blank()
          Text('✕').fontColor('#000000').fontSize(18).onClick(() => {
            this.onClose()
          })
        }
        .padding({
          left: 16,
          right: 16,
          top: 12,
          bottom: 8
        })


        // 折线图
        Row() {
          McLineChart({
            options: this.defOption
          })
        }
        .height('62%') // 让图可见区域更大
        .width('100%')
        .padding({ left: 8, right: 8 })
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
      }
      .width('100%').backgroundColor(0xFFFFFFFF)
      .borderRadius({
        topLeft: 20,
        topRight: 20,
        bottomLeft: 0,
        bottomRight: 0
      })
      // .position({ x: 0, y: 'calc(100% - 76%)' })
      .shadow({
        radius: 24,
        color: 0x33000000,
        offsetX: 0,
        offsetY: -6
      })
    }
    .width('100%').height('100%').alignContent(Alignment.Bottom)
  }

  seriesRangeKey(key: string, isRange: boolean): string {
    if (isRange) {
      return key === '30' ? '近30天' : (key === '90' ? '近90天' : '全部')
    } else {
      return key === 'width' ? '宽度' : (key === 'height' ? '高度' : '健康度')
    }
  }

  @Builder
  Chip(text: string, isRange: boolean) {
    Text(this.seriesRangeKey(text, isRange))
      .fontSize(12)
      .fontColor(text === (isRange ? this.rangeKey : this.seriesKey) ? 0xFF1565C0 :
        0xFF263238)
      .borderRadius(12)
      .backgroundColor(text === (isRange ? this.rangeKey : this.seriesKey) ?
        0x102196F3 : 0xFFECEFF1)
      .margin({ right: 8, bottom: 8 })
      .padding({
        left: 10,
        right: 10,
        top: 6,
        bottom: 6
      })
      .onClick(() => {
        if (isRange) {
          this.rangeKey = text
        } else {
          this.seriesKey = text
        }
      })
  }
}
