// /page/WaterEstimatorPage.ets
// 用量估算器（V2 装饰器 / 完整页面）：输入（盆径、深度、介质、策略、植株）→ 结果区间（ml）→ 建议 → 保存日志

import { PlantKind, RetentionType, StrategyType } from '../model/WaterEstimatorTypes';
import { WaterEstimatorViewModel } from '../viewmodel/WaterEstimatorViewModel';
import WaterEstimateLog from '../model/WaterEstimateLog';

@ComponentV2
export struct WaterEstimatorPage {
  @Param plantId: number = 0;
  @Local vm: WaterEstimatorViewModel = new WaterEstimatorViewModel(0);
  @Local noteText: string = '';

  aboutToAppear() {
    if (this.plantId && this.plantId !== 0) {
      this.vm = new WaterEstimatorViewModel(this.plantId);
    } else {
      this.vm = new WaterEstimatorViewModel(0);
    }
  }

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: 20 }) {
          this.Header()
          this.SizeCard()
          this.OptionCard()
          this.ResultCard()
          this.SaveBar()
          this.LogList()
        }
        .padding({ bottom: 32 })
      }
      .layoutWeight(1)
      .edgeEffect(EdgeEffect.Spring)
    }
    .title('浇水估算')
    .linearGradient({
      direction: GradientDirection.Top,
      colors: [[0xFFE3F2FD, 0], [0xFFE1F5FE, 0.5], [0xFFE8F5E9, 1.0]]
    }).padding({
      top: AppStorage.get<number>('topRectHeight'),
      bottom: AppStorage.get<number>('bottomRectHeight')
    })
  }

  @Builder
  Header() {
    Row() {
      Column() {
        Text('浇水估算器').fontSize(22).fontWeight(FontWeight.Medium).fontColor(0xFF263238)
        if (this.vm.plantId > 0) {
          Text(`植物ID：${this.vm.plantId}`).fontSize(14).fontColor(0xFF78909C)
        }
      }

      Blank()
      Button('重置')
        .type(ButtonType.Normal)
        .fontSize(14)
        .fontColor(0xFF2196F3)
        .backgroundColor(0xFFE3F2FD)
        .height(40)
        .onClick(() => {
          this.vm.setDiameter(14);
          this.vm.setDepth(12);
          this.vm.setRetention(RetentionType.GENERAL);
          this.vm.setStrategy(StrategyType.MAINT);
          this.vm.setPlant(PlantKind.FOLIAGE);
        })
    }
    .padding({
      left: 16,
      right: 16,
      top: 12,
      bottom: 8
    })
  }

  @Builder
  SizeCard() {
    Column({ space: 16 }) {
      Row() {
        Text('盆器尺寸').fontSize(18).fontWeight(FontWeight.Medium).fontColor(0xFF263238)
        Blank()
      }

      Column({ space: 12 }) {
        Column({ space: 8 }) {
          Row() {
            Text('盆径').fontSize(14).fontColor(0xFF78909C)
            Blank()
            Text(`${this.vm.diameterCm} cm`).fontSize(20).fontWeight(FontWeight.Bold).fontColor(0xFF2196F3)
          }

          Slider({
            value: this.vm.diameterCm,
            min: 6,
            max: 60,
            step: 1
          })
            .trackColor(0xFFE3F2FD)
            .selectedColor(0xFF2196F3)
            .blockColor(0xFF2196F3)
            .blockSize({ width: 24, height: 24 })
            .onChange((v: number) => this.vm.setDiameter(Math.floor(v)))
        }

        Column({ space: 8 }) {
          Row() {
            Text('深度').fontSize(14).fontColor(0xFF78909C)
            Blank()
            Text(`${this.vm.depthCm} cm`).fontSize(20).fontWeight(FontWeight.Bold).fontColor(0xFF2196F3)
          }

          Slider({
            value: this.vm.depthCm,
            min: 6,
            max: 60,
            step: 1
          })
            .trackColor(0xFFE3F2FD)
            .selectedColor(0xFF2196F3)
            .blockColor(0xFF2196F3)
            .blockSize({ width: 24, height: 24 })
            .onChange((v: number) => this.vm.setDepth(Math.floor(v)))
        }

        Row({ space: 8 }) {
          this.QuickButton('- 盆径', () => this.vm.setDiameter(this.vm.diameterCm - 1))
          this.QuickButton('+ 盆径', () => this.vm.setDiameter(this.vm.diameterCm + 1))
          Blank()
          this.QuickButton('- 深度', () => this.vm.setDepth(this.vm.depthCm - 1))
          this.QuickButton('+ 深度', () => this.vm.setDepth(this.vm.depthCm + 1))
        }
      }
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
  QuickButton(text: string, action: () => void) {
    Button(text)
      .type(ButtonType.Normal)
      .fontSize(13)
      .fontColor(0xFF2196F3)
      .backgroundColor(0xFFE3F2FD)
      .height(36)
      .onClick(action)
  }

  @Builder
  OptionCard() {
    Column({ space: 16 }) {
      Row() {
        Text('介质 / 策略 / 植株').fontSize(18).fontWeight(FontWeight.Medium).fontColor(0xFF263238)
        Blank()
      }

      Column({ space: 16 }) {
        Column({ space: 10 }) {
          Row() {
            Text('介质类型').fontSize(14).fontColor(0xFF78909C)
            Blank()
            Text(this.vm.labelRetention()).fontSize(14).fontWeight(FontWeight.Medium).fontColor(0xFF2196F3)
          }

          Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
            this.Chip('砂砾/透水', this.vm.retention === RetentionType.SANDY,
              () => this.vm.setRetention(RetentionType.SANDY))
            this.Chip('通用介质', this.vm.retention === RetentionType.GENERAL,
              () => this.vm.setRetention(RetentionType.GENERAL))
            this.Chip('泥炭/保水', this.vm.retention === RetentionType.PEATY,
              () => this.vm.setRetention(RetentionType.PEATY))
          }
        }

        Column({ space: 10 }) {
          Row() {
            Text('浇水策略').fontSize(14).fontColor(0xFF78909C)
            Blank()
            Text(this.vm.labelStrategy()).fontSize(14).fontWeight(FontWeight.Medium).fontColor(0xFF2196F3)
          }

          Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
            this.Chip('彻底浸润', this.vm.strategy === StrategyType.FULL, () => this.vm.setStrategy(StrategyType.FULL))
            this.Chip('日常保养', this.vm.strategy === StrategyType.MAINT,
              () => this.vm.setStrategy(StrategyType.MAINT))
          }
        }

        Column({ space: 10 }) {
          Row() {
            Text('植株类型').fontSize(14).fontColor(0xFF78909C)
            Blank()
            Text(this.vm.labelPlant()).fontSize(14).fontWeight(FontWeight.Medium).fontColor(0xFF2196F3)
          }

          Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
            this.Chip('多肉', this.vm.plantKind === PlantKind.SUCC, () => this.vm.setPlant(PlantKind.SUCC))
            this.Chip('观叶', this.vm.plantKind === PlantKind.FOLIAGE, () => this.vm.setPlant(PlantKind.FOLIAGE))
          }
        }
      }
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
  Chip(text: string, on: boolean, action: () => void) {
    Row() {
      Text(text)
        .fontSize(14)
        .fontWeight(on ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(on ? 0xFF1976D2 : 0xFF607D8B)
    }
    .padding({
      left: 14,
      right: 14,
      top: 10,
      bottom: 10
    })
    .backgroundColor(on ? 0xFFE3F2FD : 0xFFF4F6F8)
    .borderRadius(16)

    .onClick(() => {
      action();
    })
    .margin({ right: 8, bottom: 8 })
  }

  @Builder
  ResultCard() {
    Column({ space: 16 }) {
      Row() {
        Text('估算结果').fontSize(18).fontWeight(FontWeight.Medium).fontColor(0xFF263238)
        Blank()
      }

      Row({ space: 12 }) {
        this.ResultPill('下限', this.vm.low, 0xFF607D8B)
        this.ResultPill('推荐', this.vm.mid, 0xFF2196F3)
        this.ResultPill('上限', this.vm.high, 0xFF607D8B)
      }

      Column({ space: 8 }) {
        Text(this.vm.getSuggestText())
          .fontSize(14)
          .fontColor(0xFF546E7A)
          .lineHeight(20)
        Text(this.vm.getFormulaBrief())
          .fontSize(12)
          .fontColor(0xFF90A4AE)
      }
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
  ResultPill(label: string, value: number, color: ResourceColor) {
    Column({ space: 4 }) {
      Text(label).fontSize(12).fontColor(0xFF90A4AE)
      Text(`${value} ml`)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
    }
    .layoutWeight(1)
    .padding(16)
    .backgroundColor(0xFFF8FAF9)
    .borderRadius(16)
  }

  @Builder
  SaveBar() {
    Column({ space: 16 }) {
      Column({ space: 8 }) {
        Text('备注（可选）').fontSize(16).fontWeight(FontWeight.Medium).fontColor(0xFF263238)
        TextInput({ placeholder: '记录本次估算的环境/植株状态等...', text: this.noteText })
          .onChange((v: string) => {
            this.noteText = v
          })
          .height(48)
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .padding({ left: 16, right: 16 })
      }

      Column({ space: 12 }) {
        Button('保存估算记录')
          .type(ButtonType.Capsule)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .backgroundColor('#2196F3')
          .height(52)
          .width('100%')
          .onClick(() => {
          })

        Button('用"推荐"记一笔浇水')
          .type(ButtonType.Normal)
          .fontSize(14)
          .fontColor('#2196F3')
          .backgroundColor('#E3F2FD')
          .height(48)
          .width('100%')
          .onClick(() => {
          })
      }
    }
    .padding({ left: 16, right: 16 })
  }

  @Builder
  LogList() {
    Column({ space: 12 }) {
      Row() {
        Text('历史估算记录').fontSize(18).fontWeight(FontWeight.Medium).fontColor(0xFF263238)
        Blank()
      }

      if (this.vm.logs.length === 0) {
        Column() {
          Text('📝').fontSize(40).opacity(0.3)
          Text('暂无记录').fontSize(14).fontColor(0xFF90A4AE).margin({ top: 8 })
        }
        .height(140)
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#FFFFFF')
        .borderRadius(24)
        .margin({ left: 16, right: 16 })
      } else {
        List({ space: 12 }) {
          ForEach(this.vm.logs, (it: WaterEstimateLog) => {
            ListItem() {
              Column({ space: 8 }) {
                Row() {
                  Text(new Date(it.createdAt).toLocaleString())
                    .fontSize(13)
                    .fontColor(0xFF90A4AE)
                  Blank()
                }

                Row() {
                  Text(`盆径${it.diameterCm}cm 深度${it.depthCm}cm`)
                    .fontSize(14)
                    .fontColor(0xFF546E7A)
                  Blank()
                  Text(`${it.low}-${it.high}ml`)
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(0xFF2196F3)
                }

                if (it.note !== '') {
                  Text(it.note)
                    .fontSize(13)
                    .fontColor(0xFF78909C)
                    .lineHeight(18)
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
              .margin({ left: 16, right: 16 })
            }
          }, (it: WaterEstimateLog) => it.id)
        }
      }
    }
    .padding({ top: 4 })
  }
}
