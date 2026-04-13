// /model/ExposureSession.ets
// 手动光照会话记录模型
// 记录一次完整的光照过程：从开始到结束，包括时长、光照强度等信息

import { LightLevel, genId } from './LightTypes';

/**
 * 光照会话类
 * 用于记录一次完整的光照过程
 * 支持两种模式：
 * 1. 开始/结束模式：用户点击开始和结束按钮
 * 2. 即时记录模式：用户直接输入时长
 */
@ObservedV2
export default class ExposureSession {
  @Trace id: string = '';           // 会话唯一标识
  @Trace plantId: number = 0;       // 关联的植物 ID
  @Trace startAt: number = 0;       // 开始时间戳（毫秒）
  @Trace endAt: number = 0;         // 结束时间戳（毫秒）
  @Trace durationMin: number = 0;   // 持续时间（分钟）
  @Trace source: string = 'MANUAL'; // 记录来源：MANUAL=手动记录
  @Trace level: LightLevel = LightLevel.MID; // 光照级别（弱光/中光/强光）
  @Trace luxMinutes: number = 0;    // 等效光照量（lux-min）= 光照强度 × 时长
  @Trace note: string = '';         // 用户备注

  /**
   * 构造函数
   * @param plantId 关联的植物 ID
   */
  constructor(plantId: number) {
    this.id = genId('SES');  // 生成唯一 ID，格式：SES_时间戳_随机数
    this.plantId = plantId;
  }

  /**
   * 创建一个已开始的会话
   * 当用户点击"开始光照"按钮时调用
   * @param plantId 植物 ID
   * @param level 光照级别
   * @param startAt 开始时间戳
   * @returns 新的光照会话实例
   */
  static createStarted(plantId: number, level: LightLevel, startAt: number): ExposureSession {
    const s: ExposureSession = new ExposureSession(plantId);
    s.level = level;
    s.startAt = startAt;
    return s;
  }

  /**
   * 结束会话
   * 当用户点击"结束光照"按钮时调用
   * @param endAt 结束时间戳
   * @param luxMinutes 计算好的等效光照量
   */
  finishWith(endAt: number, luxMinutes: number): void {
    this.endAt = endAt;
    // 计算持续时间（分钟），至少为 1 分钟
    const dur: number = Math.max(1, Math.floor((this.endAt - this.startAt) / 60000));
    this.durationMin = dur;
    this.luxMinutes = luxMinutes;
  }

  /**
   * 创建一个即时记录的会话
   * 当用户使用"补记"功能时调用
   * @param plantId 植物 ID
   * @param level 光照级别
   * @param minutes 记录的时长（分钟）
   * @param endAt 结束时间戳
   * @returns 新的光照会话实例
   */
  static createInstant(plantId: number, level: LightLevel, minutes: number, endAt: number): ExposureSession {
    const s: ExposureSession = new ExposureSession(plantId);
    s.level = level;
    s.endAt = endAt;
    // 根据结束时间和时长反推开始时间
    s.startAt = endAt - minutes * 60000;  // 分钟转毫秒
    s.durationMin = minutes;
    s.luxMinutes = 0; // 由外部计算后赋值
    return s;
  }
}
