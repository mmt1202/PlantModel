// /component/CompareSliderV2.ets
// V2 对比滑块组件：底图(before) + 顶图(after，裁剪显示) + 中央拖杆 + 手势（拖杆拖动、双指缩放、对齐平移）
// 说明：通过 onAreaChange 获取容器宽度，用“限制宽度 + clip(true)”实现裁剪；不会用到 v1 裁剪接口。


/**
 * 对比滑块组件的对比模式枚举
 */
export enum CompareMode {
  SPLIT = 'split', // 分割模式：通过垂直分割线分隔两张图片
  SWIPE = 'swipe', // 滑动模式：通过左右滑动切换图片
  FADE = 'fade'    // 淡入淡出模式：通过透明度渐变过渡
}

/**
 * ToggleButton组件参数接口
 */
export interface ToggleButtonParams {
  label: string;
  selected: boolean;
  onToggle: () => void;
}

/**
 * 自定义切换按钮组件
 */
@ComponentV2
export struct ToggleButtonComponent {
  @Param @Require params: ToggleButtonParams;

  build() {
    Button(this.params.label)
      .type(this.params.selected ? ButtonType.Capsule : ButtonType.Normal)
      .backgroundColor(this.params.selected ? '#007DFF' : '#F2F2F2')
      .fontColor(this.params.selected ? '#FFFFFF' : '#333333')
      .width(80)
      .height(36)
      .margin({  left: 4, right: 4 })
      .onClick(() => {
        this.params.onToggle();
      })
  }
}

/**
 * V2 对比滑块组件：提供多种图片对比模式
 * 支持分割模式、滑动模式和淡入淡出模式
 * 特性：底图(before) + 顶图(after，裁剪显示) + 中央拖杆 + 手势（拖杆拖动、双指缩放、对齐平移）
 */
@ComponentV2
export struct CompareSliderV2 {
  // 必传参数
  @Require @Param beforeUri: string; // 前图片URI
  @Require @Param afterUri: string;  // 后图片URI

  // 分割比例（0..1），由父级驱动 + 组件内部拖动联动
  @Require @Param split: number;

  // 对齐参数（针对 after 图）
  @Require @Param zoom: number;    // 缩放比例
  @Require @Param offsetX: number; // X轴偏移量
  @Require @Param offsetY: number; // Y轴偏移量

  // 网格开关 & 对齐模式
  @Param showGrid: boolean = false;    // 是否显示网格
  @Param alignMode: boolean = false;   // 是否启用对齐模式
  @Param compareMode: CompareMode = CompareMode.SPLIT; // 对比模式

  // 回调事件
  @Event onSplitChange: (v: number) => void = (v: number) => {}; // 分割比例变化回调
  @Event onAlignChange: (zoom: number, offsetX: number, offsetY: number) => void = 
    (zoom: number, offsetX: number, offsetY: number) => {}; // 对齐参数变化回调
  @Event onModeChange: (mode: CompareMode) => void = (mode: CompareMode) => {}; // 模式变化回调

  // 本地状态
  @Local containerW: number = 0;            // 容器宽度
  @Local containerH: number = 0;            // 容器高度
  @Local previewBeforeOnly: boolean = false; // 长按预览“仅前图”
  @Local fadeProgress: number = 0;          // 淡入淡出进度

