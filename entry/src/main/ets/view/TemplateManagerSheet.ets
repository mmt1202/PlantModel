import { PlanTpl } from "../model/PlantModel"

@ComponentV2
export  struct TemplateManagerSheet {
  @Param @Require templates: Array<PlanTpl>
  @Param @Require editingPlantId: number
  @Event onClose: () => void
  @Event onCreate: (name: string, type: string, everyDays: number, times: number) => void
  @Event onUpdate: (id: number, name: string, type: string, everyDays: number, times: number) => void
  @Event onDelete: (id: number) => void
  @Event onApply: (id: number) => void

  @Local showCreate: boolean = false
  @Local nameDraft: string = ''
  @Local typeDraft: string = '浇水'
  @Local daysDraft: string = '7'
  @Local timesDraft: string = '4'

  @Local editingId: number = 0
  @Local editName: string = ''
  @Local editType: string = '浇水'
  @Local editDays: string = '7'
  @Local editTimes: string = '4'

  private parsePosInt(s: string): number {
    const n: number = Number.parseInt(s)
    if (Number.isNaN(n) || n <= 0) { return 0 }
    return n
  }

  private startEdit(t: PlanTpl): void {
    this.editingId = t.id
    this.editName = t.name
    this.editType = t.type
    this.editDays = t.everyDays.toString()
    this.editTimes = t.times.toString()
  }

  private cancelEdit(): void {
    this.editingId = 0
    this.editName = ''; this.editType = '浇水'; this.editDays = '7'; this.editTimes = '4'
  }

  build() {
    Stack(){
      // 蒙层
      Column(){
        Blank().width('100%').height('100%').backgroundColor(0x66000000).onClick(() => { this.onClose() })
      }

      // 底部面板
      Column({space:8}) {
        Row() {
          Text('周期模板').fontSize(16).fontWeight(FontWeight.Medium).fontColor(0xFF263238)
          Blank()
          Text('✕').fontSize(18).onClick(() => { this.onClose() })
        }
        .padding({ left: 16, right: 16, top: 12, bottom: 6 })

        // 新建模板块
        Column() {
          Row() {
            Text(this.showCreate ? '收起新建' : '新建模板').fontSize(13).fontColor(0xFF1565C0)
              .onClick(() => { this.showCreate = !this.showCreate })
            Blank()
          }
          .padding({ bottom: 6 })

          if (this.showCreate) {
            this.NewTplForm()
          }
        }
        .padding({ left: 16, right: 16, top: 6, bottom: 8 })
        .backgroundColor(0xFFFFFFFF)

        // 模板列表
        if (this.templates.length === 0) {
          Column() {
            Text('暂无模板，点击“新建模板”添加').fontSize(13).fontColor(0xFF90A4AE).margin({ top: 10 })
          }.padding({ left: 16, right: 16, bottom: 12 })
        } else {
          List({ space: 8 }) {
            ForEach(this.templates, (t: PlanTpl) => {
              ListItem() {
                this.TplItem(t)
              }.width('100%')
            }, (t: PlanTpl) => t.id.toString())
          }.height('40%').scrollBar(BarState.Off).width('100%')
          .padding({ left: 16, right: 16, bottom: 16 })
          .edgeEffect(EdgeEffect.Spring)
        }
      }
      .width('100%').backgroundColor(0xFFFFFFFF)
      .borderRadius({ topLeft: 20, topRight: 20, bottomLeft: 0, bottomRight: 0 })
      // .position({ x: 0, y: 'calc(100% - 70%)' })
      .shadow({ radius: 24, color: 0x33000000, offsetX: 0, offsetY: -6 })
      .animation({ duration: 200, curve: Curve.Sharp })
    }
    .width('100%').height('100%').alignContent(Alignment.Bottom)
  }

