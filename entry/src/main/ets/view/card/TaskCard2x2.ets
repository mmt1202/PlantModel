/**
 * 2×2 任务卡片 UI 组件
 * 使用 ArkTS 卡片 DSL 编写
 * 尺寸：2×2 (128vp × 128vp)
 * 
 * 注意：这是卡片的渲染模板，数据由 FormExtensionAbility 提供
 */

import { FormData, FormTaskItem } from '../../model/FormData';

@Entry
@Component
struct TaskCard2x2 {
  // 卡片数据由系统注入
  @ObjectLink formData: FormData = new FormData();

  /**
   * 获取任务类型图标
   */
  private getTaskIcon(type: string): string {
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
   * 获取完成率
   */
  private getCompletionRate(): number {
    if (this.formData.todayTaskCount === 0) {
      return 0;
    }
    return Math.floor((this.formData.completedCount / this.formData.todayTaskCount) * 100);
  }

  /**
   * 获取更新时间字符串
   */
  private getUpdateTimeStr(): string {
    const date = new Date(this.formData.lastUpdateTime);
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    return `${hours}:${minutes}`;
  }

  /**
   * 进度环组件
   */
  @Builder
  ProgressRing(progress: number) {
    Stack() {
      // 背景圆环
      Circle()
        .width(70)
        .height(70)
        .stroke('#E8F5E9')
        .strokeWidth(8)
        .fill('transparent')

      // 进度圆环
      Circle()
        .width(70)
        .height(70)
        .stroke('#4CAF50')
        .strokeWidth(8)
        .strokeLineCap(LineCap.Round)
        .fill('transparent')
        .attributes({
          'stroke-dasharray': `${(Math.PI * 70) * (progress / 100)} ${Math.PI * 70}`
        })
        .rotate({ angle: -90 })

      // 中心数字
      Column() {
        Text(`${this.formData.pendingCount}`)
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#263238')

        Text('待完成')
          .fontSize(9)
          .fontColor('#757575')
          .margin({ top: 2 })
      }
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .width(80)
    .height(80)
  }

  /**
   * 任务列表项
   */
  @Builder
  TaskItem(task: FormTaskItem) {
    Row() {
      Text(this.getTaskIcon(task.type))
        .fontSize(14)
        .width(20)
        .textAlign(TextAlign.Center)

      Text(task.plantName)
        .fontSize(11)
        .fontColor('#424242')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ left: 4, right: 4 })

      Text(task.type)
        .fontSize(10)
        .fontColor('#9E9E9E')
        .maxLines(1)
    }
    .width('100%')
    .height(24)
    .padding({ left: 8, right: 8 })
    .backgroundColor('#FFFFFF')
    .borderRadius(6)
    .onClick(() => {
      // 点击完成任务
      this.completeTask(task.id);
    })
  }

  /**
   * 完成单个任务
   */
  private completeTask(taskId: number) {
    // 通过 want 发送事件到 FormExtensionAbility
    // 实际实现需要调用 formExtensionAbility 的 API
    console.info(`Complete task: ${taskId}`);
  }

  /**
   * 完成所有任务按钮
   */
  @Builder
  CompleteAllButton() {
    Row() {
      Text('✓')
        .fontSize(12)
        .fontColor('#FFFFFF')
        .fontWeight(FontWeight.Bold)

      Text('全部完成')
        .fontSize(11)
        .fontColor('#FFFFFF')
        .margin({ left: 4 })
    }
    .backgroundColor('#4CAF50')
    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
    .borderRadius(16)
    .onClick(() => {
      this.completeAllTasks();
    })
  }

  /**
   * 空状态提示
   */
  @Builder
  EmptyState() {
    Column() {
      Text('✓')
        .fontSize(28)
        .fontColor('#4CAF50')
        .fontWeight(FontWeight.Bold)

      Text('全部完成')
        .fontSize(11)
        .fontColor('#4CAF50')
        .margin({ top: 4 })

      Text('今天没有待办任务')
        .fontSize(10)
        .fontColor('#9E9E9E')
        .margin({ top: 2 })
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .width('100%')
    .height('100%')
  }

  build() {
    Column() {
      // 顶部标题栏
      Row() {
        Row() {
          Text('🌿')
            .fontSize(14)
            .margin({ right: 4 })
          Text('植物日记')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor('#263238')
        }

        Blank()

        Text(this.getUpdateTimeStr())
          .fontSize(9)
          .fontColor('#BDBDBD')
      }
      .width('100%')
      .height(28)
      .padding({ left: 12, right: 12, top: 8, bottom: 4 })

      // 主要内容区域
      Row() {
        // 左侧：进度环
        this.ProgressRing(this.getCompletionRate())

        // 右侧：任务列表
        Column() {
          if (this.formData.tasks.length > 0) {
            ForEach(this.formData.tasks, (task: FormTaskItem) => {
              this.TaskItem(task)
            })
          } else {
            this.EmptyState()
          }
        }
        .width('55%')
        .padding({ left: 8, top: 8 })
      }
      .width('100%')
      .flexGrow(1)
      .alignItems(VerticalAlign.Top)
      .padding({ left: 12, right: 12 })

      // 底部操作按钮
      Row() {
        Blank()
        this.CompleteAllButton()
      }
      .width('100%')
      .height(32)
      .padding({ left: 12, right: 12, top: 4, bottom: 4 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .onClick(() => {
      // 点击卡片空白处打开应用
      this.openApp();
    })
  }

  /**
   * 打开应用
   */
  private openApp() {
    console.info('Open app from card');
  }

  /**
   * 完成所有任务
   */
  private completeAllTasks() {
    console.info('Complete all tasks');
  }
}
