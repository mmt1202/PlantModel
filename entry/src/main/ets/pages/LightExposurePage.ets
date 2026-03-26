// /page/LightExposurePage.ets
// 手动光照记录页面（开始/结束/补记 + 环形进度 + 7日条形图 + 会话列表）
// 使用 Navigation 友好参数（不使用 Router.*）

import { LightExposureViewModel } from '../viewmodel/LightExposureViewModel';
import ExposureSession from '../model/ExposureSession';
import DailyLightStat from '../model/DailyLightStat';
import { LightLevel, lightLevelLabel, statusColor, statusLabel } from '../model/LightTypes';
import { Plant } from '../model/PlantModel';
import { prompt } from '@kit.ArkUI';

@CustomDialog
struct ManualStartDialog {
  controller: CustomDialogController;
  onConfirm: (lvl: LightLevel) => void = (lvl: LightLevel) => {
  };
  @State level: LightLevel = LightLevel.MID;

  build() {
    Column({ space: 16 }) {
      Text("开始光照记录")
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .fontColor(0xff263238)
      Text("请选择光照强度")
        .fontSize(14)
        .fontColor(0xff78909c)
      Row({ space: 12 }) {
        this.LevelChip("🌤️", "弱光", LightLevel.LOW)
        this.LevelChip("⛅", "中光", LightLevel.MID)
        this.LevelChip("☀️", "强光", LightLevel.HIGH)
      }

      Row({ space: 12 }) {
        Button("取消")
          .type(ButtonType.Normal)
          .fontSize(16)
          .backgroundColor(0xfff4f6f8)
          .fontColor(0xff607d8b)
          .height(48)
          .onClick(() => {
            this.controller.close();
          })
        Button("开始记录")
          .type(ButtonType.Capsule)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .backgroundColor(0xff4caf50)
          .height(48)
          .onClick(() => {
            this.onConfirm(this.level);
            this.controller.close();
          })
      }
      .width("100%")
      .justifyContent(FlexAlign.End)
    }
    .padding(24)
    .backgroundColor("#FFFFFF")
    .borderRadius(24);
  }

