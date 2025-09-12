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