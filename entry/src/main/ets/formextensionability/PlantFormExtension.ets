import { formExtensionAbility } from "@kit.FormKit";
import { relationalStore } from "@kit.ArkData";
import { hilog } from "@kit.PerformanceAnalysisKit";
import { businessError } from "@kit.BasicServicesKit";
import { RdbManager } from "../viewmodel/RdbManager";
import { FormData, FormTaskItem } from "../model/FormData";
import { PlantTask } from "../model/PlantModel";

const DOMAIN = 0x1000;
const TAG = "PlantFormExtension";

/**
 * 植物日记桌面卡片扩展能力
 * 负责卡片的创建、更新、删除和点击事件处理
 */
export default class PlantFormExtension extends formExtensionAbility.FormExtensionAbility {
  private rdbManager: RdbManager = RdbManager.getInstance();
  private store: relationalStore.RdbStore | null = null;

  /**
   * 卡片创建回调
   * 初始化卡片数据并渲染
   */
  async onCreate(want: formExtensionAbility.Want): Promise<void> {
    hilog.info(DOMAIN, TAG, "Form onCreate called");
    try {
      // 初始化数据库连接
      await this.initDatabase();

      // 获取卡片数据
      const formData = await this.fetchFormData();

      // 渲染卡片
      await this.updateForm(want, formData);

      hilog.info(DOMAIN, TAG, "Form created successfully");
    } catch (err) {
      hilog.error(DOMAIN, TAG, "Failed to create form: %{public}s", JSON.stringify(err));
    }
  }

  /**
   * 卡片更新回调
   * 定时刷新或主动刷新时调用
   */
  async onUpdate(want: formExtensionAbility.Want): Promise<void> {
    hilog.info(DOMAIN, TAG, "Form onUpdate called");
    try {
      await this.initDatabase();
      const formData = await this.fetchFormData();
      await this.updateForm(want, formData);
      hilog.info(DOMAIN, TAG, "Form updated successfully");
    } catch (err) {
      hilog.error(DOMAIN, TAG, "Failed to update form: %{public}s", JSON.stringify(err));
    }
  }

  /**
   * 卡片点击回调
   * 处理用户点击事件
   */
  async onCast(
    want: formExtensionAbility.Want,
    formData: formExtensionAbility.FormProvider,
  ): Promise<void> {
    hilog.info(DOMAIN, TAG, "Form onCast called");
    try {
      // 获取点击事件的消息类型
      const message = want.parameters?.["message"];
      const taskId = want.parameters?.["taskId"];

      hilog.info(
        DOMAIN,
        TAG,
        "Cast message: %{public}s, taskId: %{public}s",
        message?.toString() || "unknown",
        taskId?.toString() || "0",
      );

      if (message === "complete_task" && taskId) {
        // 完成单个任务
        await this.completeTask(Number(taskId));

        // 刷新卡片
        const updatedData = await this.fetchFormData();
        await this.updateForm(want, updatedData);

        hilog.info(DOMAIN, TAG, "Task completed and form refreshed");
      } else if (message === "complete_all") {
        // 完成所有任务
        await this.completeAllTasks();

        // 刷新卡片
        const updatedData = await this.fetchFormData();
        await this.updateForm(want, updatedData);

        hilog.info(DOMAIN, TAG, "All tasks completed and form refreshed");
      } else if (message === "open_app") {
        // 打开应用
        await this.openApp();
      }
    } catch (err) {
      hilog.error(DOMAIN, TAG, "Failed to handle cast: %{public}s", JSON.stringify(err));
    }
  }

  /**
   * 卡片删除回调
   * 清理资源
   */
  async onDelete(want: formExtensionAbility.Want): Promise<void> {
    hilog.info(DOMAIN, TAG, "Form onDelete called");
    // 可以在这里清理卡片相关的资源
  }

  /**
   * 初始化数据库连接
   */
  private async initDatabase(): Promise<void> {
    try {
      this.store = this.rdbManager.rdbStore;
      if (!this.store) {
        hilog.warn(DOMAIN, TAG, "Database store is not initialized");
      }
    } catch (err) {
      hilog.error(DOMAIN, TAG, "Failed to init database: %{public}s", JSON.stringify(err));
    }
  }

