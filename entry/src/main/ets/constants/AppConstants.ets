// /constants/AppConstants.ets
// 应用程序常量定义
// 统一管理项目中的所有魔法数字，提高代码可读性和可维护性

/**
 * 浇水估算相关常量
 */
export namespace WaterConstants {
  /**
   * 介质保水系数
   * 不同介质的保水能力不同，系数越高，保水能力越强
   */
  export const RETENTION_SANDY = 0.8;      // 砂砾/透水：保水能力差
  export const RETENTION_GENERAL = 1.0;    // 通用：保水能力中等
  export const RETENTION_PEATY = 1.2;     // 泥炭偏保水：保水能力强
  export const RETENTION_ORCHID = 0.7;    // 兰花介质：保水能力差
  export const RETENTION_COCO = 1.1;       // 椰糠：保水能力较强

  /**
   * 浇水策略系数
   * 不同浇水方式的用水量不同
   */
  export const STRATEGY_FULL = 0.35;  // 彻底浸润：用水量较大
  export const STRATEGY_MAINT = 0.2;    // 日常保养：用水量较小

  /**
   * 植株类型系数
   * 不同植物的需水量不同
   */
  export const PLANT_SUCC = 0.7;       // 多肉：需水量少
  export const PLANT_FOLIAGE = 1.0;    // 观叶/热带：需水量中等
  export const PLANT_ORCHID = 0.8;     // 兰花：需水量较少
  export const PLANT_FLOWER = 1.1;     // 开花植物：需水量较多
  export const PLANT_FRUIT = 1.2;      // 果类植物：需水量多

  /**
   * 用水量估算比例
   * 用于计算下限和上限
   */
  export const WATER_RATIO_LOW = 0.85;   // 下限比例（中间值的 85%）
  export const WATER_RATIO_HIGH = 1.15;  // 上限比例（中间值的 115%）

  /**
   * 土壤孔隙率
   * 一般土壤的孔隙率约为 0.55
   */
  export const SOIL_POROSITY = 0.55;

  /**
   * 时间转换常量
   */
  export const MILLIS_PER_SECOND = 60000; // 毫秒转分钟
}

/**
 * 光照记录相关常量
 */
export namespace LightConstants {
  /**
   * 光照级别权重
   * 不同光照级别的强度权重
   */
  export const LEVEL_WEIGHT_LOW = 1.0;   // 弱光权重
  export const LEVEL_WEIGHT_MID = 1.5;   // 中光权重
  export const LEVEL_WEIGHT_HIGH = 2.0;  // 强光权重

  /**
   * 光照目标值（默认值）
   */
  export const TARGET_LUX_MIN_LOW = 12000;   // 达标下限（lux-minutes）
  export const TARGET_LUX_MIN_HIGH = 20000;  // 达标上限（满分参考值）
  export const TARGET_LUX_THRESHOLD = 25000; // 视为"过强"的阈值

  /**
   * 基础光照强度
   * 用于计算光照量
   */
  export const BASE_LUX_PER_MIN = 100; // 基础光照强度/分钟

  /**
   * 达标率阈值
   * 用于判断光照状态
   */
  export const RATE_THRESHOLD_INSUFF = 0.6; // 不足阈值（< 0.6）
  export const RATE_THRESHOLD_OK_LOW = 0.6;  // 适中下限（>= 0.6）
  export const RATE_THRESHOLD_OK_HIGH = 1.0; // 适中上限（<= 1.0）
  export const RATE_THRESHOLD_STRONG = 1.0; // 过强阈值（> 1.0）

  /**
   * 持续时间最小值
   */
  export const MIN_DURATION_MIN = 1; // 最小持续时间为 1 分钟
}

/**
 * 日期时间相关常量
 */
export namespace DateConstants {
  /**
   * 月份补零阈值
   */
  export const MONTH_SINGLE_DIGIT = 10; // 月份小于 10 时需要补零

  /**
   * 日期相关数值
   */
  export const DAYS_IN_WEEK = 7; // 一周天数
  export const DAYS_IN_MONTH = 30; // 一月天数（近似）
  export const MONTHS_IN_YEAR = 12; // 一年月数
}

/**
 * 植物相关常量
 */
export namespace PlantConstants {
  /**
   * 任务状态值
   */
  export const TASK_STATUS_PENDING = 0; // 待完成
  export const TASK_STATUS_DONE = 1;   // 已完成

  /**
   * 健康分范围
   */
  export const SCORE_MIN = 0;   // 最低健康分
  export const SCORE_MAX = 100; // 最高健康分

