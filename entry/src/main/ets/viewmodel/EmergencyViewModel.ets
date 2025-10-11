// /viewmodel/EmergencyViewModel.ets
// 急救流程 VM（V2）：症状选择 → 三步卡打勾 → 开始观察（生成记录）→ 历史列表

import EmergencyLog from '../model/EmergencyLog';
import { PlaybookItem, PlayStep, getBuiltinPlaybook, findPlaybookByKey } from '../model/EmergencyPlaybook';

function genId(prefix: string): string {
  const t: number = Date.now();
  const r: number = Math.floor(Math.random() * 1000000);
  return `${prefix}_${t}_${r}`;
}

@ObservedV2
export class EmergencyViewModel {
  plantId: string = '';

  playbook: Array<PlaybookItem> = new Array<PlaybookItem>();
  selectedKey: string = 'SCORCH';
  // 当前步骤勾选态
  stepChecked: Array<boolean> = new Array<boolean>();
  note: string = '';

  logs: Array<EmergencyLog> = new Array<EmergencyLog>();

  constructor(plantId: string) {
    this.plantId = plantId;
    this.playbook = getBuiltinPlaybook();
    this.ensureStepArray();
  }

  ensureStepArray(): void {
    const item: PlaybookItem | undefined = findPlaybookByKey(this.playbook, this.selectedKey);
    const n: number = item ? item.steps.length : 3;
    const arr: Array<boolean> = new Array<boolean>();
    for (let i: number = 0; i < n; i++) { arr.push(false); }
    this.stepChecked = arr;
  }

  selectSymptom(k: string): void {
    this.selectedKey = k;
    this.ensureStepArray();
  }

  toggleStep(i: number): void {
    if (i < 0 || i >= this.stepChecked.length) { return; }
    const arr: Array<boolean> = new Array<boolean>();
    for (let j: number = 0; j < this.stepChecked.length; j++) {
      if (j === i) { arr.push(!this.stepChecked[j]); } else { arr.push(this.stepChecked[j]); }
    }
    this.stepChecked = arr;
  }

  currentItem(): PlaybookItem | undefined {
    return findPlaybookByKey(this.playbook, this.selectedKey);
  }

  // 生成一条急救记录，并安排复查时间（仅写入日志，不做系统闹钟）
  startObservation(): EmergencyLog | undefined {
    const item: PlaybookItem | undefined = this.currentItem();
    if (!item) { return undefined; }
    const log: EmergencyLog = new EmergencyLog(genId('EMG'));
    log.plantId = this.plantId;
    log.symptomKey = item.key;
    log.title = item.title;
    log.stepsChecked = this.stepChecked;
    log.note = this.note;
    log.reviewAt = Date.now() + item.reviewHours * 60 * 60 * 1000;
    const next: Array<EmergencyLog> = new Array<EmergencyLog>();
    next.push(log);
    for (let i: number = 0; i < this.logs.length; i++) { next.push(this.logs[i]); }
    this.logs = next;
    return log;
  }

  markCompleted(id: string): void {
    const next: Array<EmergencyLog> = new Array<EmergencyLog>();
    for (let i: number = 0; i < this.logs.length; i++) {
      const x: EmergencyLog = this.logs[i];
      if (x.id === id) {
        const y: EmergencyLog = new EmergencyLog(x.id);
        y.plantId = x.plantId;
        y.symptomKey = x.symptomKey;
        y.title = x.title;
        y.startedAt = x.startedAt;
        y.reviewAt = x.reviewAt;
        y.stepsChecked = x.stepsChecked;
        y.note = x.note;
        y.completed = true;
        next.push(y);
      } else {
        next.push(x);
      }
    }
    this.logs = next;
  }

  // 工具：时间格式
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
