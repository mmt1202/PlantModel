/** -------- 自定义弹窗（覆盖式） -------- */
@ComponentV2
export struct ConfirmDialogSheet {
  @Param @Require text: string
  @Event onCancel: () => void
  @Event onConfirm: () => void

  build() {
    Stack() {
      Column() {
        Blank().width('100%').height('100%').backgroundColor(0x66000000).onClick(() => {
          this.onCancel()
        })
      }

      Column() {
        Text('请确认').fontSize(16).fontWeight(FontWeight.Medium).fontColor(0xFF263238).margin({ bottom: 6 })
        Text(this.text).fontSize(14).fontColor(0xFF607D8B)
        Row() {
          Button('取消')
            .type(ButtonType.Capsule)
            .onClick(() => {
              this.onCancel()
            })
            .backgroundColor(0xFFE0E0E0)
            .fontColor(0xFF263238)
            .borderRadius(18)
            .padding({
              left: 18,
              right: 18,
              top: 8,
              bottom: 8
            })
          Button('确认')
            .type(ButtonType.Capsule)
            .onClick(() => {
              this.onConfirm()
            })
            .backgroundColor(0xFF2E7D32)
            .fontColor(0xFFFFFFFF)
            .borderRadius(18)
            .padding({
              left: 18,
              right: 18,
              top: 8,
              bottom: 8
            })
            .margin({ left: 12 })
        }.margin({ top: 14 })
      }
      .padding(16)
      .borderRadius(20)
      .backgroundColor(0xFFFFFFFF)
      .shadow({
        radius: 24,
        color: 0x44000000,
        offsetX: 0,
        offsetY: 8
      })
      // .position({ x: '', y: '30%' })
      .width('90%')
      .animation({ duration: 180, curve: Curve.EaseInOut })
    }.width('100%').height('100%')
  }
}