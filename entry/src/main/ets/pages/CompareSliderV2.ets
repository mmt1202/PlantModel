// /component/CompareSliderV2.ets
// V2 对比滑块组件：底图(before) + 顶图(after，裁剪显示) + 中央拖杆 + 手势（拖杆拖动、双指缩放、对齐平移）
// 说明：通过 onAreaChange 获取容器宽度，用“限制宽度 + clip(true)”实现裁剪；不会用到 v1 裁剪接口。

import { PinchGesture, PanGesture, LongPressGesture } from '@kit.ArkUI';

@ComponentV2
export struct CompareSliderV2 {
  // 必传参数
  @Require @Param beforeUri: string;
  @Require @Param afterUri: string;

  // 分割比例（0..1），由父级驱动 + 组件内部拖动联动
  @Require @Param split: number;

  // 对齐参数（针对 after 图）
  @Require @Param zoom: number;
  @Require @Param offsetX: number;
  @Require @Param offsetY: number;

  // 网格开关 & 对齐模式
  @Param showGrid: boolean = false;
  @Param alignMode: boolean = false;

  // 回调事件
  @Event onSplitChange: (v: number) => void = (v: number) => {};
  @Event onAlignChange: (zoom: number, offsetX: number, offsetY: number) => void =
    (zoom: number, offsetX: number, offsetY: number) => {};

  // 本地状态
  @Local containerW: number = 0;
  @Local containerH: number = 0;
  @Local previewBeforeOnly: boolean = false; // 长按预览“仅前图”

  build() {
    Column() {
      // 显示区域
      Stack({ alignContent: Alignment.Center }) {
        // 底图：before
        Image(this.beforeUri)
          .width('100%')
          .height(300)
          .objectFit(ImageFit.Cover)
            // 为了对齐预览时的一致性，这里不做变换
          .clip(true)

        // 顶图裁剪容器（宽度 = split * 容器宽度）
        // 利用 clip(true) 防止 after 图平移/缩放后溢出
        Row() {
          // after 图（可缩放、平移）
          Image(this.afterUri)
            .width('100%')
            .height(300)
            .objectFit(ImageFit.Cover)
            .scale({ x: this.zoom, y: this.zoom, centerX: '50%', centerY: '50%' })
            .translate({ x: this.offsetX, y: this.offsetY })
            .clip(true)
              // 对齐模式：单指拖动平移 after 图
            .gesture(
              this.alignMode
                ? PanGesture({ fingers: 1 })
                .onActionUpdate((e) => {
                  // e.offsetX / e.offsetY 为增量（vp）
                  this.onAlignChange(this.zoom, this.offsetX + e.offsetX, this.offsetY + e.offsetY);
                })
                : new PanGesture({ fingers: 1 }) // 非对齐模式，不消费手势
            )
              // 双指缩放
            .gesture(
              PinchGesture()
                .onActionUpdate((e) => {
                  // e.scale 为相对缩放因子
                  const nz: number = this.zoom * e.scale;
                  // 轻度跟随手势中心的平移（提升贴合感）
                  const dx: number = e.centerXOffset;
                  const dy: number = e.centerYOffset;
                  this.onAlignChange(nz, this.offsetX + dx * 0.02, this.offsetY + dy * 0.02);
                })
            )
        }
        .width(this.overlayWidth())
        .height(300)
        .clip(true)

        // 网格（叠加在最上层，弱透明）
        if (this.showGrid) {
          this.GridOverlay()
        }

        // 中央拖杆（可拖动改变 split）
        this.SplitHandle()
      }
      .onAreaChange((oldArea, newArea) => {
        this.containerW = newArea.width;
        this.containerH = newArea.height;
      })
      .height(300)
      .width('100%')
      .backgroundColor('#111111')
      .borderRadius(16)
      .clip(true)
      .shadow({ radius: 8, color: '#22000000', offsetX: 0, offsetY: 2 })
      // 长按预览“仅前图”
      .gesture(
        LongPressGesture({ repeat: false })
          .onAction((e) => {
            if (e && e.repeat === false) {
              this.previewBeforeOnly = true;
            }
          })
          .onActionEnd(() => { this.previewBeforeOnly = false; })
      )

      // 下方“精确滑杆”同步（可选；由父级决定是否显示，这里默认显示以增强可控性）
      Slider({ value: this.split, min: 0.02, max: 0.98, step: 0.01 })
        .onChange((v: number) => this.onSplitChange(v))
        .margin({ top: 10 })
    }
  }

  private overlayWidth(): number {
    if (this.previewBeforeOnly) { // 长按时隐藏 after 层
      return 0;
    }
    if (this.containerW <= 0) {
      return 0; // 初始布局尚未测到宽度
    }
    const w: number = Math.floor(this.containerW * this.split);
    if (w < 2) { return 2; }
    return w;
  }

  // 拖杆（中线 + 拖动区）
  private SplitHandle() {
    const x: number = this.overlayWidth();
    // 拖动区宽一些以提升命中（28vp）
    Column() {
      // 可视化中线
      Divider()
        .strokeWidth(2)
        .color('#88FFFFFF')
        .height('100%')
      // 中心圆点
      Row() {
        Blank()
        Column()
          .width(20).height(20)
          .borderRadius(10)
          .backgroundColor('#FFFFFF')
          .opacity(0.9)
          .shadow({ radius: 4, color: '#33000000', offsetX: 0, offsetY: 1 })
          .margin({ top: -160 }) // 提升视觉权重
        Blank()
      }.width(28)
    }
    .width(28)
    .height('100%')
    .position({ x: x - 14, y: 0 }) // 让中线居中于裁剪边缘
    .gesture(
      PanGesture({ fingers: 1 })
        .onActionUpdate((e) => {
          if (this.containerW > 0) {
            const nx: number = x + e.offsetX;
            let ns: number = nx / this.containerW;
            if (ns < 0.02) { ns = 0.02; }
            if (ns > 0.98) { ns = 0.98; }
            this.onSplitChange(ns);
          }
        })
    )
  }

  // 三阶两横网格（九宫格）
  private GridOverlay() {
    const lines: number = 2; // 只画两条分割线即可得到三等分
    Stack({ alignContent: Alignment.Center }) {
      // 竖线
      Row() {
        ForEach<number>([1, 2], (i: number) => {
          Column().width(1).height('100%').backgroundColor('#44FFFFFF')
            .position({ x: `${i * 33.333}%`, y: 0 })
        })
      }
      // 横线
      Column() {
        ForEach<number>([1, 2], (i: number) => {
          Row().height(1).width('100%').backgroundColor('#44FFFFFF')
            .position({ x: 0, y: `${i * 33.333}%` })
        })
      }
    }
    .width('100%')
    .height('100%')
  }
}
