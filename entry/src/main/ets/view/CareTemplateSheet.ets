@ComponentV2
export
struct CareTemplateSheet {
  @Param @Require plantName: string
  @Event onApply: (waterInt: number, fertInt: number, pruneInt: number, startISO: string, days: number) => void
  @Event onClose: () => void

  @Local waterStr: string = '3'   // 浇水间隔日，0 表示不生成
  @Local fertStr: string = '14'   // 施肥间隔日
  @Local pruneStr: string = '30'  // 修剪间隔日
  @Local daysStr: string = '30'   // 生成天数
  @Local startISO: string = ''    // 起始日期（默认今天）

  aboutToAppear(): void { this.startISO = this.todayISO() }

  build() {
    Stack() {
      // 蒙层
      Column(){
        Blank().width('100%').height('100%').backgroundColor(0x66000000).onClick(() => { this.onClose() })
      }

      // 抽屉
      Column() {
        Row() {
          Text(`${this.plantName} · 养护模板`).fontSize(16).fontWeight(FontWeight.Medium).fontColor(0xFF263238)
          Blank()
          Text('✕').fontSize(18).onClick(() => { this.onClose() })
        }.padding({ left: 16, right: 16, top: 12, bottom: 6 })

        // 预设
        Row() {
          this.PresetChip('绿植常规', '3', '14', '30')
          this.PresetChip('多肉',    '7', '30', '60')
          this.PresetChip('观花',    '2', '10', '30')
        }
        .padding({ left: 16, right: 16, top: 2, bottom: 6 })

        Column() {
          this.NumField('浇水间隔（日）0=不生成', this.waterStr, (v: string) => { this.waterStr = v })
          this.NumField('施肥间隔（日）0=不生成', this.fertStr, (v: string) => { this.fertStr = v })
          this.NumField('修剪间隔（日）0=不生成', this.pruneStr, (v: string) => { this.pruneStr = v })

          Row() {
            Column() {
              Text('起始日期').fontSize(12).fontColor(0xFF607D8B)
              Text(this.startISO).fontSize(13).fontColor(0xFF263238).margin({ top: 4 })
            }
            Blank()
            Text('今天').fontSize(12).fontColor(0xFF1565C0)
              .padding({ left: 12, right: 12, top: 6, bottom: 6 }).borderRadius(14).backgroundColor(0x102196F3)
              .onClick(() => { this.startISO = this.todayISO() })
          }
          .padding({ top: 6, bottom: 6 })

          this.NumField('生成天数（建议 30~90）', this.daysStr, (v: string) => { this.daysStr = v })

          Row() {
            Text('生成任务').fontSize(14).fontColor(0xFFFFFFFF)
              .padding({ left: 18, right: 18, top: 8, bottom: 8 }).borderRadius(18).backgroundColor(0xFF2E7D32)
              .onClick(() => {
                const w: number = this.safeInt(this.waterStr)
                const f: number = this.safeInt(this.fertStr)
                const p: number = this.safeInt(this.pruneStr)
                const d: number = this.safeInt(this.daysStr)
                if (d <= 0) { return }
                if (this.startISO.length !== 10) { return }
                this.onApply(w, f, p, this.startISO, d)
              })
            Text('清空').fontSize(14).fontColor(0xFF1565C0)
              .padding({ left: 14, right: 14, top: 8, bottom: 8 }).borderRadius(18).backgroundColor(0x102196F3)
              .margin({ left: 8 })
              .onClick(() => { this.waterStr = '0'; this.fertStr = '0'; this.pruneStr = '0' })
          }
          .margin({ top: 8 })
        }
        .padding({ left: 16, right: 16, bottom: 14 })
      }
      .width('100%').backgroundColor(0xFFFFFFFF)
      .borderRadius({ topLeft: 20, topRight: 20, bottomLeft: 0, bottomRight: 0 })
      // .position({ x: 0, y: 'calc(100% - 72%)' })
      .shadow({ radius: 24, color: 0x33000000, offsetX: 0, offsetY: -6 })
      .animation({ duration: 200, curve: Curve.Sharp })
    }
    .width('100%').height('100%').alignContent(Alignment.Bottom)
  }

  @Builder
  PresetChip(label: string, w: string, f: string, p: string) {
    Text(label)
      .fontSize(12).fontColor(0xFF6A1B9A)
      .padding({ left: 10, right: 10, top: 6, bottom: 6 })
      .borderRadius(12).backgroundColor(0x10BA68C8)
      .onClick(() => { this.waterStr = w; this.fertStr = f; this.pruneStr = p })
      .margin({ right: 8 })
  }

  @Builder
  NumField(label: string, val: string, onChange: (v: string) => void) {
    Column() {
      Text(label).fontSize(12).fontColor(0xFF607D8B)
      TextInput({ placeholder: '', text: val })
        .onChange((v: string) => { onChange(v) })
        .width('100%').height(40).borderRadius(12).backgroundColor(0xFFF9F9F9)
        .padding({ left: 12, right: 12 }).margin({ top: 6 })
        .type(InputType.Number)
    }.margin({ top: 6 })
  }

  // —— 逻辑 —— //
  private todayISO(): string {
    const d = new Date()
    const y = d.getFullYear()
    const m = (d.getMonth() + 1).toString().padStart(2, '0')
    const day = d.getDate().toString().padStart(2, '0')
    return `${y}-${m}-${day}`
  }
  private safeInt(s: string): number {
    const v: number = Number(s)
    if (Number.isFinite(v)) { return Math.max(0, Math.floor(v)) }
    return 0
  }
}
