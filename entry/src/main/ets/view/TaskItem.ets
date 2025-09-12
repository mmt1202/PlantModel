import { PlantTask } from "../model/PlantModel"

/** -------- 子组件：单条任务（V2） -------- */
@ComponentV2
export  struct TaskItem {
  @Param @Require t: PlantTask
  @Param @Require plantName: string
  @Event onToggle: () => void
  @Event onDeleteAsk: () => void

  @Local pressed: boolean = false

  build() {
    Row() {
      Text(this.t.done === 1 ? '✅' : '⬜').fontSize(20).onClick(() => { this.onToggle() })

      Column() {
        Text(`${this.t.type} · ${this.plantName}`).fontSize(15).fontWeight(FontWeight.Medium).fontColor(0xFF263238)
        if (this.t.done === 1) {
          Text(`${this.t.planDate} · 已完成`).fontSize(12).fontColor(0xFF607D8B).margin({ top: 2 })
        } else {
          Text(this.t.planDate).fontSize(12).fontColor(0xFF607D8B).margin({ top: 2 })
        }
      }.margin({ left: 10 })

      Blank()
      Text('🗑️').fontSize(16).onClick(() => { this.onDeleteAsk() })
    }
    .width('100%')
    .padding(12).borderRadius(12).backgroundColor(0xFFFFFFFF)
    .shadow({ radius: 12, color: 0x14000000, offsetX: 0, offsetY: 3 })
    .scale(this.pressed ? { x: 0.98, y: 0.98 } : { x: 1, y: 1 })
    .onTouch((e: TouchEvent) => {
      if (e.type === TouchType.Down) { this.pressed = true }
      if (e.type === TouchType.Up || e.type === TouchType.Cancel) { this.pressed = false }
    })
    .animation({ duration: 120, curve: Curve.EaseInOut })
  }
}