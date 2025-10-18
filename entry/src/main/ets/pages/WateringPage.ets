// /page/WateringPage.ets
// 浇水动画页（完整实现）
// - V2 装饰器，UI 在 @Builder 中，状态/逻辑在 ViewModel
// - 点击浇水按钮播放动画（粒子 + 波纹 + 叶片反应），生成 WaterRecord 返回（页面可写入 DB）
// - 提供“跳过动画直接记录”按钮用于无障碍或低性能设备

import { ComponentV2, Param, Local } from '@ohos.aafwk.ace';
import { WateringViewModel } from '../viewmodel/WateringViewModel';
import WaterParticle from '../component/WaterParticle';
import WaterRecord from '../model/WaterRecord';

@ComponentV2
export struct WateringPage {
  @Param plantId: string = '';

  @Local vm: WateringViewModel = new WateringViewModel('');
  @Local inputAmount: number = 100; // 用户可输入的 ml 值（临时输入，UI 内不声明变量）
  @Local animPhase: number = 0; // 0=idle,1=playing,2=ending
  @Local lastRecordedText: string = '';

  aboutToAppear() {
    if (this.plantId && this.plantId !== '') {
      this.vm = new WateringViewModel(this.plantId);
    } else {
      this.vm = new WateringViewModel('PLANT_DEMO');
    }
    // 默认量根据 vm.defaultAmount
    this.inputAmount = this.vm.defaultAmount;
  }

  @Builder build() {
    Column({ space: 12 }) {
      // Header
      Row() {
        Column() {
          Text('浇水').fontSize(22).fontWeight(FontWeight.Medium)
          Text('给植物一个仪式感：浇水动画 + 记录').fontSize(12).opacity(0.6)
        }
        Blank()
        Row({ space: 8 }) {
          Text(`连胜：${this.vm.streakDays} 天`).fontSize(14).opacity(0.8)
        }
      }
      .padding({ left: 16, right: 16, top: 12 })

      // 中央展示区（植物 + 动画叠加）
      Stack({ alignContent: Alignment.Center }) {
        // 背景卡（展示植物、土壤条）
        Column({ space: 8 }) {
          // 模拟植物（简易）
          Column({ space: 6 }) {
            Column()
              .width('100%').height(200)
              .backgroundColor('#FFFFFF')
              .borderRadius(12)
              .shadow({ radius: 8, color: '#22000000', offsetX: 0, offsetY: 4 })
              .padding(12)
            // 土壤条
            Row() {
              Column().width('80%').height(12).backgroundColor('#9E6B3F').borderRadius(6)
              Blank()
              Column().width('20%').height(12).backgroundColor('#F0F0F0').borderRadius(6)
            }.margin({ top: -28 }).alignItems(HorizontalAlign.Center)
          }
        }

        // 动画层（当 animPhase=1 时显示粒子）
        Column() {
          if (this.animPhase === 1) {
            WaterParticle({ intensity: this.particleIntensity(), isAnimating: true, onAnimationEnd: () => { this.onParticleEnd(); }})
          } else {
            // 显示一颗静态水滴或提示
            Column() {
              Text(this.animPhase === 2 ? '浇水完成！' : '准备浇水').fontSize(16).opacity(0.8)
            }
          }
        }
      }
      .margin({ left: 16, right: 16 })
      .height(220)

      // 操作：模式选择 + 输入量
      Column({ space: 10 }) {
        Row({ space: 8 }) {
          // 模式按钮（浅/深）
          Button(this.vm.mode === 'light' ? '浅浇 (快捷)' : '浅浇').type(this.vm.mode === 'light' ? ButtonType.Capsule : ButtonType.Normal)
            .onClick(() => { this.vm.setMode('light'); this.inputAmount = this.vm.defaultAmount; })
          Button(this.vm.mode === 'deep' ? '浇透 (长按)' : '浇透').type(this.vm.mode === 'deep' ? ButtonType.Capsule : ButtonType.Normal)
            .onClick(() => { this.vm.setMode('deep'); this.inputAmount = this.vm.defaultAmount * 3; })
          Blank()
          Text('量 (ml)').fontSize(12).opacity(0.6)
          TextInput({ placeholder: '输入量(ml)', text: '' })
            .onChange((v: string) => {
              // 容错：非数字忽略
              let n: number = Number.parseInt(v);
              if (Number.isNaN(n)) { n = this.inputAmount; }
              this.inputAmount = Math.max(0, n);
            })
            .width(100).height(36).backgroundColor('#FFFFFF').borderRadius(8).padding({ left: 8 })
        }

        // 大按钮组
        Row({ space: 10 }) {
          Button('浇水并记录').type(ButtonType.Capsule)
            .backgroundColor('#26A69A')
            .onClick(() => { this.fireWatering(false); })
          Button('跳过动画直接记录').type(ButtonType.Normal)
            .onClick(() => { this.fireWatering(true); })
          Button('查看历史').type(ButtonType.Normal)
            .onClick(() => { /* 可在此跳到历史页或弹窗 */ })
        }
      }
      .padding({ left: 16, right: 16 })

      // 记录反馈与历史简表
      Column({ space: 8 }) {
        if (this.lastRecordedText !== '') {
          Text(this.lastRecordedText).fontSize(12).opacity(0.7)
        }
        // 最近几次时间
        if (this.vm.recentTimes.length === 0) {
          Text('暂无浇水记录').fontSize(12).opacity(0.6)
        } else {
          Column({ space: 6 }) {
            ForEach<number>(this.vm.recentTimes, (t: number) => {
              Row() {
                Text(this.vm.fmtDate(t)).fontSize(12)
                Blank()
              }
            }, (t: number) => '' + t)
          }
        }
      }
      .padding({ left: 16, right: 16, bottom: 20 })

    }
    .backgroundColor('#FAFAFA')
    .edgeEffect(EdgeEffect.Spring)
  }

