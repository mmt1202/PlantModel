// /viewmodel/WaterEstimatorViewModel.ets
// V2 可观测 VM：保存输入参数、计算结果、保存日志

import WaterEstimateLog from '../model/WaterEstimateLog';
import {
  RetentionType, StrategyType, PlantKind,
  estimateWaterML, retentionLabel, strategyLabel, plantLabel, roundInt
} from '../model/WaterEstimatorTypes';

function genId(prefix: string): string {
  const t: number = Date.now();
  const r: number = Math.floor(Math.random() * 1000000);
  return `${prefix}_${t}_${r}`;
}

@ObservedV2
export class WaterEstimatorViewModel {
  plantId: string = '';
  // 输入
  diameterCm: number = 14;     // 盆径
  depthCm: number = 12;        // 深度
  retention: RetentionType = RetentionType.GENERAL;
  strategy: StrategyType = StrategyType.MAINT;
  plant: PlantKind = PlantKind.FOLIAGE;

  // 结果
  low: number = 0;
  mid: number = 0;
  high: number = 0;

  // 历史记录
  logs: Array<WaterEstimateLog> = new Array<WaterEstimateLog>();

  constructor(plantId: string) {
    this.plantId = plantId;
    this.compute();
  }

  // —— 修改输入 ——
  setDiameter(v: number): void {
    let nv: number = v;
    if (nv < 6) { nv = 6; }
    if (nv > 60) { nv = 60; }
    this.diameterCm = roundInt(nv);
    this.compute();
  }

  setDepth(v: number): void {
    let nv: number = v;
    if (nv < 6) { nv = 6; }
    if (nv > 60) { nv = 60; }
    this.depthCm = roundInt(nv);
    this.compute();
  }

  setRetention(t: RetentionType): void {
    this.retention = t;
    this.compute();
  }

  setStrategy(s: StrategyType): void {
    this.strategy = s;
    this.compute();
  }

  setPlant(k: PlantKind): void {
    this.plant = k;
    this.compute();
  }

  // —— 计算 ——
  compute(): void {
    const r = estimateWaterML(this.diameterCm, this.depthCm, this.retention, this.strategy, this.plant);
    this.low = r.low;
    this.mid = r.mid;
    this.high = r.high;
  }

  // —— 文案与建议 ——
  getSuggestText(): string {
    // 简易建议：按策略与植株给一句提示
    if (this.strategy === StrategyType.FULL) {
      if (this.plant === PlantKind.SUCC) {
        return '建议沿盆壁缓慢注水至底孔初渗，静置 5 分钟后倒去积水。';
      }
      return '建议从盆缘环浇至下渗，确保介质均匀湿润，避免中心区积水。';
    } else {
      if (this.plant === PlantKind.SUCC) {
        return '少量沿盆壁补水，避免叶心积水；盆土 7~10 天干透后再浇透。';
      }
      return '少量多次，保持介质微湿；避免长期积水。';
    }
  }

  getFormulaBrief(): string {
    // 展示用于解释的简要计算说明
    return '估算公式：V≈π*(盆径/2)^2*深度 × 0.55(孔隙率) × 策略系数 × 植株系数 × 介质系数';
  }

  // —— 保存日志 ——
  saveLog(note: string): WaterEstimateLog {
    const log: WaterEstimateLog = new WaterEstimateLog(genId('WLOG'));
    log.plantId = this.plantId;
    log.diameterCm = this.diameterCm;
    log.depthCm = this.depthCm;
    log.retention = this.retention;
    log.strategy = this.strategy;
    log.plant = this.plant;
    log.low = this.low;
    log.mid = this.mid;
    log.high = this.high;
    log.note = note;

    const next: Array<WaterEstimateLog> = new Array<WaterEstimateLog>();
    next.push(log);
    for (let i: number = 0; i < this.logs.length; i++) { next.push(this.logs[i]); }
    this.logs = next;
    return log;
  }

  // —— 标签 ——
  labelRetention(): string { return retentionLabel(this.retention); }
  labelStrategy(): string { return strategyLabel(this.strategy); }
  labelPlant(): string { return plantLabel(this.plant); }
}
