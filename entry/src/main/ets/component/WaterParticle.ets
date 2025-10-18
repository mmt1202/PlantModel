// /component/WaterParticle.ets
// 组合粒子与波纹表现的组件（用简单的 ArkUI 元素模拟）
// 参数：isAnimating, intensity(1..3), onAnimationEnd
@ComponentV2
export struct WaterParticle {
  // 强度：1=浅浇，2=中，3=深浇
  @Require intensity: number = 1;
  @Require isAnimating: boolean = false;
  @Event onAnimationEnd: () => void = () => {};

  // Builder 中全部 UI
  @Builder build() {
    Stack({ alignContent: Alignment.Center }) {
      // 粒子层（多点水滴）
      Column() {
        // 我们用一组小圆模拟水滴，从上到下做出落下视觉（实际动画用 animateTo 在页面侧触发）
        Row({ space: 8 }) {
          ForEach<number>([1,2,3,4,5], (i: number) => {
            Column()
              .width(8).height(12)
              .borderRadius(4)
              .backgroundColor('rgba(120,180,255,0.9)')
              .opacity(this.dropOpacity(i))
              .translate({ x: 0, y: this.dropY(i) })
          })
        }
      }
      // 波纹层（3 个同心圆）
      Column() {
        Row({ space: 6 }) {
          ForEach<number>([1,2,3], (r: number) => {
            Column()
              .width(40 + r * 20 * this.intensity).height(10 + r * 6 * this.intensity)
              .borderRadius(50)
              .borderWidth(1).borderColor('rgba(100,160,255,0.5)')
              .opacity(this.waveOpacity(r))
          })
        }
      }
    }
  }

  // 这些函数仅返回常量或基于 intensity 的表现（无复杂逻辑）
  private dropOpacity(i: number): number {
    // 前几个更亮
    if (i === 1) return 1.0;
    if (i === 2) return 0.9;
    if (i === 3) return 0.75;
    return 0.6;
  }
  private dropY(i: number): string {
    // 不做动态值（页面会整组移动），这里返回小位移
    return `${i * 4}px`;
  }
  private waveOpacity(r: number): number {
    if (r === 1) return 0.9;
    if (r === 2) return 0.6;
    return 0.3;
  }
}
