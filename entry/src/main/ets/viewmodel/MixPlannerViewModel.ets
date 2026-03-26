// /viewmodel/MixPlannerViewModel.ets
// V2 可观测 VM：内置配方 / 自定义编辑 / 计算 / 保存“我的配方”与调配记录

import MixRecipe, { MixItem } from '../model/MixRecipe';
import MixRun, { MixResultItem } from '../model/MixRun';

function genId(prefix: string): string {
  const t: number = Date.now();
  const r: number = Math.floor(Math.random() * 1000000);
  return `${prefix}_${t}_${r}`;
}

function round2(v: number): number {
  return Math.round(v * 100) / 100;
}

@ObservedV2
export class MixPlannerViewModel {
  plantId: number = 0;

  // 当前编辑的配方（名称可能来自内置或“自定义”）
  recipeName: string = '自定义配方';
  items: Array<MixItem> = new Array<MixItem>();

  // 总量（L）
  totalLiters: number = 10;

  // 内置与我的配方
  builtinRecipes: Array<MixRecipe> = new Array<MixRecipe>();
  myRecipes: Array<MixRecipe> = new Array<MixRecipe>();

  // 历史调配记录
  runs: Array<MixRun> = new Array<MixRun>();

  constructor(plantId: number) {
    this.plantId = plantId;
    this.loadBuiltin();
    this.loadDefaultCustom();
  }

  // 初始化时先准备内置配方，再给用户一份可编辑的默认自定义配方。
  // —— 初始化 —— 
  private loadBuiltin(): void {
    // 预置几个常用配方（密度kg/L为经验估算。为0时使用默认0.15）
    const r1: MixRecipe = new MixRecipe(genId('R'), '多肉·排水型(2:2:1)', true);
    r1.items = [
      new MixItem(genId('I'), '泥炭', 2, 0.12),
      new MixItem(genId('I'), '珍珠岩', 2, 0.10),
      new MixItem(genId('I'), '松鳞/树皮', 1, 0.18),
    ];

    const r2: MixRecipe = new MixRecipe(genId('R'), '观叶·通用(2:2:1)', true);
    r2.items = [
      new MixItem(genId('I'), '椰糠', 2, 0.10),
      new MixItem(genId('I'), '泥炭', 2, 0.12),
      new MixItem(genId('I'), '珍珠岩', 1, 0.10),
    ];

    const r3: MixRecipe = new MixRecipe(genId('R'), '兰科·透气(3:2)', true);
    r3.items = [
      new MixItem(genId('I'), '树皮/松鳞', 3, 0.18),
      new MixItem(genId('I'), '轻石/火山岩', 2, 0.25),
    ];

    const next: Array<MixRecipe> = new Array<MixRecipe>();
    next.push(r1); next.push(r2); next.push(r3);
    this.builtinRecipes = next;
  }

  private loadDefaultCustom(): void {
    this.recipeName = '自定义配方';
    const a: Array<MixItem> = new Array<MixItem>();
    a.push(new MixItem(genId('I'), '泥炭', 2, 0.12));
    a.push(new MixItem(genId('I'), '珍珠岩', 1, 0.10));
    this.items = a;
    this.totalLiters = 10;
  }

  // —— 选择内置 ——
  // 选择配方时总是深拷贝一份材料列表，避免修改编辑态时污染内置模板。
  chooseBuiltin(index: number): void {
    if (index < 0 || index >= this.builtinRecipes.length) {
      return;
    }
    const src: MixRecipe = this.builtinRecipes[index];
    this.recipeName = src.name;
    // 深拷贝
    const a: Array<MixItem> = new Array<MixItem>();
    for (let i: number = 0; i < src.items.length; i++) {
      const it: MixItem = src.items[i];
      a.push(new MixItem(genId('I'), it.name, it.ratio, it.density));
    }
    this.items = a;
  }

  // —— 自定义编辑 ——
  addItem(): void {
    const a: Array<MixItem> = new Array<MixItem>();
    for (let i: number = 0; i < this.items.length; i++) { a.push(this.items[i]); }
    a.push(new MixItem(genId('I'), '新材料', 1, 0.15));
    this.items = a;
  }

  removeItem(id: string): void {
    const a: Array<MixItem> = new Array<MixItem>();
    for (let i: number = 0; i < this.items.length; i++) {
      if (this.items[i].id !== id) { a.push(this.items[i]); }
    }
    this.items = a;
  }

