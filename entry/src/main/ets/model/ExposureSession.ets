// /model/ExposureSession.ets
// 手动光照会话记录（开始/结束、时长、等效 lux-min）

import { LightLevel, genId } from './LightTypes';

export default class ExposureSession {
  id: string = '';
  plantId: string = '';
  startAt: number = 0;
  endAt: number = 0;
  durationMin: number = 0;
  source: string = 'MANUAL';
  level: LightLevel = LightLevel.MID;
  luxMinutes: number = 0;
  note: string = '';

  constructor(plantId: string) {
    this.id = genId('SES');
    this.plantId = plantId;
  }

  static createStarted(plantId: string, level: LightLevel, startAt: number): ExposureSession {
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

  static createInstant(plantId: string, level: LightLevel, minutes: number, endAt: number): ExposureSession {
    const s: ExposureSession = new ExposureSession(plantId);
    s.level = level;
    s.endAt = endAt;
    s.startAt = endAt - minutes * 60000;
    s.durationMin = minutes;
    s.luxMinutes = 0; // 由外部计算后赋值
    return s;
  }
}
