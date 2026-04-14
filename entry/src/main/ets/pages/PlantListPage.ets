import { Plant, PlantTask } from '../model/PlantModel'
import { PlantCard } from '../view/PlantCard'

@ComponentV2
export struct PlantListPage {
  @Param @Require plants: Array<Plant>
  @Param @Require allTasks: Array<PlantTask>
  @Event onOpenDetail: (p: Plant) => void
  @Event onQuickAdd: (plantId: number, type: string) => void
  @Event onEdit: (p: Plant) => void
  @Event onDeleteAsk: (plantId: number) => void
  @Event onOpenTemplate: (p: Plant) => void
  @Event onOpenTemplatenew: (pid: number) => void
  @Event onOpenLogs: (p: Plant) => void
  @Event onOpenWaterEstimator: (p: Plant) => void
  @Event onOpenMetrics: (p: Plant) => void
  @Event onOpenEmergencyAndRotate: (p: Plant) => void

  @Event onOpenMetric: (plantId: number) => void
  // —— 新增本地状态：筛选与排序 —— //
  @Local selectedSpecies: string = '全部'
  @Local sortKey: number = 0;
  @BuilderParam Header?:()=>void


  // 卡片上的完成数、总数都从共享任务列表里现算，避免每个 PlantCard 再单独拉数据。
  private plantTaskDone(plantId: number): number {
    let i: number = 0;
    let d: number = 0
    while (i < this.allTasks.length) {
      if (this.allTasks[i].plantId === plantId && this.allTasks[i].done === 1) {
        d = d + 1
      }
      i = i + 1
    }
    return d
  }

  private plantTaskTotal(plantId: number): number {
    let i: number = 0;
    let t: number = 0
    while (i < this.allTasks.length) {
      if (this.allTasks[i].plantId === plantId) {
        t = t + 1
      }
      i = i + 1
    }
    return t
  }

  private plantRatePct(plantId: number): number {
    const total: number = this.plantTaskTotal(plantId)
    if (total === 0) {
      return 0
    }
    const done: number = this.plantTaskDone(plantId)
    return Math.floor(done * 100 / total)
  }

  private ratioString(plantId: number): string {
    const r: number = this.plantRatePct(plantId)
    return `${r}%`
  }

  // 物种芯片列表（含“全部”）
  // 从现有植物中提取物种标签，筛选项永远和真实数据保持一致。
  private speciesChips(): Array<string> {
    const set: Array<string> = ['全部']
    let i: number = 0
    while (i < this.plants.length) {
      const sp: string = this.plants[i].species ? this.plants[i].species : ''
      if (sp.length > 0) {
        // 去重
        let exist: boolean = false
        let j: number = 0
        while (j < set.length) {
          if (set[j] === sp) {
            exist = true
          }
          j = j + 1
        }
        if (!exist) {
          set.push(sp)
        }
      }
      i = i + 1
    }
    return set
  }

  // 根据筛选+排序得到最终显示列表
  // 先做本地筛选，再做排序，最终返回列表页真正渲染的数据源。
  private filteredAndSortedPlants(): Array<Plant> {
    // 过滤
    let tmp: Array<Plant> = []
    let i: number = 0
    while (i < this.plants.length) {
      const p: Plant = this.plants[i]
      if (this.selectedSpecies === '全部' || (p.species && p.species === this.selectedSpecies)) {
        tmp.push(p)
      }
      i = i + 1
    }
    // 排序
    // 0=创建时间(新→旧)  1=名称(A→Z)  2=完成率(高→低)
    if (this.sortKey === 0) {
      tmp.sort((a: Plant, b: Plant) => b.createdAt - a.createdAt)
    } else if (this.sortKey === 1) {
      tmp.sort((a: Plant, b: Plant) => a.name.localeCompare(b.name))
    } else {
      tmp.sort((a: Plant, b: Plant) => this.plantRatePct(b.id) - this.plantRatePct(a.id))
    }
    return tmp
  }

