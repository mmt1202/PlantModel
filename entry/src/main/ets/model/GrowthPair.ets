// /model/GrowthPair.ets
// 成长前后对比实体（内存版；后续可替换为RDB持久化）

@ObservedV2
export default class GrowthPair {
  @Trace id: string = '';
  @Trace plantId: number = 0;
  @Trace beforeUri: string = '';
  @Trace afterUri: string = '';
  @Trace createdAt: number = 0;
  @Trace note: string = '';
  @Trace alignGrid: boolean = false;

  constructor(id: string, plantId: number, beforeUri: string, afterUri: string) {
    this.id = id;
    this.plantId = plantId;
    this.beforeUri = beforeUri;
    this.afterUri = afterUri;
    this.createdAt = Date.now();
  }
}
