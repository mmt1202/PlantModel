import { Plant, PlantTask } from '../model/PlantModel'
import { CalendarGrid } from './CalendarGrid'
import { TaskItem } from './TaskItem'

@ComponentV2
export struct TaskListPage {
  @Param @Require tasks: Array<PlantTask>
  @Param @Require plants: Array<Plant>
  @Event onToggle: (t: PlantTask) => void
  @Event onDeleteAsk: (taskId: number) => void
  // 已有
  @Local viewMode: number = 0 // 0 列表 1 日历
  @Local currentMonthISO: string = '' // YYYY-MM
  // —— 新增筛选与搜索 —— //
  @Local filterTab: number = 0 // 0 全部 1 今天 2 将来 3 已完成
  @Local typeFilter: string = '全部' // 任务类型过滤（自动聚合出“浇水/施肥/修剪/…”）
  @Local keyword: string = '' // 关键字：匹配“任务类型/植物名”

  aboutToAppear(): void {
    if (this.currentMonthISO.length === 0) {
      const d = new Date()
      const y = d.getFullYear().toString()
      const m = (d.getMonth() + 1).toString().padStart(2, '0')
      this.currentMonthISO = `${y}-${m}`
    }
  }

  // —— 计算工具（非 Builder） —— //
  private todayISO(): string {
    const d = new Date()
    const y = d.getFullYear()
    const m = (d.getMonth() + 1).toString().padStart(2, '0')
    const day = d.getDate().toString().padStart(2, '0')
    return `${y}-${m}-${day}`
  }

  private plantNameById(id: number): string {
    let i: number = 0
    while (i < this.plants.length) {
      if (this.plants[i].id === id) {
        return this.plants[i].name
      }
      i = i + 1
    }
    return '未知植物'
  }

  private typesChips(): Array<string> {
    const out: Array<string> = ['全部']
    let i: number = 0
    while (i < this.tasks.length) {
      const tp: string = this.tasks[i].type
      let exist: boolean = false
      let j: number = 0
      while (j < out.length) {
        if (out[j] === tp) {
          exist = true
        }
        j = j + 1
      }
      if (!exist) {
        out.push(tp)
      }
      i = i + 1
    }
    return out
  }

  private isMatchTab(t: PlantTask): boolean {
    if (this.filterTab === 0) {
      return true
    }
    if (this.filterTab === 1) {
      return t.planDate === this.todayISO()
    }
    if (this.filterTab === 2) {
      return t.planDate > this.todayISO() && t.done === 0
    } // 将来且未完成
    if (this.filterTab === 3) {
      return t.done === 1
    }
    return true
  }

  private isMatchType(t: PlantTask): boolean {
    if (this.typeFilter === '全部') {
      return true
    }
    return t.type === this.typeFilter
  }

  private isMatchKeyword(t: PlantTask): boolean {
    const kw: string = this.keyword.trim().toLowerCase()
    if (kw.length === 0) {
      return true
    }
    const pn: string = this.plantNameById(t.plantId).toLowerCase()
    const tt: string = t.type.toLowerCase()
    if (pn.indexOf(kw) >= 0) {
      return true
    }
    if (tt.indexOf(kw) >= 0) {
      return true
    }
    return false
  }

  private filteredTasks(): Array<PlantTask> {
    // 先复制
    const arr: Array<PlantTask> = []
    let i: number = 0
    while (i < this.tasks.length) {
      arr.push(this.tasks[i]);
      i = i + 1
    }
    // 过滤
    const out: Array<PlantTask> = []
    let k: number = 0
    while (k < arr.length) {
      const t: PlantTask = arr[k]
      if (this.isMatchTab(t) && this.isMatchType(t) && this.isMatchKeyword(t)) {
        out.push(t)
      }
      k = k + 1
    }
    // 排序：日期(新→旧) + id(大→小)
    out.sort((a: PlantTask, b: PlantTask) => {
      if (a.planDate === b.planDate) {
        return b.id - a.id
      }
      // ISO 字符串可直接比较
      return a.planDate < b.planDate ? 1 : -1
    })
    return out
  }

