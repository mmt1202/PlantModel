// /viewmodel/LightExposureViewModel.ets
// 手动记录视图模型（DB 持久化版）

import LightProfile from "../model/LightProfile";
import ExposureSession from "../model/ExposureSession";
import DailyLightStat from "../model/DailyLightStat";
import { LightLevel, LightStatus, levelWeight, clampRate, ymd, genId } from "../model/LightTypes";
import { RdbManager } from "./RdbManager";
import { relationalStore } from '@kit.ArkData';

@ObservedV2
export class LightExposureViewModel {
  // 状态
  @Trace plantId: number = 0;
  @Trace profile: LightProfile = new LightProfile(0);
  @Trace sessions: ExposureSession[] = [];
  @Trace dailyStats: DailyLightStat[] = [];
  @Trace hasActive: boolean = false;
  @Trace activeSession: ExposureSession | undefined = undefined;
  @Trace tick: number = 0; // 用于驱动 UI 刷新的时钟信号

  private rdbManager: RdbManager = RdbManager.getInstance();

  constructor(plantId: number) {
    this.plantId = plantId;
    this.profile = LightProfile.defaultFor(plantId);
  }

  // 初始化：从 DB 加载数据
  // 初始化时把 profile、历史 session 和当天统计一次性恢复到内存，页面后续只和 VM 交互。
  async init(): Promise<void> {
    if (!this.rdbManager.rdbStore) {
      return;
    }
    // 1. 加载 Profile
    const rsProfile = await this.rdbManager.rdbStore.querySql(
      `SELECT targetLuxMinLow, targetLuxMinHigh, preferredLevel FROM ${RdbManager.T_LIGHT_PROFILE} WHERE plantId = ?`,
      [this.plantId]
    );
    if (rsProfile.goToNextRow()) {
      this.profile.targetLuxMinLow = rsProfile.getLong(0);
      this.profile.targetLuxMinHigh = rsProfile.getLong(1);
      this.profile.preferredLevel = rsProfile.getLong(2);
      this.profile.plantId = this.plantId;
    } else {
      // 不存在则插入默认值
      const def = LightProfile.defaultFor(this.plantId);
      await this.rdbManager.rdbStore.insert(RdbManager.T_LIGHT_PROFILE, {
        plantId: this.plantId,
        targetLuxMinLow: def.targetLuxMinLow,
        targetLuxMinHigh: def.targetLuxMinHigh,
        preferredLevel: def.preferredLevel,
        updatedAt: Date.now()
      });
      this.profile = def;
    }
    rsProfile.close();

    // 2. 加载 Sessions
    const rsSession = await this.rdbManager.rdbStore.querySql(
      `SELECT id, startAt, endAt, durationMin, level, luxMinutes FROM ${RdbManager.T_EXPOSURE_SESSION} WHERE plantId = ? ORDER BY startAt DESC`,
      [this.plantId]
    );
    const loadedSessions: ExposureSession[] = [];
    while (rsSession.goToNextRow()) {
      const s = new ExposureSession(this.plantId);
      s.id = rsSession.getString(0);
      s.startAt = rsSession.getLong(1);
      s.endAt = rsSession.getLong(2);
      s.durationMin = rsSession.getLong(3);
      s.level = rsSession.getLong(4);
      s.luxMinutes = rsSession.getLong(5);
      loadedSessions.push(s);
    }
    rsSession.close();
    this.sessions = loadedSessions;

    // 3. 检查是否有进行中的任务 (endAt === 0)
    // 按 startAt DESC 排的，如果有进行中的，应该在最前面（或者混在其中，但逻辑上应该只有一个）
    // 我们找最新的一个 endAt == 0
    const active = this.sessions.find(s => s.endAt === 0);
    if (active) {
      this.activeSession = active;
      this.hasActive = true;
    } else {
      this.hasActive = false;
      this.activeSession = undefined;
    }

    // 4. 重建每日统计
    this.rebuildDailyStats();
  }

  // 刷新进度（由 UI 定时器调用）
  refreshProgress(): void {
    this.tick++;
  }

