//
// if (this.taskStatsVisible) {
//   TaskStatsSheet({
//     items: this.tasks,           // 你也可以传 this.filteredTasks()
//     onClose: () => { this.taskStatsVisible = false }
//   })
// }
// // —— 任务：批量切换完成状态（事务）—— //
// private async bulkToggleTasks(ids: Array<number>, done: number): Promise<void> {
//   if (!this.store) { return }
// await this.store.beginTransaction()
// try {
//   const now: number = done === 1 ? Date.now() : 0
//   let i: number = 0
//   while (i < ids.length) {
//     const p = new relationalStore.RdbPredicates(RdbManager.T_TASK)
//     p.equalTo('id', ids[i])
//     await this.store.update({ done: done, doneAt: now }, p)
//     i = i + 1
//   }
//   await this.store.commit()
//   await this.loadTasks()
//   this.showBanner('已批量更新任务状态', 'ok')
// } catch (_e) {
//   await this.store.rollBack()
//   this.showBanner('批量更新失败，已回滚', 'warn')
// }
// }
//
// // —— 任务：批量删除（事务）—— //
// private async bulkDeleteTasks(ids: Array<number>): Promise<void> {
//   if (!this.store) { return }
// await this.store.beginTransaction()
// try {
//   let i: number = 0
//   while (i < ids.length) {
//     const p = new relationalStore.RdbPredicates(RdbManager.T_TASK)
//     p.equalTo('id', ids[i])
//     await this.store.delete(p)
//     i = i + 1
//   }
//   await this.store.commit()
//   await this.loadTasks()
//   this.showBanner('已批量删除任务', 'ok')
// } catch (_e) {
//   await this.store.rollBack()
//   this.showBanner('批量删除失败，已回滚', 'warn')
// }
// }

// @Builder
// BindPageContentCover(){
//   // —— 指标抽屉 ——（新增组件 MetricSheet）
//   if (this.metricVisible) {
//     MetricSheet({
//       plantName: this.metricPlantName,
//       metrics: this.metrics,
//       onClose: () => { this.metricVisible = false },
//       onAdd: async (h: number, w: number, s: number, iso: string) => {
//         await this.createMetric(this.metricPlantId, h, w, s, iso)
//       },
//       onDelete: async (id: number) => { await this.deleteMetric(id) }
//     })
//   }
// }

// —— 日志抽屉 ——（使用你已有的 PlantLogSheet）
// if (this.logSheetVisible) {
//   PlantLogSheet({
//     plantName: this.currentPlantName,
//     logs: this.logs,                  // ← 你已有的日志数组
//     photos: this.logPhotos,           // ← 你维护的 LogPhoto 数组（可在加载日志时一并查询）
//     keyword: this.keyword,         // ← 来自搜索框
//     onAddLog: async (note: string, iso: string) => {
//       if (!this.store) { return }
//       await this.store.insert(RdbManager.T_LOG, { plantId: this.logPlantId, note: note, createdAt: Date.now() })
//       await this.loadLogsWithPhotos(this.logPlantId) // 重新加载
//       // await this.loadLogsByPlant(this.currentPlantId)
//     },
//     onDeleteLog: async (logId: number) => {
//       if (!this.store) { return }
//       await this.deleteLogAndPhotos(logId)
//       await this.loadLogsWithPhotos(this.logPlantId) // 按你工程里的当前 plant 状态刷新
//       //
//       this.showBanner('已删除日志与照片', 'ok')
//     },
//     onBatchDeleteLogs: async (ids: Array<number>) => {
//       if (!this.store) { return }
//       // 删除日志本体
//       const p = new relationalStore.RdbPredicates(RdbManager.T_LOG);
//       p.in('id', ids)
//       await this.store.delete(p)
//       // 删除关联图片
//       const pp = new relationalStore.RdbPredicates(RdbManager.T_LOG_PHOTO); pp.in('logId', ids)
//       await this.store.delete(pp)
//       await this.loadLogsWithPhotos(this.logPlantId)
//     },
//     onPickPhotos: async (logId: number) => {
//       // 在这里用你现有的封装（file.picker / photoAccessHelper），复制到 filesDir，
//       // 生成缩略图（可选），然后批量 insert 到 ${RdbManager.T_LOG_PHOTO}，最后刷新。
//       await this.pickAndSavePhotos(logId) // 你已有/将实现的方法
//       await this.loadLogPhotos(this.logPlantId)
//     },
//     onCapturePhoto: async (logId: number) => {
//       await this.captureAndSavePhoto(logId) // 你已有/将实现的方法
//       await this.loadLogsWithPhotos(this.logPlantId)
//     },
//     onDeletePhoto: async (pid: number) => {
//       if (!this.store) { return }
//       const p = new relationalStore.RdbPredicates(RdbManager.T_LOG_PHOTO); p.equalTo('id', pid)
//       await this.store.delete(p)
//       await this.deleteLogAndPhotos(pid)
//       await this.loadLogsWithPhotos(this.logPlantId)
//     },
//     onDelete: async (lid: number) => { await this.deleteLogAndPhotos(lid) },
//     onBatchDelete: async (ids: Array<number>) => {
//       // let i: number = 0
//       // while (i < ids.length) { await this.deleteLogAndPhotos(ids[i]); i = i + 1 }
//       await this.bulkDeleteLogsTx(ids)
//     },
//     onPreviewPhoto: (fp: string) => {
//       // this.openPhotoPreview(this.editingLogIdForPhotos, this.logPhotos, fp)
//     },
//     onClose: async  () => { this.logSheetVisible = false;await this.reloadAll() }
//   })
// }


// // 高亮片段模型（内部使用）
// class _HL {
//   key: number
//   text: string
//   // 0: 普通，1: 命中
//   hit: number
//
//   constructor(key: number, text: string, hit: number) {
//     this.key = key;
//     this.text = text;
//     this.hit = hit
//   }
// }


// /** ---- 日志 CRUD ---- */
// private async createLog(plantId: number, note: string): Promise<void> {
//   if (!this.store) {
//   return
// }
// const txt: string = note.trim()
// if (txt.length === 0) {
//   this.showBanner('日志内容不能为空', 'warn');
//   return
// }
// const values: relationalStore.ValuesBucket = { plantId: plantId, note: txt, createdAt: Date.now() }
// await this.store.insert(RdbManager.T_LOG, values)
// await this.loadLogsByPlant(plantId)
// this.showBanner('已添加日志', 'ok')
// }
//
// private async deleteLog(id: number): Promise<void> {
//   if (!this.store) {
//   return
// }
// const p = new relationalStore.RdbPredicates(RdbManager.T_LOG);
// p.equalTo('id', id)
// await this.store.delete(p)
// await this.loadLogsByPlant(this.logPlantId)
// this.showBanner('已删除日志', 'ok')
// }