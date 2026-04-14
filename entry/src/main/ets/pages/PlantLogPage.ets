import { LogRowItem } from '../view/LogRowItem';
import { LogPhoto, PlantLog } from '../view/PlantLogSheet';
import { RdbManager } from '../viewmodel/RdbManager';
import { relationalStore } from '@kit.ArkData';
import { LogEntry } from '../model/PlantModel';
import { runInTransaction } from '../model/DbUtils';
import { hilog } from '@kit.PerformanceAnalysisKit';
import fs from '@ohos.file.fs';
import { common } from '@kit.AbilityKit';
import { AddImageFileViewModel } from '../viewmodel/AddImageFileViewModel';
import { PhotoPreviewSheet } from '../view/PhotoPreviewSheet';

@ComponentV2
export struct PlantLogPage {
  private ctx: common.UIAbilityContext = getContext(this) as common.UIAbilityContext
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Consumer('RdbManager') RdbManager: RdbManager = RdbManager.getInstance()
  @Consumer('store') store: relationalStore.RdbStore | null = this.RdbManager.rdbStore
  @Local plantName: string = ''
  @Local logs: Array<PlantLog> = []
  @Local photos: Array<LogPhoto> = []
  @Local keyword: string = '' // 关键字高亮（可为空）
  @Local logPlantId: number = 0
  @Local picking: boolean = false // 防连点
  // @Event onAddLog: (note: string, dateISO: string) => void
  // @Event onDeleteLog: (logId: number) => void
  // @Event onBatchDeleteLogs: (logIds: Array<number>) => void
  // @Event onPickPhotos: (logId: number) => void
  // @Event onCapturePhoto: (logId: number) => void
  // @Event onDeletePhoto: (photoId: number) => void
  // @Event onDelete: (lid: number) => void
  // @Event onBatchDelete: (ids: Array<number>) => void
  // @Event onPreviewPhoto: (fp: string) => void
  // @Event onClose: () => void
  // 本地状态
  @Local noteText: string = ''
  @Local dateISO: string = ''
  @Local sortAsc: boolean = false
  @Local selectMode: boolean = false
  @Local selected: Array<number> = [] // 选中的 logId
  @Local previewVisible: boolean = false
  @Local previewPath: string = ''
  @Local pressedLog: boolean = false
  @Local bannerMsg: string = ''
  @Local bannerType: string = ''
  @Local photoPreviewVisible: boolean = false
  @Local previewFiles: Array<string> = []
  @Local previewIndex: number = 0
  @Local previewLogId: number = 0
  listScroller = new Scroller()
  private addImageFileViewModel = AddImageFileViewModel.getInstance(this.ctx);
  // 按钮按压状态
  @Local addLogPressed: boolean = false
  @Local sortPressed: boolean = false
  @Local deletePressed: boolean = false
  @Local cancelPressed: boolean = false

  async aboutToAppear() {
    this.dateISO = this.todayISO()
    if (this.logPlantId !== 0) {
      await this.loadLogsWithPhotos(this.logPlantId) // 重新加载
    }
  }

  // 日志新增完成后统一重新拉取日志和照片，保证列表与附件区同步刷新。
  async onAddLog(note: string, iso: string) {
    if (!this.store) {
      return
    }
    await this.store.insert(RdbManager.T_LOG, { plantId: this.logPlantId, note: note, createdAt: Date.now() })
    await this.loadLogsWithPhotos(this.logPlantId) // 重新加载
  }

  async onDeleteLog(logId: number) {
    if (!this.store) {
      return
    }
    await this.deleteLogAndPhotos(logId)
    await this.loadLogsWithPhotos(this.logPlantId) // 按你工程里的当前 plant 状态刷新
    //
    this.showBanner('已删除日志与照片', 'ok')

  }

