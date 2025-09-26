// /viewmodel/LightExposureViewModel.ets
// 手动记录视图模型（不依赖传感器；计算达标率与状态；提供近 7 天数据）

import LightProfile from '../model/LightProfile';
import ExposureSession from '../model/ExposureSession';
import DailyLightStat from '../model/DailyLightStat';
import {
  LightLevel, LightStatus,
  levelWeight, clampRate, ymd, genId
} from '../model/LightTypes';

@Observed
export class LightExposureViewModel {
  // 状态
  plantId: string = '';
  profile: LightProfile = new LightProfile('');
  sessions: ExposureSession[] = [];       // 所有（你可按需换成按日分桶）
  dailyStats: DailyLightStat[] = [];      // 每日聚合
  hasActive: boolean = false;
  activeSession: ExposureSession | undefined = undefined;

  constructor(plantId: string) {
    this.plantId = plantId;
    this.profile = LightProfile.defaultFor(plantId);
  }

  // 开始手动会话
  startManual(level: LightLevel): void {
    if (this.hasActive) {
      return;
    }
    const s: ExposureSession = ExposureSession.createStarted(this.plantId, level, Date.now());
    this.activeSession = s;
    this.hasActive = true;
  }

  // 结束当前会话（根据开始时间→现在，或外部指定 durationMin）
  endManualWithAutoDuration(): void {
    if (!this.hasActive || this.activeSession === undefined) {
      return;
    }
    const endAt: number = Date.now();
    const durMin: number = Math.max(1, Math.floor((endAt - this.activeSession.startAt) / 60000));
    const luxMin: number = this.computeLuxMinutes(this.activeSession.level, durMin);
    this.activeSession.finishWith(endAt, luxMin);
    this.commitSession(this.activeSession);
    this.activeSession = undefined;
    this.hasActive = false;
  }

  // 直接补记（无需开始），给定等级与分钟数
  addManualInstant(level: LightLevel, minutes: number): void {
    const endAt: number = Date.now();
    const s: ExposureSession = ExposureSession.createInstant(this.plantId, level, minutes, endAt);
    s.luxMinutes = this.computeLuxMinutes(level, minutes);
    this.commitSession(s);
  }

  // lux-min 近似计算（手动模式）
  computeLuxMinutes(level: LightLevel, minutes: number): number {
    const basePerMin: number = 100; // 100 lux-min/分钟的基准
    const w: number = levelWeight(level);
    const result: number = Math.floor(minutes * basePerMin * w);
    return result;
  }

  // 提交会话→写入 sessions & 更新每日统计
  private commitSession(s: ExposureSession): void {
    const arr: ExposureSession[] = [];
    arr.push(s);
    for (let i: number = 0; i < this.sessions.length; i++) {
      arr.push(this.sessions[i]);
    }
    this.sessions = arr;
    this.updateDailyStatFor(new Date(s.endAt));
  }

  // 计算某日聚合
  private updateDailyStatFor(day: Date): void {
    const key: string = ymd(day);
    let totalLux: number = 0;
    let totalMin: number = 0;
    for (let i: number = 0; i < this.sessions.length; i++) {
      const s: ExposureSession = this.sessions[i];
      const d: Date = new Date(s.endAt);
      if (ymd(d) === key) {
        totalLux += s.luxMinutes;
        totalMin += s.durationMin;
      }
    }
    const id: string = `D_${this.plantId}_${key}`;
    const stat: DailyLightStat = new DailyLightStat(id);
    stat.plantId = this.plantId;
    stat.date = key;
    stat.luxMinutes = totalLux;
    stat.durationMin = totalMin;

    const high: number = this.profile.targetLuxMinHigh;
    const rate: number = clampRate(high <= 0 ? 0 : totalLux / high);
    stat.rate = rate;

    // 状态规则：<0.6 不足；<=1 适中；>1 过强（手动无 maxLux，因此仅以超额视作可能过强）
    let st: LightStatus = LightStatus.OK;
    if (rate < 0.6) {
      st = LightStatus.INSUFF;
    } else if (rate > 1.0) {
      st = LightStatus.STRONG;
    } else {
      st = LightStatus.OK;
    }
    stat.status = st;

    // 覆盖或插入
    let replaced: boolean = false;
    const next: DailyLightStat[] = [];
    for (let j: number = 0; j < this.dailyStats.length; j++) {
      const x: DailyLightStat = this.dailyStats[j];
      if (x.id === id) {
        next.push(stat);
        replaced = true;
      } else {
        next.push(x);
      }
    }
    if (!replaced) {
      const t: DailyLightStat[] = [];
      t.push(stat);
      for (let k: number = 0; k < next.length; k++) {
        t.push(next[k]);
      }
      this.dailyStats = t;
    } else {
      this.dailyStats = next;
    }
  }

  // 获取今日达标（0..100）
  get todayRatePercent(): number {
    const key: string = ymd(new Date());
    for (let i: number = 0; i < this.dailyStats.length; i++) {
      const s: DailyLightStat = this.dailyStats[i];
      if (s.date === key) {
        return Math.floor(s.rate * 100);
      }
    }
    return 0;
  }

  get todayStatus(): LightStatus {
    const key: string = ymd(new Date());
    for (let i: number = 0; i < this.dailyStats.length; i++) {
      const s: DailyLightStat = this.dailyStats[i];
      if (s.date === key) {
        return s.status;
      }
    }
    return LightStatus.INSUFF;
  }

  // 最近 7 天（包含今天），按日期升序返回
  get sevenDays(): DailyLightStat[] {
    const result: DailyLightStat[] = [];
    const base: Date = new Date();
    for (let i: number = 6; i >= 0; i--) {
      const d: Date = new Date(base.getFullYear(), base.getMonth(), base.getDate() - i);
      const key: string = ymd(d);
      let found: DailyLightStat | undefined = undefined;
      for (let j: number = 0; j < this.dailyStats.length; j++) {
        if (this.dailyStats[j].date === key) {
          found = this.dailyStats[j];
          break;
        }
      }
      if (found === undefined) {
        const id: string = `D_${this.plantId}_${key}`;
        const empty: DailyLightStat = new DailyLightStat(id);
        empty.plantId = this.plantId;
        empty.date = key;
        empty.luxMinutes = 0;
        empty.durationMin = 0;
        empty.rate = 0;
        empty.status = LightStatus.INSUFF;
        result.push(empty);
      } else {
        result.push(found);
      }
    }
    return result;
  }

  // 更新目标配置（供页面调用）
  updateProfile(low: number, high: number, preferred: LightLevel): void {
    this.profile.targetLuxMinLow = low;
    this.profile.targetLuxMinHigh = high;
    this.profile.preferredLevel = preferred;
    this.profile.updatedAt = Date.now();
    // 目标值变化可能影响今日状态，触发刷新
    this.updateDailyStatFor(new Date());
  }
}
