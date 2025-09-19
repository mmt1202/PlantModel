@ObservedV2
export class PlantLog {
  @Trace id: number
  @Trace plantId: number
  @Trace note: string
  @Trace createdAt: number

  constructor(id: number, plantId: number, note: string, createdAt: number) {
    this.id = id;
    this.plantId = plantId;
    this.note = note;
    this.createdAt = createdAt
  }
}

@ObservedV2
export class LogPhoto {
  @Trace id: number
  @Trace logId: number
  @Trace path: string // 原图（filesDir 下）
  @Trace thumbPath: string // 缩略图（可与原图相同；若无缩略图，则传原图）
  @Trace createdAt: number

  constructor(id: number, logId: number, path: string, thumbPath: string, createdAt: number) {
    this.id = id;
    this.logId = logId;
    this.path = path;
    this.thumbPath = thumbPath;
    this.createdAt = createdAt
  }
}