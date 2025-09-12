/** -------- 子页面：统计（V2 组件） -------- */
@ComponentV2
export struct StatsPage {
  @Param @Require plantCount: number
  @Param @Require taskCount: number
  @Param @Require doneCount: number

  build() {
    Column() {
      Row() {
        this.Card('植物数', this.plantCount.toString(), 0xFF1B5E20)
        this.Card('任务数', this.taskCount.toString(), 0xFF1565C0)
      }.justifyContent(FlexAlign.SpaceAround)
      Row() {
        this.Card('完成率', this.taskCount > 0 ? `${Math.round(this.doneCount * 100 / this.taskCount)}%` : '0%', 0xFFE65100)
        this.Card('进行中', (this.taskCount - this.doneCount).toString(), 0xFF6A1B9A)
      }.justifyContent(FlexAlign.SpaceAround)
    }
    .padding({ left: 12, right: 12, top: 12 })
  }

  @Builder
  Card(title: string, value: string, color: ResourceColor) {
    Column() {
      Text(title).fontSize(12).fontColor(0xFF607D8B)
      Text(value).fontSize(22).fontWeight(FontWeight.Medium).fontColor(color)
    }
    .width('46%').padding(16).borderRadius(16).backgroundColor(0xFFFFFFFF)
    .shadow({ radius: 14, color: 0x12000000, offsetX: 0, offsetY: 4 })
    .animation({ duration: 240, curve: Curve.EaseInOut })
  }
}