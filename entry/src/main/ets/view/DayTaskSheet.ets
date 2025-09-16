import { Plant, PlantTask } from "../model/PlantModel"

@ComponentV2
export struct DayTaskSheet {
  @Param @Require dateISO: string
  @Param @Require tasks: Array<PlantTask>   // 已是当日任务
  @Param @Require plants: Array<Plant>

  @Event onToggle: (t: PlantTask) => void
  @Event onDeleteAsk: (taskId: number) => void
  @Event onQuickAdd: (plantId: number, type: string, dateISO: string) => void
  @Event onClose: () => void

  @Local selectedPlantId: number = 0

  aboutToAppear(): void {
    // 默认选中当日任务里第一个植物；若没有任务，则置 0
    let pid: number = 0
    if (this.tasks.length > 0) { pid = this.tasks[0].plantId }
    this.selectedPlantId = pid
  }

  // —— 工具 —— //
  private plantNameById(id: number): string {
    let i: number = 0
    while (i < this.plants.length) { if (this.plants[i].id === id) { return this.plants[i].name } i = i + 1 }
    return '未选植物'
  }
  private uniquePlantIdsOfDay(): Array<number> {
    const ids: Array<number> = []
    let i: number = 0
    while (i < this.tasks.length) {
      const pid: number = this.tasks[i].plantId
      if (!this.contains(ids, pid)) { ids.push(pid) }
      i = i + 1
    }
    return ids
  }
  private contains(arr: Array<number>, v: number): boolean {
    let i: number = 0
    while (i < arr.length) { if (arr[i] === v) { return true } i = i + 1 }
    return false
  }

  private typeColor(t: string): ResourceColor {
    if (t === '浇水') { return 0xFF3AAFA9 }
    if (t === '施肥') { return 0xFF8E7CC3 }
    if (t === '修剪') { return 0xFFE57373 }
    return 0xFF607D8B
  }

  // —— 视图 —— //
  build() {
    Column() {
      // 蒙层
      Blank().width('100%').height('100%').backgroundColor(0x66000000).onClick(() => { this.onClose() })

      // 抽屉
      Column() {
        // 头部：日期 + 植物选择
        Row() {
          Text(this.dateISO).fontSize(16).fontWeight(FontWeight.Medium).fontColor(0xFF263238)
          Blank()
          Text('✕').fontSize(18).onClick(() => { this.onClose() })
        }.padding({ left: 16, right: 16, top: 12, bottom: 6 })

        // 植物选择（当日出现过的植物）
        Row() {
          // const ids: Array<number> = // 只在非 Builder 里生成
          ForEach(this.uniquePlantIdsOfDay() , (pid: number) => {
            this.PlantChip(pid, this.selectedPlantId === pid)
          }, (pid: number) => pid.toString())
        }
        .padding({ left: 16, right: 16, bottom: 6 })
        // .wrapContent(true)

        // 快捷新建（基于选中植物）
        Row() {
          this.QuickChip('浇水')
          this.QuickChip('施肥')
          this.QuickChip('修剪')
          if (this.selectedPlantId === 0) {
            Text('请选择上方的植物后再添加')
              .fontSize(12).fontColor(0xFFEF6C00).margin({ left: 8 })
          }
        }.padding({ left: 16, right: 16, bottom: 8 })

        // 当日任务列表
        if (this.tasks.length === 0) {
          Column() {
            Text('当日暂无任务').fontSize(14).fontColor(0xFF90A4AE).margin({ top: 20 })
          }.width('100%')
        } else {
          List({ space: 8 }) {
            ForEach(this.tasks, (t: PlantTask) => {
              ListItem() {
                this.TaskRow(t)
              }
            }, (t: PlantTask) => t.id.toString())
          }
          .padding({ left: 12, right: 12, top: 4, bottom: 16 })
          .edgeEffect(EdgeEffect.Spring)
        }
      }
      .width('100%').backgroundColor(0xFFFFFFFF)
      .borderRadius({ topLeft: 20, topRight: 20, bottomLeft: 0, bottomRight: 0 })
      .position({ x: 0, y: 'calc(100% - 70%)' })
      .shadow({ radius: 24, color: 0x33000000, offsetX: 0, offsetY: -6 })
    }
    .width('100%').height('100%')
  }

  @Builder
  PlantChip(pid: number, active: boolean) {
    Text(active ? `✓ ${this.plantNameById(pid)}` : this.plantNameById(pid))
      .fontSize(12).fontColor(active ? 0xFF2E7D32 : 0xFF263238)
      .padding({ left: 10, right: 10, top: 6, bottom: 6 })
      .borderRadius(12)
      .backgroundColor(active ? 0x102E7D32 : 0xFFECEFF1)
      .margin({ right: 8, bottom: 8 })
      .onClick(() => { this.selectedPlantId = pid })
  }

  @Builder
  QuickChip(type: string) {
    Text(type)
      .fontSize(12).fontColor(0xFFFFFFFF)
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .borderRadius(14)
      .backgroundColor(this.typeColor(type))
      .margin({ right: 8 })
      .onClick(() => {
        if (this.selectedPlantId !== 0) {
          this.onQuickAdd(this.selectedPlantId, type, this.dateISO)
        }
      })
  }

  @Builder
  TaskRow(t: PlantTask) {
    Row() {
      Text(t.done === 1 ? '✅' : '⬜').fontSize(20).onClick(() => { this.onToggle(t) })
      Column() {
        Text(`${t.type} · ${this.plantNameById(t.plantId)}`).fontSize(15).fontWeight(FontWeight.Medium).fontColor(0xFF263238)
        Text(t.planDate).fontSize(12).fontColor(0xFF607D8B).margin({ top: 2 })
      }.margin({ left: 10 })
      Blank()
      Text('🗑️').fontSize(16).onClick(() => { this.onDeleteAsk(t.id) })
    }
    .padding(12).borderRadius(12).backgroundColor(0xFFFFFFFF)
    .shadow({ radius: 12, color: 0x14000000, offsetX: 0, offsetY: 3 })
  }
}
