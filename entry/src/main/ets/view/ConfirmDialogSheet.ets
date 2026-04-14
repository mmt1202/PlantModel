/** -------- 自定义弹窗（覆盖式） -------- */
@ComponentV2
export struct ConfirmDialogSheet {
  @Param @Require text: string
  @Event onCancel: () => void
  @Event onConfirm: () => void
  // 按钮按压状态
  @Local cancelPressed: boolean = false
  @Local confirmPressed: boolean = false
  // 背景遮罩动画
  @Local maskOpacity: number = 0

  aboutToAppear(): void {
    // 背景遮罩渐显动画
    animateTo({ duration: 250, curve: Curve.EaseInOut }, () => {
      this.maskOpacity = 1
    })
  }

  build() {
    Stack() {
      Column() {
        Blank()
          .width('100%')
          .height('100%')
          .backgroundColor(`rgba(0,0,0,${0.6 * this.maskOpacity})`)
          .onClick(() => {
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
            .scale(this.cancelPressed ? { x: 0.95, y: 0.95 } : { x: 1, y: 1 })
            .animation({ duration: 100, curve: Curve.EaseOut })
            .onTouch((e: TouchEvent) => {
              if (e.type === TouchType.Down) {
                this.cancelPressed = true
              } else if (e.type === TouchType.Up || e.type === TouchType.Cancel) {
                this.cancelPressed = false
              }
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
            .scale(this.confirmPressed ? { x: 0.95, y: 0.95 } : { x: 1, y: 1 })
            .animation({ duration: 100, curve: Curve.EaseOut })
            .onTouch((e: TouchEvent) => {
              if (e.type === TouchType.Down) {
                this.confirmPressed = true
              } else if (e.type === TouchType.Up || e.type === TouchType.Cancel) {
                this.confirmPressed = false
              }
            })
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
      .animation({
        duration: 300,
        curve: Curve.Friction,
        playMode: PlayMode.Normal
      })
    }.width('100%').height('100%')
  }
}