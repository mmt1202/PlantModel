// /model/MixRun.ets
// 一次调配结果与条目

export class MixResultItem {
  name: string = '';
  liters: number = 0;
  kg: number = 0;

  constructor(name: string, liters: number, kg: number) {
    this.name = name;
    this.liters = liters;
    this.kg = kg;
  }
}

export default class MixRun {
  id: string = '';
  recipeName: string = '';
  totalLiters: number = 0;
  result: Array<MixResultItem> = new Array<MixResultItem>();
  note: string = '';
  createdAt: number = 0;

  constructor(id: string, recipeName: string, totalLiters: number) {
    this.id = id;
    this.recipeName = recipeName;
    this.totalLiters = totalLiters;
    this.createdAt = Date.now();
  }
}
