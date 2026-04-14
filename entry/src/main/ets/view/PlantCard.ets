import { LogEntry, Plant } from '../model/PlantModel'
import { RdbManager } from '../viewmodel/RdbManager'
import { relationalStore } from '@kit.ArkData'
import { LogPhoto, PlantLog } from './PlantLogSheet'

/** -------- 子组件：单个植物卡片（V2）-------- */
@ComponentV2
export struct PlantCard {
  @Param @Require p: Plant
  @Param @Require done: number
  @Param @Require total: number
  @Param @Require ratioText: string
  @Event onQuickAdd: (type: string) => void
  @Event onEdit: () => void
  @Event onDeleteAsk: () => void
  @Event onOpenLogs: () => void
  @Event onOpenWaterEstimator: (p: Plant) => void
  @Event onOpenEmergencyAndRotate: (p: Plant) => void
  @Event onOpenMetrics: () => void
  @Event onOpenTemplate: () => void
  @Event onOpenTemplatenew: (pid: number) => void
  @Event onOpenMetric: (plantId: number) => void
  @Consumer('RdbManager') RdbManager: RdbManager = RdbManager.getInstance()
  @Consumer('store') store: relationalStore.RdbStore | null = this.RdbManager.rdbStore
  @Local pressed: boolean = false
  @Local logs: Array<PlantLog> = []
  @Local photos: Array<LogPhoto> = []
  @Local isLighting: boolean = false
  @Local lightOpacity: number = 0.3
  // 图标按钮按压状态
  @Local metricPressed: boolean = false
  @Local editPressed: boolean = false
  @Local deletePressed: boolean = false

  async aboutToAppear() {
    // 卡片自身会补拉最近日志和照片，用来展示封面图和补光状态。
    await this.loadLogsWithPhotos(this.p.id)
    this.checkLightingStatus()
  }

  // 补光状态通过 AppStorage 广播给卡片层，这样首页重载后也能立刻恢复视觉反馈。
  private checkLightingStatus() {
    this.isLighting = AppStorage.get<boolean>(`lighting_${this.p.id}`) ?? false
    if (this.isLighting) {
      this.startBreathing()
    }
  }

  private startBreathing() {
    animateTo({ duration: 1000, iterations: -1, curve: Curve.EaseInOut, playMode: PlayMode.Alternate }, () => {
      this.lightOpacity = 1.0
    })
  }

  @Builder
  BreathingOverlay() {
    Column()
      .width('100%')
      .height('100%')
      .borderRadius(20)
      .backgroundColor('#FFFF00')
      .opacity(this.lightOpacity)
      .hitTestBehavior(HitTestMode.None)
  }

  private typeColor(t: string): ResourceColor {
    if (t === '浇水') {
      return 0xFF3AAFA9
    }
    if (t === '施肥') {
      return 0xFF8E7CC3
    }
    if (t === '修剪') {
      return 0xFFE57373
    }
    return 0xFF607D8B
  }

  // 植物卡片默认取第一张日志照片做缩略封面，没有照片时才退回首字头像。
  private async loadLogsWithPhotos(plantId: number): Promise<void> {
    if (!this.store) {
      return
    }

    const rs1 = await this.store.querySql(
      `SELECT id, plantId, note, createdAt
     FROM ${RdbManager.T_LOG}
     WHERE plantId = ?
     ORDER BY createdAt DESC, id DESC`, [plantId]
    )
    const arrLogs: Array<LogEntry> = []
    while (rs1.goToNextRow()) {
      arrLogs.push(new LogEntry(rs1.getLong(0), rs1.getLong(1), rs1.getString(2), rs1.getLong(3)))
    }
    rs1.close()
    this.logs = arrLogs

    const rs2 = await this.store.querySql(
      `SELECT p.id, p.logId, p.path, p.thumbPath, p.createdAt
     FROM ${RdbManager.T_LOG_PHOTO} p
     JOIN ${RdbManager.T_LOG} l ON p.logId = l.id
     WHERE l.plantId = ?
     ORDER BY p.id DESC`, [plantId]
    )
    const arrPhotos: Array<LogPhoto> = []
    while (rs2.goToNextRow()) {
      arrPhotos.push(new LogPhoto(rs2.getLong(0), rs2.getLong(1), rs2.getString(2), rs2.getString(3), rs2.getLong(4)))
    }
    rs2.close()
    this.photos = arrPhotos
  }