  @Builder
  LevelChip(icon: string, text: string, lvl: LightLevel) {
    Column({ space: 8 }) {
      Text(icon).fontSize(28)
      Text(text)
        .fontSize(14)
        .fontWeight(this.level === lvl ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(this.level === lvl ? 0xff2e7d32 : 0xff607d8b)
    }
    .width("30%")
    .padding(16)
    .backgroundColor(this.level === lvl ? 0xffe8f5e9 : 0xfff4f6f8)
    .borderRadius(16)
    .onClick(() => {
      this.level = lvl;
    });
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
      Text("手动补记光照")
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .fontColor(0xff263238)
      Text("请选择光照强度和时长")
        .fontSize(14)
        .fontColor(0xff78909c)
      Row({ space: 12 }) {
        this.LevelChip("🌤️", "弱光", LightLevel.LOW)
        this.LevelChip("⛅", "中光", LightLevel.MID)
        this.LevelChip("☀️", "强光", LightLevel.HIGH)
      }

      Column({ space: 12 }) {
        Row() {
          Text("时长设置")
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(0xff263238)
          Blank()
          Text(`${this.minutes} 分钟`)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(0xff4caf50)
        }

        Slider({
          value: this.minutes,
          min: 5,
          max: 240,
          step: 5,
        })
          .blockColor(0xff4caf50)
          .trackColor(0xffe8f5e9)
          .selectedColor(0xff4caf50)
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
      .backgroundColor(0xfff8faf9)
      .borderRadius(16)

      Row({ space: 12 }) {
        Button("取消")
          .type(ButtonType.Normal)
          .fontSize(16)
          .backgroundColor(0xfff4f6f8)
          .fontColor(0xff607d8b)
          .height(48)
          .onClick(() => {
            this.controller.close();
          })
        Button("保存记录")
          .type(ButtonType.Capsule)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .backgroundColor(0xff4caf50)
          .height(48)
          .onClick(() => {
            this.onConfirm(this.level, this.minutes);
            this.controller.close();
          })
      }
      .width("100%")
      .justifyContent(FlexAlign.End)
    }
    .padding(24)
    .backgroundColor("#FFFFFF")
    .borderRadius(24);
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
        bottom: 8,
      })
      .backgroundColor(this.minutes === min ? 0xffe8f5e9 : 0xffffffff)
      .fontColor(this.minutes === min ? 0xff2e7d32 : 0xff607d8b)
      .borderRadius(12)
      .onClick(() => {
        this.minutes = min;
      });
  }

  @Builder
  LevelChip(icon: string, text: string, lvl: LightLevel) {
    Column({ space: 8 }) {
      Text(icon)
        .fontSize(28)
        .fontColor(this.level === lvl ? 0xff2e7d32 : 0xff607d8b)
      Text(text)
        .fontSize(14)
        .fontWeight(this.level === lvl ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(this.level === lvl ? 0xff2e7d32 : 0xff607d8b)
    }
    .width("30%")
    .padding(16)
    .backgroundColor(this.level === lvl ? 0xffe8f5e9 : 0xfff4f6f8)
    .borderRadius(16)
    .onClick(() => {
      this.level = lvl;
    });
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
      },
    }),
  });
  private instantDlg: CustomDialogController = new CustomDialogController({
    builder: ManualInstantDialog({
      onConfirm: (lvl: LightLevel, minutes: number) => {
        this.vm.addManualInstant(lvl, minutes);
      },
    }),
  });

  aboutToAppear() {
    if (this.plant) {
      this.vm = new LightExposureViewModel(this.plant.id);
      this.vm.init();
    }

    // 这里通过 tick 驱动 UI 周期刷新，让进行中的补光进度和达标率实时变化。
    // 添加定时器，每10秒更新一次UI，确保圆环图动态更新
    setInterval(() => {
      // 触发UI更新
      this.vm.refreshProgress();
    }, 1000); // 改为1秒以获得平滑更新
  }

  build() {
    NavDestination() {
      // 光照页本质是“实时会话 + 历史记录 + 偏好配置”三块信息的组合视图。
      Column() {
        Scroll() {
          Column({ space: 20 }) {
            this.RingAndStatus()
            this.ProfileCard()
            // this.SevenDaysChart()

            Column({ space: 12 }) {
              Row({ space: 4 }) {
                Text("历史光照记录")
                  .fontSize(18)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(0xff263238)
                Blank()
                Text(`${this.exposureSessionList().length} 条`)
                  .fontSize(14)
                  .fontColor(0xff90a4ae)
              }

              if (this.exposureSessionList().length === 0 && !this.vm.hasActive) {
                Column() {
                  Text("📝")
                    .fontSize(48)
                    .opacity(0.3)
                  Text("暂无光照历史记录")
                    .fontSize(16)
                    .fontColor(0xff90a4ae)
                    .margin({ top: 12 })
                  Text('点击"开始光照"或"手动补记"开始记录')
                    .fontSize(14)
                    .fontColor(0xffb0bec5)
                    .margin({ top: 4 })
                }
                .height(200)
                .width("100%")
                .justifyContent(FlexAlign.Center)
                .backgroundColor("#FFFFFF")
                .borderRadius(24);
              } else {
                List({ space: 12 }) {
                  ForEach(
                    this.exposureSessionList(),
                    (s: ExposureSession) => {
                      ListItem() {
                        Row({ space: 12 }) {
                          Column({ space: 4 }) {
                            if (s.endAt > 0) {
                              Text(`${this.hm(new Date(s.startAt))} - ${this.hm(new Date(s.endAt))}`)
                                .fontSize(15)
                                .fontWeight(FontWeight.Medium)
                                .fontColor(0xff263238)
                            } else {
                              Text(`${this.hm(new Date(s.startAt))} - 进行中`)
                                .fontSize(15)
                                .fontWeight(FontWeight.Medium)
                                .fontColor(0xff4caf50)
                            }
                            Text(`${lightLevelLabel(s.level)} · ${s.luxMinutes} lux-min`)
                              .fontSize(13)
                              .fontColor(0xff78909c)
                          }

                          Blank()
                          Column({ space: 4 }) {
                            if (s.endAt > 0) {
                              Text(`${s.durationMin} 分钟`)
                                .fontSize(16)
                                .fontWeight(FontWeight.Bold)
                                .fontColor(0xff4caf50)
                            }
                          }

                          // 替换原有 Button 为 swipeAction
                          // Button("删除") ... 移除
                        }
                        .width('100%')
                        .padding(16)
                        .backgroundColor("#FFFFFF")
                        .borderRadius(20)
                        .shadow({
                          radius: 8,
                          color: "#10000000",
                          offsetX: 0,
                          offsetY: 2,
                        })
                      }
                      .swipeAction({ end: this.DeleteAction(s.id) })
                    },
                    (s: ExposureSession) => s.id,
                  )
                }.height(400).width('100%').scrollBar(BarState.Off);
              }
            }
            .padding({
              left: 16,
              right: 16,
              bottom: 20,
              top: 4,
            });

          }
          .padding({
            left: 12,
            right: 12,
            top: 8,
            bottom: 32,
          })
        }
        .scrollBar(BarState.Off)
        .layoutWeight(1)
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .title("光照记录")
    .padding({
      top: AppStorage.get<number>("topRectHeight"),
      // bottom: AppStorage.get<number>("bottomRectHeight"),
    })
    .linearGradient({
      direction: GradientDirection.Top,
      colors: [
        [0xfff1f8e9, 0],
        [0xffe8f5e9, 0.5],
        [0xffe3f2fd, 1.0],
      ],
    })
    .onReady((param) => {
      const plant = param.pathInfo.param as Plant;
      if (this.plant !== undefined) {
        this.plant.id = plant.id;
        this.plant.name = plant.name;
        this.plant.species = plant.species;
        this.plant.location = plant.location;
        this.plant.createdAt = plant.createdAt;
        this.vm = new LightExposureViewModel(this.plant.id);
        this.vm.init();
      }
    });
  }

  @Builder
  Header() {
    Row() {
      Column() {
        Text("光照记录")
          .fontSize(22)
          .fontWeight(FontWeight.Medium)
          .fontColor(0xff263238)
        if (this.plant) {
          Text(this.plant.name).fontSize(14).fontColor(0xff78909c);
        }
      }

      Blank()

    }
    .padding({
      left: 16,
      right: 16,
      top: 12,
      bottom: 8,
    });
  }

  @Builder
  ActionButtons() {
    Row({ space: 10 }) {
      Button("手动补记")
        .type(ButtonType.Normal)
        .fontSize(14)
        .fontColor(0xff4caf50)
        .backgroundColor(0xffe8f5e9)
        .height(40)
        .onClick(() => {
          this.instantDlg.open();
        })
    };
  }

  @Builder
  RingAndStatus() {
    // 顶部卡片聚合了今日达标率、当前会话状态和主操作按钮，是页面的核心反馈区。
    Column() {
      Column({ space: 16 }) {
        Row() {
          Text("光照进度")
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor(0xff263238)
          Blank()
          if (this.vm.hasActive) {
            Row({ space: 4 }) {
              Text("●")
                .fontSize(10)
                .fontColor(0xff4caf50)
              Text("正在进行…")
                .fontSize(14)
                .fontColor(0xff4caf50)
                .fontWeight(FontWeight.Medium)
            };
          }
        }

        Row() {
          Column() {
            Stack() {
              Progress({ value: this.vm.todayRatePercent, total: 100, type: ProgressType.Ring })
                .style({ enableSmoothEffect: true })
                .width(120)
                .height(120)
                .color(statusColor(this.vm.todayStatus))
              if (!this.vm.hasActive) {
                Button("开始光照")
                  .type(ButtonType.Capsule)
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .backgroundColor(0xff4caf50)
                  .height(110)
                  .width(110)
                  .borderRadius(55)
                  .onClick(() => {
                    this.startDlg.open();
                  });
              } else {
                Button("结束光照")
                  .type(ButtonType.Capsule)
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .backgroundColor(0xff26a69a)
                  .height(110)
                  .width(110)
                  .borderRadius(55)
                  .onClick(() => {
                    this.vm.endManualWithAutoDuration();
                  });
              }
            }

            Text(`${this.vm.todayRatePercent}%`)
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor(0xff263238)
              .margin({ top: 12 })
            Text("当日达标")
              .fontSize(14)
              .fontColor(0xff78909c)
          }.layoutWeight(1)
        }

        Row({ space: 6 }) {
          this.StatItem(
            "状态",
            statusLabel(this.vm.todayStatus),
            statusColor(this.vm.todayStatus),
          )
          this.StatItem(
            "目标",
            `${this.vm.profile.targetLuxMinLow}-${this.vm.profile.targetLuxMinHigh} lux-min`,
            0xff4caf50,
          )
        }

        this.ActionButtons()
      }
      .padding(20)
      .backgroundColor("#FFFFFF")
      .borderRadius(24)
      .shadow({
        radius: 16,
        color: "#15000000",
        offsetX: 0,
        offsetY: 4,
      })
    }
    .padding({ left: 12, right: 12 });
  }

  @Builder
  StatItem(label: string, value: string, color: ResourceColor) {
    Column({ space: 4 }) {
      Text(label)
        .fontSize(14)
        .fontColor(0xff90a4ae)
      Text(value)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(color)
    }
    // .width("100%")
    .padding(12)
    .backgroundColor(0xfff8faf9)
    .borderRadius(12);
  }

  @Builder
  ProfileCard() {
    // 偏好卡片只改目标和偏好，不直接改历史记录；历史统计会由 VM 自动重算。
    Column({ space: 16 }) {
      Row() {
        Text("光照偏好")
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(0xff263238)
        Blank()
      }

      Row({ space: 12 }) {
        this.LevelTag("🌤️", "弱光", LightLevel.LOW)
        this.LevelTag("⛅", "中光", LightLevel.MID)
        this.LevelTag("☀️", "强光", LightLevel.HIGH)
      }

      Column({ space: 12 }) {
        this.ValueBox("目标下限", true)
        this.ValueBox("目标上限", false)
      }

      Button("快速调整")
        .type(ButtonType.Normal)
        .fontSize(14)
        .fontColor(0xff4caf50)
        .backgroundColor(0xffe8f5e9)
        .height(44)
        .onClick(() => {
          let low: number = this.vm.profile.targetLuxMinLow;
          let high: number = this.vm.profile.targetLuxMinHigh;
          let levelText: string = "中光";
          if (this.vm.profile.preferredLevel === LightLevel.LOW) {
            low = 9000;
            high = 15000;
            levelText = "弱光";
          } else if (this.vm.profile.preferredLevel === LightLevel.MID) {
            low = 12000;
            high = 20000;
            levelText = "中光";
          } else if (this.vm.profile.preferredLevel === LightLevel.HIGH) {
            low = 16000;
            high = 26000;
            levelText = "强光";
          }
          this.vm.updateProfile(low, high, this.vm.profile.preferredLevel);
          prompt.showToast({
            message: `已快速调整为${levelText}偏好设置`,
            duration: 2000,
          });
        })
    }
    .padding(20)
    .backgroundColor("#FFFFFF")
    .borderRadius(24)
    .shadow({
      radius: 12,
      color: "#11000000",
      offsetX: 0,
      offsetY: 2,
    })
    .margin({ left: 16, right: 16 });
  }

  @Builder
  ValueBox(label: string, isLow: boolean) {
    Column({ space: 8 }) {
      Text(label)
        .fontSize(12)
        .fontColor(0xff90a4ae)
      Row({ space: 12 }) {
        Button("-")
          .type(ButtonType.Normal)
          .fontSize(16)
          .fontColor(0xff4caf50)
          .backgroundColor(0xffe8f5e9)
          .width(40)
          .height(40)
          .onClick(() => {
            const newValue =
              Math.max(1000, isLow ? this.vm.profile.targetLuxMinLow : this.vm.profile.targetLuxMinHigh - 1000);
            if (isLow) {
              this.vm.updateProfile(
                newValue,
                this.vm.profile.targetLuxMinHigh,
                this.vm.profile.preferredLevel,
              );
            } else {
              this.vm.updateProfile(
                this.vm.profile.targetLuxMinLow,
                newValue,
                this.vm.profile.preferredLevel,
              );
            }
          })
        Text(`${isLow ? this.vm.profile.targetLuxMinLow : this.vm.profile.targetLuxMinHigh}`)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(0xff263238)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Button("+")
          .type(ButtonType.Normal)
          .fontSize(16)
          .fontColor(0xff4caf50)
          .backgroundColor(0xffe8f5e9)
          .width(40)
          .height(40)
          .onClick(() => {
            const newValue = isLow ? this.vm.profile.targetLuxMinLow : this.vm.profile.targetLuxMinHigh + 1000;
            if (isLow) {
              this.vm.updateProfile(
                newValue,
                this.vm.profile.targetLuxMinHigh,
                this.vm.profile.preferredLevel,
              );
            } else {
              this.vm.updateProfile(
                this.vm.profile.targetLuxMinLow,
                newValue,
                this.vm.profile.preferredLevel,
              );
            }
          })
      }
    }
    // .layoutWeight(1)
    .padding(16)
    .backgroundColor(0xfff8faf9)
    .borderRadius(16);
  }

  @Builder
  LevelTag(icon: string, text: string, lvl: LightLevel) {
    Column({ space: 6 }) {
      Text(icon)
        .fontSize(24)
        .fontColor(this.vm.profile.preferredLevel === lvl ? 0xff2e7d32 : 0xff607d8b)
      Text(text)
        .fontSize(12)
        .fontWeight(this.vm.profile.preferredLevel === lvl ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(this.vm.profile.preferredLevel === lvl ? 0xff2e7d32 : 0xff607d8b)
    }
    .layoutWeight(1)
    .padding(12)
    .backgroundColor(this.vm.profile.preferredLevel === lvl ? 0xffe8f5e9 : 0xfff4f6f8)
    .borderRadius(16)
    .onClick(() => {
      this.vm.updateProfile(this.vm.profile.targetLuxMinLow, this.vm.profile.targetLuxMinHigh, lvl);
    });
  }

  maxLux() {
    const data: DailyLightStat[] = this.vm.sevenDays;
    let maxLux: number = 1;
    for (let i: number = 0; i < data.length; i++) {
      if (data[i].luxMinutes > maxLux) {
        maxLux = data[i].luxMinutes;
      }
    }
    return maxLux;
  }

  @Builder
  SevenDaysChart() {
    Column({ space: 16 }) {
      Row() {
        Text("近 7 天")
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(0xff263238)
        Blank()
      }

      Column({ space: 12 }) {
        Row({ space: 10 }) {
          ForEach(
            this.vm.sevenDays,
            (d: DailyLightStat) => {
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
                  .fontColor(0xff90a4ae)
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Center);
            },
            (d: DailyLightStat) => d.id,
          )
        }.height(160)
      }
      .padding(20)
      .backgroundColor("#FFFFFF")
      .borderRadius(24)
      .shadow({
        radius: 12,
        color: "#11000000",
        offsetX: 0,
        offsetY: 2,
      })
    }
    .padding({ left: 16, right: 16 });
  }

  // 会话列表直接读 VM 的 sessions，让进行中与已结束记录共用同一条展示链路。
  exposureSessionList() {
    return this.vm.sessions;
  }

  @Builder
  TodaySessions() {

  }

  @Builder
  DeleteAction(id: string) {
    Row() {
      Button({ type: ButtonType.Circle }) {
        Text("🗑️")
          .fontColor(Color.White)
          .fontSize(20)
      }
      .width(48)
      .height(48)
      .backgroundColor('#FF5252')
      .onClick(async () => {
        // 震动反馈 (需要权限，这里暂模拟或跳过)
        // try { vibrator.startVibration(...) } catch(e) {}

        await this.vm.deleteSession(id);
        prompt.showToast({ message: '记录已删除' });
      })
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .width(80)
    .height('100%')
    .padding({ left: 16 })
  }

  private todayKey(): string {
    const now: Date = new Date();
    const y: number = now.getFullYear();
    const m: number = now.getMonth() + 1;
    const d: number = now.getDate();
    const mmStr: string = m < 10 ? "0" + m : "" + m;
    const ddStr: string = d < 10 ? "0" + d : "" + d;
    return `${y}-${mmStr}-${ddStr}`;
  }

  private hm(d: Date): string {
    const h: number = d.getHours();
    const m: number = d.getMinutes();
    const hStr: string = h < 10 ? "0" + h : "" + h;
    const mStr: string = m < 10 ? "0" + m : "" + m;
    return `${hStr}:${mStr}`;
  }
}
