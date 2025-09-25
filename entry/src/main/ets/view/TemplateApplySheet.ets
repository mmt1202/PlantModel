import { CareRule, CareTemplate } from '../model/PlantModel'

@ComponentV2
export struct TemplateApplySheet {
  // 目标植物
  @Param @Require plantName: string
  @Param @Require plantId: number
  // 模板 & 规则（Index 查出来传入）
  @Param @Require templates: Array<CareTemplate> // { id, name, desc }
  @Param @Require rules: Array<CareRule> // { id, templateId, type, intervalDays, horizonDays }
  // 提交
  @Event onApply: (templateId: number, startISO: string) => void
  @Event onClose: () => void
  // 本地状态
  @Local chosenTemplateId: number = 0
  @Local startISO: string = '' // 'YYYY-MM-DD'

  aboutToAppear(): void {
    if (this.templates.length > 0) {
      this.chosenTemplateId = this.templates[0].id
    }
    // 默认今天
    const d = new Date()
    const y: number = d.getFullYear()
    const m: number = d.getMonth() + 1
    const day: number = d.getDate()
    this.startISO = `${y}-${this.two(m)}-${this.two(day)}`
  }

  private two(n: number): string {
    const s: string = n.toString();
    if (s.length === 1) {
      return '0' + s
    }
    ;
    return s
  }

  private addDays(iso: string, delta: number): string {
    const parts: Array<string> = iso.split('-')
    const d = new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]))
    d.setDate(d.getDate() + delta)
    const mm: string = this.two(d.getMonth() + 1);
    const dd: string = this.two(d.getDate())
    return `${d.getFullYear()}-${mm}-${dd}`
  }

  // 生成预览列表（不落库）
  private previewList(): Array<string> {
    const out: Array<string> = []
    let i: number = 0
    while (i < this.rules.length) {
      const r: CareRule = this.rules[i]
      if (r.templateId === this.chosenTemplateId) {
        let day: number = 0
        while (day <= r.horizonDays) {
          out.push(`${this.addDays(this.startISO, day)} · ${r.type}`)
          day = day + r.intervalDays
        }
      }
      i = i + 1
    }
    out.sort((a: string, b: string) => a < b ? -1 : (a > b ? 1 : 0))
    return out
  }

  build() {
    Stack() {
      Column() {
        Blank().width('100%').height('100%').backgroundColor(0x66000000).onClick(() => {
          this.onClose()
        })
      }

      Column() {
        Row() {
          Text(`复制模板到：${this.plantName}`).fontSize(16).fontWeight(FontWeight.Medium).fontColor(0xFF263238)
          Blank()
          Text('✕').fontColor('#000000').fontSize(18).onClick(() => {
            this.onClose()
          })
        }
        .padding({
          left: 16,
          right: 16,
          top: 12,
          bottom: 8
        })

        // 选择模板
        Row() {
          ForEach(this.templates, (t: CareTemplate) => {
            Text(this.chosenTemplateId === t.id ? `✓ ${t.name}` : t.name)
              .fontSize(12)
              .fontColor(0xFF263238)
              .padding({
                left: 10,
                right: 10,
                top: 6,
                bottom: 6
              })
              .borderRadius(12)
              .backgroundColor(this.chosenTemplateId === t.id ? 0xFFE8F5E9 : 0xFFECEFF1)
              .onClick(() => {
                this.chosenTemplateId = t.id
              })
              .margin({ right: 8, bottom: 8 })
          }, (t: CareTemplate) => t.id.toString())
        }.padding({ left: 16, right: 16, bottom: 4 })

        // 开始日期
        Row() {
          Text('开始日期').fontSize(12).fontColor(0xFF607D8B).margin({ right: 10 })
          TextInput({ placeholder: 'YYYY-MM-DD', text: this.startISO })
            .placeholderColor('#747474').fontColor('#000000')
            .onChange((v: string) => {
              this.startISO = v
            })
            .width('60%')
            .height(36)
            .borderRadius(12)
            .backgroundColor(0xFFF5F5F5)
            .padding({ left: 10, right: 10 })
        }.padding({ left: 16, right: 16, bottom: 8 })

        // 预览列表
        if (this.previewList().length === 0) {
          Column() {
            Text('暂无预览').fontSize(13).fontColor(0xFF90A4AE)
          }.width('100%').padding({ top: 8, bottom: 8 })
        } else {
          List({ space: 4 }) {
            ForEach(this.previewList(), (s: string) => {
              ListItem() {
                Row() {
                  Text(s).fontSize(13).fontColor(0xFF263238)
                }
                .padding(10).borderRadius(10).backgroundColor(0xFFFFFFFF)
              }
            }, (s: string) => s)
          }.padding({ left: 16, right: 16, bottom: 12 }).edgeEffect(EdgeEffect.Spring)
        }

        // 底部按钮
        Row() {
          Text('复制到该植物')
            .fontSize(14)
            .fontColor(0xFFFFFFFF)
            .padding({
              left: 16,
              right: 16,
              top: 10,
              bottom: 10
            })
            .borderRadius(20)
            .backgroundColor(0xFF2E7D32)
            .onClick(() => {
              this.onApply(this.chosenTemplateId, this.startISO)
            })
        }.padding({ left: 16, right: 16, bottom: 14 })
      }
      .width('100%').backgroundColor(0xFFFFFFFF)
      .borderRadius({
        topLeft: 20,
        topRight: 20,
        bottomLeft: 0,
        bottomRight: 0
      })
      // .position({ x: 0, y: 'calc(100% - 84%)' })
      .shadow({
        radius: 24,
        color: 0x33000000,
        offsetX: 0,
        offsetY: -6
      })
    }.width('100%').height('100%').alignContent(Alignment.Bottom)
  }
}
