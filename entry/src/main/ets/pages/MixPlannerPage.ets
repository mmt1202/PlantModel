// /page/MixPlannerPage.ets
// 土壤配方调配器（V2）：选择内置/我的/自定义 → 编辑材料 → 设定总量 → 计算体积/重量 → 保存为配方/保存调配记录
// 规则：UI结构均在 @Builder；UI内不声明本地变量；事件中调用 VM 方法；Navigation 通过 @Param 传入 plantId（可为空）。

import MixRecipe, { MixItem } from '../model/MixRecipe';
import MixRun, { MixResultItem } from '../model/MixRun';
import { MixPlannerViewModel } from '../viewmodel/MixPlannerViewModel';

@CustomDialog
struct SaveRecipeDialog {
  controller: CustomDialogController;
  @Require onConfirm: (name: string, note: string) => void;

  @State name: string = '';
  @State note: string = '';

  build() {
    Column({ space: 10 }) {
      Text('保存为我的配方').fontSize(18).fontWeight(FontWeight.Medium)
      TextInput({ placeholder: '配方名称（必填）', text: this.name })
        .onChange((v: string) => { this.name = v; })
        .height(38).backgroundColor('#F4F6F8').borderRadius(10).padding({ left: 10, right: 10 })
      TextInput({ placeholder: '备注（可选）', text: this.note })
        .onChange((v: string) => { this.note = v; })
        .height(38).backgroundColor('#F4F6F8').borderRadius(10).padding({ left: 10, right: 10 })
      Row({ space: 10 }) {
        Button('取消').onClick(() => this.controller.close())
        Button('保存').type(ButtonType.Capsule)
          .backgroundColor('#26A69A')
          .onClick(() => { this.onConfirm(this.name, this.note); this.controller.close(); })
      }.justifyContent(FlexAlign.End).margin({ top: 6 })
    }
    .padding(16).backgroundColor('#FFFFFF').borderRadius(16)
  }
}

@ComponentV2
export struct MixPlannerPage {
  @Param plantId: string = '';
  @Local vm: MixPlannerViewModel = new MixPlannerViewModel('');

  private saveDlg: CustomDialogController = new CustomDialogController({
    builder: SaveRecipeDialog({ onConfirm: (name: string, note: string) => {
      const rec = this.vm.saveMyRecipe(name, note);
      if (rec) {
        // animateTo({ duration: 200, curve: Curve.EaseOut }) { }
      }
    }})
  });

  aboutToAppear() {
    if (this.plantId && this.plantId !== '') {
      this.vm = new MixPlannerViewModel(this.plantId);
    } else {
      this.vm = new MixPlannerViewModel('PLANT_DEMO');
    }
  }

  build() {
    Scroll() {
      Column({ space: 14 }) {
        this.Header()
        this.RecipeSelector()
        this.ItemsEditor()
        this.TotalAndCompute()
        this.ResultCard()
        this.ActionsBar()
        this.MyRecipesList()
        this.RunHistoryList()
      }
    }
    .backgroundColor('#FAFAFA')
    .edgeEffect(EdgeEffect.Spring)
  }

  // ===== Header =====
  @Builder Header() {
    Row() {
      Column() {
        Text('土壤配方调配器').fontSize(22).fontWeight(FontWeight.Medium)
        Text(`植物ID：${this.vm.plantId}`).fontSize(12).opacity(0.6)
      }
      Blank()
      Button('恢复默认').type(ButtonType.Normal).onClick(() => {
        // this.vm['loadDefaultCustom'](); // 本地演示调用；你也可改成公开方法
        // animateTo({ duration: 180, curve: Curve.EaseOut }) { }
      })
    }
    .padding({ left: 16, right: 16, top: 12 })
  }