  // —— 视图 —— //
  build() {
    Column() {
      // 顶部：视图模式切换
      Row() {
        this.ModeChip('列表', 0)
        this.ModeChip('日历', 1)
      }
      .justifyContent(FlexAlign.Center)
      .padding({ top: 6, bottom: 6 })

      if (this.viewMode === 0) {
        // —— 新增：筛选条 + 搜索 —— //
        Row() {
          this.TabFilterChip('全部', 0)
          this.TabFilterChip('今天', 1)
          this.TabFilterChip('将来', 2)
          this.TabFilterChip('已完成', 3)
        }
        .padding({ left: 12, right: 12, bottom: 6 })

        Row() {
          Text('类型').fontSize(12).fontColor(0xFF607D8B).margin({ right: 8 })
          ForEach(this.typesChips(), (tp: string) => {
            this.TypeChip(tp, this.typeFilter === tp, () => {
              animateTo({ duration: 120, curve: Curve.EaseInOut }, () => {
                this.typeFilter = tp
              })
            })
          }, (tp: string) => `tp-${tp}`)
        }
        .padding({ left: 12, right: 12, bottom: 6 })

        Row() {
          Text('🔎').fontSize(18).margin({ right: 8 })
          TextInput({ placeholder: '搜索任务类型/植物名称', text: this.keyword })
            .onChange((v: string) => {
              this.keyword = v
            })
            .width('100%')
            .height(36)
            .fontSize(14)
            .borderRadius(12)
            .backgroundColor(0xFFFFFFFF)
            .padding({ left: 12, right: 12 })
        }
        .height(44).width('100%').padding({ left: 12, right: 12, bottom: 8 })

        // 列表
        if (this.filteredTasks().length === 0) {
          Column() {
            Text('没有符合条件的任务').fontColor(0xFF90A4AE).fontSize(14).margin({ top: 24 })
          }.width('100%')
        } else {
          List({ space: 8 }) {
            ForEach(this.filteredTasks(), (t: PlantTask) => {
              ListItem() {
                TaskItem({
                  t: t,
                  plantName: this.plantNameById(t.plantId),
                  onToggle: () => {
                    this.onToggle(t)
                  },
                  onDeleteAsk: () => {
                    this.onDeleteAsk(t.id)
                  }
                })
              }
            }, (t: PlantTask) => t.id.toString())
          }
          .padding({
            left: 12,
            right: 12,
            top: 8,
            bottom: 8
          })
          .edgeEffect(EdgeEffect.Spring)
        }
      } else {
        // 日历模式：保持不变（不重复输出 CalendarGridV2）
        CalendarGrid({
          monthISO: this.currentMonthISO,
          tasks: this.tasks,
          plants: this.plants,
          onPrev: () => {
            this.changeMonth(-1)
          },
          onNext: () => {
            this.changeMonth(1)
          },
          onToggle: (t: PlantTask) => {
            this.onToggle(t)
          },
          onDeleteAsk: (id: number) => {
            this.onDeleteAsk(id)
          }
        })
      }
    }
  }

  // —— 辅助（非 Builder） —— //
  private changeMonth(delta: number): void {
    const arr: Array<string> = this.currentMonthISO.split('-')
    const y = Number.parseInt(arr[0]);
    const m = Number.parseInt(arr[1])
    const base = new Date(y, m - 1, 1)
    base.setMonth(base.getMonth() + delta)
    const ny = base.getFullYear().toString()
    const nm = (base.getMonth() + 1).toString().padStart(2, '0')
    this.currentMonthISO = `${ny}-${nm}`
  }

  // —— UI 子块 —— //
  @Builder
  ModeChip(label: string, idx: number) {
    Text(label)
      .fontSize(13)
      .fontWeight(this.viewMode === idx ? FontWeight.Medium : FontWeight.Regular)
      .fontColor(this.viewMode === idx ? 0xFF1B5E20 : 0xFF607D8B)
      .padding({
        left: 12,
        right: 12,
        top: 6,
        bottom: 6
      })
      .borderRadius(14)
      .backgroundColor(this.viewMode === idx ? 0xFFE8F5E9 : 0xFFFFFFFF)
      .onClick(() => {
        animateTo({ duration: 120, curve: Curve.EaseInOut }, () => {
          this.viewMode = idx
        })
      })
      .margin({ left: 4, right: 4 })
  }

  @Builder
  TabFilterChip(text: string, tab: number) {
    Text(text)
      .fontSize(11)
      .fontColor(this.filterTab === tab ? 0xFF2E7D32 : 0xFF263238)
      .padding({
        left: 10,
        right: 10,
        top: 6,
        bottom: 6
      })
      .borderRadius(12)
      .backgroundColor(this.filterTab === tab ? 0xFFE8F5E9 : 0xFFFFFFFF)
      .onClick(() => {
        animateTo({ duration: 120, curve: Curve.EaseInOut }, () => {
          this.filterTab = tab
        })
      })
      .margin({ right: 8 })
      .shadow({
        radius: this.filterTab === tab ? 10 : 6,
        color: 0x10000000,
        offsetX: 0,
        offsetY: this.filterTab === tab ? 2 : 1
      })
  }

  @Builder
  TypeChip(text: string, active: boolean, onTap: () => void) {
    Text(text)
      .fontSize(11)
      .fontColor(active ? 0xFF1565C0 : 0xFF263238)
      .padding({
        left: 10,
        right: 10,
        top: 6,
        bottom: 6
      })
      .borderRadius(12)
      .backgroundColor(active ? 0xFFE3F2FD : 0xFFFFFFFF)
      .onClick(() => {
        onTap()
      })
      .margin({ right: 8 })
      .shadow({
        radius: active ? 10 : 6,
        color: 0x10000000,
        offsetX: 0,
        offsetY: active ? 2 : 1
      })
  }
}
