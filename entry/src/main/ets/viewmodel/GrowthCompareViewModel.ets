// /viewmodel/GrowthCompareViewModel.ets
// 前后对比 VM（V2 可观测对象；管理选择、对齐与保存）

import GrowthPair from '../model/GrowthPair';

function genId(prefix: string): string {
  const t: number = Date.now();
  const r: number = Math.floor(Math.random() * 1000000);
  return `${prefix}_${t}_${r}`;
}

@ObservedV2
export class GrowthCompareViewModel {
  @Trace plantId: number = 0;
  // 当前工作区（未保存）
  @Trace beforeUri: string = '';
  @Trace afterUri: string = '';
  @Trace note: string = '';
  // 对齐参数：仅作用于“后图”
  @Trace split: number = 0.5;       // 0..1
  @Trace zoom: number = 1.0;        // 缩放
  @Trace offsetX: number = 0;       // 平移X（vp）
  @Trace offsetY: number = 0;       // 平移Y（vp）
  @Trace showGrid: boolean = false; // 网格开关
  @Trace alignMode: boolean = false;// 对齐模式（启用后，单指拖动为平移）
  // 已保存的对比卡
  @Trace pairs: Array<GrowthPair> = new Array<GrowthPair>();

  constructor(plantId: number) {
    this.plantId = plantId;
  }

  setBefore(uri: string): void {
    this.beforeUri = uri;
  }

  setAfter(uri: string): void {
    this.afterUri = uri;
  }

  swap(): void {
    const tmp: string = this.beforeUri;
    this.beforeUri = this.afterUri;
    this.afterUri = tmp;
  }

  setSplit(v: number): void {
    if (v < 0.02) { this.split = 0.02; return; }
    if (v > 0.98) { this.split = 0.98; return; }
    this.split = v;
  }

  setZoom(z: number): void {
    let nz: number = z;
    if (nz < 0.5) { nz = 0.5; }
    if (nz > 4.0) { nz = 4.0; }
    this.zoom = nz;
  }

  panBy(dx: number, dy: number): void {
    // 限个相对范围，避免飘太远
    const maxPan: number = 600;
    let nx: number = this.offsetX + dx;
    let ny: number = this.offsetY + dy;
    if (nx < -maxPan) { nx = -maxPan; }
    if (nx > maxPan) { nx = maxPan; }
    if (ny < -maxPan) { ny = -maxPan; }
    if (ny > maxPan) { ny = maxPan; }
    this.offsetX = nx;
    this.offsetY = ny;
  }

  resetAlign(): void {
    this.zoom = 1.0;
    this.offsetX = 0;
    this.offsetY = 0;
  }

  toggleGrid(): void {
    this.showGrid = !this.showGrid;
  }

  toggleAlignMode(): void {
    this.alignMode = !this.alignMode;
  }

  canSave(): boolean {
    return this.beforeUri !== '' && this.afterUri !== '';
  }

  savePair(): GrowthPair | undefined {
    if (!this.canSave()) {
      return undefined;
    }
    const p: GrowthPair = new GrowthPair(genId('GP'), this.plantId, this.beforeUri, this.afterUri);
    p.note = this.note;
    p.alignGrid = this.showGrid;
    const next: Array<GrowthPair> = new Array<GrowthPair>();
    next.push(p);
    for (let i: number = 0; i < this.pairs.length; i++) { next.push(this.pairs[i]); }
    this.pairs = next;
    // 保存后不清空选择，方便继续微调或导出；如需清空可在此处重置
    return p;
  }
}