  // 删除一条日志及其关联照片（含本地文件），并自动刷新当前植物的日志列表
  // 单条日志删除遵循“事务删记录、事务后删文件”的顺序，和植物删除逻辑保持一致。
  private async deleteLogAndPhotos(logId: number): Promise<void> {
    if (!this.store) {
      return
    }

    // await this.store.beginTransaction()
    try {
      // 取出文件路径
      const rs = await this.store.querySql(
        `SELECT filePath, thumbPath FROM ${RdbManager.T_LOG_PHOTO} WHERE logId = ? ORDER BY id ASC`, [logId]
      )
      const files: Array<string> = []
      while (rs.goToNextRow()) {
        const p1: string = rs.getString(0)
        const p2: string = rs.getString(1)
        if (p1 && p1.length > 0) {
          files.push(p1)
        }
        if (p2 && p2.length > 0) {
          files.push(p2)
        }
      }
      rs.close()

      // —— 事务：先删子表，再删日志表 —— //
      await runInTransaction(this.store, async () => {
        const pp = new relationalStore.RdbPredicates(RdbManager.T_LOG_PHOTO)
        pp.equalTo('logId', logId)
        await this.store!.delete(pp)

        const pl = new relationalStore.RdbPredicates(RdbManager.T_LOG)
        pl.equalTo('id', logId)
        const idd = await this.store!.delete(pl)
        hilog.info(0x0000, '11', `liheng 删除日志 ${idd} ${pl}`);

      })

      // —— 事务提交成功后，再删本地文件（即便个别失败也不影响数据库一致性） —— //
      let i: number = 0
      while (i < files.length) {
        try {
          await fs.unlink(files[i])
        } catch (_e) { /* 忽略单文件错误 */
        }
        i = i + 1
      }
    } catch (e) {
      await this.store.rollBack()
      this.showBanner('删除日志失败，已回滚', 'warn')
    }
  }

  async onBatchDeleteLogs(ids: Array<number>) {
    if (!this.store) {
      return
    }
    // 删除日志本体
    const p = new relationalStore.RdbPredicates(RdbManager.T_LOG);
    p.in('id', ids)
    await this.store.delete(p)
    // 删除关联图片
    const pp = new relationalStore.RdbPredicates(RdbManager.T_LOG_PHOTO);
    pp.in('logId', ids)
    await this.store.delete(pp)
    await this.loadLogsWithPhotos(this.logPlantId)
  }

  async onPickPhotos(logId: number) {
    // 在这里用你现有的封装（file.picker / photoAccessHelper），复制到 filesDir，
    // 生成缩略图（可选），然后批量 insert 到 ${RdbManager.T_LOG_PHOTO}，最后刷新。
    await this.pickAndSavePhotos(logId) // 你已有/将实现的方法
    await this.loadLogsWithPhotos(this.logPlantId) // 重新加载
  }

  private async loadLogPhotos(logId: number): Promise<void> {
    if (!this.store) {
      return
    }
    const rs = await this.store.querySql(
      `SELECT id, logId, path, thumbPath, createdAt
     FROM ${RdbManager.T_LOG_PHOTO}
     WHERE logId = ?
     ORDER BY id DESC`, [logId]
    )
    const items: Array<LogPhoto> = []
    while (rs.goToNextRow()) {
      items.push(new LogPhoto(rs.getLong(0), rs.getLong(1), rs.getString(2), rs.getString(3), rs.getLong(4)))
    }
    rs.close()
    this.photos = items
  }

  // 2) 相册多选并保存到本地（复用你已有的选择/拷贝/入库逻辑）
  private async pickAndSavePhotos(logId: number): Promise<void> {
    // 你工程里已有 pickPhotosForLog（会走 selectImagesFromAlbum → ensurePhotosDir → copyImageToAppFiles → insertLogPhoto → loadLogPhotos）
    await this.pickPhotosForLog(logId)
  }

  // 确保以 file:// 前缀返回，便于 Image 显示
  private ensureFileUri(path: string): string {
    if (path.startsWith('file://')) {
      return path
    }
    return `file://${path}`
  }

  private async insertLogPhoto(logId: number, fileUri: string): Promise<void> {
    if (!this.store) {
      return
    }
    const uri: string = this.ensureFileUri(fileUri)
    const now: number = Date.now()
    const v: relationalStore.ValuesBucket = {
      logId: logId,
      path: uri, // 原图
      thumbPath: uri, // 先用原图占位，后续如需生成缩略图再更新
      createdAt: now
    }
    await this.store.insert(RdbManager.T_LOG_PHOTO, v)
  }

