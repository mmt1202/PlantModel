// /page/LightExposurePage.ets
// 手动光照记录页面（开始/结束/补记 + 环形进度 + 7日条形图 + 会话列表）
// 使用 Navigation 友好参数（不使用 Router.*）

import { LightExposureViewModel } from '../viewmodel/LightExposureViewModel';
import LightProfile from '../model/LightProfile';
import ExposureSession from '../model/ExposureSession';
import DailyLightStat from '../model/DailyLightStat';
import {
  LightLevel, LightStatus,
  lightLevelLabel, statusLabel, statusColor
} from '../model/LightTypes';

@CustomDialog
struct ManualStartDialog {
  controller: CustomDialogController;
  onConfirm: (lvl: LightLevel) => void = (lvl: LightLevel) => {};
  @State level: LightLevel = LightLevel.MID;

  build() {
    Column({ space: 12 }) {
      Text('开始光照记录').fontSize(20).fontWeight(FontWeight.Medium)
      Row({ space: 8 }) {
        this.LevelChip('弱光', LightLevel.LOW)
        this.LevelChip('中光', LightLevel.MID)
        this.LevelChip('强光', LightLevel.HIGH)
      }
      Row({ space: 10 }) {
        Button('取消').onClick(() => { this.controller.close(); })
        Button('开始').type(ButtonType.Capsule).onClick(() => {
          this.onConfirm(this.level); this.controller.close();
        })
      }.justifyContent(FlexAlign.End).margin({ top: 6 })
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(18)
  }

  @Builder LevelChip(text: string, lvl: LightLevel) {
    // const on: boolean = this.level === lvl;
    Row() {
      Text(text).fontSize(14).fontWeight(this.level === lvl ? FontWeight.Medium : FontWeight.Normal)
        .padding({ left: 10, right: 10, top: 6, bottom: 6 })
    }
    .backgroundColor(this.level === lvl ? '#E0F2F1' : '#F2F3F5')
    .borderRadius(14)
    .onClick(() => { this.level = lvl; })
  }
}

@CustomDialog
struct ManualInstantDialog {
  controller: CustomDialogController;
  onConfirm: (lvl: LightLevel, minutes: number) => void = (lvl: LightLevel, minutes: number) => {};
  @State level: LightLevel = LightLevel.MID;
  @State minutes: number = 30;

  build() {
    Column({ space: 12 }) {
      Text('手动补记一段光照').fontSize(20).fontWeight(FontWeight.Medium)
      Row({ space: 8 }) {
        this.LevelChip('弱光', LightLevel.LOW)
        this.LevelChip('中光', LightLevel.MID)
        this.LevelChip('强光', LightLevel.HIGH)
      }
      Column({ space: 6 }) {
        Text(`时长：${this.minutes} 分钟`).fontSize(14).opacity(0.8)
        Slider({ value: this.minutes, min: 5, max: 240, step: 5 })
          .onChange((v: number) => { this.minutes = Math.floor(v); })
      }
      Row({ space: 10 }) {
        Button('取消').onClick(() => { this.controller.close(); })
        Button('保存').type(ButtonType.Capsule).onClick(() => {
          this.onConfirm(this.level, this.minutes); this.controller.close();
        })
      }.justifyContent(FlexAlign.End).margin({ top: 6 })
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(18)
  }

  @Builder LevelChip(text: string, lvl: LightLevel) {
    // const on: boolean = this.level === lvl;
    Row() {
      Text(text).fontSize(14).fontWeight(this.level === lvl ? FontWeight.Medium : FontWeight.Normal)
        .padding({ left: 10, right: 10, top: 6, bottom: 6 })
    }
    .backgroundColor(this.level === lvl ? '#E0F2F1' : '#F2F3F5')
    .borderRadius(14)
    .onClick(() => { this.level = lvl; })
  }
}

@Component
export struct LightExposurePage {
  // 通过 Navigation 传参：plantId（你在上层 NavDestination 注入即可）
  @Prop plantId: string = '';
  @State vm: LightExposureViewModel = new LightExposureViewModel('');

  private startDlg: CustomDialogController = new CustomDialogController({
    builder: ManualStartDialog({ onConfirm: (lvl: LightLevel) => {
      this.vm.startManual(lvl);
      // animateTo({ duration: 220, curve: Curve.EaseOut }) { /* 微动效 */ }
    } })
  });

  private instantDlg: CustomDialogController = new CustomDialogController({
    builder: ManualInstantDialog({ onConfirm: (lvl: LightLevel, minutes: number) => {
      this.vm.addManualInstant(lvl, minutes);
      // animateTo({ duration: 240, curve: Curve.EaseOut }) { /* 轻微动效 */ }
    } })
  });

