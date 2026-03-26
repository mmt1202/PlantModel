// /page/EnvSimulatorPage.ets
// 环境模拟器页面：调整光照/土壤/空气湿度，并实时查看植物反馈

import { PlantRenderer } from '../component/PlantRenderer';
import { EnvSimulatorViewModel } from '../viewmodel/EnvSimulatorViewModel';

@ComponentV2
export struct EnvSimulatorPage {
  @Param plantId: string = '';
  @Local vm: EnvSimulatorViewModel = new EnvSimulatorViewModel('');
  @Local lastSavedText: string = '';

  aboutToAppear() {
    // 环境模拟器允许脱离真实植物使用，所以没有 plantId 时会退化成 demo 模式。
    if (this.plantId && this.plantId !== '') {
      this.vm = new EnvSimulatorViewModel(this.plantId);
    } else {
      this.vm = new EnvSimulatorViewModel('PLANT_DEMO');
    }
  }

  build() {
    // 页面只负责调整三个环境参数并展示派生反馈，解释逻辑都在 VM 和 renderer 中。
    Column({ space: 12 }) {
      Row() {
        Column() {
          Text('环境模拟器').fontSize(22).fontWeight(FontWeight.Medium)
          Text('实时模拟光照 / 土壤湿度 / 环境湿度对植物的影响').fontSize(12).opacity(0.6)
        }
        Blank()
        Row({ space: 8 }) {
          Button('重置').type(ButtonType.Normal).onClick(() => {
            this.vm.reset();
          })
          Button('保存快照').type(ButtonType.Capsule).backgroundColor('#26A69A')
            .onClick(() => {
              const snap = this.vm.saveSnapshot();
              this.lastSavedText = `已生成快照：${new Date(snap.createdAt).toLocaleString()}`;
            })
        }
      }
      .padding({ left: 16, right: 16, top: 12 })

      PlantRenderer({
        light: this.vm.light,
        soil: this.vm.soil,
        humidity: this.vm.humidity,
        leafTone: this.vm.leafTone,
        backgroundTone: this.vm.backgroundTone,
        mood: this.vm.mood,
        isAnimating: this.vm.isAnimating,
        onTap: () => {}
      })

      Column({ space: 12 }) {
        Column({ space: 6 }) {
          Row() {
            Text('光照').fontSize(14).fontWeight(FontWeight.Medium)
            Blank()
            Text(`${Math.round(this.vm.light)}%`).fontSize(12).opacity(0.6)
          }
          Slider({ value: this.vm.light, min: 0, max: 100, step: 1 })
            .onChange((v: number) => {
              if (!this.vm.isAnimating) {
                this.vm.setLight(Math.floor(v));
              }
            })
        }

        Column({ space: 6 }) {
          Row() {
            Text('土壤含水').fontSize(14).fontWeight(FontWeight.Medium)
            Blank()
            Text(`${Math.round(this.vm.soil)}%`).fontSize(12).opacity(0.6)
          }
          Slider({ value: this.vm.soil, min: 0, max: 100, step: 1 })
            .onChange((v: number) => {
              if (!this.vm.isAnimating) {
                this.vm.setSoil(Math.floor(v));
              }
            })
        }

        Column({ space: 6 }) {
          Row() {
            Text('环境湿度').fontSize(14).fontWeight(FontWeight.Medium)
            Blank()
            Text(`${Math.round(this.vm.humidity)}%`).fontSize(12).opacity(0.6)
          }
          Slider({ value: this.vm.humidity, min: 0, max: 100, step: 1 })
            .onChange((v: number) => {
              if (!this.vm.isAnimating) {
                this.vm.setHumidity(Math.floor(v));
              }
            })
        }
      }
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .margin({ left: 16, right: 16 })
      .shadow({ radius: 6, color: '#11000000', offsetX: 0, offsetY: 1 })

      Column({ space: 8 }) {
        Row() {
          Text('模拟状态').fontSize(16).fontWeight(FontWeight.Medium)
          Blank()
        }
        Row({ space: 8 }) {
          Text(this.vm.mood).fontSize(14)
          Blank()
          Text(this.vm.recommendation).fontSize(12).opacity(0.7)
        }
        if (this.lastSavedText !== '') {
          Text(this.lastSavedText).fontSize(12).opacity(0.6)
        }
      }
      .padding({ left: 16, right: 16, bottom: 20 })
    }
    .backgroundColor('#FAFAFA')
  }
}