  /**
   * 获取卡片数据
   */
  private async fetchFormData(): Promise<FormData> {
    const formData = new FormData();

    if (!this.store) {
      hilog.warn(DOMAIN, TAG, "Store is null, returning empty form data");
      return formData;
    }

    try {
      // 获取今天的日期字符串 (YYYY-MM-DD)
      const today = new Date();
      const todayStr = `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, "0")}-${String(today.getDate()).padStart(2, "0")}`;

      hilog.info(DOMAIN, TAG, "Fetching tasks for date: %{public}s", todayStr);

      // 查询今日所有任务
      const rs = await this.store.querySql(
        `SELECT t.id, t.plantId, t.type, t.planDate, t.done, t.doneAt, p.name as plantName
         FROM ${RdbManager.T_TASK} t
         LEFT JOIN ${RdbManager.T_PLANT} p ON t.plantId = p.id
         WHERE t.planDate = ?
         ORDER BY t.done ASC, t.id ASC`,
        [todayStr],
      );

      const allTasks: Array<FormTaskItem> = [];
      let completedCount = 0;

      while (rs.goToNextRow()) {
        const id = rs.getLong(0);
        const plantId = rs.getLong(1);
        const type = rs.getString(2);
        const planDate = rs.getString(3);
        const done = rs.getLong(4);
        const plantName = rs.getString(6) || "未知植物";

        if (done === 1) {
          completedCount++;
        } else {
          // 只添加未完成任务到列表
          allTasks.push(new FormTaskItem(id, plantId, plantName, type, planDate));
        }
      }
      rs.close();

      formData.todayTaskCount = allTasks.length + completedCount;
      formData.completedCount = completedCount;
      formData.pendingCount = allTasks.length;

      // 只显示前 3 个待办任务
      formData.tasks = allTasks.slice(0, 3);
      formData.lastUpdateTime = Date.now();

      hilog.info(
        DOMAIN,
        TAG,
        "Form data fetched: total=%{public}d, completed=%{public}d, pending=%{public}d",
        formData.todayTaskCount,
        formData.completedCount,
        formData.pendingCount,
      );
    } catch (err) {
      hilog.error(DOMAIN, TAG, "Failed to fetch form data: %{public}s", JSON.stringify(err));
    }

    return formData;
  }

  /**
   * 更新卡片显示
   */
  private async updateForm(want: formExtensionAbility.Want, formData: FormData): Promise<void> {
    try {
      // 获取表单上下文
      const formDataProxy = this.context.getFormContext(want);
      if (!formDataProxy) {
        hilog.error(DOMAIN, TAG, "Form context is null");
        return;
      }

      // 准备要更新的数据
      const formDataMap: Record<string, any> = {
        todayTaskCount: formData.todayTaskCount,
        completedCount: formData.completedCount,
        pendingCount: formData.pendingCount,
        tasks: formData.tasks.map((task) => ({
          id: task.id,
          plantId: task.plantId,
          plantName: task.plantName,
          type: task.type,
          planDate: task.planDate,
        })),
        lastUpdateTime: formData.lastUpdateTime,
      };

      // 更新卡片数据
      await formDataProxy.update(formDataMap);

      hilog.info(
        DOMAIN,
        TAG,
        "Form updated with data: %{public}s",
        JSON.stringify({
          todayTaskCount: formData.todayTaskCount,
          completedCount: formData.completedCount,
          pendingCount: formData.pendingCount,
        }),
      );
    } catch (err) {
      hilog.error(DOMAIN, TAG, "Failed to update form: %{public}s", JSON.stringify(err));
    }
  }

  /**
   * 完成单个任务
   */
  private async completeTask(taskId: number): Promise<void> {
    if (!this.store) return;

    try {
      const now = Date.now();
      await this.store.executeSql(
        `UPDATE ${RdbManager.T_TASK} SET done = 1, doneAt = ? WHERE id = ?`,
        [now, taskId],
      );
      hilog.info(DOMAIN, TAG, "Task %{public}d completed", taskId);
    } catch (err) {
      hilog.error(DOMAIN, TAG, "Failed to complete task: %{public}s", JSON.stringify(err));
    }
  }

  /**
   * 完成所有任务
   */
  private async completeAllTasks(): Promise<void> {
    if (!this.store) return;

    try {
      const today = new Date();
      const todayStr = `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, "0")}-${String(today.getDate()).padStart(2, "0")}`;
      const now = Date.now();

      await this.store.executeSql(
        `UPDATE ${RdbManager.T_TASK} SET done = 1, doneAt = ? WHERE planDate = ? AND done = 0`,
        [now, todayStr],
      );
      hilog.info(DOMAIN, TAG, "All tasks for %{public}s completed", todayStr);
    } catch (err) {
      hilog.error(DOMAIN, TAG, "Failed to complete all tasks: %{public}s", JSON.stringify(err));
    }
  }

  /**
   * 打开应用
   */
  private async openApp(): Promise<void> {
    try {
      const wantInfo: formExtensionAbility.Want = {
        bundleName: "com.example.plantdiary",
        abilityName: "EntryAbility",
        action: "ohos.want.action.home",
      };

      await this.context.startAbility(wantInfo);
      hilog.info(DOMAIN, TAG, "App opened successfully");
    } catch (err) {
      hilog.error(DOMAIN, TAG, "Failed to open app: %{public}s", JSON.stringify(err));
    }
  }
}