  aboutToAppear() {
    // 初始化 VM
    if (this.plantId !== '') {
      this.vm = new LightExposureViewModel(this.plantId);
    } else {
      // 没有传参时给一个占位 ID，方便页面自测
      this.vm = new LightExposureViewModel('PLANT_DEMO');
    }
  }

  build() {
    Scroll() {
      Column({ space: 14 }) {
        // 顶部：标题 + 操作
        Row() {
          Column() {
            Text('光照记录').fontSize(22).fontWeight(FontWeight.Medium)
            Text(`植物ID：${this.vm.plantId}`).fontSize(12).opacity(0.6)
          }
          Blank()
          this.ActionButtons()
        }.padding({ left: 16, right: 16, top: 12 })

        // 环形进度 + 状态徽标
        this.RingAndStatus()

        // 目标配置（可选编辑）
        this.ProfileCard()

        // 近 7 天条形图
        this.SevenDaysChart()

        // 今日会话列表
        this.TodaySessions()
      }
    }
    .backgroundColor('#FAFAFA')
    .edgeEffect(EdgeEffect.Spring)
  }

  @Builder ActionButtons() {
    Row({ space: 10 }) {
      if (!this.vm.hasActive) {
        Button('开始光照').type(ButtonType.Capsule).onClick(() => {
          this.startDlg.open();
        })
      } else {
        Button('结束光照').type(ButtonType.Capsule).backgroundColor('#26A69A').onClick(() => {
          this.vm.endManualWithAutoDuration();
          // animateTo({ duration: 240, curve: Curve.EaseOut }) { /* ring 刷新 */ }
        })
      }
      Button('手动补记').type(ButtonType.Normal).onClick(() => {
        this.instantDlg.open();
      })
    }
  }

  @Builder RingAndStatus() {
    Column() {
      Column() {
        Progress({ value: this.vm.todayRatePercent, total: 100, type: ProgressType.Ring })
          .style({ enableSmoothEffect: true })
          .width(150).height(150)
          .color(statusColor(this.vm.todayStatus))
        Text(`${this.vm.todayRatePercent}% 达标`).fontSize(16).margin({ top: 8 })
        Text(statusLabel(this.vm.todayStatus)).fontSize(14).fontColor(statusColor(this.vm.todayStatus)).margin({ top: 2 })
      }
      .padding(16)
      .backgroundColor('#FFFFFF')
      .borderRadius(20)
      .shadow({ radius: 8, color: '#11000000', offsetX: 0, offsetY: 2 })
    }
    .padding({ left: 16, right: 16 })
  }