  setItemName(id: string, name: string): void {
    const a: Array<MixItem> = new Array<MixItem>();
    for (let i: number = 0; i < this.items.length; i++) {
      const it: MixItem = this.items[i];
      if (it.id === id) {
        const n: MixItem = new MixItem(it.id, name, it.ratio, it.density);
        a.push(n);
      } else { a.push(it); }
    }
    this.items = a;
  }

  setItemRatio(id: string, ratio: number): void {
    let rv: number = ratio;
    if (rv < 0.1) { rv = 0.1; }
    if (rv > 99) { rv = 99; }
    const a: Array<MixItem> = new Array<MixItem>();
    for (let i: number = 0; i < this.items.length; i++) {
      const it: MixItem = this.items[i];
      if (it.id === id) {
        const n: MixItem = new MixItem(it.id, it.name, rv, it.density);
        a.push(n);
      } else { a.push(it); }
    }
    this.items = a;
  }

  setItemDensity(id: string, density: number): void {
    let dv: number = density;
    if (dv < 0) { dv = 0; }      // 0 表示使用默认0.15
    if (dv > 3) { dv = 3; }      // 合理上限
    const a: Array<MixItem> = new Array<MixItem>();
    for (let i: number = 0; i < this.items.length; i++) {
      const it: MixItem = this.items[i];
      if (it.id === id) {
        const n: MixItem = new MixItem(it.id, it.name, it.ratio, dv);
        a.push(n);
      } else { a.push(it); }
    }
    this.items = a;
  }

  setTotalLiters(v: number): void {
    let nv: number = v;
    if (nv < 1) { nv = 1; }
    if (nv > 200) { nv = 200; }
    this.totalLiters = Math.floor(nv);
  }

  sumRatio(): number {
    let s: number = 0;
    for (let i: number = 0; i < this.items.length; i++) { s += this.items[i].ratio; }
    if (s <= 0) { return 0.0001; }
    return s;
  }

  // —— 计算 ——
  // 配土计算的核心：先按 ratio 分摊总体积，再根据密度估算每项重量。
  compute(): Array<MixResultItem> {
    const sum: number = this.sumRatio();
    const out: Array<MixResultItem> = new Array<MixResultItem>();
    for (let i: number = 0; i < this.items.length; i++) {
      const it: MixItem = this.items[i];
      const liters: number = this.totalLiters * it.ratio / sum;
      const dens: number = it.density > 0 ? it.density : 0.15;
      const kg: number = liters * dens;
      out.push(new MixResultItem(it.name, round2(liters), round2(kg)));
    }
    return out;
  }

  // —— 保存为“我的配方” ——
  // “我的配方”更像可复用模板，保存时会冻结当前 items 的快照。
  saveMyRecipe(name: string, note: string): MixRecipe | undefined {
    if (name === '') { return undefined; }
    const rec: MixRecipe = new MixRecipe(genId('R'), name, false);
    const a: Array<MixItem> = new Array<MixItem>();
    for (let i: number = 0; i < this.items.length; i++) {
      const it: MixItem = this.items[i];
      a.push(new MixItem(genId('I'), it.name, it.ratio, it.density));
    }
    rec.items = a;
    rec.note = note;
    const next: Array<MixRecipe> = new Array<MixRecipe>();
    next.push(rec);
    for (let j: number = 0; j < this.myRecipes.length; j++) { next.push(this.myRecipes[j]); }
    this.myRecipes = next;
    return rec;
  }

  // —— 选择我的配方 ——
  chooseMyRecipe(index: number): void {
    if (index < 0 || index >= this.myRecipes.length) { return; }
    const src: MixRecipe = this.myRecipes[index];
    this.recipeName = src.name;
    const a: Array<MixItem> = new Array<MixItem>();
    for (let i: number = 0; i < src.items.length; i++) {
      const it: MixItem = src.items[i];
      a.push(new MixItem(genId('I'), it.name, it.ratio, it.density));
    }
    this.items = a;
  }

  // —— 保存一次调配 ——
  // 调配记录保存的是计算结果快照，后续查看历史时不依赖当前编辑态。
  saveRun(note: string): MixRun {
    const run: MixRun = new MixRun(genId('RUN'), this.recipeName, this.totalLiters);
    run.result = this.compute();
    run.note = note;
    const next: Array<MixRun> = new Array<MixRun>();
    next.push(run);
    for (let i: number = 0; i < this.runs.length; i++) { next.push(this.runs[i]); }
    this.runs = next;
    return run;
  }
}
