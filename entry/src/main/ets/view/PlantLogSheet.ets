import { LogRowItem } from './LogRowItem';

@ObservedV2
export class PlantLog {
  @Trace id: number
  @Trace plantId: number
  @Trace note: string
  @Trace createdAt: number

  constructor(id: number, plantId: number, note: string, createdAt: number) {
    this.id = id;
    this.plantId = plantId;
    this.note = note;
    this.createdAt = createdAt
  }
}

@ObservedV2
export class LogPhoto {
  @Trace id: number
  @Trace logId: number
  @Trace path: string // 原图（filesDir 下）
  @Trace thumbPath: string // 缩略图（可与原图相同；若无缩略图，则传原图）
  @Trace createdAt: number

  constructor(id: number, logId: number, path: string, thumbPath: string, createdAt: number) {
    this.id = id;
    this.logId = logId;
    this.path = path;
    this.thumbPath = thumbPath;
    this.createdAt = createdAt
  }
}

@ComponentV2
export struct PlantLogSheet {
  @Param @Require plantName: string
  @Param @Require logs: Array<PlantLog>
  @Param @Require photos: Array<LogPhoto>
  @Param keyword: string = '' // 关键字高亮（可为空）
  @Event onAddLog: (note: string, dateISO: string) => void
  @Event onDeleteLog: (logId: number) => void
  @Event onBatchDeleteLogs: (logIds: Array<number>) => void
  @Event onPickPhotos: (logId: number) => void
  @Event onCapturePhoto: (logId: number) => void
  @Event onDeletePhoto: (photoId: number) => void
  @Event onDelete: (lid: number) => void
  @Event onBatchDelete: (ids: Array<number>) => void
  @Event onPreviewPhoto: (fp: string) => void
  @Event onClose: () => void
  // 本地状态
  @Local noteText: string = ''
  @Local dateISO: string = ''
  @Local sortAsc: boolean = false
  @Local selectMode: boolean = false
  @Local selected: Array<number> = [] // 选中的 logId
  @Local previewVisible: boolean = false
  @Local previewPath: string = ''
  @Local pressedLog: boolean = false

  aboutToAppear(): void {
    this.dateISO = this.todayISO()
  }

  build() {
    Column() {
      Blank().width('100%').height('100%').backgroundColor(0x66000000).onClick(() => {
        this.onClose()
      })

      Column() {
        Row() {
          Text(`${this.plantName} · 日志`).fontSize(16).fontWeight(FontWeight.Medium).fontColor(0xFF263238)
          Blank()
          if (this.selectMode) {
            Text(`删除(${this.selected.length})`)
              .fontSize(12)
              .fontColor(0xFFFFFFFF)
              .padding({
                left: 12,
                right: 12,
                top: 6,
                bottom: 6
              })
              .borderRadius(14)
              .backgroundColor(0xFFE53935)
              .onClick(() => {
                if (this.selected.length > 0) {
                  this.onBatchDeleteLogs(this.copyIds(this.selected));
                  this.selected = [];
                  this.selectMode = false
                }
              })
          }
          Text('✕').fontSize(18).onClick(() => {
            this.onClose()
          }).margin({ left: 8 })
        }
        .padding({
          left: 16,
          right: 16,
          top: 12,
          bottom: 6
        })

        Row() {
          Text(this.sortAsc ? '时间 ↑' : '时间 ↓')
            .fontSize(12)
            .fontColor(0xFF1565C0)
            .padding({
              left: 10,
              right: 10,
              top: 6,
              bottom: 6
            })
            .borderRadius(14)
            .backgroundColor(0x102196F3)
            .onClick(() => {
              this.sortAsc = !this.sortAsc
            })
          if (this.selectMode) {
            Text('取消选择')
              .fontSize(12)
              .fontColor(0xFF263238)
              .padding({
                left: 10,
                right: 10,
                top: 6,
                bottom: 6
              })
              .borderRadius(14)
              .backgroundColor(0xFFE0E0E0)
              .onClick(() => {
                this.selected = [];
                this.selectMode = false
              })
              .margin({ left: 8 })
          } else {
            Text('长按进入多选')
              .fontSize(12)
              .fontColor(0x80607278)
              .padding({
                left: 10,
                right: 10,
                top: 6,
                bottom: 6
              })
          }
          Blank()
          if (this.keyword.length > 0) {
            Text(`关键词: ${this.keyword}`).fontSize(12).fontColor(0xFF607D8B)
          }
        }.padding({ left: 16, right: 16, bottom: 8 })

        // 新增日志
        Column() {
          this.FormItem('内容', '写点什么…', this.noteText, (v: string) => {
            this.noteText = v
          })
          Row() {
            Column() {
              Text('日期').fontSize(12).fontColor(0xFF607D8B);
              Text(this.dateISO).fontSize(13).fontColor(0xFF263238).margin({ top: 4 })
            }

            Blank()
            Text('今天')
              .fontSize(12)
              .fontColor(0xFF1565C0)
              .padding({
                left: 12,
                right: 12,
                top: 6,
                bottom: 6
              })
              .borderRadius(14)
              .backgroundColor(0x102196F3)
              .onClick(() => {
                this.dateISO = this.todayISO()
              })
          }.padding({ top: 6, bottom: 6 })

          Row() {
            Text('添加日志')
              .fontSize(14)
              .fontColor(0xFFFFFFFF)
              .padding({
                left: 18,
                right: 18,
                top: 8,
                bottom: 8
              })
              .borderRadius(18)
              .backgroundColor(0xFF2E7D32)
              .onClick(() => {
                if (this.noteText.trim().length === 0) {
                  return
                }
                this.onAddLog(this.noteText.trim(), this.dateISO);
                this.noteText = ''
              })
          }
        }.padding({ left: 16, right: 16, bottom: 8 })

        // 列表
        if (this.sorted().length === 0) {
          Column() {
            Text('暂无日志').fontSize(12).fontColor(0xFF90A4AE)
          }
          .padding({ left: 16, right: 16, bottom: 18 })
        } else {
          List({ space: 8 }) {
            ForEach(this.sorted(), (lg: PlantLog, index: number) => {
              ListItem() {
                // this.LogRow(lg, index)
                LogRowItem({
                  lg: lg,
                  selectMode: this.selectMode,
                  photos: this.photos,
                  logItemPhotos: this.photos.filter(i => i.logId === lg.id) || [],
                  keyword: this.keyword,
                  isSelected: (lgId: number) => this.isSelected(lgId),
                  toggleSelect: (lgId: number) => {
                    this.toggleSelect(lgId)
                  },
                  onPickPhotos: (logId: number) => {
                    this.onPickPhotos(logId)
                  },
                  onCapturePhoto: (logId: number) => {
                    this.onCapturePhoto(logId)
                  },
                  onDeleteLog: (logId: number) => {
                    this.onDeleteLog(logId)
                  },
                  onDeletePhoto: (photoId: number) => {
                    this.onDeletePhoto(photoId)
                  },
                  onselectMode: (selectMode: boolean) => {
                    this.selectMode = selectMode
                  },
                  onPreviewVisible: (path: string, visible: boolean) => {
                    this.previewVisible = visible
                    this.previewPath = path
                  },

                })
              }
            }, (lg: PlantLog) => lg.id.toString())
          }
          .padding({ left: 16, right: 16, bottom: 16 })
          .edgeEffect(EdgeEffect.Spring)
        }
      }
      .width('100%')
      .backgroundColor(0xFFFFFFFF)
      .borderRadius({
        topLeft: 20,
        topRight: 20,
        bottomLeft: 0,
        bottomRight: 0
      })
      .position({ x: 0, y: 'calc(100% - 86%)' })
      .shadow({
        radius: 24,
        color: 0x33000000,
        offsetX: 0,
        offsetY: -6
      })
      .animation({ duration: 200, curve: Curve.Sharp })

      // 图片预览
      if (this.previewVisible) {
        Column() {
          Blank().width('100%').height('100%').backgroundColor(0xCC000000).onClick(() => {
            this.previewVisible = false
          })
          Column() {
            Image(this.previewPath).objectFit(ImageFit.Contain).width('92%').height('70%').borderRadius(12)
          }.width('100%').height('100%').justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
        }.width('100%').height('100%')
      }
    }.width('100%').height('100%')
  }