  build() {
    // 这个卡片既是植物概览，也是多个功能入口的聚合导航节点。
    Column({ space: 10 }) {
      Row() {
        Column() {
          if (this.p.name.length > 0) {
            if (this.photos.length > 0) {
              Image(this.photos[0].path).width(40).height(40).borderRadius(20)
            } else {
              Text(this.p.name.substring(0, 1)).fontSize(18).fontWeight(FontWeight.Medium).fontColor(0xFFFFFFFF)
            }
          } else {
            Text('植').fontSize(18).fontWeight(FontWeight.Medium).fontColor(0xFFFFFFFF)
          }
        }
        .width(40)
        .height(40)
        .borderRadius(20)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .border(AppStorage.get<boolean>(`lighting_${this.p.id}`) ?? false ? { width: 2, color: '#FFEB3B' } : undefined)
        .shadow(AppStorage.get<boolean>(`lighting_${this.p.id}`) ?? false ? { radius: 10, color: '#FFFF00', offsetX: 0, offsetY: 0 } : undefined)
        .overlay(AppStorage.get<boolean>(`lighting_${this.p.id}`) ?? false ? this.BreathingOverlay() : undefined)

        Column({ space: 4 }) {
          Row({ space: 8 }) {
            Text(this.p.name).fontSize(16).fontWeight(FontWeight.Medium).fontColor(0xFF263238)
            if (AppStorage.get<boolean>(`lighting_${this.p.id}`) ?? false) {
              Row({ space: 4 }) {
                Image($r('app.media.ic_sun_small')).width(10).height(10)
                Text('光照中')
                  .fontSize(10)
                  .fontColor(0xFFFFFFFF)
              }
                .backgroundColor(0xFFFFA000)
                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                .borderRadius(8)
            }
          }
          Text(`${this.p.species} · ${this.p.location}`).fontSize(12).fontColor(0xFF607D8B).margin({ top: 2 })
        }.margin({ left: 10 })

        Blank()

        Row({ space: 8 }) {
          Image($r('app.media.ic_trending'))
            .width(16)
            .height(16)
            .scale(this.metricPressed ? { x: 0.85, y: 0.85 } : { x: 1, y: 1 })
            .animation({ duration: 120, curve: Curve.EaseInOut })
            .onClick(() => {
              this.onOpenMetric(this.p.id)
            })
            .onTouch((e: TouchEvent) => {
              if (e.type === TouchType.Down) {
                this.metricPressed = true
              } else if (e.type === TouchType.Up || e.type === TouchType.Cancel) {
                this.metricPressed = false
              }
            })
          Image($r('app.media.ic_edit'))
            .width(16)
            .height(16)
            .scale(this.editPressed ? { x: 0.85, y: 0.85 } : { x: 1, y: 1 })
            .animation({ duration: 120, curve: Curve.EaseInOut })
            .onClick(() => {
              this.onEdit()
            })
            .onTouch((e: TouchEvent) => {
              if (e.type === TouchType.Down) {
                this.editPressed = true
              } else if (e.type === TouchType.Up || e.type === TouchType.Cancel) {
                this.editPressed = false
              }
            })
          Image($r('app.media.ic_delete'))
            .width(16)
            .height(16)
            .scale(this.deletePressed ? { x: 0.85, y: 0.85 } : { x: 1, y: 1 })
            .animation({ duration: 120, curve: Curve.EaseInOut })
            .onClick(() => {
              this.onDeleteAsk()
            })
            .onTouch((e: TouchEvent) => {
              if (e.type === TouchType.Down) {
                this.deletePressed = true
              } else if (e.type === TouchType.Up || e.type === TouchType.Cancel) {
                this.deletePressed = false
              }
            })
        }
      }.width('100%').justifyContent(FlexAlign.SpaceBetween)

      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
        Text('日志')
          .fontSize(12)
          .fontColor(0xFF1565C0)
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .borderRadius(12)
          .backgroundColor(0x102196F3)
          .onClick(() => {
            this.onOpenLogs()
          })
          .margin({ right: 8, bottom: 8 })

        Text('指标')
          .fontSize(12)
          .fontColor(0xFF2E7D32)
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .borderRadius(12)
          .backgroundColor(0xE8F5E9)
          .onClick(() => {
            this.onOpenMetrics()
          })
          .margin({ right: 8, bottom: 8 })

        Text('模板')
          .fontSize(12)
          .fontColor(0xFF8E24AA)
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .borderRadius(12)
          .backgroundColor(0x10BA68C8)
          .onClick(() => {
            this.onOpenTemplate()
          })
          .margin({ right: 8, bottom: 8 })

        Text('新模板')
          .fontSize(12)
          .fontColor(0xFF8E24AA)
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .borderRadius(12)
          .backgroundColor(0x10BA68C8)
          .onClick(() => {
            this.onOpenTemplatenew(this.p.id)
          })
          .margin({ right: 8, bottom: 8 })

        Text('盆栽')
          .fontSize(12)
          .fontColor(0xFF8E24AA)
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .borderRadius(12)
          .backgroundColor(0x10BA68C8)
          .onClick(() => {
            this.onOpenEmergencyAndRotate(this.p)
          })
          .margin({ right: 8, bottom: 8 })

        Text('用量估算器')
          .fontSize(12)
          .fontColor(0xFF8E24AA)
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .borderRadius(12)
          .backgroundColor(0x10BA68C8)
          .onClick(() => {
            this.onOpenWaterEstimator(this.p)
          })
          .margin({ right: 8, bottom: 8 })
      }

      Row() {
        Column() {
          Progress({ value: this.done, total: this.total, type: ProgressType.Linear })
            .width('100%')
            .height(6)
            .backgroundColor(0xFFE0E0E0)
            .color(0xFF66BB6A)
            .animation({ duration: 220, curve: Curve.EaseInOut })
        }.width('70%')

        Text(`${this.done}/${this.total}`).fontSize(12).fontColor(0xFF455A64).margin({ left: 12 })
      }.margin({ top: 10 })

      Row() {
        this.QuickChip('浇水')
        this.QuickChip('施肥')
        this.QuickChip('修剪')
      }.margin({ top: 10 })
    }
    .width('100%')
    .padding(14)
    .borderRadius(16)
    .backgroundColor(0xFFFFFFFF)
    .linearGradient({ direction: GradientDirection.Right, colors: [[0x10A5D6A7, 0], [0x1000BCD4, 1]] })
    .shadow({ radius: 16, color: 0x1F000000, offsetX: 0, offsetY: 4 })
    .scale(this.pressed ? { x: 0.98, y: 0.98 } : { x: 1, y: 1 })
    .onTouch((e: TouchEvent) => {
      if (e.type === TouchType.Down) {
        this.pressed = true
      }
      if (e.type === TouchType.Up || e.type === TouchType.Cancel) {
        this.pressed = false
      }
    })
    .animation({ duration: 120, curve: Curve.EaseInOut })
  }

  @Builder
  QuickChip(type: string) {
    // 快捷按钮只是帮用户快速创建今日任务,真正落库仍由父页面统一完成。
    Text(type)
      .fontSize(12)
      .fontColor(0xFFFFFFFF)
      .backgroundColor(this.typeColor(type))
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .borderRadius(12)
      .margin({ right: 8 })
      .onClick(() => {
        this.onQuickAdd(type)
      })
      .onTouch((e: TouchEvent) => {
        if (e.type === TouchType.Down) {
          animateTo({ duration: 80, curve: Curve.EaseOut }, () => {
          })
        }
      })
  }
}
