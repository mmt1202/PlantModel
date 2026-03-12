// /page/LightExposurePage.ets
// 手动光照记录页面（开始/结束/补记 + 环形进度 + 7日条形图 + 会话列表）
// 使用 Navigation 友好参数（不使用 Router.*）

import { LightExposureViewModel } from '../viewmodel/LightExposureViewModel';
import ExposureSession from '../model/ExposureSession';
import DailyLightStat from '../model/DailyLightStat';
import { LightLevel, lightLevelLabel, statusColor, statusLabel } from '../model/LightTypes';
import { Plant } from '../model/PlantModel';

@CustomDialog
struct ManualStartDialog {
  controller: CustomDialogController;
  onConfirm: (lvl: LightLevel) => void = (lvl: LightLevel) => {
  };
  @State level: LightLevel = LightLevel.MID;

  build() {
    Column({ space: 16 }) {
      Text('开始光照记录')
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .fontColor(0xFF263238)

      Text('请选择光照强度')
        .fontSize(14)
        .fontColor(0xFF78909C)

      Row({ space: 12 }) {
        this.LevelChip('🌤️', '弱光', LightLevel.LOW)
        this.LevelChip('⛅', '中光', LightLevel.MID)
        this.LevelChip('☀️', '强光', LightLevel.HIGH)
      }

      Row({ space: 12 }) {
        Button('取消')
          .type(ButtonType.Normal)
          .fontSize(16)
          .backgroundColor(0xFFF4F6F8)
          .fontColor(0xFF607D8B)
          .height(48)
          .onClick(() => {
            this.controller.close();
          })
        Button('开始记录')
          .type(ButtonType.Capsule)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .backgroundColor(0xFF4CAF50)
          .height(48)
          .onClick(() => {
            this.onConfirm(this.level);
            this.controller.close();
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.End)
    }
    .padding(24)
    .backgroundColor('#FFFFFF')
    .borderRadius(24)
  }

  @Builder
  LevelChip(icon: string, text: string, lvl: LightLevel) {
    Column({ space: 8 }) {
      Text(icon).fontSize(28)
      Text(text).fontSize(14).fontWeight(this.level === lvl ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(this.level === lvl ? 0xFF2E7D32 : 0xFF607D8B)
    }
    .width('30%')
    .padding(16)
    .backgroundColor(this.level === lvl ? 0xFFE8F5E9 : 0xFFF4F6F8)
    .borderRadius(16)
    .onClick(() => {
      this.level = lvl;
    })
  }
}

@CustomDialog
struct ManualInstantDialog {
  controller: CustomDialogController;
  onConfirm: (lvl: LightLevel, minutes: number) => void = (lvl: LightLevel, minutes: number) => {
  };
  @State level: LightLevel = LightLevel.MID;
  @State minutes: number = 30;

  build() {
    Column({ space: 16 }) {
      Text('手动补记光照')
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .fontColor(0xFF263238)

      Text('请选择光照强度和时长')
        .fontSize(14)
        .fontColor(0xFF78909C)

      Row({ space: 12 }) {
        this.LevelChip('🌤️', '弱光', LightLevel.LOW)
        this.LevelChip('⛅', '中光', LightLevel.MID)
        this.LevelChip('☀️', '强光', LightLevel.HIGH)
      }

      Column({ space: 12 }) {
        Row() {
          Text('时长设置')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(0xFF263238)
          Blank()
          Text(`${this.minutes} 分钟`)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(0xFF4CAF50)
        }

        Slider({
          value: this.minutes,
          min: 5,
          max: 240,
          step: 5
        })
          .blockColor(0xFF4CAF50)
          .trackColor(0xFFE8F5E9)
          .selectedColor(0xFF4CAF50)
          .onChange((v: number) => {
            this.minutes = Math.floor(v);
          })

        Row({ space: 8 }) {
          this.QuickMinuteChip(15)
          this.QuickMinuteChip(30)
          this.QuickMinuteChip(60)
          this.QuickMinuteChip(120)
        }
      }
      .padding(16)
      .backgroundColor(0xFFF8FAF9)
      .borderRadius(16)

      Row({ space: 12 }) {
        Button('取消')
          .type(ButtonType.Normal)
          .fontSize(16)
          .backgroundColor(0xFFF4F6F8)
          .fontColor(0xFF607D8B)
          .height(48)
          .onClick(() => {
            this.controller.close();
          })
        Button('保存记录')
          .type(ButtonType.Capsule)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .backgroundColor(0xFF4CAF50)
          .height(48)
          .onClick(() => {
            this.onConfirm(this.level, this.minutes);
            this.controller.close();
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.End)
    }
    .padding(24)
    .backgroundColor('#FFFFFF')
    .borderRadius(24)
  }

  @Builder
  QuickMinuteChip(min: number) {
    Text(`${min}分钟`)
      .fontSize(14)
      .fontWeight(this.minutes === min ? FontWeight.Medium : FontWeight.Normal)
      .padding({
        left: 12,
        right: 12,
        top: 8,
        bottom: 8
      })
      .backgroundColor(this.minutes === min ? 0xFFE8F5E9 : 0xFFFFFFFF)
      .fontColor(this.minutes === min ? 0xFF2E7D32 : 0xFF607D8B)
      .borderRadius(12)
      .onClick(() => {
        this.minutes = min;
      })
  }

  @Builder
  LevelChip(icon: string, text: string, lvl: LightLevel) {
    Column({ space: 8 }) {
      Text(icon).fontSize(28)
        .fontColor(this.level === lvl ? 0xFF2E7D32 : 0xFF607D8B)
      Text(text).fontSize(14).fontWeight(this.level === lvl ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(this.level === lvl ? 0xFF2E7D32 : 0xFF607D8B)
    }
    .width('30%')
    .padding(16)
    .backgroundColor(this.level === lvl ? 0xFFE8F5E9 : 0xFFF4F6F8)
    .borderRadius(16)
    .onClick(() => {
      this.level = lvl;
    })
  }
}

@ComponentV2
export struct LightExposurePage {
  @Param plant: Plant | undefined = undefined;
  @Local vm: LightExposureViewModel = new LightExposureViewModel(0);
  private startDlg: CustomDialogController = new CustomDialogController({
    builder: ManualStartDialog({
      onConfirm: (lvl: LightLevel) => {
        this.vm.startManual(lvl);
      }
    })
  });
  private instantDlg: CustomDialogController = new CustomDialogController({
    builder: ManualInstantDialog({
      onConfirm: (lvl: LightLevel, minutes: number) => {
        this.vm.addManualInstant(lvl, minutes);
      }
    })
  });

  aboutToAppear() {
    if (this.plant) {
      this.vm = new LightExposureViewModel(this.plant.id);
    }
  }

  build() {
    NavDestination() {
      Column() {
        this.Header()
        Scroll() {
          Column({ space: 20 }) {
            this.RingAndStatus()
            this.ProfileCard()
            this.SevenDaysChart()
            this.TodaySessions()
          }
          .padding({
            left: 16,
            right: 16,
            top: 8,
            bottom: 32
          })
        }
        .layoutWeight(1)
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .title('光照记录')
    .padding({
      top: AppStorage.get<number>('topRectHeight'),
      bottom: AppStorage.get<number>('bottomRectHeight')
    })
    .linearGradient({
      direction: GradientDirection.Top,
      colors: [[0xFFF1F8E9, 0], [0xFFE8F5E9, 0.5], [0xFFE3F2FD, 1.0]]
    })
    .onReady((param) => {
      const plant = param.pathInfo.param as Plant
      if (this.plant !== undefined) {
        this.plant.id = plant.id
        this.plant.name = plant.name
        this.plant.species = plant.species
        this.plant.location = plant.location
        this.plant.createdAt = plant.createdAt
        this.vm = new LightExposureViewModel(this.plant.id);
      }
    })
  }

  @Builder
  Header() {
    Row() {
      Column() {
        Text('光照记录').fontSize(22).fontWeight(FontWeight.Medium).fontColor(0xFF263238)
        if (this.plant) {
          Text(this.plant.name).fontSize(14).fontColor(0xFF78909C)
        }
      }

      Blank()
      this.ActionButtons()
    }
    .padding({
      left: 16,
      right: 16,
      top: 12,
      bottom: 8
    })
  }

  @Builder
  ActionButtons() {
    Row({ space: 10 }) {
      if (!this.vm.hasActive) {
        Button('开始光照')
          .type(ButtonType.Capsule)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .backgroundColor(0xFF4CAF50)
          .height(40)
          .onClick(() => {
            this.startDlg.open();
          })
      } else {
        Button('结束光照')
          .type(ButtonType.Capsule)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .backgroundColor(0xFF26A69A)
          .height(40)
          .onClick(() => {
            this.vm.endManualWithAutoDuration();
          })
      }
      Button('手动补记')
        .type(ButtonType.Normal)
        .fontSize(14)
        .fontColor(0xFF4CAF50)
        .backgroundColor(0xFFE8F5E9)
        .height(40)
        .onClick(() => {
          this.instantDlg.open();
        })
    }
  }

  @Builder
  RingAndStatus() {
    Column() {
      Column({ space: 16 }) {
        Row() {
          Text('今日进度')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor(0xFF263238)
          Blank()
          if (this.vm.hasActive) {
            Row({ space: 4 }) {
              Text('●')
                .fontSize(10)
                .fontColor(0xFF4CAF50)
              Text('进行中…')
                .fontSize(14)
                .fontColor(0xFF4CAF50)
                .fontWeight(FontWeight.Medium)
            }
          }
        }

        Row() {
          Column() {
            Progress({ value: this.vm.todayRatePercent, total: 100, type: ProgressType.Ring })
              .style({ enableSmoothEffect: true })
              .width(120)
              .height(120)
              .color(statusColor(this.vm.todayStatus))
            Text(`${this.vm.todayRatePercent}%`)
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor(0xFF263238)
              .margin({ top: 12 })
            Text('达标')
              .fontSize(14)
              .fontColor(0xFF78909C)
          }
          .layoutWeight(1)

          Column({ space: 12 }) {
            this.StatItem('状态', statusLabel(this.vm.todayStatus), statusColor(this.vm.todayStatus))
            this.StatItem('目标', `${this.vm.profile.targetLuxMinLow}-${this.vm.profile.targetLuxMinHigh} lux-min`,
              0xFF4CAF50)
          }
          .layoutWeight(1)
        }
      }
      .padding(20)
      .backgroundColor('#FFFFFF')
      .borderRadius(24)
      .shadow({
        radius: 16,
        color: '#15000000',
        offsetX: 0,
        offsetY: 4
      })
    }
    .padding({ left: 16, right: 16 })
  }

  @Builder
  StatItem(label: string, value: string, color: ResourceColor) {
    Column({ space: 4 }) {
      Text(label)
        .fontSize(14)
        .fontColor(0xFF90A4AE)
      Text(value)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(color)
    }
    .width('100%')
    .padding(12)
    .backgroundColor(0xFFF8FAF9)
    .borderRadius(12)
  }

  @Builder
  ProfileCard() {
    Column({ space: 16 }) {
      Row() {
        Text('光照偏好')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(0xFF263238)
        Blank()
      }

      Row({ space: 12 }) {
        this.LevelTag('🌤️', '弱光', LightLevel.LOW, this.vm.profile.preferredLevel === LightLevel.LOW)
        this.LevelTag('⛅', '中光', LightLevel.MID, this.vm.profile.preferredLevel === LightLevel.MID)
        this.LevelTag('☀️', '强光', LightLevel.HIGH, this.vm.profile.preferredLevel === LightLevel.HIGH)
      }

      Row({ space: 12 }) {
        this.ValueBox('目标下限', this.vm.profile.targetLuxMinLow)
        this.ValueBox('目标上限', this.vm.profile.targetLuxMinHigh)
      }

      Button('快速调整')
        .type(ButtonType.Normal)
        .fontSize(14)
        .fontColor(0xFF4CAF50)
        .backgroundColor(0xFFE8F5E9)
        .height(44)
        .onClick(() => {
          let low: number = this.vm.profile.targetLuxMinLow;
          let high: number = this.vm.profile.targetLuxMinHigh;
          if (this.vm.profile.preferredLevel === LightLevel.LOW) {
            low = 9000;
            high = 15000;
          } else if (this.vm.profile.preferredLevel === LightLevel.MID) {
            low = 12000;
            high = 20000;
          } else {
            low = 16000;
            high = 26000;
          }
          this.vm.updateProfile(low, high, this.vm.profile.preferredLevel);
        })
    }
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(24)
    .shadow({
      radius: 12,
      color: '#11000000',
      offsetX: 0,
      offsetY: 2
    })
    .margin({ left: 16, right: 16 })
  }

  @Builder
  ValueBox(label: string, value: number) {
    Column({ space: 4 }) {
      Text(label)
        .fontSize(12)
        .fontColor(0xFF90A4AE)
      Text(`${value}`)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(0xFF263238)
    }
    .layoutWeight(1)
    .padding(16)
    .backgroundColor(0xFFF8FAF9)
    .borderRadius(16)
  }

  @Builder
  LevelTag(icon: string, text: string, lvl: LightLevel, on: boolean) {
    Column({ space: 6 }) {
      Text(icon).fontSize(24).fontColor(on ? 0xFF2E7D32 : 0xFF607D8B)
      Text(text).fontSize(12).fontWeight(on ? FontWeight.Medium : FontWeight.Normal).fontColor(on ? 0xFF2E7D32 : 0xFF607D8B)
    }
    .layoutWeight(1)
    .padding(12)
    .backgroundColor(on ? 0xFFE8F5E9 : 0xFFF4F6F8)
    .borderRadius(16)

    .onClick(() => {
      this.vm.updateProfile(this.vm.profile.targetLuxMinLow, this.vm.profile.targetLuxMinHigh, lvl);
    })
  }

  maxLux() {
    const data: DailyLightStat[] = this.vm.sevenDays;
    let maxLux: number = 1;
    for (let i: number = 0; i < data.length; i++) {
      if (data[i].luxMinutes > maxLux) {
        maxLux = data[i].luxMinutes;
      }
    }
    return maxLux
  }

  @Builder
  SevenDaysChart() {
    Column({ space: 16 }) {
      Row() {
        Text('近 7 天')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(0xFF263238)
        Blank()
      }

      Column({ space: 12 }) {
        Row({ space: 10 }) {
          ForEach(this.vm.sevenDays, (d: DailyLightStat) => {
            Column({ space: 8 }) {
              Column()
                .width(24)
                .height(Math.floor(100 * (d.luxMinutes / this.maxLux())) + 20)
                .backgroundColor(statusColor(d.status))
                .borderRadius(12)
                .align(Alignment.Bottom)
                .opacity(0.9)
              Text(d.date.substring(5))
                .fontSize(11)
                .fontColor(0xFF90A4AE)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Center)
          }, (d: DailyLightStat) => d.id)
        }
        .height(160)
      }
      .padding(20)
      .backgroundColor('#FFFFFF')
      .borderRadius(24)
      .shadow({
        radius: 12,
        color: '#11000000',
        offsetX: 0,
        offsetY: 2
      })
    }
    .padding({ left: 16, right: 16 })
  }

  exposureSessionList() {
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

  @Builder
  TodaySessions() {
    Column({ space: 12 }) {
      Row() {
        Text('今日记录')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(0xFF263238)
        Blank()
        Text(`${this.exposureSessionList().length} 条`)
          .fontSize(14)
          .fontColor(0xFF90A4AE)
      }

      if (this.exposureSessionList().length === 0 && !this.vm.hasActive) {
        Column() {
          Text('📝')
            .fontSize(48)
            .opacity(0.3)
          Text('今天还没有光照记录')
            .fontSize(16)
            .fontColor(0xFF90A4AE)
            .margin({ top: 12 })
          Text('点击"开始光照"或"手动补记"开始记录')
            .fontSize(14)
            .fontColor(0xFFB0BEC5)
            .margin({ top: 4 })
        }
        .height(200)
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#FFFFFF')
        .borderRadius(24)
      } else {
        List({ space: 12 }) {
          ForEach(this.exposureSessionList(), (s: ExposureSession) => {
            ListItem() {
              Row({ space: 12 }) {
                Column({ space: 4 }) {
                  Text(`${this.hm(new Date(s.startAt))} - ${this.hm(new Date(s.endAt))}`)
                    .fontSize(15)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(0xFF263238)
                  Text(`${lightLevelLabel(s.level)} · ${s.luxMinutes} lux-min`)
                    .fontSize(13)
                    .fontColor(0xFF78909C)
                }

                Blank()

                Column({ space: 4 }) {
                  Text(`${s.durationMin} 分钟`)
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(0xFF4CAF50)
                }
              }
              .padding(16)
              .backgroundColor('#FFFFFF')
              .borderRadius(20)
              .shadow({
                radius: 8,
                color: '#10000000',
                offsetX: 0,
                offsetY: 2
              })
            }
          }, (s: ExposureSession) => s.id)
        }
        .height(400)
      }
    }
    .padding({
      left: 16,
      right: 16,
      bottom: 20,
      top: 4
    })
  }

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
