/** -------- 数据模型（V2） -------- */
@ObservedV2
export class Plant {
  @Trace id: number
  @Trace name: string
  @Trace species: string
  @Trace location: string
  @Trace createdAt: number

  constructor(id: number, name: string, species: string, location: string, createdAt: number) {
    this.id = id;
    this.name = name;
    this.species = species;
    this.location = location;
    this.createdAt = createdAt
  }
}

@ObservedV2
export class PlanTpl {
  @Trace id: number
  @Trace name: string
  @Trace type: string
  @Trace everyDays: number
  @Trace times: number
  @Trace createdAt: number

  constructor(id: number, name: string, type: string, everyDays: number, times: number, createdAt: number) {
    this.id = id;
    this.name = name;
    this.type = type;
    this.everyDays = everyDays;
    this.times = times;
    this.createdAt = createdAt
  }
}

@ObservedV2
export class PlantTask {
  @Trace id: number
  @Trace plantId: number
  @Trace type: string
  @Trace planDate: string // YYYY-MM-DD
  @Trace done: number // 0/1
  @Trace doneAt: number

  constructor(id: number, plantId: number, type: string, planDate: string, done: number, doneAt: number) {
    this.id = id;
    this.plantId = plantId;
    this.type = type;
    this.planDate = planDate;
    this.done = done;
    this.doneAt = doneAt
  }
}

@ObservedV2
export class PlantDraft {
  @Trace name: string = ''
  @Trace species: string = ''
  @Trace location: string = ''
}

@ObservedV2
export class TaskDraft {
  @Trace plantId: number = 0
  @Trace type: string = '浇水'
  @Trace planDate: string = ''
}

@ObservedV2
export class LogEntry {
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

export class _DayCell {
  key: string
  day: number // 1..31（0 表示占位）
  inMonth: number // 1: 当前月；0: 其他月
  iso: string // YYYY-MM-DD（占位为空串）
  isToday: number // 1/0
  constructor(key: string, day: number, inMonth: number, iso: string, isToday: number) {
    this.key = key;
    this.day = day;
    this.inMonth = inMonth;
    this.iso = iso;
    this.isToday = isToday
  }
}

@ObservedV2
export class Metric {
  @Trace id: number
  @Trace plantId: number
  @Trace height: number // cm
  @Trace width: number // cm
  @Trace score: number // 0~100
  @Trace createdAt: number

  constructor(id: number, plantId: number, height: number, width: number, score: number, createdAt: number) {
    this.id = id;
    this.plantId = plantId;
    this.height = height;
    this.width = width;
    this.score = score;
    this.createdAt = createdAt
  }
}

// —— 生长指标数据类型（若你工程里已有等价类型，可删去此定义，保持字段一致即可）——
@ObservedV2
export
class PlantMetric {
  @Trace id: number
  @Trace plantId: number
  @Trace height: number // 身高（cm）
  @Trace width: number // 冠幅（cm）
  @Trace score: number // 健康分（0~100）
  @Trace createdAt: number // 时间戳 ms

  constructor(id: number, plantId: number, height: number, width: number, score: number, createdAt: number) {
    this.id = id;
    this.plantId = plantId;
    this.height = height;
    this.width = width;
    this.score = score;
    this.createdAt = createdAt
  }
}

/** 简单模型（与 DB 字段一致即可） */
export interface CareTemplate { id: number; name: string; desc: string }
export interface CareRule { id: number; templateId: number; type: string; intervalDays: number; horizonDays: number }

//
