// /page/EmergencyAndRotatePage.ets
// 合页：急救流程卡 + 转盆提醒（V2）

import { EmergencyViewModel } from "../viewmodel/EmergencyViewModel";
import { PlaybookItem, PlayStep } from "../model/EmergencyPlaybook";
import EmergencyLog from "../model/EmergencyLog";
import { RotatePlanViewModel, RotateLog } from "../viewmodel/RotatePlanViewModel";
import { prompt } from "@kit.ArkUI";

@ComponentV2
export struct EmergencyAndRotatePage {
  @Param plantId: string = "";
  @Local tabBarIndex: number = 0;
  @Local emgVM: EmergencyViewModel = new EmergencyViewModel("");
  @Local rotVM: RotatePlanViewModel = new RotatePlanViewModel("");

  aboutToAppear() {
    // 这个合并页把“应急流程”和“转盆提醒”两条能力线放在同一入口，分别交给独立 VM 管理。
    const pid: string = this.plantId && this.plantId !== "" ? this.plantId : "PLANT_DEMO";
    this.emgVM = new EmergencyViewModel(pid);
    this.rotVM = new RotatePlanViewModel(pid);
  }

  build() {
    NavDestination() {
      // 页面只负责在两个 panel 之间切换，具体状态与规则都下沉到各自 ViewModel。
      Scroll() {
        Column({ space: 20 }) {
          this.Header()
          this.TabSwitch()
          if (this.tabBarIndex === 0) {
            this.EmergencyPanel();
          } else {
            this.RotatePanel();
          }
        }
        .padding({ bottom: 32 })
      }
      .layoutWeight(1)
      .edgeEffect(EdgeEffect.Spring)
    }
    .title("急救与转盆")
    .linearGradient({
      direction: GradientDirection.Top,
      colors: [
        [0xffffebee, 0],
        [0xfffff3e0, 0.5],
        [0xfff3e5f5, 1.0],
      ],
    })
    .padding({
      top: AppStorage.get<number>("topRectHeight"),
      bottom: AppStorage.get<number>("bottomRectHeight"),
    });
  }

  @Builder Header() {
    Row() {
      Column() {
        Text("急救与转盆")
          .fontSize(22)
          .fontWeight(FontWeight.Medium)
          .fontColor(0xff263238)
        Text(`植物ID：${this.emgVM.plantId}`)
          .fontSize(14)
          .fontColor(0xff78909c)
      }
      Blank()
    }
    .padding({ left: 16, right: 16, top: 12, bottom: 8 });
  }

  @Builder TabSwitch() {
    Row({ space: 12 }) {
      this.TabChip("🚑 急救流程", this.tabBarIndex === 0, () => {
        this.tabBarIndex = 0;
      })
      this.TabChip("🔄 转盆提醒", this.tabBarIndex === 1, () => {
        this.tabBarIndex = 1;
      })
    }
    .padding({ left: 16, right: 16 });
  }

  @Builder TabChip(text: string, on: boolean, action: () => void) {
    Row() {
      Text(text)
        .fontSize(15)
        .fontWeight(on ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(on ? 0xff1976d2 : 0xff607d8b)
    }
    .padding({ left: 20, right: 20, top: 12, bottom: 12 })
    .backgroundColor(on ? 0xffe3f2fd : 0xfff4f6f8)
    .borderRadius(100)
    .onClick(() => {
      action();
    });
  }

  @Builder EmergencyPanel() {
    // 应急面板的顺序就是完整流程：选症状 -> 勾步骤 -> 记录观察 -> 查看历史。
    Column({ space: 20 }) {
      this.SymptomSelector()
      this.StepCards()
      this.NoteAndStart()
      this.LogList()
    };
  }

  @Builder SymptomSelector() {
    Column({ space: 16 }) {
      Row() {
        Text("选择症状")
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(0xff263238)
        Blank()
      }
      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
        this.SymChip("☀️ 日灼", "SCORCH")
        this.SymChip("🥀 萎蔫", "WILT")
        this.SymChip("🍂 黄化", "YELLOW")
        this.SymChip("🔴 斑点", "SPOT")
        this.SymChip("🪵 烂根", "ROOTROT")
      }

      if (this.emgVM.currentItem() !== undefined) {
        Text(this.emgVM.currentItem()!.tip).fontSize(14).fontColor(0xff78909c).lineHeight(20);
      }
    }
    .padding(20)
    .backgroundColor("#FFFFFF")
    .borderRadius(24)
    .shadow({ radius: 12, color: "#11000000", offsetX: 0, offsetY: 2 })
    .margin({ left: 16, right: 16 });
  }

