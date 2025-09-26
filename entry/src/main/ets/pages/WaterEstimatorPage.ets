// /page/WaterEstimatorPage.ets
// 用量估算器（V2 装饰器 / 完整页面）：输入（盆径、深度、介质、策略、植株）→ 结果区间（ml）→ 建议 → 保存日志
// 要点：UI 结构全部在 @Builder 内；UI 内不声明本地变量；所有数值直接取 VM 字段或调用方法。

import {
  RetentionType, StrategyType, PlantKind
} from '../model/WaterEstimatorTypes';
import { WaterEstimatorViewModel } from '../viewmodel/WaterEstimatorViewModel';
import WaterEstimateLog from '../model/WaterEstimateLog';

@ComponentV2
export struct WaterEstimatorPage {
  @Param plantId: string = '';
  @Local vm: WaterEstimatorViewModel = new WaterEstimatorViewModel('');

  aboutToAppear() {
    if (this.plantId && this.plantId !== '') {
      this.vm = new WaterEstimatorViewModel(this.plantId);
    } else {
      this.vm = new WaterEstimatorViewModel('PLANT_DEMO');
    }
  }

  build() {
    Scroll() {
      Column({ space: 14 }) {
        this.Header()
        this.SizeCard()
        this.OptionCard()
        this.ResultCard()
        this.SaveBar()
        this.LogList()
      }
    }
    .backgroundColor('#FAFAFA')
    .edgeEffect(EdgeEffect.Spring)
  }

  // ===== Header =====
  @Builder Header() {
    Row() {
      Column() {
        Text('用量估算器').fontSize(22).fontWeight(FontWeight.Medium)
        Text(`植物ID：${this.vm.plantId}`).fontSize(12).opacity(0.6)
      }
      Blank()
      Row({ space: 8 }) {
        Button('重置').type(ButtonType.Normal).onClick(() => {
          this.vm.setDiameter(14);
          this.vm.setDepth(12);
          this.vm.setRetention(RetentionType.GENERAL);
          this.vm.setStrategy(StrategyType.MAINT);
          this.vm.setPlant(PlantKind.FOLIAGE);
          animateTo({ duration: 200, curve: Curve.EaseOut }) { }
        })
      }
    }
    .padding({ left: 16, right: 16, top: 12 })
  }

