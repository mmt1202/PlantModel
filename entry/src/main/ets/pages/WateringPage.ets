// /page/WateringPage.ets
// 浇水记录页面：记录浇水、查看历史、显示连续打卡

import { WateringViewModel } from '../viewmodel/WateringViewModel';
import WaterRecord from '../model/WaterRecord';
import { prompt } from '@kit.ArkUI';
import { WaterParticle } from '../component/WaterParticle';

@ComponentV2
export struct WateringPage {
  @Param plantId: number = 0;
  @Local vm: WateringViewModel = new WateringViewModel('');
  @Local amountStr: string = '100';
  @Local showWaterAnimation: boolean = false;

  aboutToAppear() {
    const pid: string = this.plantId && this.plantId !== 0 ? this.plantId.toString() : 'PLANT_DEMO';
    this.vm = new WateringViewModel(pid);
  }

  build() {
    NavDestination() {
      Column({ space: 16 }) {
        this.Header()
        if (this.showWaterAnimation) {
          this.WaterAnimation()
        }
        Scroll() {
          Column({ space: 20 }) {
            this.WaterControl()
            this.StreakCard()
            this.HistoryList()
          }
          .padding({ bottom: 32 })
        }
        .layoutWeight(1)
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .title('浇水记录')
    .linearGradient({
      direction: GradientDirection.Top,
      colors: [
        [0xFFE3F2FD, 0],
        [0xFFBBDEFB, 0.5],
        [0xFF90CAF9, 1.0],
      ],
    })
    .padding({
      top: AppStorage.get<number>('topRectHeight'),
      bottom: AppStorage.get<number>('bottomRectHeight'),
    });
  }

  @Builder
  Header() {
    Row() {
      Column() {
        Text('浇水记录')
          .fontSize(22)
          .fontWeight(FontWeight.Medium)
          .fontColor(0xFF263238)
        if (this.vm.plantId) {
          Text(`植物ID：${this.vm.plantId}`)
            .fontSize(14)
            .fontColor(0xFF78909C)
        }
      }
      Blank()
    }
    .padding({ left: 16, right: 16, top: 12, bottom: 8 });
  }

  @Builder
  WaterAnimation() {
    Column() {
      WaterParticle()
        .width('100%')
        .height(200)
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .margin({ left: 16, right: 16 })
    .shadow({ radius: 12, color: '#1A000000', offsetX: 0, offsetY: 4 })
  }

  @Builder
  WaterControl() {
    Column({ space: 16 }) {
      Row() {
        Text('浇水记录')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(0xFF263238)
        Blank()
      }

      Column({ space: 12 }) {
        Row() {
          Text('浇水模式')
            .fontSize(14)
            .fontColor(0xFF78909C)
          Blank()
        }
        Row({ space: 12 }) {
          this.ModeChip('日常浇水', 'light', this.vm.mode === 'light')
          this.ModeChip('深度浇透', 'deep', this.vm.mode === 'deep')
        }
      }

      Column({ space: 12 }) {
        Row() {
          Text('浇水量 (ml)')
            .fontSize(14)
            .fontColor(0xFF78909C)
          Blank()
        }
        TextInput({ placeholder: '请输入浇水量', text: this.amountStr })
          .type(InputType.Number)
          .onChange((v: string) => {
            this.amountStr = v
          })
          .height(48)
          .backgroundColor('#F9F9F9')
          .borderRadius(12)
          .padding({ left: 16, right: 16 })

        Row({ space: 12 }) {
          this.QuickAmount(50)
          this.QuickAmount(100)
          this.QuickAmount(200)
          this.QuickAmount(500)
        }
      }

      Column({ space: 12 }) {
        if (this.vm.lastWaterAt() > 0) {
          Row() {
            Text('上次浇水')
              .fontSize(14)
              .fontColor(0xFF78909C)
            Blank()
            Text(this.vm.fmtDate(this.vm.lastWaterAt()))
              .fontSize(14)
              .fontColor(0xFF546E7A)
          }
        }

        Button('记录浇水')
          .type(ButtonType.Capsule)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .backgroundColor('#2196F3')
          .height(52)
          .width('100%')
          .onClick(() => {
            this.recordWater()
          })
      }
    }
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .shadow({ radius: 12, color: '#1A000000', offsetX: 0, offsetY: 4 })
    .margin({ left: 16, right: 16 });
  }

  @Builder
  ModeChip(text: string, mode: string, on: boolean) {
    Row() {
      Text(text)
        .fontSize(14)
        .fontWeight(on ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(on ? '#FFFFFF' : '#263238')
    }
    .padding({ left: 16, right: 16, top: 10, bottom: 10 })
    .backgroundColor(on ? '#2196F3' : '#F2F3F5')
    .borderRadius(16)
    .onClick(() => {
      this.vm.setMode(mode)
    })
  }

  @Builder
  QuickAmount(amount: number) {
    Row() {
      Text(`${amount}ml`)
        .fontSize(14)
        .fontColor(this.amountStr === amount.toString() ? '#FFFFFF' : '#2196F3')
    }
    .padding({ left: 14, right: 14, top: 8, bottom: 8 })
    .backgroundColor(this.amountStr === amount.toString() ? '#2196F3' : '#E3F2FD')
    .borderRadius(12)
    .onClick(() => {
      this.amountStr = amount.toString()
    })
  }

  @Builder
  StreakCard() {
    Column({ space: 12 }) {
      Row() {
        Text('连续打卡')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(0xFF263238)
        Blank()
      }

      Row() {
        Column() {
          Text(`${this.vm.streakDays}`)
            .fontSize(48)
            .fontWeight(FontWeight.Bold)
            .fontColor('#2196F3')
          Text('天')
            .fontSize(14)
            .fontColor(0xFF78909C)
        }
        Blank()
        Column() {
          Text(`${this.vm.recentTimes.length}`)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#4CAF50')
          Text('记录')
            .fontSize(14)
            .fontColor(0xFF78909C)
        }
      }
    }
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .shadow({ radius: 12, color: '#1A000000', offsetX: 0, offsetY: 4 })
    .margin({ left: 16, right: 16 });
  }

  @Builder
  HistoryList() {
    Column({ space: 12 }) {
      Row() {
        Text('历史记录')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(0xFF263238)
        Blank()
      }

      if (this.vm.recentTimes.length === 0) {
        Column() {
          Image($r('app.media.ic_water'))
            .width(48)
            .height(48)
            .opacity(0.3)
          Text('暂无浇水记录')
            .fontSize(14)
            .fontColor(0xFF90A4AE)
            .margin({ top: 8 })
        }
        .height(120)
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#FFFFFF')
        .borderRadius(16)
      } else {
        List({ space: 12 }) {
          ForEach(this.vm.recentTimes, (ts: number) => {
            ListItem() {
              this.HistoryItem(ts)
            }
          }, (ts: number) => ts.toString())
        }
      }
    }
    .padding({ left: 16, right: 16 });
  }

  @Builder
  HistoryItem(ts: number) {
    Row() {
      Column({ space: 4 }) {
        Text(this.vm.fmtDate(ts))
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(0xFF263238)
      }
      .alignItems(HorizontalAlign.Start)
      Blank()
      Image($r('app.media.ic_water'))
        .width(20)
        .height(20)
        .fillColor('#2196F3')
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({ radius: 8, color: '#10000000', offsetX: 0, offsetY: 2 })
  }

  private async recordWater(): Promise<void> {
    const amount: number = Number(this.amountStr)
    if (isNaN(amount) || amount <= 0) {
      prompt.showToast({
        message: '请输入有效的浇水量',
        duration: 2000,
      })
      return
    }

    this.showWaterAnimation = true
    this.vm.startAnimation()

    setTimeout(() => {
      this.showWaterAnimation = false
      this.vm.stopAnimation()
    }, 2000)

    const rec: WaterRecord = this.vm.recordWater(amount)
    prompt.showToast({
      message: `已记录浇水 ${amount}ml`,
      duration: 2000,
    })
  }
}
