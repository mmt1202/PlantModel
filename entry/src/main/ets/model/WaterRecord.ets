// /model/WaterRecord.ets
// 浇水记录实体（轻量）：页面调用 vm.recordWater(...) 返回该对象，调用者可决定是否写入 DB
export default class WaterRecord {
  id: string = '';
  plantId: string = '';
  mode: string = ''; // 'light' | 'deep'
  amountMl: number = 0; // 可选用户输入
  createdAt: number = 0;

  constructor(id: string, plantId: string, mode: string, amountMl: number) {
    this.id = id;
    this.plantId = plantId;
    this.mode = mode;
    this.amountMl = amountMl;
    this.createdAt = Date.now();
  }
}