  // xuanzhe
  // 选择图片后会先复制进应用私有目录，再记录到 log_photo 表，避免外部 URI 失效。
  private async pickPhotosForLog(logId: number): Promise<void> {
    if (this.picking) {
      return
    }
    this.picking = true
    try {
      await this.addImageFileViewModel.selectAndProcessImages([], async (newImages) => {
        if (newImages.length > 0) {
          const dir = await this.ensurePhotosDir()

          let i: number = 0
          while (i < newImages.length) {
            const srcUri: string = newImages[i].path
            const dstPath: string = await this.copyImageToAppFiles(srcUri, dir)
            await this.insertLogPhoto(logId, this.ensureFileUri(dstPath))
            i = i + 1
          }
          this.loadLogsWithPhotos(this.logPlantId) // 重新加载
          this.showBanner('已添加照片', 'ok')
        }
      }, 12)

      // 确保目录存在

    } catch (e) {
      console.error(`pickPhotosForLog error: ${(e as Error).message}`)
      this.showBanner('添加照片失败', 'warn')
    } finally {
      this.picking = false
    }
  }

  private async ensurePhotosDir(): Promise<string> {
    const base: string = (this.ctx as common.UIAbilityContext).filesDir
    const dir: string = `${base}/photos`
    try {
      await fs.mkdir(dir) // 若存在会抛错，交由 catch 吞掉
    } catch (e) {
      // ignore if exists
    }
    return dir
  }

  // 生成文件名：时间戳_随机数.jpg
  private genPhotoName(): string {
    const d = new Date()
    const y = d.getFullYear().toString()
    const m = (d.getMonth() + 1).toString().padStart(2, '0')
    const day = d.getDate().toString().padStart(2, '0')
    const h = d.getHours().toString().padStart(2, '0')
    const mi = d.getMinutes().toString().padStart(2, '0')
    const s = d.getSeconds().toString().padStart(2, '0')
    const ms = d.getMilliseconds().toString().padStart(3, '0')
    return `IMG_${y}${m}${day}_${h}${mi}${s}_${ms}.jpg`
  }

  // 从 URI 复制到 app filesDir/photos/xxx.jpg
  private async copyImageToAppFiles(srcUri: string, dstDir: string): Promise<string> {
    const name: string = this.genPhotoName()
    const dstPath: string = `${dstDir}/${name}`

    // 1) file:// 直拷
    if (srcUri.length >= 7 && srcUri.substring(0, 7) === 'file://') {
      const srcPath: string = srcUri.substring(7)
      try {
        await fs.copyFile(srcPath, dstPath)
        return dstPath
      } catch (_e) {
        // 复制失败则回退到原路径（尽量不阻断）
        return srcPath
      }
    }

    // 2) 用 fileAccess 处理 datashare:// 等
    try {
      // const helper = fileAccess.createFileAccessHelper(this.ctx)
      // const rdFd: number = await helper.openFile(srcUri, fileAccess.OpenMode.READ)
      // const wrFd:  fs.File = fs.openSync(dstPath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY)
      // try {
      //   const buf = new ArrayBuffer(64 * 1024)
      //   let n: number = await helper.read(rdFd, buf)
      //   while (n > 0) {
      //     fs.writeSync(wrFd.fd, buf, { offset: 0, length: n })
      //     n = await helper.read(rdFd, buf)
      //   }
      // } finally {
      //   try { fs.closeSync(wrFd) } catch (_e1) {}
      //   try { await helper.closeFile(rdFd) } catch (_e2) {}
      // }
      return dstPath
    } catch (_e3) {
      // 再次兜底：返回一个“尽量可用”的路径
      return dstPath
    }
  }

  async onDeletePhoto(pid: number) {
    if (!this.store) {
      return
    }
    const p = new relationalStore.RdbPredicates(RdbManager.T_LOG_PHOTO);
    p.equalTo('id', pid)
    await this.store.delete(p)
    await this.deleteLogAndPhotos(pid)
    await this.loadLogsWithPhotos(this.logPlantId)
  }

  onPreviewPhoto(fp: string) {
  }

