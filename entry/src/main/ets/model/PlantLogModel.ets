// /model/PlantLogModel.ets
// 植物日志和日志照片模型

/**
 * 植物日志类
 * 记录植物的养护记录和观察笔记
 */
@ObservedV2
export class PlantLog {
  @Trace id: number; // 日志唯一标识
  @Trace plantId: number; // 关联的植物 ID
  @Trace note: string; // 日志内容/备注
  @Trace createdAt: number; // 创建时间戳

  /**
   * 构造函数
   * @param id 日志唯一标识
   * @param plantId 关联的植物 ID
   * @param note 日志内容/备注
   * @param createdAt 创建时间戳
   */
  constructor(id: number, plantId: number, note: string, createdAt: number) {
    this.id = id;
    this.plantId = plantId;
    this.note = note;
    this.createdAt = createdAt;
  }
}

/**
 * 日志照片类
 * 记录与日志关联的照片
 */
@ObservedV2
export class LogPhoto {
  @Trace id: number; // 照片唯一标识
  @Trace logId: number; // 关联的日志 ID
  @Trace path: string; // 原图路径（filesDir 下）
  @Trace thumbPath: string; // 缩略图路径（可与原图相同；若无缩略图，则传原图）
  @Trace createdAt: number; // 创建时间戳

  /**
   * 构造函数
   * @param id 照片唯一标识
   * @param logId 关联的日志 ID
   * @param path 原图路径
   * @param thumbPath 缩略图路径
   * @param createdAt 创建时间戳
   */
  constructor(id: number, logId: number, path: string, thumbPath: string, createdAt: number) {
    this.id = id;
    this.logId = logId;
    this.path = path;
    this.thumbPath = thumbPath;
    this.createdAt = createdAt;
  }
}
