// /page/GrowthComparePage.ets
// 页面：前后对比（选择图片→对齐→滑动对比→保存对比卡列表）
// - V2 装饰器 & Navigation 友好：@Param plantId 由上层路由传入；不使用 Router.*
// - 图片选择使用 MediaLibraryKit 的 PhotoViewPicker（系统自带图库选择器）

import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { GrowthCompareViewModel } from '../viewmodel/GrowthCompareViewModel';
// import CompareSliderV2 from '../component/CompareSliderV2';
import GrowthPair from '../model/GrowthPair';
import { CompareSliderV2 } from './CompareSliderV2';
import { AddImageFileViewModel } from '../viewmodel/AddImageFileViewModel';
import { common } from '@kit.AbilityKit';

@ComponentV2
export struct GrowthComparePage {
  private context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;

  // 路由参数
  @Param plantId: number = 0;

  // 本地 VM（V2）
  @Local vm: GrowthCompareViewModel = new GrowthCompareViewModel(0);

  private addImageFileViewModel:AddImageFileViewModel = AddImageFileViewModel.getInstance(this.context)

  aboutToAppear() {
    if (this.plantId && this.plantId !== 0) {
      this.vm = new GrowthCompareViewModel(this.plantId);
    } else {
      this.vm = new GrowthCompareViewModel(0);
    }
  }

  build() {
    Column({ space: 12 }) {
      // 顶部标题与工具
      Row() {
        Column() {
          Text('成长对比').fontSize(22).fontWeight(FontWeight.Medium)
          Text(`植物ID：${this.vm.plantId}`).fontSize(12).opacity(0.6)
        }
        Blank()
        this.TopActions()
      }
      .padding({ left: 16, right: 16, top: 12 })

      // 选择区（前/后）
      this.SelectorBar()

      // 对比滑块
      CompareSliderV2({
        beforeUri: this.vm.beforeUri,
        afterUri: this.vm.afterUri,
        split: this.vm.split,
        zoom: this.vm.zoom,
        offsetX: this.vm.offsetX,
        offsetY: this.vm.offsetY,
        showGrid: this.vm.showGrid,
        alignMode: this.vm.alignMode,
        onSplitChange: (v: number) => {
          this.vm.setSplit(v);
        },
        onAlignChange: (z: number, x: number, y: number) => {
          this.vm.setZoom(z);
          this.vm.offsetX = x;
          this.vm.offsetY = y;
        }
      })
        .margin({ left: 16, right: 16 })

      // 微调工具条
      this.AlignToolbar()

      // 保存 & 列表
      this.SaveBar()
      this.PairsList()
    }
    // .backgroundColor('#FAFAFA')
    // .edgeEffect(EdgeEffect.Spring)
  }

  @Builder
  TopActions() {
    Row({ space: 8 }) {
      Button(this.vm.alignMode ? '对齐中' : '对齐').type(ButtonType.Normal)
        .onClick(() => { this.vm.toggleAlignMode(); })
      Button(this.vm.showGrid ? '隐藏网格' : '显示网格').type(ButtonType.Normal)
        .onClick(() => { this.vm.toggleGrid(); })
      Button('重置对齐').type(ButtonType.Normal)
        .onClick(() => { this.vm.resetAlign(); })
      Button('互换前后').type(ButtonType.Capsule)
        .onClick(() => { this.vm.swap(); })
    }
  }

  @Builder
  SelectorBar() {
    Column({ space: 10 }) {
      // Row({ space: 12 }) {
        // 选择前照
        this.SelectCard('选择前照', this.vm.beforeUri, true)
        // 选择后照
        this.SelectCard('选择后照', this.vm.afterUri, false)
      // }
    }
    .padding({ left: 16, right: 16 })
  }

  @Builder SelectCard(title: string, uri: string, isBefore: boolean) {
    Column({ space: 8 }) {
      Text(title).fontSize(14).opacity(0.8)
      Row() {
        if (uri === '') {
          Column() {
            Text('未选择').fontSize(12).opacity(0.5)
          }
          .width('100%').height(44)
          .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
          .backgroundColor('#FFFFFF').borderRadius(12)
          .onClick(() => { this.pickPhoto(isBefore); })
        } else {
          Row() {
            Text(uri).fontSize(12).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
            Blank()
            Button('更换').type(ButtonType.Normal).onClick(() => { this.pickPhoto(isBefore); })
          }
          .padding(10)
          .backgroundColor('#FFFFFF').borderRadius(12)
        }
      }
    }
  }

