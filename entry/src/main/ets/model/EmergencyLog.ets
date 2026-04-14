// /model/EmergencyLog.ets
// 急救记录实体（内存版；后续可替换为 RDB）

export default class EmergencyLog {
  id: string = '';
  plantId: string = '';
  symptomKey: string = '';
  title: string = '';
  startedAt: number = 0;
  reviewAt: number = 0;
  stepsChecked: Array<boolean> = [false, false, false]; // 三步完成状态
  note: string = '';
  completed: boolean = false;

  constructor(id: string) {
    this.id = id;
    this.startedAt = Date.now();
  }
}