  // 1) 加载「日志 +（按需）照片」
  // 说明：这里先只加载日志列表；照片仍按你当前交互在选择某条日志后，调用 loadLogPhotos(logId) 单独加载。
  // 这样不会影响你把 logPhotos 用作“当前编辑日志照片”的语义。
  // 页面展示需要“日志列表 + 全部照片附件”两个数据源，这里一次性并行感知它们的最新状态。
  private async loadLogsWithPhotos(plantId: number): Promise<void> {
    if (!this.store) {
      return
    }

    // 1) 加载日志（新→旧）
    const rs1 = await this.store.querySql(
      `SELECT id, plantId, note, createdAt
     FROM ${RdbManager.T_LOG}
     WHERE plantId = ?
     ORDER BY createdAt DESC, id DESC`, [plantId]
    )
    const arrLogs: Array<LogEntry> = []
    while (rs1.goToNextRow()) {
      arrLogs.push(new LogEntry(rs1.getLong(0), rs1.getLong(1), rs1.getString(2), rs1.getLong(3)))
    }
    rs1.close()
    this.logs = arrLogs

    // 2) 加载该植物所有日志的照片（按照片 id 新→旧）
    const rs2 = await this.store.querySql(
      `SELECT p.id, p.logId, p.path, p.thumbPath, p.createdAt
     FROM ${RdbManager.T_LOG_PHOTO} p
     JOIN ${RdbManager.T_LOG} l ON p.logId = l.id
     WHERE l.plantId = ?
     ORDER BY p.id DESC`, [plantId]
    )
    const arrPhotos: Array<LogPhoto> = []
    while (rs2.goToNextRow()) {
      arrPhotos.push(new LogPhoto(rs2.getLong(0), rs2.getLong(1), rs2.getString(2), rs2.getString(3), rs2.getLong(4)))
    }
    rs2.close()
    this.photos = arrPhotos
  }

  @Builder
  LogTitle() {
    Row() {
      Text(this.sortAsc ? '时间 ↑' : '时间 ↓')
        .fontSize(12)
        .fontColor(0xFF1565C0)
        .padding({
          left: 10,
          right: 10,
          top: 6,
          bottom: 6
        })
        .borderRadius(14)
        .backgroundColor(0x102196F3)
        .onClick(() => {
          this.sortAsc = !this.sortAsc
        })
        .scale(this.sortPressed ? { x: 0.95, y: 0.95 } : { x: 1, y: 1 })
        .animation({ duration: 100, curve: Curve.EaseOut })
        .onTouch((e: TouchEvent) => {
          if (e.type === TouchType.Down) {
            this.sortPressed = true
          } else if (e.type === TouchType.Up || e.type === TouchType.Cancel) {
            this.sortPressed = false
          }
        })
      // Text(`${this.plantName} · 日志`).fontSize(16).fontWeight(FontWeight.Medium).fontColor(0xFF263238)
      Stack() {

        if (this.selectMode) {
          Row() {
            Text(`删除(${this.selected.length})`)
              .fontSize(12)
              .fontColor(0xFFFFFFFF)
              .padding({
                left: 12,
                right: 12,
                top: 6,
                bottom: 6
              })
              .borderRadius(14)
              .backgroundColor(0xFFE53935)
              .onClick(() => {
                if (this.selected.length > 0) {
                  this.onBatchDeleteLogs(this.copyIds(this.selected));
                  this.selected = [];
                  this.selectMode = false
                }
              })
              .scale(this.deletePressed ? { x: 0.95, y: 0.95 } : { x: 1, y: 1 })
              .animation({ duration: 100, curve: Curve.EaseOut })
              .onTouch((e: TouchEvent) => {
                if (e.type === TouchType.Down) {
                  this.deletePressed = true
                } else if (e.type === TouchType.Up || e.type === TouchType.Cancel) {
                  this.deletePressed = false
                }
              })
            Text('取消选择')
              .fontSize(12)
              .fontColor(0xFF263238)
              .padding({
                left: 10,
                right: 10,
                top: 6,
                bottom: 6
              })
              .borderRadius(14)
              .backgroundColor(0xFFE0E0E0)
              .onClick(() => {
                this.selected = [];
                this.selectMode = false
              })
              .margin({ left: 8 })
              .scale(this.cancelPressed ? { x: 0.95, y: 0.95 } : { x: 1, y: 1 })
              .animation({ duration: 100, curve: Curve.EaseOut })
              .onTouch((e: TouchEvent) => {
                if (e.type === TouchType.Down) {
                  this.cancelPressed = true
                } else if (e.type === TouchType.Up || e.type === TouchType.Cancel) {
                  this.cancelPressed = false
                }
              })
          }
        } else {
          Text('长按进入多选')
            .fontSize(12)
            .fontColor(0x80607278)
            .padding({
              left: 10,
              right: 10,
              top: 6,
              bottom: 6
            })
        }
      }

    }
    .width('85%')
    .height('100%')
    .padding({
      left: 16,
      right: 16,
    })
    .justifyContent(FlexAlign.End)
    .alignItems(VerticalAlign.Center)
  }