  // ===== 选择配方（内置 / 我的 / 自定义） =====
  @Builder RecipeSelector() {
    Column({ space: 10 }) {
      Text(`当前：${this.vm.recipeName}`).fontSize(14).opacity(0.8)
      // 内置
      Column({ space: 6 }) {
        Text('内置配方').fontSize(14).fontWeight(FontWeight.Medium)
        Row({ space: 8 }) {
          ForEach(this.vm.builtinRecipes, (r: MixRecipe, i?: number) => {
            this.Chip(r.name, false, () => this.vm.chooseBuiltin(i as number))
          }, (r: MixRecipe) => r.id)
          this.Chip('自定义', false, () => {
            // this.vm['loadDefaultCustom']();
          })
        }
      }
      // 我的配方（若有）
      if (this.vm.myRecipes.length > 0) {
        Column({ space: 6 }) {
          Text('我的配方').fontSize(14).fontWeight(FontWeight.Medium)
          Row({ space: 8 }) {
            ForEach(this.vm.myRecipes, (r: MixRecipe, i?: number) => {
              this.Chip(r.name, false, () => this.vm.chooseMyRecipe(i as number))
            }, (r: MixRecipe) => r.id)
          }
        }
      }
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({ radius: 6, color: '#11000000', offsetX: 0, offsetY: 1 })
    .margin({ left: 16, right: 16 })
  }

  @Builder Chip(text: string, on: boolean, action: () => void) {
    Row() {
      Text(text).fontSize(13).fontWeight(on ? FontWeight.Medium : FontWeight.Normal)
        .padding({ left: 10, right: 10, top: 6, bottom: 6 })
    }
    .backgroundColor(on ? '#E0F2F1' : '#F2F3F5')
    .borderRadius(14)
    .onClick(() => { action(); })
  }

  // ===== 材料编辑 =====
  @Builder ItemsEditor() {
    Column({ space: 10 }) {
      Row() {
        Text('材料与配比').fontSize(16).fontWeight(FontWeight.Medium)
        Blank()
        Button('添加材料').type(ButtonType.Normal).onClick(() => this.vm.addItem())
      }
      // 提示：不在UI里声明变量，所需数值直接从VM读取
      ForEach(this.vm.items, (it: MixItem) => {
        this.ItemRow(it)
      }, (it: MixItem) => it.id)

      Row() {
        Text(`总配比：${this.vm.sumRatio().toFixed(2)}`).fontSize(12).opacity(0.6)
      }
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({ radius: 6, color: '#11000000', offsetX: 0, offsetY: 1 })
    .margin({ left: 16, right: 16 })
  }

  @Builder ItemRow(it: MixItem) {
    Column() {
      Row() {
        TextInput({ placeholder: '材料名', text: it.name })
          .onChange((v: string) => this.vm.setItemName(it.id, v))
          .height(36).backgroundColor('#F7F8FA').borderRadius(10).padding({ left: 10, right: 10 }).width('45%')
        Text(`配比：${it.ratio.toFixed(2)}`).fontSize(12).opacity(0.7).margin({ left: 8, right: 8 })
        Slider({ value: it.ratio, min: 0.1, max: 99, step: 0.1 })
          .onChange((v: number) => this.vm.setItemRatio(it.id, Math.round(v * 10) / 10))
          .width('35%')
        Button('删除').type(ButtonType.Normal).onClick(() => this.vm.removeItem(it.id))
      }.margin({ bottom: 6 })

      Row({ space: 8 }) {
        TextInput({ placeholder: '密度 kg/L（0=默认0.15）', text: it.density.toString() })
          .onChange((v: string) => {
            // 容错：空串/非法 -> 0
            let dv: number = 0;
            if (v !== '') {
              const n: number = Number.parseFloat(v);
              if (!Number.isNaN(n)) { dv = n; }
            }
            this.vm.setItemDensity(it.id, dv);
          })
          .height(34).backgroundColor('#F7F8FA').borderRadius(10).padding({ left: 10, right: 10 }).width('65%')
        // 快选常见密度
        this.DensityQuickPick(it.id)
      }
      Divider().margin({ top: 10 })
    }
    .padding({ top: 8, bottom: 8 })
  }

  @Builder DensityQuickPick(id: string) {
    Row({ space: 6 }) {
      this.DQuick('泥炭0.12', () => this.vm.setItemDensity(id, 0.12))
      this.DQuick('珍珠岩0.10', () => this.vm.setItemDensity(id, 0.10))
      this.DQuick('树皮0.18', () => this.vm.setItemDensity(id, 0.18))
      this.DQuick('轻石0.25', () => this.vm.setItemDensity(id, 0.25))
      this.DQuick('默认0.15', () => this.vm.setItemDensity(id, 0.15))
    }
  }

  @Builder DQuick(text: string, action: () => void) {
    Row() {
      Text(text).fontSize(11)
        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
    }
    .backgroundColor('#EEF5F4')
    .borderRadius(10)
    .onClick(() => action())
  }

  // ===== 总量与计算 =====
  @Builder TotalAndCompute() {
    Column({ space: 10 }) {
      Text(`目标总量：${this.vm.totalLiters} L`).fontSize(16).fontWeight(FontWeight.Medium)
      Slider({ value: this.vm.totalLiters, min: 1, max: 200, step: 1 })
        .onChange((v: number) => this.vm.setTotalLiters(Math.floor(v)))
      Row({ space: 8 }) {
        Button('-1L').type(ButtonType.Normal).onClick(() => this.vm.setTotalLiters(this.vm.totalLiters - 1))
        Button('+1L').type(ButtonType.Normal).onClick(() => this.vm.setTotalLiters(this.vm.totalLiters + 1))
        Blank()
        Text('提示：比例按权重分配到总量。密度仅用于估算重量。').fontSize(11).opacity(0.6)
      }
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({ radius: 6, color: '#11000000', offsetX: 0, offsetY: 1 })
    .margin({ left: 16, right: 16 })
  }

  // ===== 结果卡 =====
  @Builder ResultCard() {
    Column({ space: 10 }) {
      Text('计算结果').fontSize(16).fontWeight(FontWeight.Medium)
      // 直接将 VM 的计算结果用于渲染，不在UI里声明变量
      ForEach(this.vm.compute(), (r: MixResultItem) => {
        Row() {
          Text(r.name).fontSize(14).width('40%')
          Text(`${r.liters} L`).fontSize(14).width('30%')
          Text(`${r.kg} kg`).fontSize(14).width('30%').opacity(0.8)
        }
        .padding(10).backgroundColor('#FFFFFF').borderRadius(12).margin({ bottom: 6 })
      }, (r: MixResultItem) => r.name + '_' + r.liters)
      Text('说明：若密度为0，则默认按0.15kg/L估算重量。').fontSize(11).opacity(0.6)
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({ radius: 6, color: '#11000000', offsetX: 0, offsetY: 1 })
    .margin({ left: 16, right: 16 })
  }

  // ===== 操作栏：保存为我的配方 / 保存调配记录 =====
  @Builder ActionsBar() {
    Column({ space: 10 }) {
      Row({ space: 10 }) {
        Button('保存为我的配方').type(ButtonType.Capsule)
          .onClick(() => this.saveDlg.open())
        Button('保存这次调配').type(ButtonType.Normal)
          .onClick(() => {
            const run: MixRun = this.vm.saveRun('');
            // animateTo({ duration: 200, curve: Curve.EaseOut }) { }
          })
      }
      Text('你也可以在我的配方里再次选择并微调。').fontSize(11).opacity(0.6)
    }
    .padding({ left: 16, right: 16 })
  }

  // ===== 我的配方列表 =====
  @Builder MyRecipesList() {
    if (this.vm.myRecipes.length === 0) {
      Column() {
        Text('我的配方：暂无').fontSize(12).opacity(0.6)
      }
      .height(50).width('100%').justifyContent(FlexAlign.Center)
      .backgroundColor('#FFFFFF').borderRadius(12)
      .margin({ left: 16, right: 16 })
    } else {
      Column({ space: 10 }) {
        Text('我的配方').fontSize(16).fontWeight(FontWeight.Medium).margin({ left: 16, right: 16 })
        List() {
          ForEach(this.vm.myRecipes, (r: MixRecipe, i?: number) => {
            ListItem() {
              Row() {
                Column() {
                  Text(r.name).fontSize(14).fontWeight(FontWeight.Medium)
                  Text(new Date(r.createdAt).toLocaleString()).fontSize(12).opacity(0.6)
                }
                Blank()
                Button('套用').type(ButtonType.Normal).onClick(() => this.vm.chooseMyRecipe(i as number))
              }
              .padding(10).backgroundColor('#FFFFFF').borderRadius(12)
              .margin({ left: 16, right: 16, bottom: 8 })
            }
          }, (r: MixRecipe) => r.id)
        }
      }
    }
  }

  // ===== 调配记录 =====
  @Builder RunHistoryList() {
    Column({ space: 10 }) {
      Text('调配记录').fontSize(16).fontWeight(FontWeight.Medium).margin({ left: 16, right: 16 })
      if (this.vm.runs.length === 0) {
        Column() {
          Text('暂无记录').fontSize(12).opacity(0.6)
        }
        .height(50).width('100%').justifyContent(FlexAlign.Center)
        .backgroundColor('#FFFFFF').borderRadius(12)
        .margin({ left: 16, right: 16, bottom: 16 })
      } else {
        List() {
          ForEach(this.vm.runs, (r: MixRun) => {
            ListItem() {
              Column({ space: 4 }) {
                Row() {
                  Text(r.recipeName).fontSize(14).fontWeight(FontWeight.Medium)
                  Blank()
                  Text(`${r.totalLiters} L`).fontSize(12).opacity(0.7)
                }
                Text(new Date(r.createdAt).toLocaleString()).fontSize(12).opacity(0.6)
                // 摘要：前两项结果
                if (r.result.length > 0) {
                  Row() {
                    Text(`${r.result[0].name} ${r.result[0].liters}L/${r.result[0].kg}kg`).fontSize(12)
                    if (r.result.length > 1) {
                      Text(` · ${r.result[1].name} ${r.result[1].liters}L/${r.result[1].kg}kg`).fontSize(12).margin({ left: 6 })
                    }
                  }
                }
              }
              .padding(10).backgroundColor('#FFFFFF').borderRadius(12)
              .margin({ left: 16, right: 16, bottom: 8 })
            }
          }, (r: MixRun) => r.id)
        }
      }
    }
  }
}
