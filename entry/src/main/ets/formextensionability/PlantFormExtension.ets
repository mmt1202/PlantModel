import { FormExtensionAbility, Want, FormProvider } from "@kit.FormKit";
import { relationalStore } from "@kit.ArkData";
import { hilog } from "@kit.PerformanceAnalysisKit";
import { BusinessError } from "@kit.BasicServicesKit";
import { RdbManager } from "../viewmodel/RdbManager";
import { FormData, FormTaskItem } from "../model/FormData";

const DOMAIN = 0x1000;
const TAG = "PlantFormExtension";

interface TaskDataItem {
  id: number;
  plantId: number;
  plantName: string;
  type: string;
  planDate: string;
}

interface FormDataMap {
  todayTaskCount: number;
  completedCount: number;
  pendingCount: number;
  tasks: Array<TaskDataItem>;
  lastUpdateTime: number;
}

export default class PlantFormExtension extends FormExtensionAbility {
  private rdbManager: RdbManager = RdbManager.getInstance();
  private store: relationalStore.RdbStore | null = null;

  async onCreate(want: Want): Promise<void> {
    hilog.info(DOMAIN, TAG, "Form onCreate called");
    try {
      await this.initDatabase();
      const formData = await this.fetchFormData();
      await this.updateForm(want, formData);
      hilog.info(DOMAIN, TAG, "Form created successfully");
    } catch (err) {
      const error = err as BusinessError;
      hilog.error(DOMAIN, TAG, "Failed to create form: %{public}s", JSON.stringify(error));
    }
  }

  async onUpdate(want: Want): Promise<void> {
    hilog.info(DOMAIN, TAG, "Form onUpdate called");
    try {
      await this.initDatabase();
      const formData = await this.fetchFormData();
      await this.updateForm(want, formData);
      hilog.info(DOMAIN, TAG, "Form updated successfully");
    } catch (err) {
      const error = err as BusinessError;
      hilog.error(DOMAIN, TAG, "Failed to update form: %{public}s", JSON.stringify(error));
    }
  }

  async onCast(want: Want, formProvider: FormProvider): Promise<void> {
    hilog.info(DOMAIN, TAG, "Form onCast called");
    try {
      const message = want.parameters?.["message"] as string | undefined;
      const taskId = want.parameters?.["taskId"] as number | undefined;

      hilog.info(
        DOMAIN,
        TAG,
        "Cast message: %{public}s, taskId: %{public}s",
        message || "unknown",
        taskId?.toString() || "0",
      );

      if (message === "complete_task" && taskId) {
        await this.completeTask(taskId);
        const updatedData = await this.fetchFormData();
        await this.updateForm(want, updatedData);
        hilog.info(DOMAIN, TAG, "Task completed and form refreshed");
      } else if (message === "complete_all") {
        await this.completeAllTasks();
        const updatedData = await this.fetchFormData();
        await this.updateForm(want, updatedData);
        hilog.info(DOMAIN, TAG, "All tasks completed and form refreshed");
      } else if (message === "open_app") {
        await this.openApp();
      }
    } catch (err) {
      const error = err as BusinessError;
      hilog.error(DOMAIN, TAG, "Failed to handle cast: %{public}s", JSON.stringify(error));
    }
  }

  async onDelete(want: Want): Promise<void> {
    hilog.info(DOMAIN, TAG, "Form onDelete called");
  }

  private async initDatabase(): Promise<void> {
    try {
      this.store = this.rdbManager.rdbStore;
      if (!this.store) {
        hilog.warn(DOMAIN, TAG, "Database store is not initialized");
      }
    } catch (err) {
      const error = err as BusinessError;
      hilog.error(DOMAIN, TAG, "Failed to init database: %{public}s", JSON.stringify(error));
    }
  }

  private async fetchFormData(): Promise<FormData> {
    const formData = new FormData();

    if (!this.store) {
      hilog.warn(DOMAIN, TAG, "Store is null, returning empty form data");
      return formData;
    }

    try {
      const today = new Date();
      const todayStr = `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, "0")}-${String(today.getDate()).padStart(2, "0")}`;

      hilog.info(DOMAIN, TAG, "Fetching tasks for date: %{public}s", todayStr);

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
          allTasks.push(new FormTaskItem(id, plantId, plantName, type, planDate));
        }
      }
      rs.close();

      formData.todayTaskCount = allTasks.length + completedCount;
      formData.completedCount = completedCount;
      formData.pendingCount = allTasks.length;
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
      const error = err as BusinessError;
      hilog.error(DOMAIN, TAG, "Failed to fetch form data: %{public}s", JSON.stringify(error));
    }

    return formData;
  }

  private async updateForm(want: Want, formData: FormData): Promise<void> {
    try {
      const formProvider = this.context.getFormContext(want);
      if (!formProvider) {
        hilog.error(DOMAIN, TAG, "Form context is null");
        return;
      }

      const taskItems: Array<TaskDataItem> = [];
      for (let i = 0; i < formData.tasks.length; i++) {
        const task = formData.tasks[i];
        const item: TaskDataItem = {
          id: task.id,
          plantId: task.plantId,
          plantName: task.plantName,
          type: task.type,
          planDate: task.planDate,
        };
        taskItems.push(item);
      }

      const formDataMap: FormDataMap = {
        todayTaskCount: formData.todayTaskCount,
        completedCount: formData.completedCount,
        pendingCount: formData.pendingCount,
        tasks: taskItems,
        lastUpdateTime: formData.lastUpdateTime,
      };

      await formProvider.update(formDataMap);

      hilog.info(
        DOMAIN,
        TAG,
        "Form updated with data: total=%{public}d, completed=%{public}d",
        formData.todayTaskCount,
        formData.completedCount,
      );
    } catch (err) {
      const error = err as BusinessError;
      hilog.error(DOMAIN, TAG, "Failed to update form: %{public}s", JSON.stringify(error));
    }
  }

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
      const error = err as BusinessError;
      hilog.error(DOMAIN, TAG, "Failed to complete task: %{public}s", JSON.stringify(error));
    }
  }

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
      const error = err as BusinessError;
      hilog.error(DOMAIN, TAG, "Failed to complete all tasks: %{public}s", JSON.stringify(error));
    }
  }

  private async openApp(): Promise<void> {
    try {
      const wantInfo: Want = {
        bundleName: "com.example.plantdiary",
        abilityName: "EntryAbility",
        action: "ohos.want.action.home",
      };

      await this.context.startAbility(wantInfo);
      hilog.info(DOMAIN, TAG, "App opened successfully");
    } catch (err) {
      const error = err as BusinessError;
      hilog.error(DOMAIN, TAG, "Failed to open app: %{public}s", JSON.stringify(error));
    }
  }
}
