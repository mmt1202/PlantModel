// /model/LightTypes.ets
// 光照记录模块的类型定义和工具函数
// 提供光照级别、状态枚举以及常用的工具函数

import { LightConstants } from '../constants/AppConstants';

/**
 * 光照级别枚举
 * 用于表示植物所需的光照强度偏好
 */
export enum LightLevel {
  LOW = 0,   // 弱光：适合耐阴植物
  MID = 1,   // 中光：适合大多数室内植物
  HIGH = 2   // 强光：适合喜阳植物
}

/**
 * 光照状态枚举
 * 用于表示当日光照是否达标
 */
export enum LightStatus {
  INSUFF = 0, // 不足：光照时间未达到目标下限
  OK = 1,     // 适中：光照时间在目标范围内
  STRONG = 2  // 过强：光照时间超过目标上限
}

/**
 * 将光照级别转换为可读的中文标签
 * @param level 光照级别枚举值
 * @returns 中文标签字符串
 */
export function lightLevelLabel(level: LightLevel): string {
  if (level === LightLevel.LOW) { return '弱光'; }
  if (level === LightLevel.MID) { return '中光'; }
  return '强光';
}

/**
 * 将光照状态转换为可读的中文标签
 * @param status 光照状态枚举值
 * @returns 中文标签字符串
 */
export function statusLabel(status: LightStatus): string {
  if (status === LightStatus.INSUFF) { return '日照不足'; }
  if (status === LightStatus.OK) { return '日照适中'; }
  return '日照过强';
}

/**
 * 获取光照状态对应的颜色值（用于 UI 显示）
 * @param status 光照状态枚举值
 * @returns 十六进制颜色字符串
 */
export function statusColor(status: LightStatus): string {
  if (status === LightStatus.INSUFF) { return '#FF6B6B'; } // 红色：不足
  if (status === LightStatus.OK) { return '#26A69A'; }     // 绿青色：适中
  return '#FF9F43';                                        // 橙色：过强
}

/**
 * 获取光照级别的权重系数
 * 用于计算光照强度，不同级别的光照对植物的影响不同
 * @param level 光照级别枚举值
 * @returns 权重系数
 */
export function levelWeight(level: LightLevel): number {
  // 手动近似权重：弱光=1.0，中光=1.5，强光=2.0
  // 权重越高，相同时间内积累的光照量越多
  if (level === LightLevel.LOW) { return 1.0; }
  if (level === LightLevel.MID) { return 1.5; }
  return 2.0;
}

// ---- 日期工具函数（不依赖外部库） ----

/**
 * 将日期转换为 YYYY-MM-DD 格式的字符串
 * @param d 日期对象
 * @returns 格式化的日期字符串，例如："2024-03-14"
 */
export function ymd(d: Date): string {
  const y: number = d.getFullYear();
  const m: number = d.getMonth() + 1; // getMonth() 返回 0-11，需要 +1
  const dd: number = d.getDate();
  const mmStr: string = m < 10 ? '0' + m : '' + m; // 月份补零
  const ddStr: string = dd < 10 ? '0' + dd : '' + dd; // 日期补零
  return `${y}-${mmStr}-${ddStr}`;
}

/**
 * 将日期转换为 HH:mm 格式的字符串
 * @param d 日期对象
 * @returns 格式化的时间字符串，例如："14:30"
 */
export function hm(d: Date): string {
  const h: number = d.getHours();
  const m: number = d.getMinutes();
  const hStr: string = h < 10 ? '0' + h : '' + h; // 小时补零
  const mStr: string = m < 10 ? '0' + m : '' + m; // 分钟补零
  return `${hStr}:${mStr}`;
}

/**
 * 将比率限制在 0 到 1 之间
 * 用于确保进度百分比不会超出范围
 * @param v 输入值
 * @returns 限制后的值（0-1 之间）
 */
export function clampRate(v: number): number {
  if (v < 0) { return 0; }
  if (v > 1) { return 1; }
  return v;
}

/**
 * 生成唯一 ID
 * 用于创建临时记录或标识符
 * @param prefix 前缀字符串
 * @returns 格式为 "prefix_时间戳_随机数" 的唯一 ID
 */
export function genId(prefix: string): string {
  const t: number = Date.now(); // 当前时间戳（毫秒）
  const r: number = Math.floor(Math.random() * 1000000); // 0-999999 的随机数
  return `${prefix}_${t}_${r}`;
}
