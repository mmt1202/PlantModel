import { PlantDraft } from '../model/PlantModel';
import { KeyboardAvoidMode } from '@kit.ArkUI';

/** -------- 底部「编辑/新建」抽屉（V2 组件，新增周期任务区） -------- */
@ComponentV2
export struct EditPlantSheet {
  @Param @Require title: string
  @Param @Require draft: PlantDraft
  @Param @Require editingId: number
  @Event onSave: () => void
  @Event onDelete: () => void
  @Event onClose: () => void
  @Event onQuickWater: () => void
  @Event onBulkSchedule: (type: string, everyDays: number, times: number) => void
  @Event onOpenTpl: () => void
  @Event onOpenLogs: () => void // ← 新增
  // 按钮按压状态
  @Local savePressed: boolean = false
  @Local deletePressed: boolean = false
  @Local waterPressed: boolean = false
  // 背景遮罩动画
  @Local maskOpacity: number = 0

  aboutToAppear(): void {
    this.getUIContext().setKeyboardAvoidMode(KeyboardAvoidMode.RESIZE);
    // 背景遮罩渐显动画
    animateTo({ duration: 250, curve: Curve.EaseInOut }, () => {
      this.maskOpacity = 1
    })
  }

  aboutToDisappear(): void {
    this.getUIContext().setKeyboardAvoidMode(KeyboardAvoidMode.NONE);

  }

  build() {
    Stack() {
      Column() {
        Blank()
          .backgroundColor(`rgba(0,0,0,${0.6 * this.maskOpacity})`)
          .width('100%')
          .height('100%')
          .onClick(() => {
            this.onClose()
          })
      }

      Column() {
        Row() {
          Text(this.title).fontSize(16).fontWeight(FontWeight.Medium).fontColor(0xFF263238)
          Blank()
          Image($r('app.media.ic_close')).width(18).height(18).onClick(() => {
            this.onClose()
          })
        }
        .padding({
          left: 16,
          right: 16,
          top: 12,
          bottom: 6
        })

        Column() {
          this.FormItem('名称', '输入植物名称', this.draft.name, (v: string) => {
            this.draft.name = v
          })
          this.FormItem('品种', '如：龟背竹/月季', this.draft.species, (v: string) => {
            this.draft.species = v
          })
          this.FormItem('位置', '如：客厅窗边/阳台', this.draft.location, (v: string) => {
            this.draft.location = v
          })

          // 周期任务快捷 + 模板入口
          Column({ space: 10 }) {
            Text('周期任务').fontSize(12).fontColor(0xFF607D8B).margin({ bottom: 6 })
            Row() {
              this.BulkChip('每7天×4次(浇水)', () => {
                this.onBulkSchedule('浇水', 7, 4)
              })
              this.BulkChip('每3天×6次(施肥)', () => {
                this.onBulkSchedule('施肥', 3, 6)
              })
              this.BulkChip('每14天×3次(修剪)', () => {
                this.onBulkSchedule('修剪', 14, 3)
              })
            }

            Row() {
              this.LinkChip('管理周期模板…', () => {
                this.onOpenTpl()
              })
              // ← 新增：日志入口
              // if (this.editingId !== 0) {
              //   this.LinkChip('管理日志…', () => { this.onOpenLogs() })
              // }
            }.margin({ top: 6 })
          }.margin({ top: 8 })

          Row({ space: 10 }) {
            Button('保存')
              .type(ButtonType.Capsule)
              .onClick(() => {
                this.onSave()
              })
              .backgroundColor(0xFF2E7D32)
              .fontColor(0xFFFFFFFF)
              .padding({
                left: 18,
                right: 18,
                top: 8,
                bottom: 8
              })
              .borderRadius(20)
              .scale(this.savePressed ? { x: 0.95, y: 0.95 } : { x: 1, y: 1 })
              .animation({ duration: 100, curve: Curve.EaseOut })
              .onTouch((e: TouchEvent) => {
                if (e.type === TouchType.Down) {
                  this.savePressed = true
                } else if (e.type === TouchType.Up || e.type === TouchType.Cancel) {
                  this.savePressed = false
                }
              })

            if (this.editingId !== 0) {
              Button('删除')
                .type(ButtonType.Capsule)
                .onClick(() => {
                  this.onDelete()
                })
                .backgroundColor(0xFFE53935)
                .fontColor(0xFFFFFFFF)
                .padding({
                  left: 18,
                  right: 18,
                  top: 8,
                  bottom: 8
                })
                .borderRadius(20)
                .margin({ left: 12 })
                .scale(this.deletePressed ? { x: 0.95, y: 0.95 } : { x: 1, y: 1 })
                .animation({ duration: 100, curve: Curve.EaseOut })
                .onTouch((e: TouchEvent) => {
                  if (e.type === TouchType.Down) {
                    this.deletePressed = true
                  } else if (e.type === TouchType.Up || e.type === TouchType.Cancel) {
                    this.deletePressed = false
                  }
                })
            }

            // Blank()

            Button('添加今日浇水')
              .type(ButtonType.Capsule)
              .onClick(() => {
                this.onQuickWater()
              })
              .backgroundColor(0xFF1565C0)
              .fontColor(0xFFFFFFFF)
              .padding({
                left: 14,
                right: 14,
                top: 8,
                bottom: 8
              })
              .borderRadius(20)
              .scale(this.waterPressed ? { x: 0.95, y: 0.95 } : { x: 1, y: 1 })
              .animation({ duration: 100, curve: Curve.EaseOut })
              .onTouch((e: TouchEvent) => {
                if (e.type === TouchType.Down) {
                  this.waterPressed = true
                } else if (e.type === TouchType.Up || e.type === TouchType.Cancel) {
                  this.waterPressed = false
                }
              })
          }.margin({ top: 10 })
        }
        .padding({
          left: 16,
          right: 16,
          top: 10,
          bottom: 18
        })
      }
      .width('100%')
      .backgroundColor(0xFFFFFFFF)
      .borderRadius({
        topLeft: 20,
        topRight: 20,
        bottomLeft: 0,
        bottomRight: 0
      })
      .shadow({
        radius: 24,
        color: 0x33000000,
        offsetX: 0,
        offsetY: -6
      })
      .animation({
        duration: 300,
        curve: Curve.Friction,
        playMode: PlayMode.Normal
      })
    }.width('100%').height('100%').alignContent(Alignment.Bottom)
  }

  @Builder
  BulkChip(text: string, onTap: () => void) {
    Text(text)
      .fontSize(11)
      .fontColor(0xFF263238)
      .padding({
        left: 8,
        right: 8,
        top: 5,
        bottom: 5
      })
      .borderRadius(12)
      .backgroundColor(0xFFE3F2FD)
      .onClick(() => {
        onTap()
      })
      .margin({ right: 8 })
  }

  @Builder
  LinkChip(text: string, onTap: () => void) {
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
      .margin({ right: 12 })
  }

  @Builder
  FormItem(label: string, placeholder: string, val: string, onChange: (v: string) => void) {
    Column() {
      Text(label).fontSize(12).fontColor(0xFF607D8B)
      TextInput({ placeholder: placeholder, text: val })
        .placeholderColor('#747474').fontColor('#000000')
        .onChange((v: string) => {
          onChange(v)
        })
        .width('100%')
        .height(40)
        .borderRadius(12)
        .backgroundColor(0xFFF9F9F9)
        .padding({ left: 12, right: 12 })
        .margin({ top: 6 })
    }.margin({ top: 6 })
  }
}