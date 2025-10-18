// /model/EnvSimulatorTypes.ets
// 环境模拟器常量、映射与小工具（无副作用，可直接 import 使用）

export enum EnvParam {
  LIGHT = 'light',
  SOIL = 'soil',
  HUMID = 'humidity'
}

export type Snapshot = {
  plantId: string,
  light: number,
  soil: number,
  humidity: number,
  mood: string,
  leafTone: string,
  background: string,
  recommend: string,
  createdAt: number
}

// 颜色辅助（返回 hex）
export function leafColorBy(light: number, soil: number): string {
  // light, soil: 0..100
  // 假设绿色在正常区间（light 40..80, soil 40..70）
  if (soil < 25) {
    // 干旱 -> 发灰偏褐
    return '#C7B299';
  }
  if (light < 30) {
    // 光照不足 -> 深绿偏暗
    return '#3A6B3A';
  }
  if (light > 85) {
    // 强光（可能灼伤） -> 黄褐
    return '#E6C07B';
  }
  // 正常绿 —— 根据 soil 调节鲜艳度
  const greenBase = Math.floor(80 + (soil - 40) * 0.6);
  const g = clampInt(greenBase, 60, 220);
  const hex = toHex(40) + toHex(g) + toHex(40);
  return `#${hex}`;
}

export function bgGradientBy(light: number, humidity: number): string {
  // 返回一个简化的 CSS-like 单色字符串表示（实际在 UI 里用为 color）
  // 更亮的光照 -> 更亮的背景
  const lv = Math.floor(180 + (light - 50) * 0.7);
  const hh = Math.floor(200 - (humidity - 50) * 0.5);
  const a = clampInt(lv, 100, 255);
  const b = clampInt(hh, 100, 255);
  return `rgb(${a}, ${a}, ${b})`;
}

export function moodBy(light: number, soil: number, humidity: number): string {
  // 综合判断，返回 Emoji 或短文本表示情绪
  if (soil < 20 && light > 60) {
    return '😢 （干燥 + 强光）';
  }
  if (soil < 20) {
    return '🥀（干渴）';
  }
  if (light < 25) {
    return '😐（光太弱）';
  }
  if (light > 90) {
    return '🔥（过强）';
  }
  if (humidity > 85 && soil > 70) {
    return '💧（潮湿）';
  }
  return '😊（健康）';
}

export function recommendationBy(light: number, soil: number, humidity: number): string {
  if (soil < 25) { return '建议：立即补水，移至散射光处。'; }
  if (light < 30) { return '建议：增加光照，靠近窗边或使用灯光。'; }
  if (light > 85 && soil < 50) { return '建议：遮阳并补水以防灼伤。'; }
  if (humidity > 85 && soil > 70) { return '建议：增加通风，避免闷湿导致病害。'; }
  return '建议：当前状态良好，保持现有养护。';
}

// 小工具
function toHex(n: number): string {
  let v: number = Math.round(n);
  if (v < 0) { v = 0; }
  if (v > 255) { v = 255; }
  const s: string = v.toString(16);
  return s.length === 1 ? '0' + s : s;
}
function clampInt(v: number, lo: number, hi: number): number {
  if (v < lo) { return lo; }
  if (v > hi) { return hi; }
  return v;
}
