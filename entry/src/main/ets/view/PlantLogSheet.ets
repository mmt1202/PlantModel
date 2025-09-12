import { LogEntry } from '../model/PlantModel'

@ComponentV2
export  struct PlantLogSheet {
  @Param @Require logs: Array<LogEntry>
  @Param @Require plantName: string
  @Param @Require inputText: string
  @Event onChangeInput: (v: string) => void
  @Event onAdd: () => void
  @Event onDelete: (id: number) => void
  @Event onClose: () => void

  build() {
    Column(){
      // 蒙层
      Blank().width('100%').height('100%').backgroundColor(0x66000000).onClick(() => { this.onClose() })

      // 抽屉
      Column() {
        Row() {
          Text(`${this.plantName} · 日志`).fontSize(16).fontWeight(FontWeight.Medium).fontColor(0xFF263238)
          Blank()
          Text('✕').fontSize(18).onClick(() => { this.onClose() })
        }
        .padding({ left: 16, right: 16, top: 12, bottom: 6 })

        // 输入区（使用单行 TextInput，兼容性最好；如需多行可改 TextArea）
        Column() {
          Text('新增日志').fontSize(12).fontColor(0xFF607D8B)
          TextInput({ placeholder: '例如：今天见到新叶子，状态良好…', text: this.inputText })
            .onChange((v: string) => { this.onChangeInput(v) })
            .width('100%').height(40).borderRadius(12).backgroundColor(0xFFF9F9F9)
            .padding({ left: 12, right: 12 }).margin({ top: 6 })
          Row() {
            Button('添加').type(ButtonType.Capsule).onClick(() => { this.onAdd() })
              .backgroundColor(0xFF2E7D32).fontColor(0xFFFFFFFF)
              .padding({ left: 16, right: 16, top: 8, bottom: 8 }).borderRadius(20)
          }.margin({ top: 8 })
        }
        .padding({ left: 16, right: 16, bottom: 10 })

        // 日志列表
        if (this.logs.length === 0) {
          Column() { Text('暂无日志，写一条吧。').fontSize(13).fontColor(0xFF90A4AE).margin({ top: 10 }) }
          .padding({ left: 16, right: 16, bottom: 16 })
        } else {
          List({ space: 8 }) {
            ForEach(this.logs, (l: LogEntry) => {
              ListItem() {
                Row() {
                  Column() {
                    Text(this.timeStr(l.createdAt)).fontSize(11).fontColor(0xFF607D8B)
                    Text(l.note).fontSize(14).fontColor(0xFF263238).margin({ top: 2 })
                  }
                  Blank()
                  Text('删除').fontSize(12).fontColor(0xFFE53935).onClick(() => { this.onDelete(l.id) })
                }
                .padding(12).borderRadius(12).backgroundColor(0xFFFFFFFF)
                .shadow({ radius: 10, color: 0x12000000, offsetX: 0, offsetY: 2 })
              }
            }, (l: LogEntry) => l.id.toString())
          }
          .padding({ left: 16, right: 16, bottom: 18 })
          .edgeEffect(EdgeEffect.Spring)
        }
      }
      .width('100%').backgroundColor(0xFFFFFFFF)
      .borderRadius({ topLeft: 20, topRight: 20, bottomLeft: 0, bottomRight: 0 })
      .position({ x: 0, y: 'calc(100% - 70%)' })
      .shadow({ radius: 24, color: 0x33000000, offsetX: 0, offsetY: -6 })
      .animation({ duration: 200, curve: Curve.Sharp })
    }
    .width('100%').height('100%')
  }

  // 非 Builder：时间格式化
  private timeStr(ts: number): string {
    const d = new Date(ts)
    const y = d.getFullYear()
    const m = (d.getMonth() + 1).toString().padStart(2, '0')
    const day = d.getDate().toString().padStart(2, '0')
    const hh = d.getHours().toString().padStart(2, '0')
    const mm = d.getMinutes().toString().padStart(2, '0')
    return `${y}-${m}-${day} ${hh}:${mm}`
  }
}