  @Builder SymChip(text: string, key: string) {
    Row() {
      Text(text)
        .fontSize(14)
        .fontWeight(this.emgVM.selectedKey === key ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(this.emgVM.selectedKey === key ? 0xff1976d2 : 0xff607d8b)
    }
    .width("47%")
    .padding({ left: 14, right: 14, top: 12, bottom: 12 })
    .backgroundColor(this.emgVM.selectedKey === key ? 0xffe3f2fd : 0xfff4f6f8)
    .borderRadius(16)
    .onClick(() => {
      this.emgVM.selectSymptom(key);
    })
    .margin({ bottom: 8 });
  }

  @Builder StepCards() {
    Column({ space: 16 }) {
      Row() {
        Text("急救步骤")
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(0xff263238)
        Blank()
      }

      if (this.emgVM.currentItem()) {
        Column({ space: 12 }) {
          ForEach(
            this.emgVM.currentItem()?.steps,
            (step: PlayStep, i: number) => {
              this.StepRow(i, step.text);
            },
            (step: PlayStep, i?: number) => step + "_" + (i as number),
          )
          Row() {
            Text("⏰").fontSize(16)
            Text(`建议 ${this.emgVM.currentItem()!.reviewHours} 小时后复查`)
              .fontSize(14)
              .fontColor(0xff78909c)
          }
        };
      }
    }
    .padding(20)
    .backgroundColor("#FFFFFF")
    .borderRadius(24)
    .shadow({ radius: 12, color: "#11000000", offsetX: 0, offsetY: 2 })
    .margin({ left: 16, right: 16 });
  }

  @Builder StepRow(index: number, text: string) {
    Row({ space: 12 }) {
      Column()
        .width(28)
        .height(28)
        .borderRadius(14)
        .backgroundColor(this.emgVM.stepChecked[index] ? "#26A69A" : "#E0E0E0")
        .onClick(() => {
          this.emgVM.toggleStep(index);
        })
      Text(text)
        .fontSize(15)
        .fontColor(0xff37474f)
        .flexGrow(1)
        .lineHeight(22)
    }
    .padding(12)
    .backgroundColor(0xfff8faf9)
    .borderRadius(16);
  }

  @Builder NoteAndStart() {
    Column({ space: 16 }) {
      Column({ space: 8 }) {
        Text("备注（可选）")
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(0xff263238)
        TextInput({ placeholder: "记录原因、环境或药剂等…", text: this.emgVM.note })
          .onChange((v: string) => {
            this.emgVM.note = v;
          })
          .height(52)
          .backgroundColor("#FFFFFF")
          .borderRadius(16)
          .padding({ left: 16, right: 16 })
      }
      Column({ space: 12 }) {
        Button("开始观察")
          .type(ButtonType.Capsule)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .backgroundColor("#26A69A")
          .height(52)
          .width("100%")
          .onClick(() => {
            const log: EmergencyLog | undefined = this.emgVM.startObservation();
            if (log) {
              prompt.showToast({
                message: "已开始观察，复查时间：" + this.emgVM.fmtDate(log.reviewAt),
                duration: 3000,
              });
            }
          })
        Button("清空勾选")
          .type(ButtonType.Normal)
          .fontSize(14)
          .fontColor("#26A69A")
          .backgroundColor("#E0F2F1")
          .height(48)
          .width("100%")
          .onClick(() => {
            this.emgVM.ensureStepArray();
            prompt.showToast({
              message: "已清空勾选状态",
              duration: 2000,
            });
          })
      }
    }
    .padding({ left: 16, right: 16 });
  }

  @Builder LogList() {
    Column({ space: 12 }) {
      Row() {
        Text("急救记录")
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(0xff263238)
        Blank()
      }

      if (this.emgVM.logs.length === 0) {
        Column() {
          Text("📝")
            .fontSize(40)
            .opacity(0.3)
          Text("暂无记录")
            .fontSize(14)
            .fontColor(0xff90a4ae)
            .margin({ top: 8 })
        }
        .height(140)
        .width("100%")
        .justifyContent(FlexAlign.Center)
        .backgroundColor("#FFFFFF")
        .borderRadius(24)
        .margin({ left: 16, right: 16 });
      } else {
        List({ space: 12 }) {
          ForEach(
            this.emgVM.logs,
            (it: EmergencyLog) => {
              ListItem() {
                Column({ space: 10 }) {
                  Row() {
                    Text(it.title)
                      .fontSize(16)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(0xff263238)
                    Blank()
                    Text(it.completed ? "✓ 已完成" : "⏳ 观察中")
                      .fontSize(14)
                      .fontColor(it.completed ? "#26A69A" : "#FF9F43")
                      .fontWeight(FontWeight.Medium)
                  }
                  Row() {
                    Column({ space: 4 }) {
                      Text("开始时间")
                        .fontSize(12)
                        .fontColor(0xff90a4ae)
                      Text(this.emgVM.fmtDate(it.startedAt))
                        .fontSize(13)
                        .fontColor(0xff546e7a)
                    }
                    Blank()
                    Column({ space: 4 }) {
                      Text("复查时间")
                        .fontSize(12)
                        .fontColor(0xff90a4ae)
                      Text(this.emgVM.fmtDate(it.reviewAt))
                        .fontSize(13)
                        .fontColor(0xff546e7a)
                    }
                  }
                  if (it.note !== "") {
                    Text(it.note).fontSize(14).fontColor(0xff78909c).lineHeight(20);
                  }
                  if (!it.completed) {
                    Button("标记完成")
                      .type(ButtonType.Normal)
                      .fontSize(14)
                      .fontColor("#26A69A")
                      .backgroundColor("#E0F2F1")
                      .height(40)
                      .width("100%")
                      .onClick(() => {
                        this.emgVM.markCompleted(it.id);
                        prompt.showToast({
                          message: "已标记为完成",
                          duration: 2000,
                        });
                      });
                  }
                }
                .padding(16)
                .backgroundColor("#FFFFFF")
                .borderRadius(20)
                .shadow({ radius: 8, color: "#10000000", offsetX: 0, offsetY: 2 })
                .margin({ left: 16, right: 16 })
              };
            },
            (it: EmergencyLog) => it.id,
          )
        };
      }
    };
  }

  @Builder RotatePanel() {
    // 转盆面板围绕一个简单计划展开：设置周期、查看下次到期、记录历史。
    Column({ space: 20 }) {
      this.RotateSettingCard()
      this.NextDueCard()
      this.RotateHistory()
    };
  }

  @Builder RotateSettingCard() {
    Column({ space: 20 }) {
      Row() {
        Text("转盆计划")
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(0xff263238)
        Blank()
        this.EnableSwitch()
      }
      Column({ space: 12 }) {
        Row() {
          Text("转盆周期")
            .fontSize(14)
            .fontColor(0xff78909c)
          Blank()
          Text(`每 ${this.rotVM.intervalDays} 天`)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(0xff9c27b0)
        }
        Slider({ value: this.rotVM.intervalDays, min: 3, max: 60, step: 1 })
          .trackColor(0xfff3e5f5)
          .selectedColor(0xff9c27b0)
          .blockColor(0xff9c27b0)
          .blockSize({ width: 24, height: 24 })
          .onChange((v: number) => this.rotVM.setIntervalDays(Math.floor(v)))
      }
      Column({ space: 12 }) {
        Button("转盆 90° · 打卡")
          .type(ButtonType.Capsule)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .backgroundColor("#9C27B0")
          .height(52)
          .width("100%")
          .onClick(() => {
            this.rotVM.markRotatedNow();
            prompt.showToast({
              message: "已记录转盆，下次到期：" + this.rotVM.fmtDate(this.rotVM.nextDueAt()),
              duration: 3000,
            });
          })

        if (this.rotVM.lastRotatedAt > 0) {
          Row() {
            Text("上次转盆")
              .fontSize(14)
              .fontColor(0xff90a4ae)
            Blank()
            Text(this.rotVM.fmtDate(this.rotVM.lastRotatedAt))
              .fontSize(14)
              .fontColor(0xff546e7a)
              .fontWeight(FontWeight.Medium)
          };
        } else {
          Text("上次：未记录").fontSize(14).fontColor(0xff90a4ae);
        }
      }
    }
    .padding(20)
    .backgroundColor("#FFFFFF")
    .borderRadius(24)
    .shadow({ radius: 12, color: "#11000000", offsetX: 0, offsetY: 2 })
    .margin({ left: 16, right: 16 });
  }

  @Builder EnableSwitch() {
    Row() {
      Text(this.rotVM.enabled ? "已启用" : "未启用")
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        .fontColor(this.rotVM.enabled ? 0xff7b1fa2 : 0xff607d8b)
    }
    .backgroundColor(this.rotVM.enabled ? 0xfff3e5f5 : 0xfff4f6f8)
    .borderRadius(100)
    .onClick(() => {
      this.rotVM.setEnabled(!this.rotVM.enabled);
      prompt.showToast({
        message: this.rotVM.enabled ? "已启用转盆计划" : "已禁用转盆计划",
        duration: 2000,
      });
    });
  }

  @Builder NextDueCard() {
    Column({ space: 12 }) {
      Row() {
        Text("下一次到期")
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(0xff263238)
        Blank()
      }

      if (!this.rotVM.enabled) {
        Column() {
          Text("🔕")
            .fontSize(32)
            .opacity(0.5)
          Text("未启用计划")
            .fontSize(14)
            .fontColor(0xff90a4ae)
            .margin({ top: 8 })
        }
        .width("100%")
        .padding(24)
        .backgroundColor(0xfff8faf9)
        .borderRadius(16);
      } else {
        Column({ space: 8 }) {
          Text(this.rotVM.fmtDate(this.rotVM.nextDueAt()))
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.rotVM.overdue() ? "#D32F2F" : "#9C27B0")
          Text(this.rotVM.overdue() ? "⚠️ 已到期，请尽快转盆" : "✓ 未到期")
            .fontSize(14)
            .fontColor(this.rotVM.overdue() ? "#D32F2F" : "#7B1FA2")
            .fontWeight(this.rotVM.overdue() ? FontWeight.Medium : FontWeight.Normal)
        }
        .width("100%")
        .padding(24)
        .backgroundColor(this.rotVM.overdue() ? 0xffebee : 0xfff3e5f5)
        .borderRadius(16);
      }
    }
    .padding(20)
    .backgroundColor("#FFFFFF")
    .borderRadius(24)
    .shadow({ radius: 12, color: "#11000000", offsetX: 0, offsetY: 2 })
    .margin({ left: 16, right: 16 });
  }

  @Builder RotateHistory() {
    Column({ space: 12 }) {
      Row() {
        Text("转盆历史")
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(0xff263238)
        Blank()
      }

      if (this.rotVM.logs.length === 0) {
        Column() {
          Text("📅")
            .fontSize(40)
            .opacity(0.3)
          Text("暂无记录")
            .fontSize(14)
            .fontColor(0xff90a4ae)
            .margin({ top: 8 })
        }
        .height(140)
        .width("100%")
        .justifyContent(FlexAlign.Center)
        .backgroundColor("#FFFFFF")
        .borderRadius(24)
        .margin({ left: 16, right: 16 });
      } else {
        List({ space: 12 }) {
          ForEach(
            this.rotVM.logs,
            (x: RotateLog) => {
              ListItem() {
                Row() {
                  Text("🔄").fontSize(18)
                  Text(this.rotVM.fmtDate(x.ts))
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(0xff263238)
                  Blank()
                }
                .padding(16)
                .backgroundColor("#FFFFFF")
                .borderRadius(20)
                .shadow({ radius: 8, color: "#10000000", offsetX: 0, offsetY: 2 })
                .margin({ left: 16, right: 16 })
              };
            },
            (x: RotateLog) => x.id,
          )
        };
      }
    };
  }
}