  build() {
    NavDestination() {
      Stack() {

        Column() {
          Row() {
            Blank()
            if (this.keyword.length > 0) {
              Text(`关键词: ${this.keyword}`).fontSize(12).fontColor(0xFF607D8B)
            }
          }.padding({ left: 16, right: 16, bottom: 8 })

          // 新增日志
          Column() {
            this.FormItem('内容', '写点什么…', this.noteText, (v: string) => {
              this.noteText = v
            })
            Row({ space: 5 }) {
              Text('今天')
                .fontSize(12)
                .fontColor(0xFF1565C0)
                .padding({
                  left: 12,
                  right: 12,
                  top: 6,
                  bottom: 6
                })
                .borderRadius(14)
                .backgroundColor(0x102196F3)
                .onClick(() => {
                  this.dateISO = this.todayISO()
                })

              Text(this.dateISO).fontSize(13).fontColor(0xFF263238).margin({ top: 4 })


            }
            .padding({ top: 6, bottom: 6 })
            .height(40)
            .justifyContent(FlexAlign.Center)
            .alignItems(VerticalAlign.Center)

            Row() {
              Text('添加日志')
                .fontSize(14)
                .fontColor(0xFFFFFFFF)
                .padding({
                  left: 18,
                  right: 18,
                  top: 8,
                  bottom: 8
                })
                .borderRadius(18)
                .backgroundColor(0xFF2E7D32)
                .onClick(() => {
                  if (this.noteText.trim().length === 0) {
                    return
                  }
                  this.onAddLog(this.noteText.trim(), this.dateISO);
                  this.noteText = ''
                })
                .scale(this.addLogPressed ? { x: 0.95, y: 0.95 } : { x: 1, y: 1 })
                .animation({ duration: 100, curve: Curve.EaseOut })
                .onTouch((e: TouchEvent) => {
                  if (e.type === TouchType.Down) {
                    this.addLogPressed = true
                  } else if (e.type === TouchType.Up || e.type === TouchType.Cancel) {
                    this.addLogPressed = false
                  }
                })
            }
          }.padding({ left: 16, right: 16, bottom: 8 })

          // 列表
          if (this.sorted().length === 0) {
            Column() {
              Text('暂无日志').fontSize(12).fontColor(0xFF90A4AE)
            }
            .padding({ left: 16, right: 16, bottom: 18 })
          } else {
            List({ space: 8, scroller: this.listScroller }) {
              ForEach(this.sorted(), (lg: PlantLog, index: number) => {
                ListItem() {
                  // this.LogRow(lg, index)
                  LogRowItem({
                    lg: lg,
                    selectMode: this.selectMode,
                    photos: this.photos,
                    logItemPhotos: this.photos.filter(i => i.logId === lg.id) || [],
                    keyword: this.keyword,
                    isSelected: (lgId: number) => this.isSelected(lgId),
                    toggleSelect: (lgId: number) => {
                      this.toggleSelect(lgId)
                    },
                    onPickPhotos: (logId: number) => {
                      this.onPickPhotos(logId)
                    },
                    onCapturePhoto: (logId: number) => {
                      // this.onCapturePhoto(logId)
                      this.showBanner('可以点击添加图片拍照', 'warn')
                    },
                    onDeleteLog: (logId: number) => {
                      this.onDeleteLog(logId)
                    },
                    onDeletePhoto: (photoId: number) => {
                      this.onDeletePhoto(photoId)
                    },
                    onselectMode: (selectMode: boolean) => {
                      this.selectMode = selectMode
                    },
                    onPreviewVisible: (path: string, visible: boolean) => {
                      this.previewVisible = visible
                      this.previewPath = path
                    },
                  })
                }
              }, (lg: PlantLog) => lg.id.toString())
            }
            .scrollBar(BarState.Off).height('80%')
            .padding({ left: 16, right: 16, bottom: 16 })
            .edgeEffect(EdgeEffect.Spring)
            .animation({
              duration: 300,
              curve: Curve.EaseInOut
            })
          }
        }
        .width('100%')
        // .backgroundColor(0xFFFFFFFF)
        .animation({ duration: 200, curve: Curve.Sharp })

        if (this.bannerMsg.length > 0) {
          this.Banner(this.bannerMsg, this.bannerType)
        }
        // 图片预览
        if (this.previewVisible) {
          Column() {
            Blank().width('100%').height('100%').backgroundColor(0xCC000000).onClick(() => {
              this.previewVisible = false
            })
            Column() {
              Image(this.previewPath).objectFit(ImageFit.Contain).width('92%').height('70%').borderRadius(12)
            }.width('100%').height('100%').justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
          }.width('100%').height('100%')
        }
        if (this.photoPreviewVisible) {
          PhotoPreviewSheet({
            files: this.previewFiles,
            startIndex: this.previewIndex,
            onDelete: async (idx: number) => {
              if (idx >= 0 && idx < this.previewFiles.length) {
                const target: string = this.previewFiles[idx]
                await this.deletePhotoByFilePath(target)
                // 预览收尾：若删到没图了则关闭；否则保持当前下标合理
                if (this.previewFiles.length === 0) {
                  this.photoPreviewVisible = false
                } else {
                  if (idx >= this.previewFiles.length) {
                    this.previewIndex = this.previewFiles.length - 1
                  } else {
                    this.previewIndex = idx
                  }
                }
              }
            },
            onClose: () => {
              this.photoPreviewVisible = false
            }
          })
        }
      }.width('100%').height('100%')
    }
    .onReady((parma: NavDestinationContext) => {
      this.logPlantId = (parma.pathInfo.param as number)
      if (this.logPlantId !== 0) {
        this.loadLogsWithPhotos(this.logPlantId) // 重新加载
      }
    })
    .onBackPressed(()=>{
      this.pageStack.pop(this.logPlantId)
      return true;
    })
    .padding({
      top: AppStorage.get<number>('topRectHeight'),
      bottom: AppStorage.get<number>('bottomRectHeight')
    })
    .width('100%')
    .title(this.LogTitle())
    .height('100%')
    .linearGradient({
      direction: GradientDirection.Top,
      colors: [[0xFFF1F8E9, 0], [0xFFE8F5E9, 0.5], [0xFFE3F2FD, 1.0]]
    })

    // .bindToScrollable([this.listScroller])
  }