  @Builder
  NewTplForm() {
    Column() {
      this.KV('名称', this.nameDraft, (v: string) => { this.nameDraft = v })
      this.KV('类型', this.typeDraft, (v: string) => { this.typeDraft = v })
      this.KV('间隔天数', this.daysDraft, (v: string) => { this.daysDraft = v })
      this.KV('次数', this.timesDraft, (v: string) => { this.timesDraft = v })
      Row() {
        Button('创建').type(ButtonType.Capsule).onClick(() => {
          const d: number = this.parsePosInt(this.daysDraft)
          const n: number = this.parsePosInt(this.timesDraft)
          this.onCreate(this.nameDraft, this.typeDraft, d, n)
        })
          .backgroundColor(0xFF2E7D32).fontColor(0xFFFFFFFF)
          .padding({ left: 16, right: 16, top: 8, bottom: 8 }).borderRadius(20)

        Blank()

        Button('应用到当前植物').type(ButtonType.Capsule).onClick(() => {
          // 创建后应用场景通常从列表点“应用”；这里保留占位，可按需改成创建即应用
          // 这里不做动作
        })
          .backgroundColor(0xFFE0E0E0).fontColor(0xFF263238)
          .padding({ left: 16, right: 16, top: 8, bottom: 8 }).borderRadius(20)
      }.margin({ top: 8 })
    }
    .padding(10).borderRadius(12).backgroundColor('#ffffff')
    .shadow({ radius: 12, color: 0x14000000, offsetX: 0, offsetY: 3 })
  }

  @Builder
  TplItem(t: PlanTpl) {
    Column() {
      if (this.editingId !== t.id) {
        // 显示态
        Row() {
          Column() {
            Text(t.name).fontSize(15).fontWeight(FontWeight.Medium).fontColor(0xFF263238)
            Text(`${t.type} · 每${t.everyDays}天 × ${t.times}次`).fontSize(12).fontColor(0xFF607D8B).margin({ top: 2 })
          }
          Blank()
          Row() {
            Text('应用').fontSize(13).fontColor(0xFF2E7D32).onClick(() => { this.onApply(t.id) }).margin({ right: 10 })
            Text('编辑').fontSize(13).fontColor(0xFF1565C0).onClick(() => { this.startEdit(t) }).margin({ right: 10 })
            Text('删除').fontSize(13).fontColor(0xFFE53935).onClick(() => { this.onDelete(t.id) })
          }
        }.width('96%').alignItems(VerticalAlign.Center).justifyContent(FlexAlign.SpaceBetween)
      } else {
        // 编辑态
        Column() {
          this.KV('名称', this.editName, (v: string) => { this.editName = v })
          this.KV('类型', this.editType, (v: string) => { this.editType = v })
          this.KV('间隔天数', this.editDays, (v: string) => { this.editDays = v })
          this.KV('次数', this.editTimes, (v: string) => { this.editTimes = v })
          Row() {
            Button('保存').type(ButtonType.Capsule).onClick(() => {
              const d: number = this.parsePosInt(this.editDays)
              const n: number = this.parsePosInt(this.editTimes)
              this.onUpdate(this.editingId, this.editName, this.editType, d, n)
              this.cancelEdit()
            })
              .backgroundColor(0xFF1565C0).fontColor(0xFFFFFFFF)
              .padding({ left: 16, right: 16, top: 8, bottom: 8 }).borderRadius(20)

            Button('取消').type(ButtonType.Capsule).onClick(() => { this.cancelEdit() })
              .backgroundColor(0xFFE0E0E0).fontColor(0xFF263238)
              .padding({ left: 16, right: 16, top: 8, bottom: 8 }).borderRadius(20).margin({ left: 10 })
          }.margin({ top: 6 })
        }.width('100%')
      }
    }.width('96%')
    .padding(12).borderRadius(14).backgroundColor(0xFFFFFFFF)
    .shadow({ radius: 12, color: 0x14000000, offsetX: 0, offsetY: 3 })
    .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
  }

  @Builder
  KV(label: string, val: string, onChange: (v: string) => void) {
    Column() {
      Text(label).fontSize(12).fontColor(0xFF607D8B)
      TextInput({ placeholder: '', text: val })
        .onChange((v: string) => { onChange(v) })
        .width('100%').height(40).borderRadius(12).backgroundColor(0xFFF9F9F9)
        .padding({ left: 12, right: 12 }).margin({ top: 6 })
    }.margin({ top: 6 })
  }
}
