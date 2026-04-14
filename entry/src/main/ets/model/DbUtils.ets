import relationalStore from '@ohos.data.relationalStore'

/**
 * 统一事务封装：确保批量写入要么全部成功、要么全部回滚。
 * 用法：
 *   await runInTransaction(this.store!, async () => {
 *     await this.store!.executeSql('DELETE FROM ...')
 *     await this.store!.insert(...)
 *     // ...
 *   })
 */
export async function runInTransaction(store: relationalStore.RdbStore, fn: () => Promise<void>): Promise<void> {
  await store.beginTransaction()
  try {
    await fn()
    await store.commit()
  } catch (e) {
    await store.rollBack()
    console.error(`事务执行失败：${(e as Error).message}`)
    throw e as Error
  }
}
