import { LogPhoto, PlantLog } from "./PlantLogSheet";

@ComponentV2
export struct LogRowItem {
  @Local pressedLog: boolean = false;
  @Param @Require lg:PlantLog
  @Param @Require selectMode: boolean
  @Param @Require photos: Array<LogPhoto>
  @Param @Require logItemPhotos: Array<LogPhoto>
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
    Column({space:5}) {
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
      // this.PhotoGrid(this.lg.id)
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
  AddPic(logId: number) {
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

              Image($r('app.media.ic_image_delete'))
                .width(12)
                .height(12)
                .alignRules({
                  top: { anchor: "__container__", align: VerticalAlign.Top },
                  right: { anchor: "__container__", align: HorizontalAlign.End }
                })
                .margin(8)
                .onClick(() => {
                  // this.deleteMicroOnClick(index)
                  this.onDeletePhoto(item.id)
                })


              // Text('编辑')
              //   .fontSize(12)
              //   .fontColor('#FFFFFF')
              //   .fontWeight(400)
              //   .alignRules({
              //     bottom: { anchor: "__container__", align: VerticalAlign.Bottom },
              //     left: { anchor: "__container__", align: HorizontalAlign.Start }
              //   })
              //   .margin(8)
            }.width($r('app.integer.add_image_area_size'))
            .height($r('app.integer.add_image_area_size'))

          }.width($r('app.integer.add_image_area_size'))
          .height($r('app.integer.add_image_area_size'))
        }, (item: LogPhoto, index: number) => JSON.stringify(item) + index)
        // if (this.photosByLog(logId).length < 12) {
        //   GridItem() {
        //     this.AddDefaultPic(logId)
        //   }
        //   .width(104)
        //   .height(104)
        // }
      }
      .width('100%')
      .columnsTemplate('1fr 1fr 1fr')
      // .enableScrollInteraction(false)
      .nestedScroll({
        scrollForward: NestedScrollMode.PARENT_FIRST, // Set the effect of scrolling the component to the end: The parent component rolls first, and then rolls itself to the edge
        scrollBackward: NestedScrollMode.SELF_FIRST // Set the effect of rolling the component to the start end: Rolls itself first, and then the parent component scrolls to the edge
      })
      .height(this.getImageGridHeight(this.logItemPhotos.length))
      .layoutDirection(GridDirection.Row)
      .columnsGap(8)
      .rowsGap(8)
      .maxCount(3)
      .minCount(1)
      .cellLength(104)

    }
    .padding({
      right: 24,
      left: 24
    })
  }

  getImageGridHeight(ctn:number){
    let h = 0;
    if (ctn>9) {
      h = 328 + 104
    }
    if (ctn>6) {
      h = 328
    }
    if (ctn>3) {
      h = 216
    }
    if (ctn>1) {
      h = 104
    }
    return h

  }

  @Builder
  AddDefaultPic(logId:number) {
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
      } else {
        // this.getUIContext().getPromptAction().showToast({ message: $r('app.string.add_picture_prompt') });
      }
    })
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