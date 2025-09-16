@ComponentV2
export struct CareFilterSheet {
  @Param @Require status: number
  @Param @Require typeValue: string
  @Param @Require fromDate: string
  @Param @Require toDate: string
  @Param @Require keyword: string
  @Param @Require sortKey: string
  @Param @Require sortAsc: boolean
  @Event onChangeStatus: (v: number) => void
  @Event onChangeType: (v: string) => void
  @Event onChangeFrom: (v: string) => void
  @Event onChangeTo: (v: string) => void
  @Event onChangeKeyword: (v: string) => void
  @Event onChangeSortKey: (k: string) => void
  @Event onToggleAsc: () => void
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
        Row() {
          Text('筛选 / 排序').fontSize(16).fontWeight(FontWeight.Medium).fontColor(0xFF263238)
          Blank()
          Text('重置')
            .fontSize(12)
            .fontColor(0xFFE65100)
            .padding({
              left: 10,
              right: 10,
              top: 6,
              bottom: 6
            })
            .borderRadius(12)
            .backgroundColor(0x10E65100)
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
        this.SectionTitle('状态')
        Row() {
          this.Chip(this.status === 0 ? '✓ 全部' : '全部', () => {
            this.onChangeStatus(0)
          })
          this.Chip(this.status === 1 ? '✓ 未完成' : '未完成', () => {
            this.onChangeStatus(1)
          })
          this.Chip(this.status === 2 ? '✓ 已完成' : '已完成', () => {
            this.onChangeStatus(2)
          })
        }.padding({ left: 16, right: 16, bottom: 6 })

        // 类型
        this.SectionTitle('类型')
        Row() {
          this.Chip(this.typeValue.length === 0 ? '✓ 全部' : '全部', () => {
            this.onChangeType('')
          })
          this.Chip(this.typeValue === '浇水' ? '✓ 浇水' : '浇水', () => {
            this.onChangeType('浇水')
          })
          this.Chip(this.typeValue === '施肥' ? '✓ 施肥' : '施肥', () => {
            this.onChangeType('施肥')
          })
          this.Chip(this.typeValue === '修剪' ? '✓ 修剪' : '修剪', () => {
            this.onChangeType('修剪')
          })
        }.padding({ left: 16, right: 16, bottom: 6 })

        // .wrapContent(true)

        // 日期范围
        this.SectionTitle('日期范围')
        Row() {
          TextInput({ placeholder: '起始 YYYY-MM-DD', text: this.fromDate })
            .onChange((v: string) => {
              this.onChangeFrom(v)
            })
            .width('48%')
            .height(36)
            .borderRadius(12)
            .backgroundColor(0xFFF5F5F5)
            .padding({ left: 10, right: 10 })
          Blank()
          TextInput({ placeholder: '结束 YYYY-MM-DD', text: this.toDate })
            .onChange((v: string) => {
              this.onChangeTo(v)
            })
            .width('48%')
            .height(36)
            .borderRadius(12)
            .backgroundColor(0xFFF5F5F5)
            .padding({ left: 10, right: 10 })
        }.padding({ left: 16, right: 16, bottom: 6 })

        // 关键词
        this.SectionTitle('关键词')
        Row() {
          TextInput({ placeholder: '类型/植物名', text: this.keyword })
            .onChange((v: string) => {
              this.onChangeKeyword(v)
            })
            .width('100%')
            .height(36)
            .borderRadius(12)
            .backgroundColor(0xFFF5F5F5)
            .padding({ left: 10, right: 10 })
        }.padding({ left: 16, right: 16, bottom: 10 })

        // 排序
        this.SectionTitle('排序')
        Row() {
          this.Chip(this.sortKey === 'date' ? '✓ 日期' : '日期', () => {
            this.onChangeSortKey('date')
          })
          this.Chip(this.sortKey === 'type' ? '✓ 类型' : '类型', () => {
            this.onChangeSortKey('type')
          })
          this.Chip(this.sortKey === 'status' ? '✓ 状态' : '状态', () => {
            this.onChangeSortKey('status')
          })
          this.Chip(this.sortKey === 'plant' ? '✓ 植物' : '植物', () => {
            this.onChangeSortKey('plant')
          })
          Text(this.sortAsc ? '↑ 升序' : '↓ 降序')
            .fontSize(12)
            .fontColor(0xFF1565C0)
            .padding({
              left: 10,
              right: 10,
              top: 6,
              bottom: 6
            })
            .borderRadius(12)
            .backgroundColor(0x102196F3)
            .onClick(() => {
              this.onToggleAsc()
            })
        }.padding({ left: 16, right: 16, bottom: 14 })
      }
      .width('100%')
      .backgroundColor(0xFFFFFFFF)
      .borderRadius({
        topLeft: 20,
        topRight: 20,
        bottomLeft: 0,
        bottomRight: 0
      })
      .position({ x: 0, y: 'calc(100% - 70%)' })
      .shadow({
        radius: 24,
        color: 0x33000000,
        offsetX: 0,
        offsetY: -6
      })
    }
    .width('100%').height('100%')
  }

  @Builder
  SectionTitle(t: string) {
    Row() {
      Text(t).fontSize(12).fontColor(0xFF607D8B)
    }
    .padding({
      left: 16,
      right: 16,
      top: 6,
      bottom: 6
    })
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
      .margin({ right: 8, bottom: 8 })
      .onClick(() => {
        onTap()
      })
  }
}