  // 页面内方法（不能在 UI 中声明局部变量）
  private particleIntensity(): number {
    return this.vm.mode === 'deep' ? 3 : 1;
  }

  // 触发浇水流程
  private fireWatering(skipAnimation: boolean): void {
    if (skipAnimation) {
      // 直接记录
      const rec: WaterRecord = this.vm.recordWater(this.inputAmount);
      this.lastRecordedText = `已记录 ${rec.amountMl}ml（${rec.mode}） ${new Date(rec.createdAt).toLocaleString()}`;
      // 若你要写入 DB 在这里接入：例如使用 RdbManager 插入 log 表或 task 标记
      return;
    }

    // 启动动画流程
    this.animPhase = 1;
    this.vm.startAnimation();
    // 页面管理动画时序（不使用 setTimeout 的真实 API 仅示意，实际 environment 支持）
    // 下面用一系列的 animateTo 等价占位逻辑：
    // 1) 动画持续 timeA(ms)，此处用伪异步：start -> after X ms -> call onParticleEnd
    // 实现上：若平台支持 Promise/async setTimeout，请在此替换为具体 API；
    // 为保证代码完整性，这里用一个简单的模拟函数（伪代码注释），并在结束时调用 onParticleEnd。
    this.innerPlaySequence();
  }

  // 播放序列（控制 animPhase 与调用 VM.recordWater）
  private async innerPlaySequence(): Promise<void> {
    // 标记播放中
    this.animPhase = 1;
    this.vm.startAnimation();
    // 时长按模式： light=1100ms deep=2000ms
    const duration: number = this.vm.mode === 'deep' ? 2000 : 1100;
    // 使用全局 setTimeout（ArkTS 环境通常支持），若你的工程封装了 time api，请按项目替换
    setTimeout(() => {
      // 粒子结束回调
      this.onParticleEnd();
    }, duration);
  }

  // 动画结束处理：记录并把界面移到完成状态
  private onParticleEnd(): void {
    // 结束动画
    this.vm.stopAnimation();
    this.animPhase = 2;
    // 记录（默认使用 inputAmount）
    const rec: WaterRecord = this.vm.recordWater(this.inputAmount);
    this.lastRecordedText = `已记录 ${rec.amountMl}ml（${rec.mode}） ${new Date(rec.createdAt).toLocaleString()}`;
    // 完成态保持一段时间后回到 idle
    setTimeout(() => { this.animPhase = 0; }, 900);
    // 若需持久化，请在此调用 RdbManager 插入 log / task（示例伪代码在注释里）
    // 例：
    // const note = JSON.stringify({ type: 'WATER', amount: rec.amountMl, mode: rec.mode });
    // await RdbManager.getInstance().rdbStore.insert(RdbManager.T_LOG, { plantId: rec.plantId, note, createdAt: rec.createdAt, category:'WATER' });
  }
}
