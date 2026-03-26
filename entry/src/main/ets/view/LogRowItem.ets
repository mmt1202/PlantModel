import { LogPhoto, PlantLog } from './PlantLogSheet';

@ComponentV2
export struct LogRowItem {
  @Local pressedLog: boolean = false;
  @Param @Require lg: PlantLog
  @Param @Require selectMode: boolean
  @Param @Require photos: Array<LogPhoto>
  @Param @Require logItemPhotos: Array<LogPhoto>
  @Param keyword: string = ''
  @Event isSelected: (lgId: number) => boolean
  @Event toggleSelect: (lgId: number) => void
  @Event onPickPhotos: (logId: number) => void
  @Event onCapturePhoto: (logId: number) => void
  @Event onDeleteLog: (logId: number) => void
  @Event onDeletePhoto: (photoId: number) => void
  @Event onselectMode: (selectMode: boolean) => void
  @Event onPreviewVisible: (path: string, visible: boolean) => void

  // 这一行组件只负责单条日志的展示和交互，真正的增删改仍由日志页统一处理。
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

  // 这里保留按 logId 过滤照片的能力，便于未来恢复独立的日志图片网格模式。
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
    // 单条日志卡片只负责展示文字和附件缩略图，不直接持有数据库状态。
    Column({ space: 5 }) {
      Row() {
        if (this.selectMode) {
          Text(this.isSelected(this.lg.id) ? '✔' : '○').fontSize(18)
        }
        Column() {
          Text(this.dateFromTs(this.lg.createdAt)).fontSize(12).fontColor(0xFF607D8B)
          this.HighlightLine(this.lg.note)
        }.margin({ left: this.selectMode ? 8 : 0 })
        .width(`calc(100% - 120vp)`)
        .alignItems(HorizontalAlign.Start)

        Blank()
        Row() {
          Text('📤').fontSize(16).onClick(() => {
            this.onPickPhotos(this.lg.id)
          }).margin({ right: 10 })
          Text('📲').fontSize(16).onClick(() => {
            this.onCapturePhoto(this.lg.id)
          }).margin({ right: 10 })
          Text('🗏').fontSize(16).onClick(() => {
            if (this.selectMode) {
              this.toggleSelect(this.lg.id)
            } else {
              this.onDeleteLog(this.lg.id)
            }
          })
        }.width(100).justifyContent(FlexAlign.SpaceAround)
      }.width('100%').justifyContent(FlexAlign.SpaceBetween)

      this.AddPic(this.lg.id)
    }
    .width('100%')
    .padding(12)
    .borderRadius(12)
    .scale(this.pressedLog ? { x: 0.98, y: 0.98 } : { x: 1, y: 1 })
    .backgroundColor(0xFFFFFFFF)
    .shadow({ radius: 12, color: 0x13000000, offsetX: 0, offsetY: 3 })
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
          if (event && event.repeat) {
            this.onselectMode(true)
          }
        })
    )
    .animation({ duration: 120, curve: Curve.EaseInOut })
  }

  @Builder
  HighlightLine(text: string) {
    if (this.keyword.length === 0) {
      Text(text).fontSize(15).fontWeight(FontWeight.Medium).fontColor(0xFF263238)
    } else {
      this.HighlightPieces(text)
    }
  }

  @Builder
  HighlightPieces(text: string) {
    Column() {
      Text(this.beforeKeyword(text)).fontSize(15).fontColor(0xFF263238)
      Text(this.midKeyword(text)).fontSize(15).fontColor(0xFFD84315).fontWeight(FontWeight.Medium)
      Text(this.afterKeyword(text)).fontSize(15).fontColor(0xFF263238)
    }
  }

  @Builder
  AddPic(logId: number) {
    // 当前用 Grid 直接展示某条日志下的附件，并把删除事件回抛给父页。
    Column() {
      Grid() {
        ForEach(this.logItemPhotos, (item: LogPhoto, index: number) => {
          GridItem() {
            RelativeContainer() {
              Image(item.path)
                .borderRadius(4)
                .visibility(item ? Visibility.Visible : Visibility.None)
                .width($r('app.integer.add_image_area_size'))
                .height($r('app.integer.add_image_area_size'))
                .onClick(() => {
                  this.onPreviewVisible(item.path, true)
                })

              Image($r('app.media.ic_image_delete'))
                .width(12)
                .height(12)
                .alignRules({
                  top: { anchor: "__container__", align: VerticalAlign.Top },
                  right: { anchor: "__container__", align: HorizontalAlign.End }
                })
                .margin(8)
                .onClick(() => {
                  this.onDeletePhoto(item.id)
                })
            }.width($r('app.integer.add_image_area_size'))
            .height($r('app.integer.add_image_area_size'))

          }.width($r('app.integer.add_image_area_size'))
          .height($r('app.integer.add_image_area_size'))
        }, (item: LogPhoto, index: number) => JSON.stringify(item) + index)
      }
      .width('100%')
      .columnsTemplate('1fr 1fr 1fr')
      .nestedScroll({
        scrollForward: NestedScrollMode.PARENT_FIRST,
        scrollBackward: NestedScrollMode.SELF_FIRST
      })
      .height(this.getImageGridHeight(this.logItemPhotos.length))
      .layoutDirection(GridDirection.Row)
      .columnsGap(8)
      .rowsGap(8)
      .maxCount(3)
      .minCount(1)
      .cellLength(104)

    }
    .padding({ right: 24, left: 24 })
  }

  getImageGridHeight(ctn: number) {
    let h = 0;
    if (ctn > 9) {
      h = 328 + 104
    }
    if (ctn > 6) {
      h = 328
    }
    if (ctn > 3) {
      h = 216
    }
    if (ctn > 0) {
      h = 104
    }
    return h
  }

  @Builder
  AddDefaultPic(logId: number) {
    Stack() {
      Image($r('app.media.ic_add_pic2'))
        .objectFit(ImageFit.Cover)
        .width(104)
        .height(104)
    }
    .alignContent(Alignment.Center)
    .backgroundColor('#F4F5F7')
    .margin({ bottom: 36 })
    .onClick(() => {
      if (this.photosByLog(logId).length < 9) {
        this.onCapturePhoto(this.lg.id)
      }
    })
  }

  @Builder
  PhotoGrid(logId: number) {
    Row() {
      ForEach(this.photosByLog(logId), (ph: LogPhoto) => {
        Column() {
          Image(ph.thumbPath.length > 0 ? ph.thumbPath : ph.path)
            .width('31%')
            .aspectRatio(1)
            .borderRadius(10)
            .objectFit(ImageFit.Cover)
            .onClick(() => {
              this.onPreviewVisible(ph.path, true)
            })
          Text('移除')
            .fontSize(10)
            .fontColor(0xFFE53935)
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
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
    .justifyContent(FlexAlign.SpaceBetween)
  }
}
