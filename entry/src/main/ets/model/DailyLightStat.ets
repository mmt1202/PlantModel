// /model/DailyLightStat.ets
// 每日光照汇总统计模型
// 用于显示环形进度图和 7 日条形图的数据结构

import { LightStatus } from "./LightTypes";

/**
 * 每日光照统计类
 * 记录植物每日的光照情况，包括累积光照量、总时长、达标率等
 */
@ObservedV2
export default class DailyLightStat {
  @Trace id: string = ""; // 统计记录的唯一标识
  @Trace plantId: number = 0; // 关联的植物 ID
  @Trace date: string = ""; // 日期，格式：YYYY-MM-DD
  @Trace luxMinutes: number = 0; // 当日累积光照量（lux-min）
  @Trace durationMin: number = 0; // 当日总光照时长（分钟）
  @Trace maxLux: number = 0; // 最大光照强度（手动模式恒为 0，保留字段）
  @Trace rate: number = 0; // 达标率（0-1 之间）
  @Trace status: LightStatus = LightStatus.OK; // 光照状态（不足/适中/过强）

  /**
   * 构造函数
   * @param id 统计记录的唯一标识
   */
  constructor(id: string) {
    this.id = id;
  }
}
