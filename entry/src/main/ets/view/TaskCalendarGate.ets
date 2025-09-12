import { PlantTask } from '../model/PlantModel'
import { CalendarGrid, CalendarSheet } from './CalendarView'

// import { CalendarSheet } from "./CalendarSheet"

@ComponentV2
export struct TaskCalendarGate {
  @Param @Require tasks: Array<PlantTask>
  @Event onToggle: (t: PlantTask) => void
  @Event onDelete: (id: number) => void
  @Local visible: boolean = false
  @Local y: number = 1970
  @Local m: number = 1

  aboutToAppear(): void {
    // 初始化为今天所在年月
    const now = new Date()
    this.y = now.getFullYear()
    this.m = now.getMonth() + 1
  }

  build() {
    Column() {
      // 顶部一行入口（放在任务列表上方）
      Row() {
        Blank()
        this.LinkChip('📅 日历', () => {
          this.visible = true
        })
      }
      .padding({
        left: 16,
        right: 16,
        top: 4,
        bottom: 6
      })

      // 日历抽屉
      if (this.visible) {
        CalendarSheet({
          year: this.y,
          month: this.m,
          tasks: this.tasks,
          onToggle: (t: PlantTask) => this.onToggle(t),
          onDelete: (id: number) => this.onDelete(id),
          onClose: () => {
            this.visible = false
          }
        })
      }
      if (false) {
        CalendarGrid({
          year: this.y,
          month: this.m,
          tasks: this.tasks,
          onToggle: (t) => this.onToggle(t),
          onDelete: (id) => this.onDelete(id)
        })
      }
    }
  }

  @Builder
  LinkChip(text: string, onTap: () => void) {
    Text(text)
      .fontSize(13)
      .fontColor(0xFF1565C0)
      .padding({
        left: 12,
        right: 12,
        top: 8,
        bottom: 8
      })
      .borderRadius(16)
      .backgroundColor(0x102196F3)
      .onClick(() => {
        onTap()
      })
  }
}
