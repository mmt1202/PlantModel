// /viewmodel/RotatePlanViewModel.ets
// 转盆计划 VM（V2）：启用/周期、下一次到期、完成打卡、历史列表

import RotatePlan from '../model/RotatePlan';

function genId(prefix: string): string {
  const t: number = Date.now();
  const r: number = Math.floor(Math.random() * 1000000);
  return `${prefix}_${t}_${r}`;
}

export class RotateLog {
  id: string = '';
  ts: number = 0;
  constructor(id: string, ts: number) { this.id = id; this.ts = ts; }
}

@ObservedV2
export class RotatePlanViewModel {
  plantId: string = '';
  plan: RotatePlan = new RotatePlan('');
  enabled: boolean = false;
  intervalDays: number = 14;
  lastRotatedAt: number = 0;
  logs: Array<RotateLog> = new Array<RotateLog>();

  constructor(plantId: string) {
    this.plantId = plantId;
    this.plan = new RotatePlan(plantId);
    this.syncFromPlan();
  }

  private syncFromPlan(): void {
    this.enabled = this.plan.enabled;
    this.intervalDays = this.plan.intervalDays;
    this.lastRotatedAt = this.plan.lastRotatedAt;
  }

  setEnabled(on: boolean): void {
    this.enabled = on;
    this.plan.enabled = on;
  }

  setIntervalDays(d: number): void {
    let nv: number = d;
    if (nv < 3) { nv = 3; }
    if (nv > 60) { nv = 60; }
    this.intervalDays = nv;
    this.plan.intervalDays = nv;
  }

  markRotatedNow(): void {
    const now: number = Date.now();
    this.plan.markRotated(now);
    this.lastRotatedAt = now;
    const next: Array<RotateLog> = new Array<RotateLog>();
    next.push(new RotateLog(genId('RLOG'), now));
    for (let i: number = 0; i < this.logs.length; i++) { next.push(this.logs[i]); }
    this.logs = next;
  }

  nextDueAt(): number {
    return this.plan.nextDueAt(Date.now());
  }

  overdue(): boolean {
    const due: number = this.nextDueAt();
    return this.enabled && due <= Date.now();
  }

  fmtDate(ts: number): string {
    const d: Date = new Date(ts);
    const y: number = d.getFullYear();
    const m: number = d.getMonth() + 1;
    const dd: number = d.getDate();
    const hh: number = d.getHours();
    const mi: number = d.getMinutes();
    const mStr: string = m < 10 ? '0' + m : '' + m;
    const dStr: string = dd < 10 ? '0' + dd : '' + dd;
    const hStr: string = hh < 10 ? '0' + hh : '' + hh;
    const iStr: string = mi < 10 ? '0' + mi : '' + mi;
    return `${y}-${mStr}-${dStr} ${hStr}:${iStr}`;
  }
}
