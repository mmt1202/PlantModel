// /model/WaterEstimatorTypes.ets
// 用量估算相关枚举、工具与核心计算（ArkTS / ArkUI V2 兼容）

export enum RetentionType {
  SANDY = 0, // 砂砾/透水
  GENERAL = 1, // 通用
  PEATY = 2, // 泥炭偏保水
  ORCHID = 3, // 兰花介质
  COCO = 4, // 椰糠
}

export enum StrategyType {
  FULL = 0, // 彻底浸润（一次浇透）
  MAINT = 1, // 日常保养（少量补水）
}

export enum PlantKind {
  SUCC = 0, // 多肉
  FOLIAGE = 1, // 观叶/热带
  FLOWER = 2, // 开花植物
  ORCHID = 3, // 兰花
  FRUIT = 4, // 果类植物
}

// —— 参数映射 ——
// 介质保水系数
export function retentionFactor(t: RetentionType): number {
  if (t === RetentionType.SANDY) {
    return 0.8;
  }
  if (t === RetentionType.PEATY) {
    return 1.2;
  }
  if (t === RetentionType.ORCHID) {
    return 0.7;
  }
  if (t === RetentionType.COCO) {
    return 1.1;
  }
  return 1.0; // GENERAL
}

// 浇水策略系数
export function strategyFactor(s: StrategyType): number {
  if (s === StrategyType.FULL) {
    return 0.35;
  }
  return 0.2; // MAINT
}

// 植株类型系数
export function plantFactor(k: PlantKind): number {
  if (k === PlantKind.SUCC) {
    return 0.7;
  }
  if (k === PlantKind.ORCHID) {
    return 0.8;
  }
  if (k === PlantKind.FLOWER) {
    return 1.1;
  }
  if (k === PlantKind.FRUIT) {
    return 1.2;
  }
  return 1.0; // FOLIAGE
}

// 标签
export function retentionLabel(t: RetentionType): string {
  if (t === RetentionType.SANDY) {
    return "砂砾/透水";
  }
  if (t === RetentionType.PEATY) {
    return "泥炭/保水";
  }
  if (t === RetentionType.ORCHID) {
    return "兰花介质";
  }
  if (t === RetentionType.COCO) {
    return "椰糠";
  }
  return "通用介质";
}
export function strategyLabel(s: StrategyType): string {
  if (s === StrategyType.FULL) {
    return "彻底浸润";
  }
  return "日常保养";
}
export function plantLabel(k: PlantKind): string {
  if (k === PlantKind.SUCC) {
    return "多肉";
  }
  if (k === PlantKind.FOLIAGE) {
    return "观叶";
  }
  if (k === PlantKind.FLOWER) {
    return "开花植物";
  }
  if (k === PlantKind.ORCHID) {
    return "兰花";
  }
  if (k === PlantKind.FRUIT) {
    return "果类植物";
  }
  return "观叶";
}

// —— 核心估算 ——
// 输入：盆径d(cm)、深度h(cm)，介质/策略/植株
// 体积 V≈π*(d/2)^2*h（ml≈cm³）
// 可用水量 ≈ V * porosity(0.55) * strategy * plant * retention
export function estimateWaterML(
  d: number,
  h: number,
  rt: RetentionType,
  st: StrategyType,
  pk: PlantKind,
): EstimateWater {
  const V: number = Math.PI * Math.pow(d / 2.0, 2.0) * h; // cm³ ≈ ml
  const porosity: number = 0.55;
  const midFloat: number =
    V * porosity * strategyFactor(st) * plantFactor(pk) * retentionFactor(rt);
  const mid: number = roundInt(midFloat);
  const low: number = roundInt(midFloat * 0.85);
  const high: number = roundInt(midFloat * 1.15);
  return { low, mid, high };
}

// —— 工具 ——
export function roundInt(v: number): number {
  if (v < 0) {
    return 0;
  }
  return Math.round(v);
}

export interface EstimateWater {
  low: number;
  mid: number;
  high: number;
}
