// /model/GrowthPair.ets
// 成长前后对比实体（内存版；后续可替换为RDB持久化）

export default class GrowthPair {
  id: string = '';
  plantId: string = '';
  beforeUri: string = '';
  afterUri: string = '';
  createdAt: number = 0;
  note: string = '';
  alignGrid: boolean = false;

  constructor(id: string, plantId: string, beforeUri: string, afterUri: string) {
    this.id = id;
    this.plantId = plantId;
    this.beforeUri = beforeUri;
    this.afterUri = afterUri;
    this.createdAt = Date.now();
  }
}
