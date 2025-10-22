// /viewmodel/EnvSimulatorViewModel.ets
// 环境模拟器视图模型（V2）：管理 light/soil/humidity，提供计算属性与快照导出
// 不直接持久化，仅返回 snapshot 供调用者决定是否写入数据库


import {
  EnvParam, Snapshot,
  leafColorBy, bgGradientBy, moodBy, recommendationBy
} from '../model/EnvSimulatorTypes';

@ObservedV2
export class EnvSimulatorViewModel {
  // 绑定植物 ID（由页面通过 Param 或构造传入）
  plantId: string = '';

  // 三个主要参数（0..100）
  light: number = 50;
  soil: number = 50;
  humidity: number = 50;

  // 额外状态（UI 友好）
  lastSnapshot: Snapshot | null = null;
  isAnimating: boolean = false;

  constructor(plantId: string) {
    this.plantId = plantId ? plantId : 'PLANT_DEMO';
    // 默认可以尝试恢复上次设置（若你实现 Prefs）
    // 这里不自动读取持久化，外部调用方可以通过 vm.setXXX 恢复
  }

  // setters（会触发视图刷新）
  setLight(v: number): void {
    this.light = clamp(v, 0, 100);
  }
  setSoil(v: number): void {
    this.soil = clamp(v, 0, 100);
  }
  setHumidity(v: number): void {
    this.humidity = clamp(v, 0, 100);
  }

  reset(): void {
    this.light = 50; this.soil = 50; this.humidity = 50;
  }

  // 动态计算属性（纯函数）
  get leafTone(): string {
    return leafColorBy(this.light, this.soil);
  }

  get backgroundTone(): string {
    return bgGradientBy(this.light, this.humidity);
  }

  get mood(): string {
    return moodBy(this.light, this.soil, this.humidity);
  }

  get recommendation(): string {
    return recommendationBy(this.light, this.soil, this.humidity);
  }

  // 生成可持久化快照对象（调用方可把此对象写进 DB）
  saveSnapshot(): Snapshot {
    const s: Snapshot = {
      plantId: this.plantId,
      light: Math.round(this.light),
      soil: Math.round(this.soil),
      humidity: Math.round(this.humidity),
      mood: this.mood,
      leafTone: this.leafTone,
      background: this.backgroundTone,
      recommend: this.recommendation,
      createdAt: Date.now()
    };
    this.lastSnapshot = s;
    return s;
  }

  // 小动画开关（页面可在动画期间禁用滑杆）
  startAnim() { this.isAnimating = true; }
  stopAnim() { this.isAnimating = false; }

  // 一个辅助：把 snapshot 格式化为可存 DB 的 note 字符串
  snapshotToNote(s: Snapshot): string {
    return JSON.stringify({
      plantId: s.plantId,
      light: s.light,
      soil: s.soil,
      humidity: s.humidity,
      mood: s.mood,
      createdAt: s.createdAt
    });
  }
}

// 小帮助函数
function clamp(v: number, lo: number, hi: number): number {
  if (v < lo) return lo;
  if (v > hi) return hi;
  return Math.round(v);
}
