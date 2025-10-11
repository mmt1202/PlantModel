// /page/EmergencyAndRotatePage.ets
// 合页：急救流程卡 + 转盆提醒（V2）
// - 顶部二段切换（Chip）在“急救 / 转盆”之间切换
// - UI 结构全部在 @Builder 中，UI 内不声明本地变量
// - 通过 @Param 注入 plantId；不使用 Router.*

import { EmergencyViewModel } from '../viewmodel/EmergencyViewModel';
import { PlaybookItem, PlayStep } from '../model/EmergencyPlaybook';
import EmergencyLog from '../model/EmergencyLog';
import { RotatePlanViewModel, RotateLog } from '../viewmodel/RotatePlanViewModel';

@ComponentV2
export struct EmergencyAndRotatePage {
  @Param plantId: string = '';

  @Local tabBarIndex: number = 0; // 0=急救，1=转盆

  @Local emgVM: EmergencyViewModel = new EmergencyViewModel('');
  @Local rotVM: RotatePlanViewModel = new RotatePlanViewModel('');

  aboutToAppear() {
    const pid: string = (this.plantId && this.plantId !== '') ? this.plantId : 'PLANT_DEMO';
    this.emgVM = new EmergencyViewModel(pid);
    this.rotVM = new RotatePlanViewModel(pid);
  }

  build() {
    Scroll() {
      Column({ space: 14 }) {
        this.Header()
        this.TabSwitch()
        if (this.tabBarIndex === 0) {
          this.EmergencyPanel()
        } else {
          this.RotatePanel()
        }
      }
    }
    .backgroundColor('#FAFAFA')
    .edgeEffect(EdgeEffect.Spring)
  }

  // ===== 顶部 =====
  @Builder Header() {
    Row() {
      Column() {
        Text('急救流程卡 & 转盆提醒').fontSize(22).fontWeight(FontWeight.Medium)
        Text(`植物ID：${this.emgVM.plantId}`).fontSize(12).opacity(0.6)
      }
      Blank()
    }
    .padding({ left: 16, right: 16, top: 12 })
  }

  // ===== Tab 切换 =====
  @Builder TabSwitch() {
    Row({ space: 10 }) {
      this.TabChip('急救流程', this.tabBarIndex === 0, () => { this.tabBarIndex = 0; })
      this.TabChip('转盆提醒', this.tabBarIndex === 1, () => { this.tabBarIndex = 1; })
      Blank()
    }
    .padding({ left: 16, right: 16 })
  }

  @Builder TabChip(text: string, on: boolean, action: () => void) {
    Row() {
      Text(text).fontSize(14).fontWeight(on ? FontWeight.Medium : FontWeight.Normal)
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    }
    .backgroundColor(on ? '#E0F2F1' : '#F2F3F5')
    .borderRadius(16)
    .onClick(() => { action(); })
  }

  // ===== 急救面板 =====
  @Builder EmergencyPanel() {
    Column({ space: 12 }) {
      this.SymptomSelector()
      this.StepCards()
      this.NoteAndStart()
      this.LogList()
    }
  }

