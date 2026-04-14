// /model/WaterEstimatorTypes.ets
// 浇水用量估算相关枚举、工具函数与核心计算
// 支持 ArkTS / ArkUI V2 兼容

import { WaterConstants } from "../constants/AppConstants";

/**
 * 介质类型枚举
 * 表示土壤/介质的保水能力
 */
export enum RetentionType {
  SANDY = 0, // 砂砾/透水：保水能力差
  GENERAL = 1, // 通用：保水能力中等
  PEATY = 2, // 泥炭偏保水：保水能力强
  ORCHID = 3, // 兰花介质：保水能力差
  COCO = 4, // 椰糠：保水能力较强
}

/**
 * 浇水策略枚举
 * 表示浇水的方式
 */
export enum StrategyType {
  FULL = 0, // 彻底浸润（一次浇透）
  MAINT = 1, // 日常保养（少量补水）
}

/**
 * 植株类型枚举
 * 表示不同植物的需水量
 */
export enum PlantKind {
  SUCC = 0, // 多肉：需水量少
  FOLIAGE = 1, // 观叶/热带：需水量中等
  FLOWER = 2, // 开花植物：需水量较多
  ORCHID = 3, // 兰花：需水量较少
  FRUIT = 4, // 果类植物：需水量多
}

// —— 参数映射函数 ——

/**
 * 获取介质保水系数
 * @param t 介质类型
 * @returns 保水系数（0.7-1.2）
 */
export function retentionFactor(t: RetentionType): number {
  if (t === RetentionType.SANDY) {
    return WaterConstants.RETENTION_SANDY; // 砂砾：保水能力差
  }
  if (t === RetentionType.PEATY) {
    return WaterConstants.RETENTION_PEATY; // 泥炭：保水能力强
  }
  if (t === RetentionType.ORCHID) {
    return WaterConstants.RETENTION_ORCHID; // 兰花介质：保水能力差
  }
  if (t === RetentionType.COCO) {
    return WaterConstants.RETENTION_COCO; // 椰糠：保水能力较强
  }
  return WaterConstants.RETENTION_GENERAL; // GENERAL：保水能力中等
}

/**
 * 获取浇水策略系数
 * @param s 浇水策略
 * @returns 策略系数
 */
export function strategyFactor(s: StrategyType): number {
  if (s === StrategyType.FULL) {
    return WaterConstants.STRATEGY_FULL; // 彻底浸润：用水量较大
  }
  return WaterConstants.STRATEGY_MAINT; // MAINT：日常保养，用水量较小
}

/**
 * 获取植株类型系数
 * @param k 植株类型
 * @returns 需水系数
 */
export function plantFactor(k: PlantKind): number {
  if (k === PlantKind.SUCC) {
    return WaterConstants.PLANT_SUCC; // 多肉：需水量少
  }
  if (k === PlantKind.ORCHID) {
    return WaterConstants.PLANT_ORCHID; // 兰花：需水量较少
  }
  if (k === PlantKind.FLOWER) {
    return WaterConstants.PLANT_FLOWER; // 开花植物：需水量较多
  }
  if (k === PlantKind.FRUIT) {
    return WaterConstants.PLANT_FRUIT; // 果类植物：需水量多
  }
  return WaterConstants.PLANT_FOLIAGE; // FOLIAGE：需水量中等
}

// —— 标签转换函数 ——

/**
 * 将介质类型转换为中文标签
 * @param t 介质类型
 * @returns 中文标签
 */
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

/**
 * 将浇水策略转换为中文标签
 * @param s 浇水策略
 * @returns 中文标签
 */
export function strategyLabel(s: StrategyType): string {
  if (s === StrategyType.FULL) {
    return "彻底浸润";
  }
  return "日常保养";
}

/**
 * 将植株类型转换为中文标签
 * @param k 植株类型
 * @returns 中文标签
 */
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

// —— 核心估算函数 ——

/**
 * 估算浇水量
 * @param d 盆径（厘米）
 * @param h 盆深度（厘米）
 * @param rt 介质类型
 * @param st 浇水策略
 * @param pk 植株类型
 * 体积 V≈π*(d/2)^2*h（ml≈cm³） 可用水量 ≈ V * porosity(0.55) * strategy * plant * retention
 * @returns 估算的用水量范围（ml）
 */
export function estimateWaterML(
  d: number,
  h: number,
  rt: RetentionType,
  st: StrategyType,
  pk: PlantKind,
): EstimateWater {
  // 计算花盆体积（cm³ ≈ ml）
  const V: number = Math.PI * Math.pow(d / 2.0, 2.0) * h;
  // 土壤孔隙率（一般为 0.55）
  const porosity: number = WaterConstants.SOIL_POROSITY;
  // 计算中间值
  const midFloat: number =
    V * porosity * strategyFactor(st) * plantFactor(pk) * retentionFactor(rt);
  // 四舍五入到整数
  const mid: number = roundInt(midFloat);
  // 计算下限（中间值的 85%）
  const low: number = roundInt(midFloat * WaterConstants.WATER_RATIO_LOW);
  // 计算上限（中间值的 115%）
  const high: number = roundInt(midFloat * WaterConstants.WATER_RATIO_HIGH);
  // 返回估算结果
  return { low, mid, high };
}

// —— 工具函数 ——

/**
 * 四舍五入到整数，确保非负
 * @param v 输入值
 * @returns 四舍五入后的整数
 */
export function roundInt(v: number): number {
  if (v < 0) {
    return 0; // 确保非负
  }
  return Math.round(v); // 四舍五入
}

/**
 * 用水量估算结果接口
 */
export interface EstimateWater {
  low: number; // 最低用水量（ml）
  mid: number; // 推荐用水量（ml）
  high: number; // 最高用水量（ml）
}
