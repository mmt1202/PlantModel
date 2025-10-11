// /model/RotatePlan.ets
// 转盆计划（内存版）

export default class RotatePlan {
  plantId: string = '';
  enabled: boolean = false;
  intervalDays: number = 14;    // 转盆周期（天）
  lastRotatedAt: number = 0;    // 最近一次转盆时间戳（0=未转过）

  constructor(plantId: string) {
    this.plantId = plantId;
  }

  nextDueAt(baseNow: number): number {
    const now: number = baseNow;
    const base: number = this.lastRotatedAt > 0 ? this.lastRotatedAt : now;
    const next: number = base + this.intervalDays * 24 * 60 * 60 * 1000;
    return next;
  }

  markRotated(ts: number): void {
    this.lastRotatedAt = ts;
  }
}