  // 开始手动会话
  // 开始手动会话：先写数据库里的进行中记录，再同步内存态和 AppStorage 标记。
  async startManual(level: LightLevel): Promise<void> {
    if (this.hasActive) {
      return;
    }
    const s: ExposureSession = ExposureSession.createStarted(this.plantId, level, Date.now());
    this.activeSession = s;
    this.hasActive = true;

    // 插入 DB (endAt=0)
    if (this.rdbManager.rdbStore) {
      await this.rdbManager.rdbStore.insert(RdbManager.T_EXPOSURE_SESSION, {
        id: s.id,
        plantId: s.plantId,
        startAt: s.startAt,
        endAt: 0,
        durationMin: 0,
        level: s.level,
        luxMinutes: 0
      });
      // 同步状态到 AppStorage
      AppStorage.setOrCreate<boolean>(`lighting_${this.plantId}`, true);
    }

    // 更新内存列表（插入到头部）
    this.sessions = [s, ...this.sessions];
    // 立即触发一次 UI 更新
    this.refreshProgress();
  }

  // 结束当前会话
  // 结束当前会话时会反算持续分钟数和 luxMinutes，然后只增量刷新当天统计。
  async endManualWithAutoDuration(): Promise<void> {
    if (!this.hasActive || this.activeSession === undefined) {
      return;
    }
    const endAt: number = Date.now();
    const durMin: number = Math.max(1, Math.floor((endAt - this.activeSession.startAt) / 60000));
    const luxMin: number = this.computeLuxMinutes(this.activeSession.level, durMin);
    
    this.activeSession.finishWith(endAt, luxMin);

    // 更新 DB
    if (this.rdbManager.rdbStore) {
      const val: relationalStore.ValuesBucket = {
        endAt: endAt,
        durationMin: durMin,
        luxMinutes: luxMin
      };
      const pred = new relationalStore.RdbPredicates(RdbManager.T_EXPOSURE_SESSION);
      pred.equalTo('id', this.activeSession.id);
      await this.rdbManager.rdbStore.update(val, pred);

      // 同步状态到 AppStorage
      AppStorage.setOrCreate<boolean>(`lighting_${this.plantId}`, false);
    }

    this.activeSession = undefined;
    this.hasActive = false;
    
    // 更新统计
    this.updateDailyStatFor(new Date(endAt));
  }

  // 直接补记
  // 直接补记用于补录历史/刚完成的光照，不会进入“进行中”状态。
  async addManualInstant(level: LightLevel, minutes: number): Promise<void> {
    const endAt: number = Date.now();
    const s: ExposureSession = ExposureSession.createInstant(this.plantId, level, minutes, endAt);
    s.luxMinutes = this.computeLuxMinutes(level, minutes);

    // 插入 DB
    if (this.rdbManager.rdbStore) {
      await this.rdbManager.rdbStore.insert(RdbManager.T_EXPOSURE_SESSION, {
        id: s.id,
        plantId: s.plantId,
        startAt: s.startAt,
        endAt: s.endAt,
        durationMin: s.durationMin,
        level: s.level,
        luxMinutes: s.luxMinutes
      });
    }

    this.sessions = [s, ...this.sessions];
    this.updateDailyStatFor(new Date(endAt));
  }

  // 删除记录
  // 删除记录后需要顺手纠正 active 状态和对应日期的聚合结果。
  async deleteSession(id: string): Promise<void> {
    if (this.rdbManager.rdbStore) {
      const pred = new relationalStore.RdbPredicates(RdbManager.T_EXPOSURE_SESSION);
      pred.equalTo('id', id);
      await this.rdbManager.rdbStore.delete(pred);
    }

    // 如果删除的是正在进行的
    if (this.activeSession && this.activeSession.id === id) {
      this.activeSession = undefined;
      this.hasActive = false;
      AppStorage.setOrCreate<boolean>(`lighting_${this.plantId}`, false);
    }

    // 更新内存列表
    const s = this.sessions.find(x => x.id === id);
    this.sessions = this.sessions.filter(x => x.id !== id);
    if (s && s.endAt > 0) {
      this.updateDailyStatFor(new Date(s.endAt));
    }
  }

  // lux-min 近似计算
  computeLuxMinutes(level: LightLevel, minutes: number): number {
    const basePerMin: number = 100; 
    const w: number = levelWeight(level);
    return Math.floor(minutes * basePerMin * w);
  }

