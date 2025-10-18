// /component/PlantRenderer.ets
// 可视化渲染组件：根据 vm 提供的 light/soil/humidity 等属性渲染植物状态与简单动效
// 输入参数：light, soil, humidity, leafTone, backgroundTone, mood
// 这个组件侧重表现力，用 ArkUI 基础组件绘制（不依赖外部图片资源）
// UI 结构必须写在 @Builder 中

import { ComponentV2, Require, Event } from '@ohos.aafwk.ace'; // 示意装饰器

@ComponentV2
export struct PlantRenderer {
  @Require light: number = 50;
  @Require soil: number = 50;
  @Require humidity: number = 50;
  @Require leafTone: string = '#66AA66';
  @Require backgroundTone: string = 'rgb(220,220,240)';
  @Require mood: string = '😊（健康）';

  // 动画控制（页面或 vm 可传入）
  @Require isAnimating: boolean = false;

  // 交互回调：当用户点中植株时可以触发
  @Event onTap: () => void = () => {};

  // 所有 UI 在 Builder 中
  @Builder build() {
    // 顶层卡片：背景色随 light 调整（使用 backgroundTone）
    Column({ space: 10 }) {
      Stack({ alignContent: Alignment.Center }) {
        // 背景层（用一个大圆做太阳光晕 + 线性块）
        Column() {
          Box()
            .width('100%').height(180)
            .backgroundColor(this.backgroundTone)
            .borderRadius(12)
            .shadow({ radius: 12, color: '#22000000', offsetX: 0, offsetY: 6 })
        }

        // 植物 & pot 层（使用简单形状模拟）
        Column({ space: 6 }) {
          // 叶片（两个椭圆渐变），叶色来自 leafTone
          Row({ space: 6 }) {
            Column()
              .width(160).height(120)
              .borderRadius(80)
              .backgroundColor(this.leafGradientLeft())
              .transformOrigin({ x: '50%', y: '50%' })
              .scale({ x: this.leafScale(), y: this.leafScale() })
              .shadow({ radius: 8, color: '#22000000', offsetX: 0, offsetY: 4 })
            Column()
              .width(160).height(120)
              .borderRadius(80)
              .backgroundColor(this.leafGradientRight())
              .transformOrigin({ x: '50%', y: '50%' })
              .scale({ x: this.leafScale(), y: this.leafScale() })
              .shadow({ radius: 8, color: '#22000000', offsetX: 0, offsetY: 4 })
          }.alignItems(HorizontalAlign.Center)

          // 花盆（矩形 + 圆角）
          Column({ space: 4 }) {
            Column()
              .width(220).height(48)
              .backgroundColor('#8B5A2B')
              .borderRadius(12)
              .shadow({ radius: 6, color: '#22000000', offsetX: 0, offsetY: 2 })
            // soil surface
            Row() {
              Column()
                .width(200).height(8)
                .backgroundColor(this.soilSurfaceColor())
                .borderRadius(6)
            }
          }.alignItems(HorizontalAlign.Center)

          // 表情与提示
          Row({ space: 6 }) {
            Text(this.mood).fontSize(16)
            Blank()
            Text(`${Math.round(this.light)}·${Math.round(this.soil)}·${Math.round(this.humidity)}`)
              .fontSize(12).opacity(0.7)
          }.padding({ top: 6 })
        }
        .onClick(() => { this.onTap(); })
      }
      .width('100%')
      .height(240)
      .padding(12)
      .backgroundColor('#FFFFFF')
      .borderRadius(14)
    }
    .padding({ left: 16, right: 16 })
  }

  // 辅助：叶片渐变（左/右）—— 简化为单色或轻微变体
  private leafGradientLeft(): string {
    // 使左叶稍微暗一点
    return this.adjustColor(this.leafTone, -12);
  }
  private leafGradientRight(): string {
    // 右叶稍微亮一点
    return this.adjustColor(this.leafTone, 10);
  }

  // soil surface color（根据湿度深浅）
  private soilSurfaceColor(): string {
    // 湿度越高 soil color 越深
    const base = 120 + Math.floor(this.humidity * 0.8);
    const capped = base > 200 ? 200 : base;
    const hex = toHex(capped);
    return `#${hex}${hex.substring(0,2)}66`; // 伪造色值，视觉上偏棕
  }

  // 叶片 scale：soil 越低，叶片越下垂（scale <1）
  private leafScale(): number {
    if (this.soil < 20) { return 0.78; }
    if (this.soil < 40) { return 0.9; }
    if (this.soil > 80) { return 1.02; }
    return 1.0;
  }

  // 调整颜色明暗（偏差 -100..100）
  private adjustColor(hex: string, delta: number): string {
    // hex support like '#RRGGBB'
    try {
      if (hex.charAt(0) === '#') { hex = hex.substring(1); }
      const r = parseInt(hex.substring(0,2), 16);
      const g = parseInt(hex.substring(2,4), 16);
      const b = parseInt(hex.substring(4,6), 16);
      const nr = clampByte(r + delta);
      const ng = clampByte(g + delta);
      const nb = clampByte(b + delta);
      return '#' + toHex(nr) + toHex(ng) + toHex(nb);
    } catch (e) {
      return this.leafTone;
    }
  }
}

// 工具
function toHex(n: number): string {
  let v = Math.round(n);
  if (v < 0) v = 0;
  if (v > 255) v = 255;
  const s = v.toString(16);
  return s.length === 1 ? '0' + s : s;
}
function clampByte(v: number): number {
  if (v < 0) return 0;
  if (v > 255) return 255;
  return Math.round(v);
}