  @Builder
  FormItem(label: string, placeholder: string, val: string, onChange: (v: string) => void) {
    Column() {
      Text(label).fontSize(12).fontColor(0xFF607D8B)
      TextInput({ placeholder: placeholder, text: val }).placeholderColor('#747474').fontColor('#000000')
        .onChange((v: string) => {
          onChange(v)
        })
        .width('100%')
        .height(40)
        .borderRadius(12)
        .backgroundColor(0xFFF9F9F9)
        .padding({ left: 12, right: 12 })
        .margin({ top: 6 })
    }.margin({ top: 6 })
  }

  @Builder
  LogRow(lg: PlantLog, index: number) {

  }

  @Builder
  Banner(text: string, type: string) {
    Row() {
      if (type === 'ok') {
        Image($r('app.media.ic_success')).width(14).height(14).margin({ right: 8 })
      }
      if (type === 'warn') {
        Text('!').fontSize(14).fontWeight(FontWeight.Medium).fontColor(0xFFEF6C00).margin({ right: 8 })
      }
      if (type === 'info') {
        Text('i').fontSize(14).fontWeight(FontWeight.Medium).fontColor(0xFF1565C0).margin({ right: 8 })
      }
      Text(text).fontSize(13).fontColor(type === 'ok' ? 0xFF2E7D32 : (type === 'warn' ? 0xFFEF6C00 : 0xFF1565C0))
    }
    .padding({
      left: 14,
      right: 14,
      top: 10,
      bottom: 10
    })
    .layoutWeight(100)
    .zIndex(1000)
    .borderRadius(16)
    .backgroundColor(type === 'ok' ? 0xFFE8F5E9 : (type === 'warn' ? 0xFFFFF3E0 : 0xFFE3F2FD))
    .position({ x: 12, y: 70 })
    .shadow({
      radius: 12,
      color: 0x18000000,
      offsetX: 0,
      offsetY: 4
    })
    .animation({ duration: 220, curve: Curve.EaseInOut })
  }

  // 通过 filePath 定位并删除该照片（含本地文件），随后刷新当前日志照片与预览列表
  // 预览层按 filePath 定位照片记录，这样删除时不需要额外把 photoId 透传到每个子组件。
  private async deletePhotoByFilePath(fp: string): Promise<void> {
    if (!this.store) {
      return
    }
    // 取照片 id/logId
    const rs =
      await this.store.querySql(`SELECT id, logId FROM ${RdbManager.T_LOG_PHOTO} WHERE filePath = ? LIMIT 1`, [fp])
    let pid: number = 0;
    let lid: number = 0
    if (rs.goToNextRow()) {
      pid = rs.getLong(0);
      lid = rs.getLong(1)
    }
    rs.close()
    if (pid !== 0) {
      // await this.deleteLogPhoto(pid, lid)
      await this.loadLogPhotos(lid)
      // 重建预览数组
      const arr: Array<string> = []
      let i: number = 0
      while (i < this.photos.length) {
        arr.push(this.photos[i].path);
        i = i + 1
      }
      this.previewFiles = arr
      this.previewLogId = lid
    }
  }

