import { relationalStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

export class RdbManager {
  static instance: RdbManager | null = null
  public rdbStore: relationalStore.RdbStore | null = null;
  static readonly DB_NAME: string = 'plantdiary.db'
  static readonly T_PLANT: string = 'plant'
  static readonly T_TASK: string = 'task'
  static readonly T_TPL: string = 'tpl' // 周期模板
  static readonly T_LOG: string = 'log' // ← 新增：日志表
  static readonly T_METRIC: string = 'metric'
  static readonly T_LOG_PHOTO: string = 'log_photo'
  static readonly T_TEMPLATE: string = 'care_template'
  static readonly T_RULE: string = 'care_rule'
  static readonly T_LIGHT_PROFILE: string = 'light_profile'
  static readonly T_EXPOSURE_SESSION: string = 'exposure_session'

  static getInstance(): RdbManager {
    if (!RdbManager.instance) {
      RdbManager.instance = new RdbManager()
    }
    return RdbManager.instance
  }

  async initDb(context: common.Context) {
    const config: relationalStore.StoreConfig = {
      name: RdbManager.DB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1,
      encrypt: false,
      isReadOnly: false,
    }
    this.rdbStore = await relationalStore.getRdbStore(context, config)

    await this.rdbStore.executeSql(
      `CREATE TABLE IF NOT EXISTS ${RdbManager.T_PLANT}(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        species TEXT,
        location TEXT,
        createdAt INTEGER
      )`)
    await this.rdbStore.executeSql(
      `CREATE TABLE IF NOT EXISTS ${RdbManager.T_TASK}(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plantId INTEGER NOT NULL,
        type TEXT NOT NULL,
        planDate TEXT NOT NULL,
        done INTEGER DEFAULT 0,
        doneAt INTEGER DEFAULT 0
      )`)
    await this.rdbStore.executeSql(
      `CREATE TABLE IF NOT EXISTS ${RdbManager.T_TPL}(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        everyDays INTEGER NOT NULL,
        times INTEGER NOT NULL,
        createdAt INTEGER
      )`)
    // ← 新增日志表
    await this.rdbStore.executeSql(
      `CREATE TABLE IF NOT EXISTS ${RdbManager.T_LOG}(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plantId INTEGER NOT NULL,
        note TEXT NOT NULL,
        createdAt INTEGER
      )`)
    await this.rdbStore.executeSql(
      `CREATE TABLE IF NOT EXISTS ${RdbManager.T_METRIC}(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plantId INTEGER NOT NULL,
        height REAL DEFAULT 0,
        width REAL DEFAULT 0,
        score INTEGER DEFAULT 0,
        createdAt INTEGER NOT NULL
      )`)
    // —— 日志图片表 ——
    await this.rdbStore.executeSql(
      `CREATE TABLE IF NOT EXISTS ${RdbManager.T_LOG_PHOTO}(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        logId INTEGER NOT NULL,
        path TEXT NOT NULL,
        thumbPath TEXT NOT NULL,
        createdAt INTEGER NOT NULL
      )`)
    await this.rdbStore.executeSql(
      `CREATE TABLE IF NOT EXISTS ${RdbManager.T_TEMPLATE}(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    desc TEXT
  )`
    )
    await this.rdbStore.executeSql(
      `CREATE TABLE IF NOT EXISTS ${RdbManager.T_RULE}(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    templateId INTEGER NOT NULL,
    type TEXT NOT NULL,
    intervalDays INTEGER NOT NULL,
    horizonDays INTEGER NOT NULL
  )`
    )

    // ===== LIGHT EXPOSURE (光照) =====
    // 光照配置 (plantId 为主键，每植物一条)
    await this.rdbStore.executeSql(
      `CREATE TABLE IF NOT EXISTS ${RdbManager.T_LIGHT_PROFILE}(
        plantId INTEGER PRIMARY KEY,
        targetLuxMinLow INTEGER NOT NULL,
        targetLuxMinHigh INTEGER NOT NULL,
        preferredLevel INTEGER NOT NULL,
        updatedAt INTEGER
      )`
    )
    // 光照会话 (id 为主键，endAt=0 表示进行中)
    await this.rdbStore.executeSql(
      `CREATE TABLE IF NOT EXISTS ${RdbManager.T_EXPOSURE_SESSION}(
        id TEXT PRIMARY KEY,
        plantId INTEGER NOT NULL,
        startAt INTEGER NOT NULL,
        endAt INTEGER DEFAULT 0,
        durationMin INTEGER DEFAULT 0,
        level INTEGER NOT NULL,
        luxMinutes INTEGER DEFAULT 0,
        note TEXT
      )`
    )

    // ===== TASK（任务）=====
    // 唯一：同一植物 + 类型 + 计划日 不重复
    await this.rdbStore.executeSql(
      `CREATE UNIQUE INDEX IF NOT EXISTS idx_task_unique
   ON ${RdbManager.T_TASK}(plantId, type, planDate)`
    )
    // 常用查询/排序：按日期、按植物
    await this.rdbStore.executeSql(
      `CREATE INDEX IF NOT EXISTS idx_task_planDate
   ON ${RdbManager.T_TASK}(planDate)`
    )
    await this.rdbStore.executeSql(
      `CREATE INDEX IF NOT EXISTS idx_task_plantId
   ON ${RdbManager.T_TASK}(plantId)`
    )

    // ===== LOG（日志）=====
    // 典型查询：WHERE plantId=? ORDER BY createdAt DESC
    // 用组合索引即可，避免再单独建 plantId / createdAt 两个索引的重复
    await this.rdbStore.executeSql(
      `CREATE INDEX IF NOT EXISTS idx_log_plant_created
   ON ${RdbManager.T_LOG}(plantId, createdAt)`
    )

    // ===== LOG_PHOTO（日志照片）=====
    await this.rdbStore.executeSql(
      `CREATE INDEX IF NOT EXISTS idx_logphoto_logId
   ON ${RdbManager.T_LOG_PHOTO}(logId)`
    )

    // ===== METRIC（指标）=====
    // 典型查询：按植物 + 时间范围/排序
    await this.rdbStore.executeSql(
      `CREATE INDEX IF NOT EXISTS idx_metric_plant_created
   ON ${RdbManager.T_METRIC}(plantId, createdAt)`
    )
  }

  // 启动一次性初始化 5 个模板（存在即跳过）
  async ensureCareTemplates(): Promise<void> {
    if (!this.rdbStore) {
      return
    }
    const rs = await this.rdbStore.querySql(`SELECT COUNT(1) FROM ${RdbManager.T_TEMPLATE}`, [])
    let count: number = 0
    if (rs.goToNextRow()) {
      count = rs.getLong(0)
    }
    rs.close()
    if (count > 0) {
      return
    }

    // 插入模板
    const idSucc: number = await this.rdbStore.insert(RdbManager.T_TEMPLATE, { name: '多肉', desc: '耐旱，少浇' })
    const idMon: number = await this.rdbStore.insert(RdbManager.T_TEMPLATE, { name: '龟背竹', desc: '喜湿散光' })
    const idRose: number = await this.rdbStore.insert(RdbManager.T_TEMPLATE, { name: '月季', desc: '勤花，需修剪' })
    const idPoth: number = await this.rdbStore.insert(RdbManager.T_TEMPLATE, { name: '绿萝', desc: '易养，见光' })
    const idIvy: number = await this.rdbStore.insert(RdbManager.T_TEMPLATE, { name: '常春藤', desc: '通风散光' })

    // 规则：type, intervalDays, horizonDays(生成周期)
    // 多肉：浇水 14 天，施肥 45 天
    await this.rdbStore.insert(RdbManager.T_RULE, {
      templateId: idSucc,
      type: '浇水',
      intervalDays: 14,
      horizonDays: 90
    })
    await this.rdbStore.insert(RdbManager.T_RULE, {
      templateId: idSucc,
      type: '施肥',
      intervalDays: 45,
      horizonDays: 90
    })

    // 龟背竹：浇水 7，施肥 30，修剪 60
    await this.rdbStore.insert(RdbManager.T_RULE, {
      templateId: idMon,
      type: '浇水',
      intervalDays: 7,
      horizonDays: 90
    })
    await this.rdbStore.insert(RdbManager.T_RULE, {
      templateId: idMon,
      type: '施肥',
      intervalDays: 30,
      horizonDays: 120
    })
    await this.rdbStore.insert(RdbManager.T_RULE, {
      templateId: idMon,
      type: '修剪',
      intervalDays: 60,
      horizonDays: 180
    })

    // 月季：浇水 3，施肥 14，修剪 30
    await this.rdbStore.insert(RdbManager.T_RULE, {
      templateId: idRose,
      type: '浇水',
      intervalDays: 3,
      horizonDays: 60
    })
    await this.rdbStore.insert(RdbManager.T_RULE, {
      templateId: idRose,
      type: '施肥',
      intervalDays: 14,
      horizonDays: 90
    })
    await this.rdbStore.insert(RdbManager.T_RULE, {
      templateId: idRose,
      type: '修剪',
      intervalDays: 30,
      horizonDays: 120
    })

    // 绿萝：浇水 5，施肥 30
    await this.rdbStore.insert(RdbManager.T_RULE, {
      templateId: idPoth,
      type: '浇水',
      intervalDays: 5,
      horizonDays: 90
    })
    await this.rdbStore.insert(RdbManager.T_RULE, {
      templateId: idPoth,
      type: '施肥',
      intervalDays: 30,
      horizonDays: 120
    })

    // 常春藤：浇水 7，施肥 30
    await this.rdbStore.insert(RdbManager.T_RULE, {
      templateId: idIvy,
      type: '浇水',
      intervalDays: 7,
      horizonDays: 90
    })
    await this.rdbStore.insert(RdbManager.T_RULE, {
      templateId: idIvy,
      type: '施肥',
      intervalDays: 30,
      horizonDays: 120
    })
  }
  // 查询所有活跃的光照会话 (endAt=0)
  async getActiveLightSessions(): Promise<Map<number, boolean>> {
    const map = new Map<number, boolean>()
    if (!this.rdbStore) return map

    try {
      const rs = await this.rdbStore.querySql(
        `SELECT DISTINCT plantId FROM ${RdbManager.T_EXPOSURE_SESSION} WHERE endAt = 0`, []
      )
      while (rs.goToNextRow()) {
        map.set(rs.getLong(0), true)
      }
      rs.close()
    } catch (e) {
      // 失败降级：返回空 map
    }
    return map
  }
}