  build() {
    // Header 由首页透传进来，这样列表页可以复用统一的搜索与标题区域。
    Column() {
      // —— 新增：筛选与排序条 —— //
      if (this.Header){
        this.Header()
      }
      // 物种筛选芯片
      Row() {
        Text('物种').fontSize(12).fontColor(0xFF607D8B).margin({ right: 8 })
        // ForEach 渲染物种芯片
        ForEach(this.speciesChips(), (sp: string, index:number) => {
          this.SpeciesChip(sp)
        }, (sp: string) => `sp-${sp}`)
      }
      .padding({
        left: 12,
        right: 12,
        top: 4,
        bottom: 2
      })

      // 排序芯片
      Row() {
        Text('排序').fontSize(12).fontColor(0xFF607D8B).margin({ right: 8 })
        this.SortChip('最新', 0)
        this.SortChip('名称', 1)
        this.SortChip('完成率', 2)
      }
      .padding({ left: 12, right: 12, bottom: 6 })

      if (this.filteredAndSortedPlants().length === 0) {
        Column() {
          Text('没有符合条件的植物').fontColor(0xFF90A4AE).fontSize(14).margin({ top: 24 })
          // Text('暂无植物，点击右下角 “＋” 添加').fontColor(0xFF90A4AE).fontSize(14).margin({ top: 32 })
        }.width('100%')
      } else {
        List({ space: 8 }) {
          ForEach(this.filteredAndSortedPlants(), (p: Plant) => {
            ListItem() {
              // PlantCard 只负责展示和抛事件,实际增删改统一交回上层页面处理。
              PlantCard({
                p: p,
                done: this.plantTaskDone(p.id),
                total: this.plantTaskTotal(p.id),
                ratioText: this.ratioString(p.id),
                onQuickAdd: (type: string) => {
                  this.onQuickAdd(p.id, type)
                },
                onEdit: () => {
                  this.onEdit(p)
                },
                onDeleteAsk: () => {
                  this.onDeleteAsk(p.id)
                },
                onOpenLogs: () => { this.onOpenLogs(p) },
                onOpenWaterEstimator: () => { this.onOpenWaterEstimator(p) },
                onOpenEmergencyAndRotate: ()=>{ this.onOpenEmergencyAndRotate(p) },
                onOpenMetrics: () => { this.onOpenMetrics(p) },
                onOpenTemplate: () => { this.onOpenTemplate(p) },
                onOpenTemplatenew: (pid:number) => { this.onOpenTemplatenew(pid) }, // ← 新增透传
                onOpenMetric: () => { this.onOpenMetric(p.id) }
              })
            }.onClick(()=>{
              this.onOpenDetail(p)
            })
          }, (p: Plant) => p.id.toString())
        }
        .padding({
          left: 12,
          right: 12,
          top: 8,
          bottom: 64
        }).width('100%').height('calc(100% - 105vp)')
        .edgeEffect(EdgeEffect.Spring)
        .scrollBar(BarState.Off)
        .animation({
          duration: 300,
          curve: Curve.EaseInOut
        })
      }
    }.height('100%').width('100%')

  }
  // —— UI 子块（Builder 内不做计算） —— //
  // Builder 里尽量只保留展示代码，避免在重复渲染时夹杂复杂计算。
  @Builder
  SpeciesChip(text: string) {
    Text(text)
      .fontSize(11)
      .fontColor(this.selectedSpecies === text ? 0xFF1B5E20 : 0xFF263238)
      .padding({ left: 10, right: 10, top: 6, bottom: 6 })
      .borderRadius(12)
      .backgroundColor(this.selectedSpecies === text ? 0xFFE8F5E9 : 0xFFFFFFFF)
      .onClick(() => { animateTo({ duration: 120, curve: Curve.EaseInOut }, () => { this.selectedSpecies = text})})
      .margin({ right: 8, bottom: 4 })
      .shadow({ radius: this.selectedSpecies === text ? 10 : 6, color: 0x10000000, offsetX: 0, offsetY: this.selectedSpecies === text ? 2 : 1 })
  }

  @Builder
  SortChip(text: string, key: number) {
    Text(text)
      .fontSize(11)
      .fontColor(this.sortKey === key ? 0xFF1565C0 : 0xFF263238)
      .padding({ left: 10, right: 10, top: 6, bottom: 6 })
      .borderRadius(12)
      .backgroundColor(this.sortKey === key ? 0xFFE3F2FD : 0xFFFFFFFF)
      .onClick(() => { animateTo({ duration: 120, curve: Curve.EaseInOut }, () => { this.sortKey = key }) })
      .margin({ right: 8, bottom: 4 })
      .shadow({ radius: this.sortKey === key ? 10 : 6, color: 0x10000000, offsetX: 0, offsetY: this.sortKey === key ? 2 : 1 })
  }
}