  private openPhotoPreview(logId: number, files: Array<LogPhoto>, startPath: string): void {
    this.previewLogId = logId
    const arr: Array<string> = []
    let i: number = 0
    while (i < files.length) {
      arr.push(files[i].path);
      i = i + 1
    }
    this.previewFiles = arr
    this.previewIndex = this.indexOfPath(arr, startPath)
    this.photoPreviewVisible = true
  }

  // —— 日志：批量删除（事务 + 两阶段删文件）—— //
  private async bulkDeleteLogsTx(logIds: Array<number>): Promise<void> {
    if (!this.store) {
      return
    }

    // 预收集所有将要删除的文件路径
    const files: Array<string> = []
    let k: number = 0
    while (k < logIds.length) {
      const rs = await this.store.querySql(
        `SELECT path, thumbPath FROM ${RdbManager.T_LOG_PHOTO} WHERE logId = ?`, [logIds[k]]
      )
      while (rs.goToNextRow()) {
        const p1: string = rs.getString(0)
        const p2: string = rs.getString(1)
        if (p1 && p1.length > 0) {
          files.push(p1)
        }
        if (p2 && p2.length > 0) {
          files.push(p2)
        }
      }
      rs.close()
      k = k + 1
    }

    // 事务：删子表 → 删日志
    await this.store.beginTransaction()
    try {
      let i: number = 0
      while (i < logIds.length) {
        const pp = new relationalStore.RdbPredicates(RdbManager.T_LOG_PHOTO);
        pp.equalTo('logId', logIds[i])
        await this.store.delete(pp)
        const pl = new relationalStore.RdbPredicates(RdbManager.T_LOG);
        pl.equalTo('id', logIds[i])
        await this.store.delete(pl)
        i = i + 1
      }
      await this.store.commit()
    } catch (_e) {
      await this.store.rollBack()
      this.showBanner('批量删除日志失败，已回滚', 'warn')
      return
    }

    // 事务提交后再删本地文件（无法回滚，放事务外）
    let j: number = 0
    while (j < files.length) {
      try {
        await fs.unlink(files[j])
      } catch (_e) { /* ignore */
      }
      j = j + 1
    }

    // 刷新
    await this.loadLogsWithPhotos(this.logPlantId) // 如果你有 currentPlantId；否则按你的刷新逻辑处理
    this.showBanner('已批量删除日志与照片', 'ok')
  }

  private indexOfPath(arr: Array<string>, path: string): number {
    let i: number = 0
    while (i < arr.length) {
      if (arr[i] === path) {
        return i
      }
      ;
      i = i + 1
    }
    return 0
  }

  // 收集一批日志的图片与缩略图路径（去重）
  private async collectPhotoFilesByLogIds(logIds: Array<number>): Promise<Array<string>> {
    const files: Array<string> = []
    if (!this.store) {
      return files
    }
    if (logIds.length === 0) {
      return files
    }

    // 逐条取（兼容性最好；避免 IN 语法差异）
    let i: number = 0
    while (i < logIds.length) {
      const rs = await this.store.querySql(
        `SELECT filePath, thumbPath FROM ${RdbManager.T_LOG_PHOTO} WHERE logId = ?`,
        [logIds[i]]
      )
      while (rs.goToNextRow()) {
        const p1: string = rs.getString(0)
        const p2: string = rs.getString(1)
        if (p1 && p1.length > 0 && files.indexOf(p1) < 0) {
          files.push(p1)
        }
        if (p2 && p2.length > 0 && files.indexOf(p2) < 0) {
          files.push(p2)
        }
      }
      rs.close()
      i = i + 1
    }
    return files
  }