  // 症状选择
  @Builder SymptomSelector() {
    Column({ space: 10 }) {
      Text('选择症状').fontSize(16).fontWeight(FontWeight.Medium)
      Row({ space: 8 }) {
        this.SymChip('日灼', 'SCORCH')
        this.SymChip('萎蔫', 'WILT')
        this.SymChip('黄化', 'YELLOW')
        this.SymChip('斑点', 'SPOT')
        this.SymChip('烂根', 'ROOTROT')
      }
      // 当前方案提示
      if (this.emgVM.currentItem() !== undefined) {
        Text(this.emgVM.currentItem()!.tip).fontSize(12).opacity(0.6)
      }
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({ radius: 6, color: '#11000000', offsetX: 0, offsetY: 1 })
    .margin({ left: 16, right: 16 })
  }

  @Builder SymChip(text: string, key: string) {
    Row() {
      // const on: boolean = (); // 仅读取，不声明新变量
      Text(text).fontSize(13).fontWeight(this.emgVM.selectedKey === key ? FontWeight.Medium : FontWeight.Normal)
        .padding({ left: 10, right: 10, top: 6, bottom: 6 })
    }
    .backgroundColor(this.emgVM.selectedKey === key ? '#E0F2F1' : '#F2F3F5')
    .borderRadius(14)
    .onClick(() => { this.emgVM.selectSymptom(key); })
  }

  // 三步卡
  @Builder StepCards() {
    Column({ space: 10 }) {
      Text('急救三步').fontSize(16).fontWeight(FontWeight.Medium)
      if (this.emgVM.currentItem()) {
        // const item: PlaybookItem = !; // 只读引用
        ForEach(this.emgVM.currentItem()?.steps, (step: PlayStep, i: number) => {
          // const idx: number = (i as number);
          this.StepRow(i, step.text)
        }, (step: PlayStep, i?: number) => step + '_' + (i as number))
        Text(`建议 ${this.emgVM.currentItem()!.reviewHours} 小时后复查`).fontSize(12).opacity(0.6)
      }
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({ radius: 6, color: '#11000000', offsetX: 0, offsetY: 1 })
    .margin({ left: 16, right: 16 })
  }

  @Builder StepRow(index: number, text: string) {
    Row({ space: 10 }) {
      // 自绘 Check 视图
      Column()
        .width(22).height(22)
        .borderRadius(11)
        .backgroundColor(this.emgVM.stepChecked[index] ? '#26A69A' : '#E0E0E0')
        .onClick(() => { this.emgVM.toggleStep(index); })
      Text(text).fontSize(14).flexGrow(1)
    }
  }

  // 备注 + 开始观察
  @Builder NoteAndStart() {
    Column({ space: 10 }) {
      Text('备注（可选）').fontSize(14).opacity(0.8)
      TextInput({ placeholder: '记录原因、环境或药剂等…', text: this.emgVM.note })
        .onChange((v: string) => { this.emgVM.note = v; })
        .height(38).backgroundColor('#FFFFFF').borderRadius(10).padding({ left: 10, right: 10 })
      Row({ space: 10 }) {
        Button('开始观察').type(ButtonType.Capsule)
          .backgroundColor('#26A69A')
          .onClick(() => {
            const log: EmergencyLog | undefined = this.emgVM.startObservation();
            if (log) {
              // animateTo({ duration: 220, curve: Curve.EaseOut }) { }
            }
          })
        Button('清空勾选').type(ButtonType.Normal)
          .onClick(() => {
            this.emgVM.ensureStepArray();
          })
      }
    }
    .padding({ left: 16, right: 16 })
  }

  // 历史记录
  @Builder LogList() {
    Column({ space: 10 }) {
      Text('急救记录').fontSize(16).fontWeight(FontWeight.Medium).margin({ left: 16, right: 16 })
      if (this.emgVM.logs.length === 0) {
        Column() { Text('暂无记录').fontSize(12).opacity(0.6) }
        .height(50).width('100%').justifyContent(FlexAlign.Center)
        .backgroundColor('#FFFFFF').borderRadius(12)
        .margin({ left: 16, right: 16, bottom: 16 })
      } else {
        List() {
          ForEach(this.emgVM.logs, (it: EmergencyLog) => {
            ListItem() {
              Column({ space: 4 }) {
                Row() {
                  Text(it.title).fontSize(14).fontWeight(FontWeight.Medium)
                  Blank()
                  Text(it.completed ? '已完成' : '观察中').fontSize(12).fontColor(it.completed ? '#26A69A' : '#FF9F43')
                }
                Text(`开始：${this.emgVM.fmtDate(it.startedAt)}`).fontSize(12).opacity(0.7)
                Text(`复查：${this.emgVM.fmtDate(it.reviewAt)}`).fontSize(12).opacity(0.7)
                if (it.note !== '') {
                  Text(it.note).fontSize(12).opacity(0.8)
                }
                Row({ space: 10 }) {
                  Button('标记完成').type(ButtonType.Normal)
                    .onClick(() => this.emgVM.markCompleted(it.id))
                }.margin({ top: 4 })
              }
              .padding(10).backgroundColor('#FFFFFF').borderRadius(12)
              .margin({ left: 16, right: 16, bottom: 8 })
            }
          }, (it: EmergencyLog) => it.id)
        }
      }
    }
  }

  // ===== 转盆面板 =====
  @Builder RotatePanel() {
    Column({ space: 12 }) {
      this.RotateSettingCard()
      this.NextDueCard()
      this.RotateHistory()
    }
  }

  // 设置卡：启用/周期/打卡
  @Builder RotateSettingCard() {
    Column({ space: 10 }) {
      Row() {
        Text('转盆计划').fontSize(16).fontWeight(FontWeight.Medium)
        Blank()
        // 简易开关（Chip 风格）
        Row() {
          Text(this.rotVM.enabled ? '已启用' : '未启用').fontSize(12)
            .padding({ left: 10, right: 10, top: 6, bottom: 6 })
        }
        .backgroundColor(this.rotVM.enabled ? '#E0F2F1' : '#F2F3F5')
        .borderRadius(14)
        .onClick(() => { this.rotVM.setEnabled(!this.rotVM.enabled); })
      }
      Column({ space: 6 }) {
        Text(`周期：每 ${this.rotVM.intervalDays} 天`).fontSize(14)
        Slider({ value: this.rotVM.intervalDays, min: 3, max: 60, step: 1 })
          .onChange((v: number) => this.rotVM.setIntervalDays(Math.floor(v)))
      }
      Row({ space: 10 }) {
        Button('转盆 90° · 打卡').type(ButtonType.Capsule)
          .backgroundColor('#26A69A')
          .onClick(() => {
            this.rotVM.markRotatedNow();
            // animateTo({ duration: 200, curve: Curve.EaseOut })
          })
        if (this.rotVM.lastRotatedAt > 0) {
          Text(`上次：${this.rotVM.fmtDate(this.rotVM.lastRotatedAt)}`).fontSize(12).opacity(0.7)
        } else {
          Text('上次：未记录').fontSize(12).opacity(0.7)
        }
      }
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({ radius: 6, color: '#11000000', offsetX: 0, offsetY: 1 })
    .margin({ left: 16, right: 16 })
  }

  // 下一次到期
  @Builder NextDueCard() {
    Column({ space: 6 }) {
      Text('下一次到期').fontSize(16).fontWeight(FontWeight.Medium)
      if (!this.rotVM.enabled) {
        Text('未启用计划').fontSize(12).opacity(0.6)
      } else {
        Text(this.rotVM.fmtDate(this.rotVM.nextDueAt())).fontSize(14)
        Text(this.rotVM.overdue() ? '已到期，请尽快转盆' : '未到期')
          .fontSize(12)
          .fontColor(this.rotVM.overdue() ? '#FF6B6B' : '#26A69A')
      }
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({ radius: 6, color: '#11000000', offsetX: 0, offsetY: 1 })
    .margin({ left: 16, right: 16 })
  }

  // 历史列表
  @Builder RotateHistory() {
    Column({ space: 10 }) {
      Text('转盆历史').fontSize(16).fontWeight(FontWeight.Medium).margin({ left: 16, right: 16 })
      if (this.rotVM.logs.length === 0) {
        Column() { Text('暂无记录').fontSize(12).opacity(0.6) }
        .height(50).width('100%').justifyContent(FlexAlign.Center)
        .backgroundColor('#FFFFFF').borderRadius(12)
        .margin({ left: 16, right: 16, bottom: 16 })
      } else {
        List() {
          ForEach(this.rotVM.logs, (x: RotateLog) => {
            ListItem() {
              Row() {
                Text(this.rotVM.fmtDate(x.ts)).fontSize(14)
                Blank()
              }
              .padding(10).backgroundColor('#FFFFFF').borderRadius(12)
              .margin({ left: 16, right: 16, bottom: 8 })
            }
          }, (x: RotateLog) => x.id)
        }
      }
    }
  }
}
