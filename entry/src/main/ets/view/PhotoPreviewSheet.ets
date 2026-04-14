/** 大图预览（全屏 Sheet） */
@ComponentV2
export struct PhotoPreviewSheet {
  @Param @Require files: Array<string>
  @Param @Require startIndex: number
  @Event onDelete: (index: number) => void
  @Event onClose: () => void
  @Local index: number = 0
  @Local scaleImage: number = 1.0 // 1.0 / 1.8 切换
  @Local bgDark: number = 0xE6000000
  // 预览动画
  @Local previewScale: number = 0
  @Local previewOpacity: number = 0
  @Local imageTranslateX: number = 0
  @Local imageOpacity: number = 1

  aboutToAppear(): void {
    // 起始下标越界保护
    let i: number = this.startIndex
    if (i < 0) {
      i = 0
    }
    if (i >= this.files.length) {
      i = this.files.length > 0 ? this.files.length - 1 : 0
    }
    this.index = i
    // 预览打开动画
    setTimeout(() => {
      animateTo({ duration: 300, curve: Curve.EaseOut }, () => {
        this.previewScale = 1
        this.previewOpacity = 1
      })
    }, 50)
  }

  private total(): number {
    return this.files.length
  }

  private canPrev(): boolean {
    return this.index > 0
  }

  private canNext(): boolean {
    return this.index + 1 < this.files.length
  }

  private fileAt(i: number): string {
    return (i >= 0 && i < this.files.length) ? this.files[i] : ''
  }

  private stepPrev(): void {
    if (this.index > 0) {
      // 切换动画:先向右滑出
      animateTo({ duration: 150, curve: Curve.EaseInOut }, () => {
        this.imageTranslateX = 50
        this.imageOpacity = 0
      })
      setTimeout(() => {
        this.index = this.index - 1
        this.scaleImage = 1.0
        this.imageTranslateX = -50
        this.imageOpacity = 0
        // 再滑入
        animateTo({ duration: 200, curve: Curve.EaseOut }, () => {
          this.imageTranslateX = 0
          this.imageOpacity = 1
        })
      }, 150)
    }
  }

  private stepNext(): void {
    if (this.index + 1 < this.files.length) {
      // 切换动画:先向左滑出
      animateTo({ duration: 150, curve: Curve.EaseInOut }, () => {
        this.imageTranslateX = -50
        this.imageOpacity = 0
      })
      setTimeout(() => {
        this.index = this.index + 1
        this.scaleImage = 1.0
        this.imageTranslateX = 50
        this.imageOpacity = 0
        // 再滑入
        animateTo({ duration: 200, curve: Curve.EaseOut }, () => {
          this.imageTranslateX = 0
          this.imageOpacity = 1
        })
      }, 150)
    }
  }

  private toggleZoom(): void {
    if (this.scaleImage === 1.0) {
      this.scaleImage = 1.8
    } else {
      this.scaleImage = 1.0
    }
  }

  build() {
    // 蒙层 + 顶部工具条 + 中部图片 + 底部计数
    Column() {
      // 半透明背景,可点空白退出
      Blank()
        .width('100%')
        .height('100%')
        .backgroundColor(this.bgDark)
        .opacity(this.previewOpacity)
        .onClick(() => {
          this.onClose()
        })

      // 顶部工具条
      Row() {
        Text(`${this.index + 1}/${this.total()}`)
          .fontSize(14)
          .fontColor(0xFFFFFFFF)
          .padding({
            left: 10,
            right: 10,
            top: 6,
            bottom: 6
          })
          .borderRadius(12)
          .backgroundColor(0x33000000)

        Blank()

        Text('删除')
          .fontSize(12)
          .fontColor(0xFFFFFFFF)
          .padding({
            left: 12,
            right: 12,
            top: 8,
            bottom: 8
          })
          .borderRadius(18)
          .backgroundColor(0xFFE53935)
          .onClick(() => {
            this.onDelete(this.index)
          })

        Text('✕').fontColor('#000000')
          .fontSize(18).fontColor(0xFFFFFFFF)
          .padding({
            left: 12,
            right: 12,
            top: 8,
            bottom: 8
          })
          .onClick(() => {
            this.onClose()
          })
      }
      .padding({
        left: 16,
        right: 16,
        top: 16,
        bottom: 6
      })
      .position({ x: 0, y: 0 })

      // 中部图片区域（左右点击切换，单击缩放）
      Row() {
        // 上一张
        Column() {
          if (this.canPrev()) {
            Text('‹').fontSize(28).fontColor(0xFFFFFFFF)
          } else {
            Text(' ').fontSize(28).fontColor(0x00FFFFFF)
          }
        }
        .width('12%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .onClick(() => {
          this.stepPrev()
        })

        // 当前图
        Column() {
          Image(this.fileAt(this.index))
            .objectFit(ImageFit.Contain)
            .width('100%')
            .height('100%')
            .scale({ x: this.scaleImage * this.previewScale, y: this.scaleImage * this.previewScale })
            .translate({ x: this.imageTranslateX, y: 0 })
            .opacity(this.imageOpacity)
            .animation({ duration: 250, curve: Curve.EaseInOut })
            .onClick(() => {
              this.toggleZoom()
            })
        }
        .width('76%').height('100%')
        .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)

        // 下一张
        Column() {
          if (this.canNext()) {
            Text('›').fontSize(28).fontColor(0xFFFFFFFF)
          } else {
            Text(' ').fontSize(28).fontColor(0x00FFFFFF)
          }
        }
        .width('12%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .onClick(() => {
          this.stepNext()
        })
      }
      .width('100%').height('100%')
      .position({ x: 0, y: 0 })
    }
    .width('100%').height('100%')
  }
}
