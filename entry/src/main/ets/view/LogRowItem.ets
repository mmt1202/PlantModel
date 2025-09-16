import { LogPhoto, PlantLog } from "./PlantLogSheet";

@ComponentV2
export struct LogRowItem {
  @Local pressedLog: boolean = false;
  @Param @Require lg:PlantLog
  @Param @Require selectMode: boolean
  @Param @Require photos: Array<LogPhoto>
  @Param keyword: string = '' // 关键字高亮（可为空）
  @Event isSelected: (lgId:number)=> boolean
  @Event toggleSelect: (lgId:number)=> void
  @Event onPickPhotos: (logId: number) => void
  @Event onCapturePhoto: (logId: number) => void
  @Event onDeleteLog: (logId: number) => void
  @Event onDeletePhoto: (photoId: number) => void
  @Event onselectMode: (selectMode: boolean) => void
  @Event onPreviewVisible: (path:string, visible: boolean) => void


  private dateFromTs(ts: number): string {
    const d = new Date(ts);
    const y = d.getFullYear();
    const m = (d.getMonth() + 1).toString().padStart(2, '0');
    const day = d.getDate().toString().padStart(2, '0');
    return `${y}-${m}-${day}`
  }

  private beforeKeyword(text: string): string {
    const kw: string = this.keyword.toLowerCase()
    const src: string = text
    const i: number = src.toLowerCase().indexOf(kw)
    if (kw.length === 0 || i < 0) {
      return src
    }
    return src.substring(0, i)
  }

  private midKeyword(text: string): string {
    const kw: string = this.keyword.toLowerCase()
    const src: string = text
    const i: number = src.toLowerCase().indexOf(kw)
    if (kw.length === 0 || i < 0) {
      return ''
    }
    return src.substring(i, i + kw.length)
  }

  private afterKeyword(text: string): string {
    const kw: string = this.keyword.toLowerCase()
    const src: string = text
    const i: number = src.toLowerCase().indexOf(kw)
    if (kw.length === 0 || i < 0) {
      return ''
    }
    return src.substring(i + kw.length)
  }

  private photosByLog(logId: number): Array<LogPhoto> {
    const out: Array<LogPhoto> = []
    let i: number = 0
    while (i < this.photos.length) {
      if (this.photos[i].logId === logId) {
        out.push(this.photos[i])
      }
      i = i + 1
    }
    return out
  }

  build() {
    Column() {
      Row() {
        if (this.selectMode) {
          Text(this.isSelected(this.lg.id) ? '✅' : '⬜').fontSize(18)
        }
        Column() {
          Text(this.dateFromTs(this.lg.createdAt)).fontSize(12).fontColor(0xFF607D8B)
          this.HighlightLine(this.lg.note)
        }.margin({ left: this.selectMode ? 8 : 0 })
        .width(`calc(100% - 120vp)`)
        .alignItems(HorizontalAlign.Start)

        Blank()
        Row() {
          Text('🖼️').fontSize(16).onClick(() => {
            this.onPickPhotos(this.lg.id)
          }).margin({ right: 10 })
          Text('📷').fontSize(16).onClick(() => {
            this.onCapturePhoto(this.lg.id)
          }).margin({ right: 10 })
          Text('🗑️').fontSize(16).onClick(() => {
            if (this.selectMode) {
              this.toggleSelect(this.lg.id)
            } else {
              this.onDeleteLog(this.lg.id)
            }
          })
        }.width(100).justifyContent(FlexAlign.SpaceAround)
      }.width('100%').justifyContent(FlexAlign.SpaceBetween)

      // 照片网格
      this.PhotoGrid(this.lg.id)
    }
    .width('100%')
    .padding(12)
    .borderRadius(12)
    .scale(this.pressedLog ? { x: 0.98, y: 0.98 } : { x: 1, y: 1 })
    .backgroundColor(0xFFFFFFFF)
    .shadow({
      radius: 12,
      color: 0x14000000,
      offsetX: 0,
      offsetY: 3
    })
    .onTouch((e: TouchEvent) => {
      if (e.type === TouchType.Down) {
        this.pressedLog = true
      }
      if (e.type === TouchType.Up || e.type === TouchType.Cancel) {
        this.pressedLog = false
      }
    })
    .onClick(() => {
      if (this.selectMode) {
        this.toggleSelect(this.lg.id)
      }
    })
    .gesture(
      LongPressGesture({ repeat: true })
        .onAction((event: GestureEvent | undefined) => {
          if (event) {
            if (event.repeat) {
              this.onselectMode(true)
            }
          }
        })
    )
    .animation({ duration: 120, curve: Curve.EaseInOut })
  }
  @Builder
  HighlightLine(text: string) {
    // 简单高亮：前后拆分为 3 段
    if (this.keyword.length === 0) {
      Text(text).fontSize(15).fontWeight(FontWeight.Medium).fontColor(0xFF263238)
    } else {
      // 为了遵守 @Builder 规则，不在此处做 split；改为调用方法拆分并一次性渲染
      this.HighlightPieces(text)
    }
  }
  @Builder
  HighlightPieces(text: string) {
    // 依靠三个 Text 拼装（前/中/后）
    Column() {
      // 用多行容器承载，避免超长一行不换行
      Text(this.beforeKeyword(text)).fontSize(15).fontColor(0xFF263238)
      Text(this.midKeyword(text)).fontSize(15).fontColor(0xFFD84315).fontWeight(FontWeight.Medium)
      Text(this.afterKeyword(text)).fontSize(15).fontColor(0xFF263238)
    }
  }

  @Builder
  PhotoGrid(logId: number) {
    // 三列栅格：每项使用缩略图路径（无缩略图则用原图）
    // ArkUI 中 ForEach 的第二个参数提供 key
    Row() {
      ForEach(this.photosByLog(logId), (ph: LogPhoto) => {
        Column() {
          Image(ph.thumbPath.length > 0 ? ph.thumbPath : ph.path)
            .width('31%')
            .aspectRatio(1)
            .borderRadius(10)
            .objectFit(ImageFit.Cover)
            .onClick(() => {
              this.onPreviewVisible(ph.path,true)
            })
          Text('移除')
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
              this.onDeletePhoto(ph.id)
            })
        }
        .width('31%').margin({ right: 6, top: 6 })
      }, (ph: LogPhoto) => ph.id.toString())
    }
    // .wrap(WrapStyle.Wrap)
    .justifyContent(FlexAlign.SpaceBetween)
  }
}