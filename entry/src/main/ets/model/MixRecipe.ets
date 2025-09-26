// /model/MixRecipe.ets
// 土壤配方实体与条目定义（内存版；可后续替换为RDB）

export class MixItem {
  id: string = '';
  name: string = '';
  ratio: number = 1;      // 配比权重（相对值）
  density: number = 0.15; // kg/L 估算；可为0表示用默认值0.15

  constructor(id: string, name: string, ratio: number, density: number) {
    this.id = id;
    this.name = name;
    this.ratio = ratio;
    this.density = density;
  }
}

export default class MixRecipe {
  id: string = '';
  name: string = '';
  items: Array<MixItem> = new Array<MixItem>();
  note: string = '';
  createdAt: number = 0;
  isBuiltin: boolean = false;

  constructor(id: string, name: string, isBuiltin: boolean) {
    this.id = id;
    this.name = name;
    this.isBuiltin = isBuiltin;
    this.createdAt = Date.now();
  }
}