  @Builder
  FormItem(label: string, placeholder: string, val: string, onChange: (v: string) => void) {
    Column() {
      Text(label).fontSize(12).fontColor(0xFF607D8B)
      TextInput({ placeholder: placeholder, text: val })
        .placeholderColor('#747474').fontColor('#000000')
        .onChange((v: string) => {
          onChange(v)
        })
        .width('100%')
        .height(40)
        .borderRadius(12)
        .backgroundColor(0xFFF9F9F9)
        .padding({ left: 12, right: 12 })
        .margin({ top: 6 })
    }.margin({ top: 6 })
  }

  @Builder
  LogRow(lg: PlantLog, index: number) {

  }

  // —— 逻辑方法 —— //
  private sorted(): Array<PlantLog> {
    // 先简单复制再排序（不在 @Builder 内部）
    const arr: Array<PlantLog> = []
    let i: number = 0
    while (i < this.logs.length) {
      arr.push(this.logs[i]);
      i = i + 1
    }
    arr.sort((a: PlantLog, b: PlantLog) => this.sortAsc ? (a.createdAt - b.createdAt) : (b.createdAt - a.createdAt))
    return arr
  }

  private isSelected(id: number): boolean {
    let i: number = 0
    while (i < this.selected.length) {
      if (this.selected[i] === id) {
        return true
      }
      i = i + 1
    }
    return false
  }

  private toggleSelect(id: number): void {
    const arr: Array<number> = []
    let removed: boolean = false
    let i: number = 0
    while (i < this.selected.length) {
      if (this.selected[i] === id) {
        removed = true
      } else {
        arr.push(this.selected[i])
      }
      i = i + 1
    }
    if (!removed) {
      arr.push(id)
    }
    this.selected = arr
  }

  private copyIds(src: Array<number>): Array<number> {
    const out: Array<number> = []
    let i: number = 0
    while (i < src.length) {
      out.push(src[i]);
      i = i + 1
    }
    return out
  }

  private todayISO(): string {
    const d = new Date();
    const y = d.getFullYear();
    const m = (d.getMonth() + 1).toString().padStart(2, '0');
    const day = d.getDate().toString().padStart(2, '0');
    return `${y}-${m}-${day}`
  }
}


// 高亮片段模型（内部使用）
class _HL {
  key: number
  text: string
  // 0: 普通，1: 命中
  hit: number

  constructor(key: number, text: string, hit: number) {
    this.key = key;
    this.text = text;
    this.hit = hit
  }
}

