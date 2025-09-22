import { Plant } from '../model/PlantModel'

@ObservedV2
export class PlantTaskFilter {
  @Trace status: 'all' | 'undone' | 'done' = 'all' // 状态
  @Trace typeWater: boolean = true
  @Trace typeFertilize: boolean = true
  @Trace typePrune: boolean = true
  @Trace dateFromISO: string = '' // YYYY-MM-DD 或空
  @Trace dateToISO: string = '' // YYYY-MM-DD 或空
  @Trace sortKey: 'date' | 'type' | 'plant' = 'date' // 排序键
  @Trace sortAsc: boolean = false
  @Trace keyword: string = '' // 关键词（匹配 植物名 / 类型）
}

@ComponentV2
export struct PlantTaskFilterSheet {
  @Param @Require filter: PlantTaskFilter
  @Param @Require plants: Array<Plant> // 用于 Plant 排序说明/展示（不改数据）
  @Event onApply: (f: PlantTaskFilter) => void
  @Event onReset: () => void
  @Event onClose: () => void

  build() {
    Column() {
      // 蒙层
      Blank().width('100%').height('100%').backgroundColor(0x66000000).onClick(() => {
        this.onClose()
      })

      // 抽屉
      Column() {
        // 头部
        Row() {
          Text('筛选 / 排序').fontSize(16).fontWeight(FontWeight.Medium).fontColor(0xFF263238)
          Blank()
          Text('重置')
            .fontSize(12)
            .fontColor(0xFF607D8B)
            .padding({
              left: 10,
              right: 10,
              top: 6,
              bottom: 6
            })
            .borderRadius(12)
            .backgroundColor(0x10A0A0A0)
            .onClick(() => {
              this.onReset()
            })
          Text('✕').fontSize(18).onClick(() => {
            this.onClose()
          }).margin({ left: 8 })
        }
        .padding({
          left: 16,
          right: 16,
          top: 12,
          bottom: 8
        })

        // 状态
        Column() {
          Text('状态').fontSize(12).fontColor(0xFF607D8B)
          Row() {
            this.StatusChip('全部', 'all')
            this.StatusChip('未完成', 'undone')
            this.StatusChip('已完成', 'done')
          }.margin({ top: 6 })
        }.padding({ left: 16, right: 16, bottom: 8 })

        // 类型
        Column() {
          Text('类型').fontSize(12).fontColor(0xFF607D8B)
          Row() {
            this.TypeChip('浇水')
            this.TypeChip('施肥')
            this.TypeChip('修剪')
          }.margin({ top: 6 })
        }.padding({ left: 16, right: 16, bottom: 8 })

        // 日期范围
        Column() {
          Text('日期范围（可留空）').fontSize(12).fontColor(0xFF607D8B)
          Row() {
            Column() {
              Text('起始').fontSize(12).fontColor(0xFF607D8B)
              TextInput({ placeholder: 'YYYY-MM-DD', text: this.filter.dateFromISO })
                .onChange((v: string) => {
                  this.filter.dateFromISO = v
                })
                .width('100%')
                .height(40)
                .borderRadius(12)
                .backgroundColor(0xFFF9F9F9)
                .padding({ left: 12, right: 12 })
                .margin({ top: 4 })
            }.width('48%')

            Blank()
            Column() {
              Text('结束').fontSize(12).fontColor(0xFF607D8B)
              TextInput({ placeholder: 'YYYY-MM-DD', text: this.filter.dateToISO })
                .onChange((v: string) => {
                  this.filter.dateToISO = v
                })
                .width('100%')
                .height(40)
                .borderRadius(12)
                .backgroundColor(0xFFF9F9F9)
                .padding({ left: 12, right: 12 })
                .margin({ top: 4 })
            }.width('48%')
          }
          .margin({ top: 6 })

          Row() {
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
                const t = this.todayISO();
                this.filter.dateFromISO = t;
                this.filter.dateToISO = t
              })
            Text('清空')
              .fontSize(12)
              .fontColor(0xFF607D8B)
              .padding({
                left: 12,
                right: 12,
                top: 6,
                bottom: 6
              })
              .borderRadius(14)
              .backgroundColor(0x10A0A0A0)
              .margin({ left: 8 })
              .onClick(() => {
                this.filter.dateFromISO = '';
                this.filter.dateToISO = ''
              })
          }.margin({ top: 6 })
        }.padding({ left: 16, right: 16, bottom: 8 })

        // 关键词
        Column() {
          Text('关键词（植物名 / 类型）').fontSize(12).fontColor(0xFF607D8B)
          TextInput({ placeholder: '例如：龟背竹 / 浇水', text: this.filter.keyword })
            .onChange((v: string) => {
              this.filter.keyword = v
            })
            .width('100%')
            .height(40)
            .borderRadius(12)
            .backgroundColor(0xFFF9F9F9)
            .padding({ left: 12, right: 12 })
            .margin({ top: 6 })
        }.padding({ left: 16, right: 16, bottom: 8 })

        // 排序
        Column() {
          Text('排序').fontSize(12).fontColor(0xFF607D8B)
          Row() {
            this.SortChip('按日期', 'date')
            this.SortChip('按类型', 'type')
            this.SortChip('按植物', 'plant')
            Blank()
            Text(this.filter.sortAsc ? '升序 ↑' : '降序 ↓')
              .fontSize(12)
              .fontColor(0xFF1565C0)
              .padding({
                left: 10,
                right: 10,
                top: 6,
                bottom: 6
              })
              .borderRadius(14)
              .backgroundColor(0x102196F3)
              .onClick(() => {
                this.filter.sortAsc = !this.filter.sortAsc
              })
          }.margin({ top: 6 })
        }.padding({ left: 16, right: 16, bottom: 10 })

        // 底部操作
        Row() {
          Text('应用')
            .fontSize(14)
            .fontColor(0xFFFFFFFF)
            .padding({
              left: 18,
              right: 18,
              top: 10,
              bottom: 10
            })
            .borderRadius(20)
            .backgroundColor(0xFF2E7D32)
            .onClick(() => {
              this.onApply(this.cloneFilter(this.filter))
            })
          Text('关闭')
            .fontSize(14)
            .fontColor(0xFF1565C0)
            .padding({
              left: 18,
              right: 18,
              top: 10,
              bottom: 10
            })
            .borderRadius(20)
            .backgroundColor(0x102196F3)
            .margin({ left: 10 })
            .onClick(() => {
              this.onClose()
            })
        }
        .padding({ left: 16, right: 16, bottom: 16 })
      }
      .width('100%')
      .backgroundColor(0xFFFFFFFF)
      .borderRadius({
        topLeft: 20,
        topRight: 20,
        bottomLeft: 0,
        bottomRight: 0
      })
      .position({ x: 0, y: 'calc(100% - 76%)' })
      .shadow({
        radius: 24,
        color: 0x33000000,
        offsetX: 0,
        offsetY: -6
      })
      .animation({ duration: 200, curve: Curve.Sharp })
    }
    .width('100%').height('100%')
  }

  // ---------- 子块 ----------
  @Builder
  StatusChip(text: string, val: 'all' | 'undone' | 'done') {
    Text(text)
      .fontSize(12)
      .fontColor(this.filter.status === val ? 0xFFFFFFFF : 0xFF263238)
      .padding({
        left: 12,
        right: 12,
        top: 6,
        bottom: 6
      })
      .borderRadius(14)
      .backgroundColor(this.filter.status === val ? 0xFF1565C0 : 0x11000000)
      .onClick(() => {
        this.filter.status = val
      })
      .margin({ right: 8 })
  }

  @Builder
  TypeChip(label: string) {
    // 开关映射
    // const on: boolean = t
    Text(label)
      .fontSize(12)
      .fontColor(this.typeOn(label) ? 0xFFFFFFFF : 0xFF263238)
      .padding({
        left: 12,
        right: 12,
        top: 6,
        bottom: 6
      })
      .borderRadius(14)
      .backgroundColor(this.typeOn(label) ? this.typeColor(label) : 0x11000000)
      .onClick(() => {
        this.toggleType(label)
      })
      .margin({ right: 8 })
  }

  @Builder
  SortChip(text: string, key: 'date' | 'type' | 'plant') {
    Text(text)
      .fontSize(12)
      .fontColor(this.filter.sortKey === key ? 0xFFFFFFFF : 0xFF263238)
      .padding({
        left: 12,
        right: 12,
        top: 6,
        bottom: 6
      })
      .borderRadius(14)
      .backgroundColor(this.filter.sortKey === key ? 0xFF2E7D32 : 0x11000000)
      .onClick(() => {
        this.filter.sortKey = key
      })
      .margin({ right: 8 })
  }

  // ---------- 工具 ----------
  private todayISO(): string {
    const d = new Date();
    const y = d.getFullYear()
    const m = (d.getMonth() + 1).toString().padStart(2, '0');
    const day = d.getDate().toString().padStart(2, '0')
    return `${y}-${m}-${day}`
  }

  private typeOn(label: string): boolean {
    if (label === '浇水') {
      return this.filter.typeWater
    }
    if (label === '施肥') {
      return this.filter.typeFertilize
    }
    if (label === '修剪') {
      return this.filter.typePrune
    }
    return true
  }

  private toggleType(label: string): void {
    if (label === '浇水') {
      this.filter.typeWater = !this.filter.typeWater;
      return
    }
    if (label === '施肥') {
      this.filter.typeFertilize = !this.filter.typeFertilize;
      return
    }
    if (label === '修剪') {
      this.filter.typePrune = !this.filter.typePrune;
      return
    }
  }

  private typeColor(type: string): ResourceColor {
    if (type === '浇水') {
      return 0xFF3AAFA9
    }
    if (type === '施肥') {
      return 0xFF8E7CC3
    }
    if (type === '修剪') {
      return 0xFFE57373
    }
    return 0xFF607D8B
  }

  private cloneFilter(src: PlantTaskFilter): PlantTaskFilter {
    const f = new PlantTaskFilter()
    f.status = src.status
    f.typeWater = src.typeWater;
    f.typeFertilize = src.typeFertilize;
    f.typePrune = src.typePrune
    f.dateFromISO = src.dateFromISO;
    f.dateToISO = src.dateToISO
    f.sortKey = src.sortKey;
    f.sortAsc = src.sortAsc
    f.keyword = src.keyword
    return f
  }
}
