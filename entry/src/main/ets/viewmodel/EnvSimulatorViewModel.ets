// /viewmodel/EnvSimulatorViewModel.ets
// 环境模拟器视图模型（V2）：管理 light/soil/humidity，提供派生展示状态与快照导出
// 不直接持久化，只返回 snapshot 供调用方决定是否写入数据库

import {
  EnvParam, Snapshot,
  leafColorBy, bgGradientBy, moodBy, recommendationBy
} from '../model/EnvSimulatorTypes';

@ObservedV2
export class EnvSimulatorViewModel {
  // 绑定植物 ID，由页面通过 Param 或构造时传入。
  plantId: string = '';

  // 三个主参数都约束在 0..100，用来模拟光照、土壤湿度与空气湿度。
  light: number = 50;
  soil: number = 50;
  humidity: number = 50;

  // UI 友好的附加状态。
  lastSnapshot: Snapshot | null = null;
  isAnimating: boolean = false;

  constructor(plantId: string) {
    this.plantId = plantId && plantId.trim() ? plantId : 'PLANT_DEMO';
  }

  // 模拟器是纯计算型 VM：参数变化即刷新派生状态，不依赖数据库。
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
    this.light = 50;
    this.soil = 50;
    this.humidity = 50;
  }

  // 以下 getter 都是纯派生值，页面可以直接消费而不必重复拼展示文案。
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

  // snapshot 是当前模拟状态的快照，是否入库由页面或调用方决定。
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

  // 页面可以在动画期间用这个开关禁用某些交互。
  startAnim() {
    this.isAnimating = true;
  }

  stopAnim() {
    this.isAnimating = false;
  }

  // 提供一个轻量序列化出口，方便把模拟结果塞进日志或备注字段。
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

function clamp(v: number, lo: number, hi: number): number {
  if (v < lo) return lo;
  if (v > hi) return hi;
  return v;
}
