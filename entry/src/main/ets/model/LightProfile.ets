// /model/LightProfile.ets
// 每株植物的光照目标配置

import { LightLevel } from './LightTypes';

@ObservedV2
export default class LightProfile {
  @Trace plantId: number = 0;
  @Trace targetLuxMinLow: number = 12000;   // 达标下限（lux-minutes）
  @Trace targetLuxMinHigh: number = 20000;  // 达标上限（满分参考）
  @Trace highLuxThreshold: number = 25000;  // 视为“过强”的阈值（手动近似）
  @Trace preferredLevel: LightLevel = LightLevel.MID;
  @Trace updatedAt: number = 0;

  constructor(plantId: number) {
    this.plantId = plantId;
    this.updatedAt = Date.now();
  }

  static defaultFor(plantId: number): LightProfile {
    const p: LightProfile = new LightProfile(plantId);
    // 默认偏好中光，目标范围：12k-20k，可按品类后续微调
    return p;
  }
}