  // 重建所有每日统计
  // 从 sessions 全量重建每日统计，适合初始化或需要兜底校正时使用。
  private rebuildDailyStats(): void {
    const map = new Map<string, DailyLightStat>();
    
    // 遍历所有已完成会话 (endAt > 0)
    for (const s of this.sessions) {
      if (s.endAt === 0) continue;
      const key = ymd(new Date(s.endAt));
      let stat = map.get(key);
      if (!stat) {
        const id = `D_${this.plantId}_${key}`;
        stat = new DailyLightStat(id);
        stat.plantId = this.plantId;
        stat.date = key;
        map.set(key, stat);
      }
      stat.luxMinutes += s.luxMinutes;
      stat.durationMin += s.durationMin;
    }

    // 计算率和状态
    const arr: DailyLightStat[] = [];
    for (const stat of map.values()) {
      this.calcStatStatus(stat);
      arr.push(stat);
    }

    // 排序（日期降序? 或保持无序由 get sevenDays 处理）
    // 为了方便，不强制排序，sevenDays 会自己找
    this.dailyStats = arr;
  }

  // 增量更新某一天的统计，避免每次结束会话都重扫全部历史。
  private updateDailyStatFor(day: Date): void {
    // 简单起见，直接重新计算当天的
    // 也可以复用 rebuildDailyStats 的逻辑，但为了性能只更新一天
    const key = ymd(day);
    let totalLux = 0;
    let totalMin = 0;
    
    for (const s of this.sessions) {
      if (s.endAt > 0 && ymd(new Date(s.endAt)) === key) {
        totalLux += s.luxMinutes;
        totalMin += s.durationMin;
      }
    }

    const id = `D_${this.plantId}_${key}`;
    const stat = new DailyLightStat(id);
    stat.plantId = this.plantId;
    stat.date = key;
    stat.luxMinutes = totalLux;
    stat.durationMin = totalMin;
    this.calcStatStatus(stat);

    // 更新数组
    const idx = this.dailyStats.findIndex(d => d.date === key);
    if (idx >= 0) {
      // 替换（触发观察更新需要替换数组或使用 splice，ArkTS V2 建议直接修改数组元素属性或替换数组）
      // 这里直接替换数组元素
      this.dailyStats[idx] = stat; 
    } else {
      this.dailyStats.push(stat);
    }
  }

  private calcStatStatus(stat: DailyLightStat): void {
    const high = this.profile.targetLuxMinHigh;
    const rate = clampRate(high <= 0 ? 0 : stat.luxMinutes / high);
    stat.rate = rate;
    
    if (rate < 0.6) {
      stat.status = LightStatus.INSUFF;
    } else if (rate > 1.0) {
      stat.status = LightStatus.STRONG;
    } else {
      stat.status = LightStatus.OK;
    }
  }

  // 获取今日达标（0..100）
  // 今日达标率会把“已完成历史 + 正在进行中的实时贡献”一起算进去。
  get todayRatePercent(): number {
    // 依赖 tick，确保每秒更新
    const _ = this.tick;
    
    const key: string = ymd(new Date());
    let totalLux: number = 0;

    // 查找今日已完成
    const stat = this.dailyStats.find(s => s.date === key);
    if (stat) {
      totalLux = stat.luxMinutes;
    }

    // 加上活跃会话的实时贡献
    if (this.hasActive && this.activeSession) {
      const now: number = Date.now();
      const durMin: number = Math.max(1, Math.floor((now - this.activeSession.startAt) / 60000));
      const activeLux: number = this.computeLuxMinutes(this.activeSession.level, durMin);
      totalLux += activeLux;
    }

    const high: number = this.profile.targetLuxMinHigh;
    const rate: number = clampRate(high <= 0 ? 0 : totalLux / high);
    return Math.floor(rate * 100);
  }

  get todayStatus(): LightStatus {
    const _ = this.tick; // 依赖 tick
    const key: string = ymd(new Date());
    const stat = this.dailyStats.find(s => s.date === key);
    
    // 此时也要考虑 active session 带来的变化吗？
    // 通常状态是基于总量的，所以应该考虑
    let totalLux = stat ? stat.luxMinutes : 0;
    
    if (this.hasActive && this.activeSession) {
      const now: number = Date.now();
      const durMin: number = Math.max(1, Math.floor((now - this.activeSession.startAt) / 60000));
      totalLux += this.computeLuxMinutes(this.activeSession.level, durMin);
    }
    
    const high = this.profile.targetLuxMinHigh;
    const rate = clampRate(high <= 0 ? 0 : totalLux / high);
    
    if (rate < 0.6) return LightStatus.INSUFF;
    if (rate > 1.0) return LightStatus.STRONG;
    return LightStatus.OK;
  }