  @Builder AlignToolbar() {
    Column({ space: 10 }) {
      Text('分割位置与缩放/平移（对齐在“对齐”模式下单指拖动后图，双指缩放）')
        .fontSize(12).opacity(0.6)
      Column({ space: 12 }) {
        // 分割滑杆（与组件内的滑杆保持同步）
        Column() {
          Text(`分割：${Math.floor(this.vm.split * 100)}%`).fontSize(12).opacity(0.7)
          Slider({ value: this.vm.split, min: 0.02, max: 0.98, step: 0.01 })
            .onChange((v: number) => this.vm.setSplit(v))
        }.width('45%')
        // 缩放
        Column() {
          Text(`缩放：${this.vm.zoom.toFixed(2)}x`).fontSize(12).opacity(0.7)
          Slider({ value: this.vm.zoom, min: 0.5, max: 4.0, step: 0.01 })
            .onChange((v: number) => this.vm.setZoom(v))
        }.width('25%')
        // 平移X
        Column() {
          Text(`X：${Math.floor(this.vm.offsetX)}vp`).fontSize(12).opacity(0.7)
          Slider({ value: this.vm.offsetX, min: -600, max: 600, step: 1 })
            .onChange((v: number) => { this.vm.offsetX = Math.floor(v); })
        }.width('15%')
        // 平移Y
        Column() {
          Text(`Y：${Math.floor(this.vm.offsetY)}vp`).fontSize(12).opacity(0.7)
          Slider({ value: this.vm.offsetY, min: -600, max: 600, step: 1 })
            .onChange((v: number) => { this.vm.offsetY = Math.floor(v); })
        }.width('15%')
      }
    }
    .padding({ left: 16, right: 16 })
  }

  @Builder SaveBar() {
    Column({ space: 10 }) {
      Row() {
        Text('备注').fontSize(14).opacity(0.8)
        Blank()
      }
      TextInput({ placeholder: '可填写拍摄时间/养护要点等...', text: this.vm.note })
        .onChange((v: string) => { this.vm.note = v; })
        .height(38).backgroundColor('#FFFFFF').borderRadius(10).padding({ left: 10, right: 10 })

      Row({ space: 10 }) {
        Button('保存对比卡').type(ButtonType.Capsule)
          .backgroundColor(this.vm.canSave() ? '#26A69A' : '#BDBDBD')
          .onClick(() => {
            if (this.vm.canSave()) {
              const p: GrowthPair | undefined = this.vm.savePair();
              if (p) {
                // animateTo({ duration: 200, curve: Curve.EaseOut }) { /* 微动效 */ }
              }
            }
          })
        Text(this.vm.canSave() ? '' : '请先选择前照与后照').fontSize(12).opacity(0.5)
      }
    }
    .padding({ left: 16, right: 16 })
  }

  @Builder PairsList() {
    Column({ space: 10 }) {
      Row() {
        Text('已保存的对比卡').fontSize(16).fontWeight(FontWeight.Medium)
        Blank()
      }
      if (this.vm.pairs.length === 0) {
        Column() {
          Text('暂无对比卡').fontSize(12).opacity(0.6)
        }
        .height(60).width('100%').justifyContent(FlexAlign.Center)
        .backgroundColor('#FFFFFF').borderRadius(10)
        .margin({ bottom: 16 })
      } else {
        List() {
          ForEach(this.vm.pairs, (p: GrowthPair) => {
            ListItem() {
              Row({ space: 10 }) {
                // 小缩略（并排 2 图）
                Row() {
                  Image(p.beforeUri).width(72).height(54).objectFit(ImageFit.Cover).borderRadius(6)
                  Image(p.afterUri).width(72).height(54).objectFit(ImageFit.Cover).borderRadius(6).margin({ left: 6 })
                }
                Column({ space: 4 }) {
                  Text(new Date(p.createdAt).toLocaleString()).fontSize(12).opacity(0.7)
                  Text(p.note === '' ? '无备注' : p.note).fontSize(12).maxLines(2)
                }
                Blank()
              }
              .padding(10)
              .backgroundColor('#FFFFFF')
              .borderRadius(12)
            }
          }, (p: GrowthPair) => p.id)
        }
        .margin({ bottom: 16 })
      }
    }
    .padding({ left: 16, right: 16 })
  }

  // 选择图片
  private async pickPhoto(isBefore: boolean): Promise<void> {
    try {
      this.addImageFileViewModel.selectAndProcessImages([],(newImage)=>{
        // 返回为永久授权的 photoUris
        const res = newImage[0]
        if (newImage && res.path && res.path.length > 0) {
          // const uri: string = res.photoUris[0];
          if (isBefore) {
            this.vm.setBefore(res.path);
          } else {
            this.vm.setAfter(res.path);
          }
        }
      },1)

    } catch (e) {
      // 选择被取消或权限问题，静默处理
    }
  }
}