  @Builder ProfileCard() {
    Column({ space: 8 }) {
      Text('目标区间（lux-min）').fontSize(14).opacity(0.8)
      Row({ space: 10 }) {
        this.ValueBox('下限', this.vm.profile.targetLuxMinLow)
        this.ValueBox('上限', this.vm.profile.targetLuxMinHigh)
      }
      Row({ space: 10 }) {
        Text('偏好：').fontSize(14).opacity(0.8)
        this.LevelTag('弱光', LightLevel.LOW, this.vm.profile.preferredLevel === LightLevel.LOW)
        this.LevelTag('中光', LightLevel.MID, this.vm.profile.preferredLevel === LightLevel.MID)
        this.LevelTag('强光', LightLevel.HIGH, this.vm.profile.preferredLevel === LightLevel.HIGH)
        Blank()
        Button('微调目标').type(ButtonType.Normal).onClick(() => {
          // 简易微调：上下限按偏好做一个轻微偏移
          let low: number = this.vm.profile.targetLuxMinLow;
          let high: number = this.vm.profile.targetLuxMinHigh;
          if (this.vm.profile.preferredLevel === LightLevel.LOW) {
            low = 9000; high = 15000;
          } else if (this.vm.profile.preferredLevel === LightLevel.MID) {
            low = 12000; high = 20000;
          } else {
            low = 16000; high = 26000;
          }
          this.vm.updateProfile(low, high, this.vm.profile.preferredLevel);
        })
      }
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({ radius: 6, color: '#11000000', offsetX: 0, offsetY: 1 })
    .margin({ left: 16, right: 16 })
  }

  @Builder ValueBox(label: string, value: number) {
    Column() {
      Text(label).fontSize(12).opacity(0.6)
      Text(`${value}`).fontSize(16).fontWeight(FontWeight.Medium)
        .padding({ top: 4, bottom: 4 })
    }
    .backgroundColor('#F4F6F8')
    .borderRadius(12)
    .padding({ left: 10, right: 10 })
  }

  @Builder LevelTag(text: string, lvl: LightLevel, on: boolean) {
    Row() {
      Text(text).fontSize(12).fontWeight(on ? FontWeight.Medium : FontWeight.Normal)
        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
    }
    .backgroundColor(on ? '#E0F2F1' : '#F2F3F5')
    .borderRadius(12)
    .onClick(() => {
      this.vm.updateProfile(this.vm.profile.targetLuxMinLow, this.vm.profile.targetLuxMinHigh, lvl);
    })
  }

  maxLux(){
    const data: DailyLightStat[] = this.vm.sevenDays;
    // 计算最大 luxMin，用于归一化
    let maxLux: number = 1;
    for (let i: number = 0; i < data.length; i++) {
      if (data[i].luxMinutes > maxLux) {
        maxLux = data[i].luxMinutes;
      }
    }
    return maxLux
  }

  @Builder SevenDaysChart() {
    Column({ space: 10 }) {
      Text('近 7 天光照趋势').fontSize(16).fontWeight(FontWeight.Medium)
      Row({ space: 10 }) {
        ForEach(this.vm.sevenDays, (d: DailyLightStat) => {
          // const h: number = Math.floor(100 * (d.luxMinutes / maxLux));
          // const col: string = statusColor(d.status);
          Column() {
            // 柱
            Column().width(16).height(Math.floor(100 * (d.luxMinutes / this.maxLux())) + 10)
              .backgroundColor(statusColor(d.status)).borderRadius(8)
              .align(Alignment.Bottom)
              .opacity(0.9)
            // 日期简记
            Text(d.date.substring(5)).fontSize(10).opacity(0.6).margin({ top: 6 })
          }
          .width(24)
          .alignItems(HorizontalAlign.Center)
        }, (d: DailyLightStat) => d.id)
      }
      .height(140)
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
      .padding(12)
      .shadow({ radius: 6, color: '#11000000', offsetX: 0, offsetY: 1 })
    }
    .padding({ left: 16, right: 16 })
  }

  exposureSessionList(){
    const today: string = this.todayKey();
    const list: ExposureSession[] = this.vm.sessions.filter((s: ExposureSession) => {
      const d: Date = new Date(s.endAt);
      const y: number = d.getFullYear();
      const m: number = d.getMonth() + 1;
      const dd: number = d.getDate();
      const mmStr: string = m < 10 ? '0' + m : '' + m;
      const ddStr: string = dd < 10 ? '0' + dd : '' + dd;
      const key: string = `${y}-${mmStr}-${ddStr}`;
      return key === today;
    });
    return list;
  }

  @Builder TodaySessions() {
    Column({ space: 8 }) {
      Row() {
        Text('今日记录').fontSize(16).fontWeight(FontWeight.Medium)
        Blank()
        if (this.vm.hasActive) {
          Text('进行中…').fontSize(12).fontColor('#26A69A')
        }
      }
      .padding({ left: 2, right: 2 })

      if (this.exposureSessionList().length === 0 && !this.vm.hasActive) {
        Column() {
          Text('今天还没有光照记录').fontSize(13).opacity(0.6)
          Text('点击“开始光照”或“手动补记”试试').fontSize(12).opacity(0.5).margin({ top: 4 })
        }
        .height(80)
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
      } else {
        List() {
          ForEach(this.exposureSessionList(), (s: ExposureSession) => {
            ListItem() {
              Row() {
                Column() {
                  Text(`${this.hm(new Date(s.startAt))} - ${this.hm(new Date(s.endAt))}  ·  ${s.durationMin} 分钟`).fontSize(14)
                  Text(`${lightLevelLabel(s.level)} · ${s.luxMinutes} lux-min`).fontSize(12).opacity(0.6)
                }
                Blank()
              }
              .padding(12)
              .backgroundColor('#FFFFFF')
              .borderRadius(12)
            }
          }, (s: ExposureSession) => s.id)
        }
      }
    }
    .padding({ left: 16, right: 16, bottom: 20, top: 6 })
  }

  // 工具
  private todayKey(): string {
    const now: Date = new Date();
    const y: number = now.getFullYear();
    const m: number = now.getMonth() + 1;
    const d: number = now.getDate();
    const mmStr: string = m < 10 ? '0' + m : '' + m;
    const ddStr: string = d < 10 ? '0' + d : '' + d;
    return `${y}-${mmStr}-${ddStr}`;
  }

  private hm(d: Date): string {
    const h: number = d.getHours();
    const m: number = d.getMinutes();
    const hStr: string = h < 10 ? '0' + h : '' + h;
    const mStr: string = m < 10 ? '0' + m : '' + m;
    return `${hStr}:${mStr}`;
  }
}
