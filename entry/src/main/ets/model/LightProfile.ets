// /model/LightProfile.ets
// 植物光照目标配置模型
// 每株植物的光照偏好和目标设置

import { LightLevel } from './LightTypes';

/**
 * 光照配置档案类
 * 记录植物的光照偏好和目标范围
 */
@ObservedV2
export default class LightProfile {
  @Trace plantId: number = 0;                 // 关联的植物 ID
  @Trace targetLuxMinLow: number = 12000;     // 达标下限（lux-minutes）
  @Trace targetLuxMinHigh: number = 20000;    // 达标上限（满分参考值）
  @Trace highLuxThreshold: number = 25000;    // 视为"过强"的阈值（手动近似）
  @Trace preferredLevel: LightLevel = LightLevel.MID; // 偏好的光照级别
  @Trace updatedAt: number = 0;              // 更新时间戳

  /**
   * 构造函数
   * @param plantId 关联的植物 ID
   */
  constructor(plantId: number) {
    this.plantId = plantId;
    this.updatedAt = Date.now(); // 设置当前时间戳作为更新时间
  }

  /**
   * 创建默认的光照配置
   * @param plantId 植物 ID
   * @returns 默认的光照配置实例
   */
  static defaultFor(plantId: number): LightProfile {
    const p: LightProfile = new LightProfile(plantId);
    // 默认偏好中光，目标范围：12000-20000 lux-min
    // 可根据植物品类后续进行微调
    return p;
  }
}
