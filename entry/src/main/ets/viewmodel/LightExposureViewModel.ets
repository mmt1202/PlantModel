// /viewmodel/LightExposureViewModel.ets
// 光照记录视图模型
// 负责光照会话的管理、数据持久化和统计计算
// 完整的光照会话管理
import LightProfile from "../model/LightProfile";
import ExposureSession from "../model/ExposureSession";
import DailyLightStat from "../model/DailyLightStat";
import { LightLevel, LightStatus, levelWeight, clampRate, ymd, genId } from "../model/LightTypes";
import { RdbManager } from "./RdbManager";
import { relationalStore } from "@kit.ArkData";

/**
 * 光照记录视图模型
 * 负责管理光照会话、数据持久化和统计计算
 */
@ObservedV2
export class LightExposureViewModel {
  // 状态属性
  @Trace plantId: number = 0; // 植物 ID
  @Trace profile: LightProfile = new LightProfile(0); // 光照配置档案
  @Trace sessions: ExposureSession[] = []; // 所有光照会话记录
  @Trace dailyStats: DailyLightStat[] = []; // 每日统计数据
  @Trace hasActive: boolean = false; // 是否有进行中的光照会话
  @Trace activeSession: ExposureSession | undefined = undefined; // 当前进行中的会话
  @Trace tick: number = 0; // 用于驱动 UI 刷新的时钟信号

  private rdbManager: RdbManager = RdbManager.getInstance(); // 数据库管理器

  /**
   * 构造函数
   * @param plantId 植物 ID
   */
  constructor(plantId: number) {
    this.plantId = plantId;
    this.profile = LightProfile.defaultFor(plantId); // 初始化默认光照配置
  }

