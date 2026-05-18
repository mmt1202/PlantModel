/**
 * 桌面卡片数据模型
 * 用于在 FormExtensionAbility 和 UI 组件之间传递数据
 */
import { ObservedV2, Trace } from '@ohos.stateobservation';

/**
 * 卡片任务项数据结构
 */
@ObservedV2
export class FormTaskItem {
  @Trace id: number
  @Trace plantId: number
  @Trace plantName: string
  @Trace type: string
  @Trace planDate: string

  constructor(id: number, plantId: number, plantName: string, type: string, planDate: string) {
    this.id = id;
    this.plantId = plantId;
    this.plantName = plantName;
    this.type = type;
    this.planDate = planDate;
  }
}

/**
 * 卡片数据主模型
 * 包含今日任务统计和待办任务列表
 */
@ObservedV2
export class FormData {
  @Trace todayTaskCount: number = 0        // 今日任务总数
  @Trace completedCount: number = 0        // 已完成任务数
  @Trace pendingCount: number = 0          // 待完成任务数
  @Trace tasks: Array<FormTaskItem> = []   // 待办任务列表（最多显示 3 条）
  @Trace lastUpdateTime: number = 0        // 最后更新时间戳

  constructor() {
    this.lastUpdateTime = Date.now();
  }

  /**
   * 计算完成率百分比
   */
  getCompletionRate(): number {
    if (this.todayTaskCount === 0) {
      return 0;
    }
    return Math.floor((this.completedCount / this.todayTaskCount) * 100);
  }

  /**
   * 获取任务类型图标
   */
  getTaskIcon(type: string): string {
    switch (type) {
      case '浇水':
        return '💧';
      case '施肥':
        return '🌱';
      case '修剪':
        return '✂️';
      case '光照':
        return '☀️';
      case '转盆':
        return '🔄';
      default:
        return '📋';
    }
  }

  /**
   * 获取任务类型颜色
   */
  getTaskColor(type: string): number {
    switch (type) {
      case '浇水':
        return 0xFF3AAFA9;
      case '施肥':
        return 0xFF8E7CC3;
      case '修剪':
        return 0xFFE57373;
      case '光照':
        return 0xFFFFA726;
      case '转盆':
        return 0xFF7986CB;
      default:
        return 0xFF607D8B;
    }
  }
}

/**
 * 卡片配置数据
 */
export interface FormConfig {
  formId: number;                    // 卡片 ID
  formName: string;                  // 卡片名称
  description: string;               // 卡片描述
  jsComponentName: string;           // JS 组件名称（ArkTS 卡片留空）
  src: string;                       // 卡片 UI 源文件路径
  type: string;                      // 卡片类型（2x2, 2x4, 4x2 等）
  supportDimensions: Array<string>;  // 支持的尺寸
  updateEnabled: boolean;            // 是否启用定时更新
  updateDuration: number;            // 更新间隔（秒）
  scheduledUpdateTime: string;       // 定时更新时间（HH:mm）
  defaultDimension: string;          // 默认尺寸
  metaData: {
    description: string;             // 元数据描述
    apiVersion: string;              // API 版本
    source: string;                  // 数据源
    refreshInterval: number;         // 刷新间隔（秒）
  };
}
