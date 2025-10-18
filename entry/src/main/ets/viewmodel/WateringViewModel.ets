// /viewmodel/WateringViewModel.ets
// V2 可观测 ViewModel：管理浇水动画状态、历史（内存）、连胜天数逻辑、生成 WaterRecord
import WaterRecord from '../model/WaterRecord';

function genId(prefix: string): string {
  const t: number = Date.now();
  const r: number = Math.floor(Math.random() * 1000000);
  return `${prefix}_${t}_${r}`;
}

@ObservedV2
export class WateringViewModel {
  plantId: string = '';
  // 动画与交互态
  isAnimating: boolean = false;
  // 当前浇水模式： 'light' | 'deep'
  mode: string = 'light';
  // 可自定义的默认量（ml）
  defaultAmount: number = 100;
  // 最近 10 次浇水的时间戳（降序）
  recentTimes: Array<number> = new Array<number>();
  // 连续打卡天数（从最近记录推断）
  streakDays: number = 0;

  constructor(plantId: string) {
    this.plantId = plantId ? plantId : 'PLANT_DEMO';
  }

  // 切换模式（light/deep）
  setMode(m: string): void {
    if (m !== 'light' && m !== 'deep') { return; }
    this.mode = m;
  }

  // 开始播放动画（页面会在需要时调用）
  startAnimation(): void {
    this.isAnimating = true;
  }
  stopAnimation(): void {
    this.isAnimating = false;
  }

  // 记录一次浇水（不直接写 DB；返回 WaterRecord）
  recordWater(amountMl: number): WaterRecord {
    const amt: number = Math.max(0, Math.round(amountMl));
    const rec: WaterRecord = new WaterRecord(genId('W'), this.plantId, this.mode, amt);
    // 更新内存历史（放在最前）
    const next: Array<number> = new Array<number>();
    next.push(rec.createdAt);
    for (let i: number = 0; i < this.recentTimes.length && i < 9; i++) {
      next.push(this.recentTimes[i]);
    }
    this.recentTimes = next;
    // 更新连胜天数（简单逻辑）
    this.updateStreak();
    return rec;
  }

  // 返回最近一次浇水时间（0 表示无）
  lastWaterAt(): number {
    if (this.recentTimes.length === 0) { return 0; }
    return this.recentTimes[0];
  }

  // 计算并更新 streakDays（连续天数）
  private updateStreak(): void {
    if (this.recentTimes.length === 0) { this.streakDays = 0; return; }
    let days: number = 1;
    const dayMs: number = 24 * 60 * 60 * 1000;
    for (let i: number = 1; i < this.recentTimes.length; i++) {
      const prev = this.recentTimes[i - 1];
      const cur = this.recentTimes[i];
      // 若时间差在 (0, 36h) 以内视为同一天或连续（容错）
      if ((prev - cur) <= (36 * 60 * 60 * 1000)) {
        // check date boundary
        const prevD = new Date(prev);
        const curD = new Date(cur);
        const prevDay = Math.floor(prev / dayMs);
        const curDay = Math.floor(cur / dayMs);
        if (prevDay === curDay || prevDay - curDay === 1) {
          days++;
          continue;
        }
      }
      break;
    }
    this.streakDays = days;
  }

  // 格式化时间
  fmtDate(ts: number): string {
    if (ts === 0) { return '—'; }
    const d = new Date(ts);
    return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}`;
  }
}

// 工具
function pad(n: number): string {
  return n < 10 ? '0' + n : '' + n;
}
