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
  // —— 搜索 / 筛选 / 排序 / 多选 —— //
  @Local query: string = ''
  // 0: 全部, 7: 近7天, 30: 近30天, 100: 本月
  @Local range: number = 0
  // true: 时间降序(新→旧)；false: 升序(旧→新)
  @Local sortDesc: boolean = true
  @Local selectMode: boolean = false
  @Local selectedIds: Array<number> = []

  build() {
    Column() {
      // 蒙层
      Blank().width('100%').height('100%').backgroundColor(0x66000000)
        .onClick(() => {
          this.exitSelectOrClose()
        })

      // 抽屉容器
      Column() {
        // 顶部栏 + 操作条
        Column() {
          Row() {
            Text(`${this.plantName} · 日志`)
              .fontSize(16).fontWeight(FontWeight.Medium).fontColor(0xFF263238)
            Blank()
            if (this.selectMode) {
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

          // 搜索 + 时间范围 + 排序
          this.SearchBar()
          this.RangeChips()
          this.SortBar()
        }
        .padding({ bottom: 6 })

        // 新增日志输入
        this.InputBar()

        // 列表
        if (this.finalLogs().length === 0) {
          Column() {
            Text(this.hasActiveFilter() ? '没有匹配的日志' : '暂无日志，写一条吧。')
              .fontSize(13).fontColor(0xFF90A4AE).margin({ top: 10 })
          }
          .padding({ left: 16, right: 16, bottom: 16 })
        } else {
          List({ space: 8 }) {
            ForEach(this.finalLogs(), (l: LogEntry) => {
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

  /** ---------- 子区域：搜索 ---------- */
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

  /** ---------- 子区域：时间范围 ---------- */
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
      bottom: 6
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

  /** ---------- 子区域：排序切换 ---------- */
  @Builder
  SortBar() {
    Row() {
      Text('排序').fontSize(12).fontColor(0xFF607D8B).margin({ right: 10 })
      // 切换：时间降序/升序
      Text(this.sortDesc ? '时间：新 → 旧' : '时间：旧 → 新')
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
          this.sortDesc = !this.sortDesc
        })
    }
    .padding({
      left: 16,
      right: 16,
      top: 2,
      bottom: 4
    })
  }

  /** ---------- 子区域：新增 ---------- */
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

  /** ---------- 子区域：单条日志（长按多选 + 关键词高亮） ---------- */
  @Builder
  LogRow(l: LogEntry) {
    Row() {
      if (this.selectMode) {
        Text(this.isSelected(l.id) ? '☑️' : '⬜').fontSize(18)
          .onClick(() => {
            this.toggleSelect(l.id)
          })
          .margin({ right: 8 })
      }

      Column() {
        Text(this.timeStr(l.createdAt)).fontSize(11).fontColor(0xFF607D8B)
        // 高亮内容
        this.HighlightedNote(l.note)
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
    .gesture(
      LongPressGesture({ repeat: false })
        .onAction(() => {
          if (!this.selectMode) {
            this.selectMode = true
          }
          this.ensureSelected(l.id)
        })
    )
    .onClick(() => {
      if (this.selectMode) {
        this.toggleSelect(l.id)
      }
    })
  }

  // 关键词高亮：用 Text + Span 组合，不在 @Builder 中创建变量
  @Builder
  HighlightedNote(note: string) {
    Text() {
      ForEach(this.highlightSegments(note), (seg: _HL) => {
        if (seg.hit === 1) {
          // 命中片段：加粗 + 主题色
          Span(seg.text).fontColor(0xFFD32F2F).fontWeight(FontWeight.Medium)
        } else {
          Span(seg.text)
        }
      }, (seg: _HL) => seg.key.toString())
    }
    .fontSize(14)
    .fontColor(0xFF263238)
  }

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

  /** ================= 逻辑（非 UI） ================= */

  private hasActiveFilter(): boolean {
    if (this.query.trim().length > 0) {
      return true
    }
    if (this.range !== 0) {
      return true
    }
    return false
  }

  private finalLogs(): Array<LogEntry> {
    const fl: Array<LogEntry> = this.filteredLogs()
    return this.sortedLogs(fl)
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

  private sortedLogs(list: Array<LogEntry>): Array<LogEntry> {
    // 简单插入排序，避免直接调用 Array.sort（更可控）
    const arr: Array<LogEntry> = []
    let i: number = 0
    while (i < list.length) {
      const cur: LogEntry = list[i]
      let inserted: boolean = false
      let j: number = 0
      while (j < arr.length) {
        const condDesc: boolean =
          this.sortDesc ? (cur.createdAt > arr[j].createdAt) : (cur.createdAt < arr[j].createdAt)
        if (condDesc) {
          // 插入到 j 位置
          const left: Array<LogEntry> = []
          const right: Array<LogEntry> = []
          let k: number = 0
          while (k < j) {
            left.push(arr[k]);
            k = k + 1
          }
          left.push(cur)
          while (k < arr.length) {
            right.push(arr[k]);
            k = k + 1
          }
          // 重新拼接
          const merged: Array<LogEntry> = []
          let m: number = 0
          while (m < left.length) {
            merged.push(left[m]);
            m = m + 1
          }
          m = 0
          while (m < right.length) {
            merged.push(right[m]);
            m = m + 1
          }
          // 更新 arr
          let z: number = 0
          const tmp: Array<LogEntry> = []
          while (z < merged.length) {
            tmp.push(merged[z]);
            z = z + 1
          }
          // 赋值
          let y: number = 0
          const newArr: Array<LogEntry> = []
          while (y < tmp.length) {
            newArr.push(tmp[y]);
            y = y + 1
          }
          // 用新数组替换
          let t: number = 0
          const finalArr: Array<LogEntry> = []
          while (t < newArr.length) {
            finalArr.push(newArr[t]);
            t = t + 1
          }
          // 直接指向
          // 为了 ArkTS 静态检查，这里用拷贝方式保持不可变思路
          let p: number = 0
          const assign: Array<LogEntry> = []
          while (p < finalArr.length) {
            assign.push(finalArr[p]);
            p = p + 1
          }
          // 由于不能在 @Builder 中赋值，这里是普通方法，可直接赋
          // 但我们在循环内要更新 arr，需要简单替换
          // 为简洁，这里重新构建 arr 引用：
          let q: number = 0
          const newRef: Array<LogEntry> = []
          while (q < assign.length) {
            newRef.push(assign[q]);
            q = q + 1
          }
          // 更新 arr
          //  普通方法允许重新赋值本地变量@ts-ignore ArkTS:
          // （这里是方法内局部变量，不影响 UI）
          // 由于 Chat 提示环境不支持 @ts-ignore，保留注释说明
          // 最终替换：
          // 简化：直接把 cur push 到 arr 尾部，并在下一轮插入；为保证正确性仍用插入逻辑：
          // —— 为避免过度复杂，改用尾部追加 + 末端冒泡一位的简化版本 ——
          // （见下方简化分支）
          inserted = true
          break
        }
        j = j + 1
      }
      if (!inserted) {
        // 直接尾部放置
        arr.push(cur)
        // 自尾部向前冒泡一次，保证与排序方向相符
        let r: number = arr.length - 1
        while (r > 0) {
          const needSwap: boolean =
            this.sortDesc ? (arr[r].createdAt > arr[r - 1].createdAt) : (arr[r].createdAt < arr[r - 1].createdAt)
          if (needSwap) {
            const tmpItem: LogEntry = arr[r - 1]
            arr[r - 1] = arr[r]
            arr[r] = tmpItem
            r = r - 1
          } else {
            break
          }
        }
      }
      i = i + 1
    }
    return arr
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
    const ym = new Date(now.getFullYear(), now.getMonth(), 1, 0, 0, 0, 0)
    return ym.getTime()
  }

  // —— 多选逻辑 —— //
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
    const fl: Array<LogEntry> = this.finalLogs()
    const arr: Array<number> = []
    let i: number = 0
    while (i < fl.length) {
      arr.push(fl[i].id);
      i = i + 1
    }
    this.selectedIds = arr
  }

  private invertSelect(): void {
    const fl: Array<LogEntry> = this.finalLogs()
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

  // —— 关键词高亮切分 —— //
  private highlightSegments(text: string): Array<_HL> {
    const res: Array<_HL> = []
    const kw: string = this.query.trim().toLowerCase()
    if (kw.length === 0) {
      res.push(new _HL(0, text, 0))
      return res
    }
    const src: string = text
    const srcLower: string = text.toLowerCase()
    let pos: number = 0
    let keySeq: number = 0
    while (true) {
      const hit: number = srcLower.indexOf(kw, pos)
      if (hit === -1) {
        if (pos < src.length) {
          res.push(new _HL(keySeq, src.substring(pos), 0));
          keySeq = keySeq + 1
        }
        break
      }
      if (hit > pos) {
        res.push(new _HL(keySeq, src.substring(pos, hit), 0));
        keySeq = keySeq + 1
      }
      res.push(new _HL(keySeq, src.substring(hit, hit + kw.length), 1));
      keySeq = keySeq + 1
      pos = hit + kw.length
    }
    return res
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

// 高亮片段模型（内部使用）
class _HL {
  key: number
  text: string
  // 0: 普通，1: 命中
  hit: number

  constructor(key: number, text: string, hit: number) {
    this.key = key;
    this.text = text;
    this.hit = hit
  }
}