  build() {
    Column({space:10}) {
      // 显示区域
      Stack({ alignContent: Alignment.Center }) {
        // 底图：before
        // Image(this.beforeUri)
        //   .width('100%')
        //   .height(300)
        //   .objectFit(ImageFit.Cover)
        //     // 为了对齐预览时的一致性，这里不做变换
        //   .clip(true)

        // 根据不同的对比模式显示不同的UI
        if (this.compareMode === CompareMode.SPLIT) {
          // 分割模式：原始的滑块对比
          this.SplitModeContent(false);
        } else if (this.compareMode === CompareMode.SWIPE) {
          // 滑动模式：左右滑动切换图片
          this.SwipeModeContent(false);
        } else if (this.compareMode === CompareMode.FADE) {
          // 淡入淡出模式：渐变过渡
          this.FadeModeContent(false);
        }

        // 网格（叠加在最上层，弱透明）
        if (this.showGrid) {
          this.GridOverlay()
        }

        // 分割模式下显示中央拖杆
        if (this.compareMode === CompareMode.SPLIT) {
          this.SplitHandle()
        }
      }
      .onAreaChange((oldArea, newArea) => {
        this.containerW = newArea.width as number;
        this.containerH = newArea.height as number;
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

      // 显示区域2
      Stack({ alignContent: Alignment.Center }) {
        // 底图：before
        // Image(this.afterUri)
        //   .width('100%')
        //   .height(300)
        //   .objectFit(ImageFit.Cover)
        //   // 为了对齐预览时的一致性，这里不做变换
        //   .clip(true)

        // 根据不同的对比模式显示不同的UI
        if (this.compareMode === CompareMode.SPLIT) {
          // 分割模式：原始的滑块对比
          this.SplitModeContent(true);
        } else if (this.compareMode === CompareMode.SWIPE) {
          // 滑动模式：左右滑动切换图片
          this.SwipeModeContent(true);
        } else if (this.compareMode === CompareMode.FADE) {
          // 淡入淡出模式：渐变过渡
          this.FadeModeContent(true);
        }

        // 网格（叠加在最上层，弱透明）
        if (this.showGrid) {
          this.GridOverlay()
        }

        // 分割模式下显示中央拖杆
        if (this.compareMode === CompareMode.SPLIT) {
          this.SplitHandle()
        }
      }
      .onAreaChange((oldArea, newArea) => {
        this.containerW = newArea.width as number;
        this.containerH = newArea.height as number;
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

      // 对比模式切换器
      this.ModeSelector();

      // 下方“精确滑杆”同步（可选；由父级决定是否显示，这里默认显示以增强可控性）
      if (this.compareMode === CompareMode.SPLIT || this.compareMode === CompareMode.FADE) {
        Slider({ 
          value: this.compareMode === CompareMode.FADE ? this.fadeProgress : this.split, 
          min: 0.02, 
          max: 0.98, 
          step: 0.01 
        })
          .onChange((v: number) => {
            if (this.compareMode === CompareMode.FADE) {
              this.fadeProgress = v;
            } else {
              this.onSplitChange(v);
            }
          })
          .margin({ top: 10 })
          .backgroundColor('#F2F2F2')
          .blockColor('#007DFF')
          .trackColor('#E0E0E0')
      }
    }
  }

  // 分割模式内容
  @Builder
  SplitModeContent(isAfter: boolean) {
    // 顶图裁剪容器（宽度 = split * 容器宽度）
    // 利用 clip(true) 防止 after 图平移/缩放后溢出
    Row() {
      // after 图（可缩放、平移）
      Image(isAfter ? this.afterUri : this.beforeUri)
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
            : PanGesture({ fingers: 1 }) // 非对齐模式，不消费手势
        )
          // 双指缩放
        .gesture(
          PinchGesture()
            .onActionUpdate((e) => {
              // e.scale 为相对缩放因子
              const nz: number = this.zoom * e.scale;
              // 轻度跟随手势中心的平移（提升贴合感）
              const dx: number = e.offsetX;
              const dy: number = e.offsetY;
              this.onAlignChange(nz, this.offsetX + dx * 0.02, this.offsetY + dy * 0.02);
            })
        )
    }
    .width(this.overlayWidth())
    .height(300)
    .clip(true)
  }

  // 滑动模式内容
  @Builder
  SwipeModeContent(isAfter: boolean): void {
    // after 图（可缩放、平移）
    Image(isAfter ? this.afterUri : this.beforeUri)
      .width('100%')
      .height(300)
      .objectFit(ImageFit.Cover)
      .scale({ x: this.zoom, y: this.zoom, centerX: '50%', centerY: '50%' })
      .translate({ 
        x: this.offsetX + (this.split - 0.5) * this.containerW, 
        y: this.offsetY 
      })
      .clip(true)
      // 左右滑动切换
      .gesture(
        PanGesture({ fingers: 1 })
          .onActionUpdate((e) => {
            if (this.containerW > 0) {
              const newSplit = this.split + e.offsetX / (this.containerW * 2);
              const clampedSplit = Math.max(0, Math.min(1, newSplit));
              this.onSplitChange(clampedSplit);
            }
          })
      )
      // 双指缩放
      .gesture(
        PinchGesture()
          .onActionUpdate((e) => {
            // e.scale 为相对缩放因子
            const nz: number = this.zoom * e.scale;
            // 轻度跟随手势中心的平移（提升贴合感）
            const dx: number = e.offsetX;
            const dy: number = e.offsetY;
            this.onAlignChange(nz, this.offsetX + dx * 0.02, this.offsetY + dy * 0.02);
          })
      )
  }

  // 淡入淡出模式内容
  @Builder
  FadeModeContent(isAfter: boolean): void {
    // after 图（可缩放、平移、透明度变化）
    Image(isAfter ? this.afterUri : this.beforeUri)
      .width('100%')
      .height(300)
      .objectFit(ImageFit.Cover)
      .scale({ x: this.zoom, y: this.zoom, centerX: '50%', centerY: '50%' })
      .translate({ x: this.offsetX, y: this.offsetY })
      .opacity(this.fadeProgress)
      .clip(true)
      // 水平滑动改变透明度
      .gesture(
        PanGesture({ fingers: 1 })
          .onActionUpdate((e) => {
            if (this.containerW > 0) {
              const newProgress = this.fadeProgress + e.offsetX / this.containerW;
              this.fadeProgress = Math.max(0, Math.min(1, newProgress));
            }
          })
      )
      // 双指缩放
      .gesture(
        PinchGesture()
          .onActionUpdate((e) => {
            // e.scale 为相对缩放因子
            const nz: number = this.zoom * e.scale;
            // 轻度跟随手势中心的平移（提升贴合感）
            const dx: number = e.offsetX;
            const dy: number = e.offsetY;
            this.onAlignChange(nz, this.offsetX + dx * 0.02, this.offsetY + dy * 0.02);
          })
      )
  }

  // 模式选择器
  @Builder
  ModeSelector(): void {
    Row() {
      ToggleButtonComponent({
        params: {
          label: '分割',
          selected: this.compareMode === CompareMode.SPLIT,
          onToggle: () => {
            // this.compareMode = CompareMode.SPLIT;
            this.onModeChange(CompareMode.SPLIT);
          }
        }
      });
      ToggleButtonComponent({
        params: {
          label: '滑动',
          selected: this.compareMode === CompareMode.SWIPE,
          onToggle: () => {
            // this.compareMode = CompareMode.SWIPE;
            this.onModeChange(CompareMode.SWIPE);
          }
        }
      });
      ToggleButtonComponent({
        params: {
          label: '淡入淡出',
          selected: this.compareMode === CompareMode.FADE,
          onToggle: () => {
            // this.compareMode = CompareMode.FADE;
            this.onModeChange(CompareMode.FADE);
          }
        }
      });
    }
    .justifyContent(FlexAlign.Center)
    .margin({ top: 15, bottom: 5 })
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
  @Builder
  SplitHandle() {
    // const x: number = this.overlayWidth();
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
    .position({ x: this.overlayWidth() - 14, y: 0 }) // 让中线居中于裁剪边缘
    .gesture(
      PanGesture({ fingers: 1 })
        .onActionUpdate((e) => {
          if (this.containerW > 0) {
            const nx: number = this.overlayWidth() + e.offsetX;
            let ns: number = nx / this.containerW;
            if (ns < 0.02) { ns = 0.02; }
            if (ns > 0.98) { ns = 0.98; }
            this.onSplitChange(ns);
          }
        })
    )
  }

  // 三阶两横网格（九宫格）
  @Builder
  GridOverlay() {
    // const lines: number = 2; // 只画两条分割线即可得到三等分
    Stack({ alignContent: Alignment.Center }) {
      // 竖线
      Row() {
        ForEach([1, 2], (i: number) => {
          Column().width(1).height('100%').backgroundColor('#44FFFFFF')
            .position({ x: `${i * 33.333}%`, y: 0 })
        })
      }
      // 横线
      Column() {
        ForEach([1, 2], (i: number) => {
          Row().height(1).width('100%').backgroundColor('#44FFFFFF')
            .position({ x: 0, y: `${i * 33.333}%` })
        })
      }
    }
    .width('100%')
    .height('100%')
  }
}