  /**
   * 日期范围
   */
  export const DAY_MIN = 1;  // 日期最小值
  export const DAY_MAX = 31; // 日期最大值
}

/**
 * 环境模拟相关常量
 */
export namespace EnvConstants {
  /**
   * 光照范围
   */
  export const LIGHT_MIN = 40;   // 最低光照
  export const LIGHT_MAX = 80;   // 最高光照
  export const LIGHT_OPTIMAL_MIN = 40;  // 适宜光照下限
  export const LIGHT_OPTIMAL_MAX = 80;  // 适宜光照上限

  /**
   * 土壤范围
   */
  export const SOIL_MIN = 25;   // 最低土壤湿度
  export const SOIL_MAX = 70;   // 最高土壤湿度
  export const SOIL_OPTIMAL_MIN = 40; // 适宜土壤下限
  export const SOIL_OPTIMAL_MAX = 70; // 适宜土壤上限

  /**
   * 湿度范围
   */
  export const HUMIDITY_MIN = 30; // 最低湿度
  export const HUMIDITY_MAX = 85; // 最高湿度
  export const HUMIDITY_OPTIMAL_MIN = 30; // 适宜湿度下限
  export const HUMIDITY_OPTIMAL_MAX = 85; // 适宜湿度上限

  /**
   * 光照阈值
   */
  export const LIGHT_THRESHOLD_LOW = 30;  // 光照不足阈值
  export const LIGHT_THRESHOLD_HIGH = 85;  // 光照过强阈值

  /**
   * 颜色计算系数
   */
  export const COLOR_BASE_GREEN = 40;  // 绿色基数
  export const COLOR_BASE_YELLOW = 180; // 黄色基数
  export const COLOR_ADJUSTMENT_GREEN = 0.6; // 绿色调整系数
  export const COLOR_ADJUSTMENT_YELLOW = 0.7; // 黄色调整系数

  /**
   * 计算系数
   */
  export const GREEN_BASE_CALC = 80;  // 绿色计算基数
  export const GREEN_ADJUSTMENT = 0.6;  // 绿色调整系数
  export const YELLOW_BASE_CALC = 180; // 黄色计算基数
  export const YELLOW_ADJUSTMENT = 0.7; // 黄色调整系数

  /**
   * 范围限制
   */
  export const CLAMP_MIN_GREEN = 60;  // 绿色最小值
  export const CLAMP_MAX_GREEN = 220; // 绿色最大值
  export const CLAMP_MIN_YELLOW = 100; // 黄色最小值
  export const CLAMP_MAX_YELLOW = 255; // 黄色最大值

  /**
   * 阈值
   */
  export const SOIL_THRESHOLD_LOW = 20; // 土壤过低阈值
  export const SOIL_THRESHOLD_HIGH = 50; // 土壤过高阈值

  /**
   * 计算基数
   */
  export const CALC_BASE_LIGHT = 180; // 光照计算基数
  export const CALC_BASE_HUMIDITY = 200; // 湿度计算基数
  export const CALC_ADJUSTMENT = 0.5; // 调整系数
}

/**
 * UI 相关常量
 */
export namespace UIConstants {
  /**
   * 尺寸常量
   */
  export const BUTTON_HEIGHT_NORMAL = 40;  // 普通按钮高度
  export const BUTTON_HEIGHT_LARGE = 52;   // 大按钮高度
  export const INPUT_HEIGHT = 40;    // 输入框高度
  export const ICON_SIZE = 24;       // 图标大小

  /**
   * 间距常量
   */
  export const SPACING_SMALL = 8;   // 小间距
  export const SPACING_NORMAL = 12; // 普通间距
  export const SPACING_LARGE = 16;   // 大间距

  /**
   * 圆角常量
   */
  export const BORDER_RADIUS_SMALL = 8;   // 小圆角
  export const BORDER_RADIUS_NORMAL = 12; // 普通圆角
  export const BORDER_RADIUS_LARGE = 16; // 大圆角

  /**
   * 字体大小常量
   */
  export const FONT_SIZE_SMALL = 12;   // 小字体
  export const FONT_SIZE_NORMAL = 14;  // 普通字体
  export const FONT_SIZE_LARGE = 16;   // 大字体
  export const FONT_SIZE_TITLE = 18;  // 标题字体
  export const FONT_SIZE_HEADING = 22; // 标题字体

  /**
   * 阴影常量
   */
  export const SHADOW_RADIUS = 8;    // 阴影圆角
  export const SHADOW_OFFSET_Y = 2; // 阴影 Y 轴偏移
}