  private async deleteLogsBatchTx(logIds: Array<number>): Promise<void> {
    if (!this.store) {
      return
    }
    if (logIds.length === 0) {
      return
    }

    // 1) 预先收集所有文件路径（commit 后再删）
    const fileList: Array<string> = await this.collectPhotoFilesByLogIds(logIds)

    // 2) 事务删除：log_photo -> log
    await this.store.beginTransaction()
    let ok: boolean = false
    try {
      // 逐条删，保证兼容性（也可自行换成 IN 语句）
      let i: number = 0
      while (i < logIds.length) {
        const pPhoto = new relationalStore.RdbPredicates(RdbManager.T_LOG_PHOTO)
        pPhoto.equalTo('logId', logIds[i])
        await this.store.delete(pPhoto)

        const pLog = new relationalStore.RdbPredicates(RdbManager.T_LOG)
        pLog.equalTo('id', logIds[i])
        await this.store.delete(pLog)

        i = i + 1
      }
      await this.store.commit()
      ok = true
    } catch (_e) {
      await this.store.rollBack()
      ok = false
    }

    // 3) 提交成功后再删文件（容错）
    if (ok) {
      let j: number = 0
      while (j < fileList.length) {
        try {
          await fs.unlink(fileList[j])
        } catch (_e2) { /* 忽略删除失败 */
        }
        j = j + 1
      }
      // 4) 刷新界面（按你工程习惯选择刷新范围）
      // await this.reloadAll()
      this.showBanner('已批量删除日志及照片', 'ok')
    } else {
      this.showBanner('批量删除失败，已回滚', 'warn')
    }
  }

  private async deleteFileIfExists(pathOrUri: string): Promise<void> {
    try {
      // 统一为 file:// 前缀
      const uri: string = this.ensureFileUri(pathOrUri)
      // 去掉前缀拿到真实路径
      const realPath: string = uri.startsWith('file://') ? uri.substring(7) : uri
      // if (fs.accessSync(realPath) === 0) {
      //   fs.unlinkSync(realPath)
      // }
    } catch (_e) {
      // 忽略任何文件不存在/权限等异常，保证级联流程不中断
    }
  }

  // —— 逻辑方法 —— //
  // 只在普通方法里排序，Builder 直接消费结果，避免列表重绘时重复创建临时数组。
  private sorted(): Array<PlantLog> {
    // 先简单复制再排序（不在 @Builder 内部）
    const arr: Array<PlantLog> = []
    let i: number = 0
    while (i < this.logs.length) {
      arr.push(this.logs[i]);
      i = i + 1
    }
    arr.sort((a: PlantLog, b: PlantLog) => this.sortAsc ? (a.createdAt - b.createdAt) : (b.createdAt - a.createdAt))
    return arr
  }

  private isSelected(id: number): boolean {
    let i: number = 0
    while (i < this.selected.length) {
      if (this.selected[i] === id) {
        return true
      }
      i = i + 1
    }
    return false
  }

  // 多选态通过“重建新数组”切换勾选，便于触发 ArkUI 对 selected 的响应式更新。
  private toggleSelect(id: number): void {
    const arr: Array<number> = []
    let removed: boolean = false
    let i: number = 0
    while (i < this.selected.length) {
      if (this.selected[i] === id) {
        removed = true
      } else {
        arr.push(this.selected[i])
      }
      i = i + 1
    }
    if (!removed) {
      arr.push(id)
    }
    this.selected = arr
  }

  private copyIds(src: Array<number>): Array<number> {
    const out: Array<number> = []
    let i: number = 0
    while (i < src.length) {
      out.push(src[i]);
      i = i + 1
    }
    return out
  }

  private todayISO(): string {
    const d = new Date();
    const y = d.getFullYear();
    const m = (d.getMonth() + 1).toString().padStart(2, '0');
    const day = d.getDate().toString().padStart(2, '0');
    return `${y}-${m}-${day}`
  }

  private async loadLogsByPlant(plantId: number): Promise<void> {
    if (!this.store) {
      return
    }
    const rs =
      await this.store.querySql(`SELECT id,plantId,note,createdAt FROM ${RdbManager.T_LOG} WHERE plantId=? ORDER BY createdAt DESC, id DESC`,
        [plantId])
    const arr: Array<LogEntry> = []
    while (rs.goToNextRow()) {
      arr.push(new LogEntry(rs.getLong(0), rs.getLong(1), rs.getString(2), rs.getLong(3)))
    }
    rs.close()
    this.logs = arr
  }

  private showBanner(text: string, type: 'ok' | 'warn' | 'info' = 'info'): void {
    this.bannerMsg = text;
    this.bannerType = type
    setTimeout(() => {
      animateTo({ duration: 180, curve: Curve.EaseInOut }, () => {
        this.bannerMsg = ''
      })
    }, 2800)
  }
}





