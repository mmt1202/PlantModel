// /model/LightProfile.ets
// 每株植物的光照目标配置

import { LightLevel } from './LightTypes';

export default class LightProfile {
  plantId: string = '';
  targetLuxMinLow: number = 12000;   // 达标下限（lux-minutes）
  targetLuxMinHigh: number = 20000;  // 达标上限（满分参考）
  highLuxThreshold: number = 25000;  // 视为“过强”的阈值（手动近似）
  preferredLevel: LightLevel = LightLevel.MID;
  updatedAt: number = 0;

  constructor(plantId: string) {
    this.plantId = plantId;
    this.updatedAt = Date.now();
  }

  static defaultFor(plantId: string): LightProfile {
    const p: LightProfile = new LightProfile(plantId);
    // 默认偏好中光，目标范围：12k-20k，可按品类后续微调
    return p;
  }
}
