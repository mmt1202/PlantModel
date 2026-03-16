// /model/DailyLightStat.ets
// 每日汇总统计（用于环形进度与 7 日条形图）

import { LightStatus } from './LightTypes';

@ObservedV2
export default class DailyLightStat {
  @Trace id: string = '';
  @Trace plantId: number = 0;
  @Trace date: string = '';        // YYYY-MM-DD
  @Trace luxMinutes: number = 0;   // 当日累积
  @Trace durationMin: number = 0;  // 当日总时长
  @Trace maxLux: number = 0;       // 手动模式恒为 0（保留字段）
  @Trace rate: number = 0;         // 0..1
  @Trace status: LightStatus = LightStatus.OK;

  constructor(id: string) {
    this.id = id;
  }
}
