import { Plant } from "../model/PlantModel"

/** -------- 子组件：单个植物卡片（V2） -------- */
@ComponentV2
export  struct PlantCard {
  @Param @Require p: Plant
  @Param @Require done: number
  @Param @Require total: number
  @Param @Require ratioText: string
  @Event onQuickAdd: (type: string) => void
  @Event onEdit: () => void
  @Event onDeleteAsk: () => void
  @Event onOpenLogs: () => void
  @Event onOpenMetrics: () => void
  @Event onOpenTemplate: () => void  // ← 新增

  @Local pressed: boolean = false

  private typeColor(t: string): ResourceColor {
    if (t === '浇水') { return 0xFF3AAFA9 }
    if (t === '施肥') { return 0xFF8E7CC3 }
    if (t === '修剪') { return 0xFFE57373 }
    return 0xFF607D8B
  }

  build() {
    Column() {
      Row() {
        // 头像圆片
        Column() {
          if (this.p.name.length > 0) { Text(this.p.name.substring(0, 1)).fontSize(18).fontWeight(FontWeight.Medium).fontColor(0xFFFFFFFF) }
          else { Text('植').fontSize(18).fontWeight(FontWeight.Medium).fontColor(0xFFFFFFFF) }
        }
        .width(40).height(40).borderRadius(20).backgroundColor(0xFF66BB6A)
        .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)

        Column() {
          Text(this.p.name).fontSize(16).fontWeight(FontWeight.Medium).fontColor(0xFF263238)
          Text(`${this.p.species} · ${this.p.location}`).fontSize(12).fontColor(0xFF607D8B).margin({ top: 2 })
        }.margin({ left: 10 })

        Blank()

        Row() {
          Text('日志').fontSize(12).fontColor(0xFF1565C0)
            .padding({ left: 10, right: 10, top: 6, bottom: 6 }).borderRadius(12).backgroundColor(0x102196F3)
            .onClick(() => { this.onOpenLogs() })
            .margin({ right: 8 })

          Text('指标').fontSize(12).fontColor(0xFF2E7D32)
            .padding({ left: 10, right: 10, top: 6, bottom: 6 }).borderRadius(12).backgroundColor(0xE8F5E9)
            .onClick(() => { this.onOpenMetrics() })
            .margin({ right: 8 })

          // ← 新增：模板
          Text('模板').fontSize(12).fontColor(0xFF8E24AA)
            .padding({ left: 10, right: 10, top: 6, bottom: 6 }).borderRadius(12).backgroundColor(0x10BA68C8)
            .onClick(() => { this.onOpenTemplate() })
            .margin({ right: 8 })

          Text('✏️').fontSize(16).onClick(() => { this.onEdit() }).margin({ right: 8 })
          Text('🗑️').fontSize(16).onClick(() => { this.onDeleteAsk() })
        }
      }

      // 进度条
      Row() {
        Column() {
          Blank().width('100%').height(6).borderRadius(3).backgroundColor(0xFFE0E0E0)
          Blank().position({ x: 0, y: -6 }).width(this.total > 0 ? this.ratioText : '0%').height(6).borderRadius(3).backgroundColor(0xFF66BB6A)
            .animation({ duration: 220, curve: Curve.EaseInOut })
        }.width('70%')
        Text(`${this.done}/${this.total}`).fontSize(12).fontColor(0xFF455A64).margin({ left: 12 })
      }.margin({ top: 10 })

      // 快捷添加
      Row() { this.QuickChip('浇水'); this.QuickChip('施肥'); this.QuickChip('修剪') }.margin({ top: 10 })
    }
    .padding(14).borderRadius(16).backgroundColor(0xFFFFFFFF)
    .linearGradient({ direction: GradientDirection.Right, colors: [[0x10A5D6A7, 0], [0x1000BCD4, 1]] })
    .shadow({ radius: 16, color: 0x1F000000, offsetX: 0, offsetY: 4 })
    .scale(this.pressed ? { x: 0.98, y: 0.98 } : { x: 1, y: 1 })
    .onTouch((e: TouchEvent) => { if (e.type === TouchType.Down) { this.pressed = true } if (e.type === TouchType.Up || e.type === TouchType.Cancel) { this.pressed = false } })
    .animation({ duration: 120, curve: Curve.EaseInOut })
  }

  @Builder
  QuickChip(text: string) {
    Text(text)
      .fontSize(12).fontColor(0xFF263238)
      .padding({ left: 10, right: 10, top: 6, bottom: 6 })
      .borderRadius(12).backgroundColor(this.typeColor(text))
      .onClick(() => { this.onQuickAdd(text) })
      .margin({ right: 8 })
  }
}