  // ===== 尺寸卡：盆径/深度 =====
  @Builder SizeCard() {
    Column({ space: 12 }) {
      Text('盆器尺寸').fontSize(16).fontWeight(FontWeight.Medium)
      // 盆径
      Column({ space: 6 }) {
        Text(`盆径：${this.vm.diameterCm} cm`).fontSize(14)
        Slider({ value: this.vm.diameterCm, min: 6, max: 60, step: 1 })
          .onChange((v: number) => this.vm.setDiameter(Math.floor(v)))
      }
      // 深度
      Column({ space: 6 }) {
        Text(`深度：${this.vm.depthCm} cm`).fontSize(14)
        Slider({ value: this.vm.depthCm, min: 6, max: 60, step: 1 })
          .onChange((v: number) => this.vm.setDepth(Math.floor(v)))
      }

      // 快捷步进
      Row({ space: 8 }) {
        Button('- 盆径').type(ButtonType.Normal).onClick(() => this.vm.setDiameter(this.vm.diameterCm - 1))
        Button('+ 盆径').type(ButtonType.Normal).onClick(() => this.vm.setDiameter(this.vm.diameterCm + 1))
        Blank()
        Button('- 深度').type(ButtonType.Normal).onClick(() => this.vm.setDepth(this.vm.depthCm - 1))
        Button('+ 深度').type(ButtonType.Normal).onClick(() => this.vm.setDepth(this.vm.depthCm + 1))
      }
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({ radius: 6, color: '#11000000', offsetX: 0, offsetY: 1 })
    .margin({ left: 16, right: 16 })
  }

  // ===== 选项卡：介质/策略/植株 =====
  @Builder OptionCard() {
    Column({ space: 12 }) {
      Text('介质 / 策略 / 植株').fontSize(16).fontWeight(FontWeight.Medium)

      // 介质
      Column({ space: 8 }) {
        Text(`介质：${this.vm.labelRetention()}`).fontSize(14)
        Row({ space: 8 }) {
          this.Chip('砂砾/透水', this.vm.retention === RetentionType.SANDY, () => this.vm.setRetention(RetentionType.SANDY))
          this.Chip('通用介质', this.vm.retention === RetentionType.GENERAL, () => this.vm.setRetention(RetentionType.GENERAL))
          this.Chip('泥炭/保水', this.vm.retention === RetentionType.PEATY, () => this.vm.setRetention(RetentionType.PEATY))
        }
      }

      // 策略
      Column({ space: 8 }) {
        Text(`策略：${this.vm.labelStrategy()}`).fontSize(14)
        Row({ space: 8 }) {
          this.Chip('彻底浸润', this.vm.strategy === StrategyType.FULL, () => this.vm.setStrategy(StrategyType.FULL))
          this.Chip('日常保养', this.vm.strategy === StrategyType.MAINT, () => this.vm.setStrategy(StrategyType.MAINT))
        }
      }

      // 植株
      Column({ space: 8 }) {
        Text(`植株：${this.vm.labelPlant()}`).fontSize(14)
        Row({ space: 8 }) {
          this.Chip('多肉', this.vm.plant === PlantKind.SUCC, () => this.vm.setPlant(PlantKind.SUCC))
          this.Chip('观叶', this.vm.plant === PlantKind.FOLIAGE, () => this.vm.setPlant(PlantKind.FOLIAGE))
        }
      }
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({ radius: 6, color: '#11000000', offsetX: 0, offsetY: 1 })
    .margin({ left: 16, right: 16 })
  }

  // —— Chip ——（无局部变量，直接使用参数）
  @Builder Chip(text: string, on: boolean, action: () => void) {
    Row() {
      Text(text).fontSize(13).fontWeight(on ? FontWeight.Medium : FontWeight.Normal)
        .padding({ left: 10, right: 10, top: 6, bottom: 6 })
    }
    .backgroundColor(on ? '#E0F2F1' : '#F2F3F5')
    .borderRadius(14)
    .onClick(() => { action(); })
  }

  // ===== 结果卡 =====
  @Builder ResultCard() {
    Column({ space: 10 }) {
      Text('估算结果（毫升）').fontSize(16).fontWeight(FontWeight.Medium)
      Row({ space: 12 }) {
        this.ResultPill('下限', this.vm.low)
        this.ResultPill('推荐', this.vm.mid)
        this.ResultPill('上限', this.vm.high)
      }
      Text(this.vm.getSuggestText()).fontSize(12).opacity(0.8).margin({ top: 2 })
      Text(this.vm.getFormulaBrief()).fontSize(10).opacity(0.5)
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({ radius: 6, color: '#11000000', offsetX: 0, offsetY: 1 })
    .margin({ left: 16, right: 16 })
  }

  @Builder ResultPill(label: string, value: number) {
    Column() {
      Text(label).fontSize(12).opacity(0.6)
      Text(`${value} ml`).fontSize(18).fontWeight(FontWeight.Medium).margin({ top: 2 })
    }
    .padding({ left: 12, right: 12, top: 10, bottom: 10 })
    .backgroundColor('#F7FAF8')
    .borderRadius(14)
  }

  // ===== 保存区 =====
  @Builder SaveBar() {
    Column({ space: 10 }) {
      Text('备注（可选）').fontSize(14).opacity(0.8)
      TextInput({ placeholder: '记录本次估算的环境/植株状态等...', text: '' })
        .onChange((v: string) => {
          // 这里不存中间态，点击保存时再传入（避免页面大量状态字段）
        })
        .id('note_input')
        .height(38).backgroundColor('#FFFFFF').borderRadius(10).padding({ left: 10, right: 10 })

      Row({ space: 10 }) {
        Button('保存估算记录').type(ButtonType.Capsule).backgroundColor('#26A69A')
          .onClick(() => {
            // 读取输入框文本
            const ctx = this.getUIContext();
            if (ctx !== undefined) {
              const note: string = ctx.getInspectorById('note_input')?.getAttribute('value') ?? '';
              const log: WaterEstimateLog = this.vm.saveLog(note);
              animateTo({ duration: 200, curve: Curve.EaseOut }) { }
            }
          })
        Button('用“推荐”记一笔浇水').type(ButtonType.Normal)
          .onClick(() => {
            // 此处只做视觉反馈/提示；真正落账你可在业务里接 CareTask
            animateTo({ duration: 220, curve: Curve.EaseOutBack }) { }
          })
      }
    }
    .padding({ left: 16, right: 16 })
  }

  // ===== 历史记录列表 =====
  @Builder LogList() {
    Column({ space: 10 }) {
      Row() {
        Text('历史估算记录').fontSize(16).fontWeight(FontWeight.Medium)
        Blank()
      }
      if (this.vm.logs.length === 0) {
        Column() {
          Text('暂无记录').fontSize(12).opacity(0.6)
        }
        .height(60).width('100%').justifyContent(FlexAlign.Center)
        .backgroundColor('#FFFFFF').borderRadius(10)
        .margin({ left: 16, right: 16, bottom: 16 })
      } else {
        List() {
          ForEach(this.vm.logs, (it: WaterEstimateLog) => {
            ListItem() {
              Row({ space: 10 }) {
                Column({ space: 2 }) {
                  Text(new Date(it.createdAt).toLocaleString()).fontSize(12).opacity(0.7)
                  Text(`盆径${it.diameterCm}cm 深度${it.depthCm}cm · ${it.low}-${it.high}ml（推${it.mid}ml）`)
                    .fontSize(12).maxLines(2)
                  if (it.note !== '') {
                    Text(it.note).fontSize(12).opacity(0.8).maxLines(2)
                  }
                }
                Blank()
              }
              .padding(10)
              .backgroundColor('#FFFFFF')
              .borderRadius(12)
              .margin({ left: 16, right: 16 })
            }
          }, (it: WaterEstimateLog) => it.id)
        }
        .margin({ bottom: 16 })
      }
    }
  }
}