  /**
   * 初始化方法
   * 从数据库加载数据，包括光照配置、历史会话和当天统计
   * 页面后续只与 ViewModel 交互，不直接访问数据库
   */
  async init(): Promise<void> {
    if (!this.rdbManager.rdbStore) {
      return;
    }
    // 1. 加载 Profile
    const rsProfile = await this.rdbManager.rdbStore.querySql(
      `SELECT targetLuxMinLow, targetLuxMinHigh, preferredLevel FROM ${RdbManager.T_LIGHT_PROFILE} WHERE plantId = ?`,
      [this.plantId],
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
        updatedAt: Date.now(),
      });
      this.profile = def;
    }
    rsProfile.close();

    // 2. 加载 Sessions
    const rsSession = await this.rdbManager.rdbStore.querySql(
      `SELECT id, startAt, endAt, durationMin, level, luxMinutes FROM ${RdbManager.T_EXPOSURE_SESSION} WHERE plantId = ? ORDER BY startAt DESC`,
      [this.plantId],
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

    // 3. 检查并清理异常的进行中会话 (endAt === 0)
    // 理论上只应该有一个进行中的会话，但如果出现异常可能有多个
    const activeSessions = this.sessions.filter((s) => s.endAt === 0);
    if (activeSessions.length > 1) {
      // 保留最新的（第一个），其他的标记为异常结束
      const latest = activeSessions[0];
      for (let i = 1; i < activeSessions.length; i++) {
        const abnormal = activeSessions[i];
        // 强制结束异常会话
        await this.forceCloseAbnormalSession(abnormal);
      }
      this.activeSession = latest;
      this.hasActive = true;
    } else if (activeSessions.length === 1) {
      this.activeSession = activeSessions[0];
      this.hasActive = true;
    } else {
      this.hasActive = false;
      this.activeSession = undefined;
    }

    // 4. 重建每日统计
    this.rebuildDailyStats();
  }

  /**
   * 刷新进度
   * 由 UI 定时器调用，用于触发 UI 实时更新
   * 通过增加 tick 值来驱动响应式更新
   */
  refreshProgress(): void {
    this.tick++; // 增加 tick 值，触发 UI 刷新
  }

  /**
   * 开始手动光照会话
   * 先在数据库中创建进行中记录，再同步内存状态和 AppStorage 标记
   * @param level 光照级别（弱光/中光/强光）
   */
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
        luxMinutes: 0,
      });
      // 同步状态到 AppStorage
      AppStorage.setOrCreate<boolean>(`lighting_${this.plantId}`, true);
    }

    // 更新内存列表（插入到头部）
    this.sessions = [s, ...this.sessions];
    // 立即触发一次 UI 更新
    this.refreshProgress();
  }

  /**
   * 结束当前光照会话
   * 自动计算持续时间和光照量，然后刷新当天统计
   */
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
        luxMinutes: luxMin,
      };
      const pred = new relationalStore.RdbPredicates(RdbManager.T_EXPOSURE_SESSION);
      pred.equalTo("id", this.activeSession.id);
      await this.rdbManager.rdbStore.update(val, pred);

      // 同步状态到 AppStorage
      AppStorage.setOrCreate<boolean>(`lighting_${this.plantId}`, false);
    }

    this.activeSession = undefined;
    this.hasActive = false;

    // 更新统计
    this.updateDailyStatFor(new Date(endAt));
  }

  /**
   * 直接补记光照记录
   * 用于补录历史或刚完成的光照，不会进入"进行中"状态
   * @param level 光照级别
   * @param minutes 光照时长（分钟）
   */
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
        luxMinutes: s.luxMinutes,
      });
    }

    this.sessions = [s, ...this.sessions];
    this.updateDailyStatFor(new Date(endAt));
  }

  /**
   * 强制关闭异常的进行中会话
   * 用于清理多个进行中会话的异常情况
   * @param session 要关闭的会话
   */
  private async forceCloseAbnormalSession(session: ExposureSession): Promise<void> {
    const endAt: number = Date.now();
    const durMin: number = Math.max(1, Math.floor((endAt - session.startAt) / 60000));
    const luxMin: number = this.computeLuxMinutes(session.level, durMin);

    // 更新数据库
    if (this.rdbManager.rdbStore) {
      const val: relationalStore.ValuesBucket = {
        endAt: endAt,
        durationMin: durMin,
        luxMinutes: luxMin,
      };
      const pred = new relationalStore.RdbPredicates(RdbManager.T_EXPOSURE_SESSION);
      pred.equalTo("id", session.id);
      await this.rdbManager.rdbStore.update(val, pred);
    }

    // 更新内存中的会话对象
    session.finishWith(endAt, luxMin);

    // 从内存列表中移除（因为已经不是进行中了）
    this.sessions = this.sessions.filter((s) => s.id !== session.id);

    console.warn(`强制关闭异常会话：${session.id}, 时长：${durMin}分钟`);
  }

  /**
   * 删除光照记录
   * 删除后会纠正进行中状态和对应日期的统计结果
   * @param id 要删除的会话 ID
   */
  async deleteSession(id: string): Promise<void> {
    if (this.rdbManager.rdbStore) {
      const pred = new relationalStore.RdbPredicates(RdbManager.T_EXPOSURE_SESSION);
      pred.equalTo("id", id);
      await this.rdbManager.rdbStore.delete(pred);
    }

    // 如果删除的是正在进行的
    if (this.activeSession && this.activeSession.id === id) {
      this.activeSession = undefined;
      this.hasActive = false;
      AppStorage.setOrCreate<boolean>(`lighting_${this.plantId}`, false);
    }

    // 更新内存列表
    const s = this.sessions.find((x) => x.id === id);
    this.sessions = this.sessions.filter((x) => x.id !== id);
    if (s && s.endAt > 0) {
      this.updateDailyStatFor(new Date(s.endAt));
    }
  }

  /**
   * 计算光照量（lux-min）
   * 基于光照级别和时长计算等效光照量
   * @param level 光照级别
   * @param minutes 光照时长（分钟）
   * @returns 计算后的光照量（lux-min）
   */
  computeLuxMinutes(level: LightLevel, minutes: number): number {
    const basePerMin: number = 100; // 基础光照强度/分钟
    const w: number = levelWeight(level); // 光照级别权重
    return Math.floor(minutes * basePerMin * w); // 计算并取整
  }

  /**
   * 重建所有每日统计
   * 从所有光照会话中重新计算每日统计数据
   * 适合初始化或需要兜底校正时使用
   */
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

  /**
   * 增量更新某一天的统计
   * 只更新指定日期的统计数据，避免每次结束会话都重扫全部历史
   * @param day 要更新的日期
   */
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
    const idx = this.dailyStats.findIndex((d) => d.date === key);
    if (idx >= 0) {
      // 替换（触发观察更新需要替换数组或使用 splice，ArkTS V2 建议直接修改数组元素属性或替换数组）
      // 这里直接替换数组元素
      this.dailyStats[idx] = stat;
    } else {
      this.dailyStats.push(stat);
    }
  }

  /**
   * 计算统计状态
   * 根据光照量计算达标率和状态（不足/适中/过强）
   * @param stat 每日统计对象
   */
  private calcStatStatus(stat: DailyLightStat): void {
    const high = this.profile.targetLuxMinHigh; // 目标上限
    const rate = clampRate(high <= 0 ? 0 : stat.luxMinutes / high); // 计算达标率并限制在 0-1 之间
    stat.rate = rate;

    // 根据达标率判断状态
    if (rate < 0.6) {
      stat.status = LightStatus.INSUFF; // 不足
    } else if (rate > 1.0) {
      stat.status = LightStatus.STRONG; // 过强
    } else {
      stat.status = LightStatus.OK; // 适中
    }
  }

  /**
   * 获取今日达标率
   * 计算今日光照的达标百分比（0-100）
   * 包含已完成的历史记录和正在进行中的实时贡献
   */
  get todayRatePercent(): number {
    // 依赖 tick，确保每秒更新
    const _ = this.tick;

    const key: string = ymd(new Date());
    let totalLux: number = 0;

    // 查找今日已完成
    const stat = this.dailyStats.find((s) => s.date === key);
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

  /**
   * 获取今日光照状态
   * 计算今日光照的状态（不足/适中/过强）
   * 包含已完成的历史记录和正在进行中的实时贡献
   */
  get todayStatus(): LightStatus {
    const _ = this.tick; // 依赖 tick，确保实时更新
    const key: string = ymd(new Date());
    const stat = this.dailyStats.find((s) => s.date === key);

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

  /**
   * 获取最近 7 天的统计数据
   * 专门用于图表展示
   * 今天如果有进行中的光照会话，会临时叠加实时值
   */
  get sevenDays(): DailyLightStat[] {
    const result: DailyLightStat[] = [];
    const base: Date = new Date();
    for (let i: number = 6; i >= 0; i--) {
      const d: Date = new Date(base.getFullYear(), base.getMonth(), base.getDate() - i);
      const key: string = ymd(d);

      const found = this.dailyStats.find((s) => s.date === key);
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

  /**
   * 更新光照目标配置
   * 更新后会自动切换光照偏好级别，并刷新当天统计
   * @param low 目标下限（lux-min）
   * @param high 目标上限（lux-min）
   * @param preferred 偏好的光照级别
   */
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
        updatedAt: this.profile.updatedAt,
      };
      const pred = new relationalStore.RdbPredicates(RdbManager.T_LIGHT_PROFILE);
      pred.equalTo("plantId", this.plantId);
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
