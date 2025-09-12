import { LogEntry } from '../model/PlantModel'


@ComponentV2
export struct PlantLogSheet {
  @Param @Require logs: Array<LogEntry>
  @Param @Require plantName: string
  @Param @Require inputText: string
  @Event onChangeInput: (v: string) => void
  @Event onAdd: () => void
  @Event onDelete: (id: number) => void
  @Event onClose: () => void
  // —— 本地状态（搜索 & 选择）——
  @Local query: string = ''
  // 0: 全部, 7: 近7天, 30: 近30天, 100: 本月
  @Local range: number = 0
  @Local selectMode: boolean = false
  @Local selectedIds: Array<number> = []

  build() {
    Column() {
      // 背景蒙层
      Blank().width('100%').height('100%').backgroundColor(0x66000000).onClick(() => {
        this.exitSelectOrClose()
      })

      // 抽屉
      Column() {
        // 标题 & 选择操作条
        Column() {
          Row() {
            Text(`${this.plantName} · 日志`).fontSize(16).fontWeight(FontWeight.Medium).fontColor(0xFF263238)
            Blank()
            if (this.selectMode) {
              // 多选模式下显示“已选 N”
              Text(`已选 ${this.selectedCount()}`).fontSize(12).fontColor(0xFF1565C0).margin({ right: 8 })
              this.ActionChip('全选', () => {
                this.selectAll()
              })
              this.ActionChip('反选', () => {
                this.invertSelect()
              })
              this.ActionChip('删除所选', () => {
                this.batchDelete()
              })
              this.ActionChip('完成', () => {
                this.exitSelectMode()
              })
            } else {
              Text('✕').fontSize(18).onClick(() => {
                this.onClose()
              })
            }
          }
          .padding({
            left: 16,
            right: 16,
            top: 12,
            bottom: 6
          })

          // 搜索区（关键词 + 时间范围）
          this.SearchBar()
          this.RangeChips()
        }
        .padding({ bottom: 6 })

        // 输入区（新增日志）
        this.InputBar()

        // 日志列表（支持长按进入多选）
        if (this.filteredLogs().length === 0) {
          Column() {
            Text(this.hasActiveFilter() ? '没有匹配的日志' : '暂无日志，写一条吧。')
              .fontSize(13).fontColor(0xFF90A4AE).margin({ top: 10 })
          }
          .padding({ left: 16, right: 16, bottom: 16 })
        } else {
          List({ space: 8 }) {
            ForEach(this.filteredLogs(), (l: LogEntry) => {
              ListItem() {
                this.LogRow(l)
              }
            }, (l: LogEntry) => l.id.toString())
          }
          .padding({ left: 16, right: 16, bottom: 18 })
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
      .position({ x: 0, y: 'calc(100% - 72%)' })
      .shadow({
        radius: 24,
        color: 0x33000000,
        offsetX: 0,
        offsetY: -6
      })
      .animation({ duration: 200, curve: Curve.Sharp })
    }
    .width('100%').height('100%')
  }

  // —— 子区域：搜索栏 ----
  @Builder
  SearchBar() {
    Row() {
      Text('🔎').fontSize(18).margin({ right: 8 })
      TextInput({ placeholder: '搜索日志内容', text: this.query })
        .onChange((v: string) => {
          this.query = v
        })
        .width('100%')
        .height(36)
        .fontSize(14)
        .borderRadius(12)
        .backgroundColor(0xFFF9F9F9)
        .padding({ left: 12, right: 12 })
      if (this.query.length > 0) {
        Text('清空').fontSize(12).fontColor(0xFF1565C0).margin({ left: 8 })
          .onClick(() => {
            this.query = ''
          })
      }
    }
    .padding({ left: 16, right: 16 })
  }

  // —— 子区域：时间范围 chips ----
  @Builder
  RangeChips() {
    Row() {
      this.RangeChip('全部', 0)
      this.RangeChip('近7天', 7)
      this.RangeChip('近30天', 30)
      this.RangeChip('本月', 100)
    }
    .padding({
      left: 16,
      right: 16,
      top: 6,
      bottom: 8
    })
    .justifyContent(FlexAlign.Start)
  }

  @Builder
  RangeChip(text: string, v: number) {
    Text(text)
      .fontSize(12)
      .fontColor(this.range === v ? 0xFF2E7D32 : 0xFF607D8B)
      .padding({
        left: 10,
        right: 10,
        top: 6,
        bottom: 6
      })
      .borderRadius(12)
      .backgroundColor(this.range === v ? 0xFFE8F5E9 : 0xFFFFFFFF)
      .onClick(() => {
        this.range = v
      })
      .margin({ right: 8 })
  }

  // —— 子区域：新增输入 ----
  @Builder
  InputBar() {
    Column() {
      Text('新增日志').fontSize(12).fontColor(0xFF607D8B)
      Row() {
        TextInput({ placeholder: '例如：今天见到新叶子，状态良好…', text: this.inputText })
          .onChange((v: string) => {
            this.onChangeInput(v)
          })
          .width('100%')
          .height(40)
          .borderRadius(12)
          .backgroundColor(0xFFF9F9F9)
          .padding({ left: 12, right: 12 })
        Text('添加')
          .fontSize(14)
          .fontColor(0xFFFFFFFF)
          .padding({
            left: 14,
            right: 14,
            top: 8,
            bottom: 8
          })
          .borderRadius(16)
          .backgroundColor(0xFF2E7D32)
          .margin({ left: 8 })
          .onClick(() => {
            this.onAdd()
          })
      }
    }
    .padding({ left: 16, right: 16, bottom: 10 })
  }

  // —— 子区域：单条日志行（支持长按多选）----
  @Builder
  LogRow(l: LogEntry) {
    Row() {
      if (this.selectMode) {
        // 多选状态下左侧勾选
        Text(this.isSelected(l.id) ? '☑️' : '⬜').fontSize(18)
          .onClick(() => {
            this.toggleSelect(l.id)
          })
          .margin({ right: 8 })
      }

      Column() {
        Text(this.timeStr(l.createdAt)).fontSize(11).fontColor(0xFF607D8B)
        Text(l.note).fontSize(14).fontColor(0xFF263238).margin({ top: 2 })
      }

      Blank()

      if (!this.selectMode) {
        Text('删除').fontSize(12).fontColor(0xFFE53935)
          .onClick(() => {
            this.onDelete(l.id)
          })
      }
    }
    .padding(12)
    .borderRadius(12)
    .backgroundColor(0xFFFFFFFF)
    .shadow({
      radius: 10,
      color: 0x12000000,
      offsetX: 0,
      offsetY: 2
    })
    // 长按进入多选并选中当前项（ArkUI 手势写法）
    .gesture(
      LongPressGesture({ repeat: false })
        .onAction(() => {
          if (!this.selectMode) {
            this.selectMode = true
          }
          this.ensureSelected(l.id)
        })
    )
    // 多选模式下，点击整行也可切换选择
    .onClick(() => {
      if (this.selectMode) {
        this.toggleSelect(l.id)
      }
    })
  }

  // —— 顶部操作条上的小按钮 ----
  @Builder
  ActionChip(text: string, onTap: () => void) {
    Text(text)
      .fontSize(12)
      .fontColor(0xFF1565C0)
      .padding({
        left: 10,
        right: 10,
        top: 6,
        bottom: 6
      })
      .borderRadius(12)
      .backgroundColor(0x102196F3)
      .onClick(() => {
        onTap()
      })
      .margin({ left: 6 })
  }

  // ======= 非 UI 计算 & 选择逻辑 =======
  private hasActiveFilter(): boolean {
    if (this.query.trim().length > 0) {
      return true
    }
    if (this.range !== 0) {
      return true
    }
    return false
  }

  private filteredLogs(): Array<LogEntry> {
    const kw: string = this.query.trim().toLowerCase()
    const start: number = this.rangeStartTs()
    const out: Array<LogEntry> = []
    let i: number = 0
    while (i < this.logs.length) {
      const it: LogEntry = this.logs[i]
      if (start > 0 && it.createdAt < start) {
        i = i + 1;
        continue
      }
      if (kw.length > 0) {
        const hit: boolean = it.note.toLowerCase().includes(kw)
        if (!hit) {
          i = i + 1;
          continue
        }
      }
      out.push(it)
      i = i + 1
    }
    return out
  }

  private rangeStartTs(): number {
    if (this.range === 0) {
      return 0
    }
    const now = new Date()
    if (this.range === 7) {
      return now.getTime() - 7 * 24 * 3600 * 1000
    }
    if (this.range === 30) {
      return now.getTime() - 30 * 24 * 3600 * 1000
    }
    // 本月：取当月1号 00:00
    const ym = new Date(now.getFullYear(), now.getMonth(), 1, 0, 0, 0, 0)
    return ym.getTime()
  }

  private isSelected(id: number): boolean {
    let i: number = 0
    while (i < this.selectedIds.length) {
      if (this.selectedIds[i] === id) {
        return true
      }
      i = i + 1
    }
    return false
  }

  private ensureSelected(id: number): void {
    if (!this.isSelected(id)) {
      const arr: Array<number> = []
      let i: number = 0
      while (i < this.selectedIds.length) {
        arr.push(this.selectedIds[i]);
        i = i + 1
      }
      arr.push(id)
      this.selectedIds = arr
    }
  }

  private toggleSelect(id: number): void {
    const arr: Array<number> = []
    let found: boolean = false
    let i: number = 0
    while (i < this.selectedIds.length) {
      const v: number = this.selectedIds[i]
      if (v === id) {
        found = true
      } else {
        arr.push(v)
      }
      i = i + 1
    }
    if (!found) {
      arr.push(id)
    }
    this.selectedIds = arr
  }

  private selectAll(): void {
    const fl: Array<LogEntry> = this.filteredLogs()
    const arr: Array<number> = []
    let i: number = 0
    while (i < fl.length) {
      arr.push(fl[i].id);
      i = i + 1
    }
    this.selectedIds = arr
  }

  private invertSelect(): void {
    const fl: Array<LogEntry> = this.filteredLogs()
    const arr: Array<number> = []
    let i: number = 0
    while (i < fl.length) {
      const id: number = fl[i].id
      if (!this.isSelected(id)) {
        arr.push(id)
      }
      i = i + 1
    }
    this.selectedIds = arr
  }

  private selectedCount(): number {
    return this.selectedIds.length
  }

  private async batchDelete(): Promise<void> {
    if (this.selectedIds.length === 0) {
      return
    }
    // 逐个调用外部 onDelete，不需要修改 Index
    let i: number = 0
    while (i < this.selectedIds.length) {
      this.onDelete(this.selectedIds[i])
      i = i + 1
    }
    this.selectedIds = []
    this.selectMode = false
  }

  private exitSelectMode(): void {
    this.selectMode = false
    this.selectedIds = []
  }

  private exitSelectOrClose(): void {
    if (this.selectMode) {
      this.exitSelectMode()
    } else {
      this.onClose()
    }
  }

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
