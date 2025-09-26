// /model/LightTypes.ets
// 光照枚举与工具

export enum LightLevel {
  LOW = 0,
  MID = 1,
  HIGH = 2
}

export enum LightStatus {
  INSUFF = 0, // 不足
  OK = 1,     // 适中
  STRONG = 2  // 过强
}

export function lightLevelLabel(level: LightLevel): string {
  if (level === LightLevel.LOW) { return '弱光'; }
  if (level === LightLevel.MID) { return '中光'; }
  return '强光';
}

export function statusLabel(status: LightStatus): string {
  if (status === LightStatus.INSUFF) { return '日照不足'; }
  if (status === LightStatus.OK) { return '日照适中'; }
  return '日照过强';
}

export function statusColor(status: LightStatus): string {
  if (status === LightStatus.INSUFF) { return '#FF6B6B'; } // 红
  if (status === LightStatus.OK) { return '#26A69A'; }     // 绿青
  return '#FF9F43';                                        // 橙
}

export function levelWeight(level: LightLevel): number {
  // 手动近似权重：弱=1.0，中=1.5，强=2.0
  if (level === LightLevel.LOW) { return 1.0; }
  if (level === LightLevel.MID) { return 1.5; }
  return 2.0;
}

// ---- 日期工具（不依赖外部库） ----
export function ymd(d: Date): string {
  const y: number = d.getFullYear();
  const m: number = d.getMonth() + 1;
  const dd: number = d.getDate();
  const mmStr: string = m < 10 ? '0' + m : '' + m;
  const ddStr: string = dd < 10 ? '0' + dd : '' + dd;
  return `${y}-${mmStr}-${ddStr}`;
}

export function hm(d: Date): string {
  const h: number = d.getHours();
  const m: number = d.getMinutes();
  const hStr: string = h < 10 ? '0' + h : '' + h;
  const mStr: string = m < 10 ? '0' + m : '' + m;
  return `${hStr}:${mStr}`;
}

export function clampRate(v: number): number {
  if (v < 0) { return 0; }
  if (v > 1) { return 1; }
  return v;
}

export function genId(prefix: string): string {
  const t: number = Date.now();
  const r: number = Math.floor(Math.random() * 1000000);
  return `${prefix}_${t}_${r}`;
}
