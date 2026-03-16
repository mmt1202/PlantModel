// /model/ExposureSession.ets
// 手动光照会话记录（开始/结束、时长、等效 lux-min）

import { LightLevel, genId } from './LightTypes';

@ObservedV2
export default class ExposureSession {
  @Trace id: string = '';
  @Trace plantId: number = 0;
  @Trace startAt: number = 0;
  @Trace endAt: number = 0;
  @Trace durationMin: number = 0;
  @Trace source: string = 'MANUAL';
  @Trace level: LightLevel = LightLevel.MID;
  @Trace luxMinutes: number = 0;
  @Trace note: string = '';

  constructor(plantId: number) {
    this.id = genId('SES');
    this.plantId = plantId;
  }

  static createStarted(plantId: number, level: LightLevel, startAt: number): ExposureSession {
    const s: ExposureSession = new ExposureSession(plantId);
    s.level = level;
    s.startAt = startAt;
    return s;
  }

  finishWith(endAt: number, luxMinutes: number): void {
    this.endAt = endAt;
    const dur: number = Math.max(1, Math.floor((this.endAt - this.startAt) / 60000));
    this.durationMin = dur;
    this.luxMinutes = luxMinutes;
  }

  static createInstant(plantId: number, level: LightLevel, minutes: number, endAt: number): ExposureSession {
    const s: ExposureSession = new ExposureSession(plantId);
    s.level = level;
    s.endAt = endAt;
    s.startAt = endAt - minutes * 60000;
    s.durationMin = minutes;
    s.luxMinutes = 0; // 由外部计算后赋值
    return s;
  }
}
