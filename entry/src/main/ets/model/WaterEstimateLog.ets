// /model/WaterEstimateLog.ets
// 估算记录实体（内存版；后续可替换为 RDB）

import { RetentionType, StrategyType, PlantKind } from './WaterEstimatorTypes';

export default class WaterEstimateLog {
  id: string = '';
  plantId: number = 0;
  diameterCm: number = 0;
  depthCm: number = 0;
  retention: RetentionType = RetentionType.GENERAL;
  strategy: StrategyType = StrategyType.MAINT;
  plantKind: PlantKind = PlantKind.FOLIAGE;
  low: number = 0;
  mid: number = 0;
  high: number = 0;
  createdAt: number = 0;
  note: string = '';

  constructor(id: string) {
    this.id = id;
    this.createdAt = Date.now();
  }
}
