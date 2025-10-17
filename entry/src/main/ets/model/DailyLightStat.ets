// /model/DailyLightStat.ets
// 每日汇总统计（用于环形进度与 7 日条形图）

import { LightStatus } from './LightTypes';

export default class DailyLightStat {
  id: string = '';
  plantId: number = 0;
  date: string = '';        // YYYY-MM-DD
  luxMinutes: number = 0;   // 当日累积
  durationMin: number = 0;  // 当日总时长
  maxLux: number = 0;       // 手动模式恒为 0（保留字段）
  rate: number = 0;         // 0..1
  status: LightStatus = LightStatus.OK;

  constructor(id: string) {
    this.id = id;
  }
}
