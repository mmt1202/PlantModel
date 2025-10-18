// /page/EnvSimulatorPage.ets
// 环境模拟器页面（完整）：使用 V2 装饰器 + @Builder UI，绑定 Vm，并提供保存快照（返回 snapshot JSON）
// 说明：页面不直接写入数据库；若你想持久化，调用 vm.saveSnapshot() 的结果并用你项目的 RdbManager 写入 log 表。

import { ComponentV2, Param, Local } from '@ohos.aafwk.ace'; // 示意装饰器
import { EnvSimulatorViewModel } from '../viewmodel/EnvSimulatorViewModel';
import PlantRenderer from '../component/PlantRenderer';

@ComponentV2
export struct EnvSimulatorPage {
  // 从 Navigation 注入 plantId（可选）
  @Param plantId: string = '';

  // local vm（V2 可观测）
  @Local vm: EnvSimulatorViewModel = new EnvSimulatorViewModel('');

  // 控制对话与提示
  @Local lastSavedText: string = '';

  aboutToAppear() {
    if (this.plantId && this.plantId !== '') {
      this.vm = new EnvSimulatorViewModel(this.plantId);
    } else {
      this.vm = new EnvSimulatorViewModel('PLANT_DEMO');
    }
  }

  @Builder build() {
    Column({ space: 12 }) {
      // Header
      Row() {
        Column() {
          Text('环境模拟器').fontSize(22).fontWeight(FontWeight.Medium)
          Text('实时模拟光照 / 土壤湿度 / 环境湿度对植物的影响').fontSize(12).opacity(0.6)
        }
        Blank()
        Row({ space: 8 }) {
          Button('重置').type(ButtonType.Normal).onClick(() => { this.vm.reset(); })
          Button('保存快照').type(ButtonType.Capsule).backgroundColor('#26A69A')
            .onClick(() => {
              const snap = this.vm.saveSnapshot();
              this.lastSavedText = `已生成快照 ${new Date(snap.createdAt).toLocaleString()}`;
              // 说明：若你想把 snap 写入 DB：
              // const note = this.vm.snapshotToNote(snap);
              // 调用你的 RdbManager 写入 log 表（category = 'ENV_SNAPSHOT', note = note）
              // 例子 (伪代码):
              // try { const mgr = RdbManager.getInstance(); await mgr.rdbStore.insert(RdbManager.T_LOG, { plantId: ..., note, createdAt: snap.createdAt, category:'ENV_SNAPSHOT' }); }
              // catch (e) { /* 容错处理 */ }
            })
        }
      }
      .padding({ left: 16, right: 16, top: 12 })

      // Renderer
      PlantRenderer({
        light: this.vm.light,
        soil: this.vm.soil,
        humidity: this.vm.humidity,
        leafTone: this.vm.leafTone,
        backgroundTone: this.vm.backgroundTone,
        mood: this.vm.mood,
        isAnimating: this.vm.isAnimating,
        onTap: () => { /* 可触发微交互，例如抖动 */ }
      })

      // 三个滑杆控制区
      Column({ space: 12 }) {
        // Light
        Column({ space: 6 }) {
          Row() {
            Text('光照').fontSize(14).fontWeight(FontWeight.Medium)
            Blank()
            Text(`${Math.round(this.vm.light)}%`).fontSize(12).opacity(0.6)
          }
          Slider({ value: this.vm.light, min: 0, max: 100, step: 1 })
            .onChange((v: number) => { if (!this.vm.isAnimating) this.vm.setLight(Math.floor(v)); })
        }
        // Soil
        Column({ space: 6 }) {
          Row() {
            Text('土壤含水').fontSize(14).fontWeight(FontWeight.Medium)
            Blank()
            Text(`${Math.round(this.vm.soil)}%`).fontSize(12).opacity(0.6)
          }
          Slider({ value: this.vm.soil, min: 0, max: 100, step: 1 })
            .onChange((v: number) => { if (!this.vm.isAnimating) this.vm.setSoil(Math.floor(v)); })
        }
        // Humidity
        Column({ space: 6 }) {
          Row() {
            Text('环境湿度').fontSize(14).fontWeight(FontWeight.Medium)
            Blank()
            Text(`${Math.round(this.vm.humidity)}%`).fontSize(12).opacity(0.6)
          }
          Slider({ value: this.vm.humidity, min: 0, max: 100, step: 1 })
            .onChange((v: number) => { if (!this.vm.isAnimating) this.vm.setHumidity(Math.floor(v)); })
        }
      }
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .margin({ left: 16, right: 16 })
      .shadow({ radius: 6, color: '#11000000', offsetX: 0, offsetY: 1 })

      // 状态栏 + 建议
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
    .edgeEffect(EdgeEffect.Spring)
  }
}