  // 最近 7 天
  // 最近 7 天的数据专门服务图表展示；今天如果有 active session，会临时叠加实时值。
  get sevenDays(): DailyLightStat[] {
    const result: DailyLightStat[] = [];
    const base: Date = new Date();
    for (let i: number = 6; i >= 0; i--) {
      const d: Date = new Date(base.getFullYear(), base.getMonth(), base.getDate() - i);
      const key: string = ymd(d);
      
      const found = this.dailyStats.find(s => s.date === key);
      if (found) {
        // 如果是今天，需要加上 active 的部分用于显示吗？
        // 图表通常显示已完成的，或者包含实时的。为了一致性，最好包含实时的。
        if (i === 0 && this.hasActive && this.activeSession) {
           // 克隆一个临时的 stat 用于显示
           const temp = new DailyLightStat(found.id);
           temp.plantId = found.plantId;
           temp.date = found.date;
           temp.luxMinutes = found.luxMinutes;
           temp.durationMin = found.durationMin;
           temp.maxLux = found.maxLux;
           temp.rate = found.rate;
           temp.status = found.status;
           const now = Date.now();
           const durMin = Math.max(1, Math.floor((now - this.activeSession.startAt) / 60000));
           const extraLux = this.computeLuxMinutes(this.activeSession.level, durMin);
           temp.luxMinutes += extraLux;
           this.calcStatStatus(temp);
           result.push(temp);
        } else {
           result.push(found);
        }
      } else {
        // 没数据，造一个空的
        // 如果是今天且有 active
        if (i === 0 && this.hasActive && this.activeSession) {
          const id = `D_${this.plantId}_${key}`;
          const temp = new DailyLightStat(id);
          temp.plantId = this.plantId;
          temp.date = key;
          const now = Date.now();
          const durMin = Math.max(1, Math.floor((now - this.activeSession.startAt) / 60000));
          temp.luxMinutes = this.computeLuxMinutes(this.activeSession.level, durMin);
          this.calcStatStatus(temp);
          result.push(temp);
        } else {
          const id = `D_${this.plantId}_${key}`;
          const stat = new DailyLightStat(id);
          stat.plantId = this.plantId;
          stat.date = key;
          // status default OK? No, should be INSUFF if 0
          stat.status = LightStatus.INSUFF; 
          result.push(stat);
        }
      }
    }
    return result;
  }

  // 更新目标配置
  // 更新目标配置后，今日状态和达标率都可能变化，所以最后会刷新当天统计。
  async updateProfile(low: number, high: number, preferred: LightLevel): Promise<void> {
    // 自动切换逻辑：根据 low 值所在的范围，动态建议/切换强度偏好
    let finalPreferred = preferred;
    if (low < 10000) {
      finalPreferred = LightLevel.LOW;
    } else if (low < 15000) {
      finalPreferred = LightLevel.MID;
    } else {
      finalPreferred = LightLevel.HIGH;
    }

    this.profile.targetLuxMinLow = low;
    this.profile.targetLuxMinHigh = high;
    this.profile.preferredLevel = finalPreferred;
    this.profile.updatedAt = Date.now();

    // 更新 DB
    if (this.rdbManager.rdbStore) {
      const val: relationalStore.ValuesBucket = {
        targetLuxMinLow: low,
        targetLuxMinHigh: high,
        preferredLevel: finalPreferred,
        updatedAt: this.profile.updatedAt
      };
      const pred = new relationalStore.RdbPredicates(RdbManager.T_LIGHT_PROFILE);
      pred.equalTo('plantId', this.plantId);
      // 应该是 update，因为 init 时已经 ensure 了一条
      const rows = await this.rdbManager.rdbStore.update(val, pred);
      if (rows === 0) {
        // 理论上不会发生，除非被删了
        val.plantId = this.plantId;
        await this.rdbManager.rdbStore.insert(RdbManager.T_LIGHT_PROFILE, val);
      }
    }

    // 目标值变化可能影响今日状态，触发刷新
    this.updateDailyStatFor(new Date());
  }
}
