@ObservedV2
export
class LogPhoto {
  @Trace id: number
  @Trace logId: number
  @Trace filePath: string // 本地完整路径，建议以 file:// 开头
  @Trace createdAt: number

  constructor(id: number, logId: number, filePath: string, createdAt: number) {
    this.id = id;
    this.logId = logId;
    this.filePath = filePath;
    this.createdAt = createdAt
  }
}

/** 横向缩略图条 + “添加照片”按钮（仅 UI，具体选择动作交给外部 onPick） */
@ComponentV2
export struct PhotoAttachBar {
  @Param @Require photos: Array<LogPhoto>
  @Event onPick: () => void
  @Event onDeleteAsk: (photoId: number) => void
  @Event onPreview: (filePath: string) => void

  build() {
    Column() {
      Row() {
        Text('照片').fontSize(12).fontColor(0xFF607D8B)
        Blank()
        Text('添加')
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
            this.onPick()
          })
      }.padding({ left: 16, right: 16, bottom: 6 })

      // 缩略图横向滚动
      Row() {
        // “添加”圆卡
        Column() {
          Text('＋').fontSize(20).fontColor(0xFF1565C0)
        }
        .width(64)
        .height(64)
        .borderRadius(12)
        .backgroundColor(0xFFE3F2FD)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .onClick(() => {
          this.onPick()
        })
        .margin({ right: 10 })

        ForEach(this.photos, (p: LogPhoto) => {
          Column() {
            // 用文件路径直接显示
            Image(p.filePath)
              .width(64)
              .height(64)
              .borderRadius(12)
              .objectFit(ImageFit.Cover)
              .onClick(() => {
                this.onPreview(p.filePath)
              })
            Text('删除')
              .fontSize(10)
              .fontColor(0xFFE53935)
              .padding({
                left: 8,
                right: 8,
                top: 4,
                bottom: 4
              })
              .borderRadius(10)
              .backgroundColor(0x10E53935)
              .margin({ top: 4 })
              .onClick(() => {
                this.onDeleteAsk(p.id)
              })
          }
          .margin({ right: 10 })
        }, (p: LogPhoto) => p.id.toString())
      }
      .padding({ left: 16, right: 16 })

      // .scrollable(ScrollDirection.Horizontal)
    }
    .padding({ top: 8, bottom: 8 })
  }
}
