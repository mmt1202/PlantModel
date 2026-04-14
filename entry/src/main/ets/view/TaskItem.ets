import { PlantTask } from '../model/PlantModel'
import { hilog } from '@kit.PerformanceAnalysisKit'

/** -------- 子组件：单条任务（V2）-------- */
@ComponentV2
export struct TaskItem {
  @Param @Require t: PlantTask
  @Param @Require plantName: string
  @Event onToggle: (pt: PlantTask) => void
  @Event onDeleteAsk: () => void
  @Local pressed: boolean = false

  aboutToAppear(): void {
    hilog.info(0x0000, 'index', '%{public}s', `liheng 鏁版嵁鍒锋柊${JSON.stringify(this.t)}`);
  }

  build() {
    // 任务项保持很轻,只做展示和交互回调;真正状态以上层重载结果为准。
    Row() {
      Text(this.t.done === 1 ? '✔' : '○').fontSize(20)
        .scale(this.t.done === 1 ? { x: 1.2, y: 1.2 } : { x: 1, y: 1 })
        .animation({ duration: 200, curve: Curve.EaseOut })
        .onClick(() => {
          this.onToggle(this.t)
          // 这里的本地切换只是为了立刻给用户反馈,最终仍会被父层 reload 校正。
          this.t.done = this.t.done === 1 ? 0 : 1
        })
  
      Column() {
        Text(`${this.t.type} · ${this.plantName}`)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(0xFF263238)
          .opacity(this.t.done === 1 ? 0.6 : 1.0)
          .decoration({ type: this.t.done === 1 ? TextDecorationType.LineThrough : TextDecorationType.None })
          .animation({ duration: 250, curve: Curve.EaseInOut })
        if (this.t.done === 1) {
          Text(`${this.t.planDate} · 已完成`).fontSize(12).fontColor(0xFF607D8B).margin({ top: 2 })
        } else {
          Text(this.t.planDate).fontSize(12).fontColor(0xFF607D8B).margin({ top: 2 })
        }
      }.margin({ left: 10 })
  
      Blank()
      Text('🗏').fontSize(16).onClick(() => {
        this.onDeleteAsk()
      })
    }
    .width('100%')
    .padding(12)
    .borderRadius(12)
    .backgroundColor(0xFFFFFFFF)
    .shadow({ radius: 12, color: 0x14000000, offsetX: 0, offsetY: 3 })
    .scale(this.pressed ? { x: 0.98, y: 0.98 } : { x: 1, y: 1 })
    .opacity(this.t.done === 1 ? 0.85 : 1.0)
    .onTouch((e: TouchEvent) => {
      if (e.type === TouchType.Down) {
        this.pressed = true
      }
      if (e.type === TouchType.Up || e.type === TouchType.Cancel) {
        this.pressed = false
      }
    })
    .animation({ duration: 250, curve: Curve.EaseInOut })
  }
}
