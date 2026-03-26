import { Plant } from '../model/PlantModel';
import { LogPhoto } from '../view/PlantLogSheet';
import { RdbManager } from '../viewmodel/RdbManager';
import relationalStore from '@ohos.data.relationalStore';
import { common } from '@kit.AbilityKit';
import { AddImageFileViewModel } from '../viewmodel/AddImageFileViewModel';
import fs from '@ohos.file.fs';
import { hilog } from '@kit.PerformanceAnalysisKit';

@ComponentV2
export struct GrowthComparePage {
  private ctx: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Consumer('store') store: relationalStore.RdbStore | null = null;
  @Local plant: Plant | undefined = undefined;
  @Local photos: Array<LogPhoto> = [];
  @Local selIdx: number = 0;
  @Local picking: boolean = false;
  private addImageFileViewModel = AddImageFileViewModel.getInstance(this.ctx);

  aboutToAppear() {
  }

  build() {
    NavDestination() {
      // 成长对比页的核心不是复杂计算，而是把同一植物的时间序列照片按时间顺序浏览出来。
      Column() {
        this.Header()
        Scroll() {
          Column({ space: 16 }) {
            this.MainSlider()
            this.PreviewGrid()
            this.TimeTip()
          }
          .padding({
            left: 16,
            right: 16,
            top: 8,
            bottom: 32
          })
        }
        .layoutWeight(1)
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .title('成长对比')
    .padding({
      top: AppStorage.get<number>('topRectHeight'),
      bottom: AppStorage.get<number>('bottomRectHeight')
    })
    .linearGradient({
      direction: GradientDirection.Top,
      colors: [[0xFFFFF3E0, 0], [0xFFFFECB3, 0.5], [0xFFFFF8E1, 1.0]]
    })
    .onReady((param) => {
      const plant = param.pathInfo.param as Plant;
      this.plant = plant;
      this.loadPhotos();
    })
  }

  @Builder
  Header() {
    Row() {
      Column() {
        Text('成长对比').fontSize(22).fontWeight(FontWeight.Medium).fontColor(0xFF263238);
        if (this.plant) {
          Text(this.plant.name).fontSize(14).fontColor(0xFF78909C);
        }
      }
      Blank();
      this.TopActions()
    }
    .padding({
      left: 16,
      right: 16,
      top: 12,
      bottom: 8
    })
  }

  @Builder
  TopActions() {
    Row({ space: 8 }) {
      Button('添加照片')
        .type(ButtonType.Capsule)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .backgroundColor(0xFFFF9800)
        .height(40)
        .onClick(() => {
          this.pickAndAddPhoto();
        })
    }
  }

  @Builder
  MainSlider() {
    // 主视图一次只突出一张照片，底部 slider 负责在植物成长时间线里跳转。
    Column({ space: 16 }) {
      Row() {
        Text('滑动对比')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(0xFF263238);
        Blank();
        Text(`${this.selIdx + 1}/${Math.max(1, this.photos.length)}`)
          .fontSize(14)
          .fontColor(0xFF90A4AE);
      }

      Column({ space: 12 }) {
        if (this.photos.length === 0) {
          Column() {
            Text('📸')
              .fontSize(56)
              .opacity(0.3);
            Text('还没有照片')
              .fontSize(16)
              .fontColor(0xFF90A4AE)
              .margin({ top: 12 });
            Text('点击"添加照片"开始记录成长')
              .fontSize(14)
              .fontColor(0xFFB0BEC5)
              .margin({ top: 4 });
          }
          .width('100%')
          .height(320)
          .justifyContent(FlexAlign.Center)
          .backgroundColor('#FFFFFF')
          .borderRadius(24);
        } else {
          Column({ space: 12 }) {
            Stack() {
              ForEach(this.photos, (p: LogPhoto) => {
                Image(p.path)
                  .width('100%')
                  .height(320)
                  .borderRadius(24)
                  .objectFit(ImageFit.Cover)
                  .opacity(this.selIdx === this.photos.indexOf(p) ? 1 : 0)
                  .animation({
                    duration: 300,
                    curve: Curve.EaseInOut
                  })
              }, (p: LogPhoto) => p.id.toString());

              if (this.photos[this.selIdx]) {
                Column() {
                  Text(this.labelOf(this.photos[this.selIdx]))
                    .fontSize(14)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(0xFFFFFFFF)
                    .padding({
                      left: 12,
                      right: 12,
                      top: 8,
                      bottom: 8
                    })
                    .backgroundColor(0x99000000)
                    .borderRadius(100);
                }
                .width('100%')
                .alignItems(HorizontalAlign.End)
                .padding(16);
              }
            }
            .width('100%')
            .height(320)
            .backgroundColor('#FFFFFF')
            .borderRadius(24)
            .shadow({
              radius: 16,
              color: '#15000000',
              offsetX: 0,
              offsetY: 8
            });

            Column({ space: 12 }) {
              Row() {
                Text('选择照片')
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(0xFF263238);
              }

              Slider({
                value: this.selIdx,
                min: 0,
                max: Math.max(0, this.photos.length - 1),
                step: 1,
                style: SliderStyle.OutSet
              })
                .blockSize({
                  width: 24,
                  height: 24
                })
                .trackColor(0xFFFFE0B2)
                .selectedColor(0xFFFF9800)
                .blockColor(0xFFFF9800)
                .showSteps(true)
                .onChange((value: number) => {
                  this.selIdx = Math.floor(value);
                });

              Row({ space: 8 }) {
                Button('最早')
                  .type(ButtonType.Normal)
                  .fontSize(14)
                  .fontColor(0xFFFF9800)
                  .backgroundColor(0xFFFFF3E0)
                  .height(36)
                  .onClick(() => {
                    this.selIdx = 0;
                  });
                Blank();
                Button('最新')
                  .type(ButtonType.Normal)
                  .fontSize(14)
                  .fontColor(0xFFFF9800)
                  .backgroundColor(0xFFFFF3E0)
                  .height(36)
                  .onClick(() => {
                    this.selIdx = this.photos.length - 1;
                  });
              }
            }
            .padding(16)
            .backgroundColor(0xFFFFFFFF)
            .borderRadius(20)
            .shadow({
              radius: 8,
              color: '#10000000',
              offsetX: 0,
              offsetY: 2
            });
          }
        }
      }
    }
    .padding({ left: 16, right: 16 });
  }

  @Builder
  PreviewGrid() {
    if (this.photos.length > 1) {
      Column({ space: 12 }) {
        Row() {
          Text('全部照片')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor(0xFF263238);
          Blank();
        }

        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
          ForEach(this.photos, (p: LogPhoto) => {
            Column({ space: 6 }) {
              Image(p.path)
                .width('100%')
                .aspectRatio(1)
                .borderRadius(16)
                .objectFit(ImageFit.Cover);

              Text(this.shortLabelOf(p))
                .fontSize(12)
                .fontColor(0xFF78909C)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis });
            }
            .width('30%')
            .onClick(() => {
              this.selIdx = this.photos.indexOf(p);
            })
            .borderRadius(16)
            .border({
              width: this.photos.indexOf(p) === this.selIdx ? 3 : 0,
              color: 0xFFFF9800
            })
            .margin({ bottom: 12 });
          }, (p: LogPhoto) => p.id.toString());
        }
      }
      .padding(20)
      .backgroundColor('#FFFFFF')
      .borderRadius(24)
      .shadow({
        radius: 12,
        color: '#11000000',
        offsetX: 0,
        offsetY: 2
      })
      .margin({ left: 16, right: 16 });
    }
  }

  @Builder
  TimeTip() {
    if (this.photos.length >= 2) {
      Column({ space: 8 }) {
        Row() {
          Text('时间跨度')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor(0xFF263238);
          Blank();
        }

        Row() {
          Text('从')
            .fontSize(14)
            .fontColor(0xFF78909C);
          Text(this.shortLabelOf(this.photos[0]))
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(0xFFFF9800);
          Text('到')
            .fontSize(14)
            .fontColor(0xFF78909C)
            .margin({ left: 8 });
          Text(this.shortLabelOf(this.photos[this.photos.length - 1]))
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(0xFFFF9800)
            .margin({ left: 8 });
        }
        .width('100%')
        .justifyContent(FlexAlign.Start);
      }
      .padding(20)
      .backgroundColor('#FFFFFF')
      .borderRadius(24)
      .shadow({
        radius: 12,
        color: '#11000000',
        offsetX: 0,
        offsetY: 2
      })
      .margin({ left: 16, right: 16 });
    }
  }

  labelOf(p: LogPhoto): string {
    const d: Date = new Date(p.createdAt);
    return `${d.getFullYear()}年${d.getMonth() + 1}月${d.getDate()}日`;
  }

  shortLabelOf(p: LogPhoto): string {
    const d: Date = new Date(p.createdAt);
    return `${d.getMonth() + 1}/${d.getDate()}`;
  }

  // 照片来源仍然是日志系统，这里只是按 plantId 聚合读取并转成“成长相册”视图。
  private async loadPhotos(): Promise<void> {
    if (!this.store || !this.plant) {
      return;
    }
    const rs = await this.store.querySql(
      `SELECT p.id, p.logId, p.path, p.thumbPath, p.createdAt
     FROM ${RdbManager.T_LOG_PHOTO} p
     JOIN ${RdbManager.T_LOG} l ON p.logId = l.id
     WHERE l.plantId = ?
     ORDER BY p.createdAt ASC`, [this.plant.id]
    );
    const arr: Array<LogPhoto> = [];
    while (rs.goToNextRow()) {
      arr.push(new LogPhoto(rs.getLong(0), rs.getLong(1), rs.getString(2), rs.getString(3), rs.getLong(4)));
    }
    rs.close();
    this.photos = arr;
    if (this.photos.length > 0 && this.selIdx >= this.photos.length) {
      this.selIdx = this.photos.length - 1;
    }
  }

  // 新增照片时如果当前植物还没有日志，会自动创建一条占位日志来承接图片。
  private async pickAndAddPhoto(): Promise<void> {
    if (this.picking || !this.plant) {
      return;
    }
    this.picking = true;
    try {
      await this.addImageFileViewModel.selectAndProcessImages([], async (newImages) => {
        if (newImages.length > 0) {
          const dir = await this.ensurePhotosDir();
          for (let i: number = 0; i < newImages.length; i++) {
            const srcUri: string = newImages[i].path;
            const dstPath: string = await this.copyImageToAppFiles(srcUri, dir);
            await this.insertTemporaryPhoto(this.plant!.id, dstPath);
          }
          await this.loadPhotos();
          hilog.info(0x0000, 'GrowthCompare', 'Photos added successfully');
        }
      }, 12);
    } catch (e) {
      console.error(`pickAndAddPhoto error: ${(e as Error).message}`);
    } finally {
      this.picking = false;
    }
  }

  private async ensurePhotosDir(): Promise<string> {
    const base: string = this.ctx.filesDir;
    const dir: string = `${base}/photos`;
    try {
      await fs.mkdir(dir);
    } catch (e) {
    }
    return dir;
  }

  private genPhotoName(): string {
    const d = new Date();
    const y = d.getFullYear().toString();
    const m = (d.getMonth() + 1).toString().padStart(2, '0');
    const day = d.getDate().toString().padStart(2, '0');
    const h = d.getHours().toString().padStart(2, '0');
    const mi = d.getMinutes().toString().padStart(2, '0');
    const s = d.getSeconds().toString().padStart(2, '0');
    const ms = d.getMilliseconds().toString().padStart(3, '0');
    return `GC_${y}${m}${day}_${h}${mi}${s}_${ms}.jpg`;
  }

  private async copyImageToAppFiles(srcUri: string, dstDir: string): Promise<string> {
    const name: string = this.genPhotoName();
    const dstPath: string = `${dstDir}/${name}`;
    if (srcUri.length >= 7 && srcUri.substring(0, 7) === 'file://') {
      const srcPath: string = srcUri.substring(7);
      try {
        await fs.copyFile(srcPath, dstPath);
        return dstPath;
      } catch (_e) {
        return srcPath;
      }
    }
    return dstPath;
  }

  private ensureFileUri(path: string): string {
    if (path.startsWith('file://')) {
      return path;
    }
    return `file://${path}`;
  }

  private async insertTemporaryPhoto(plantId: number, filePath: string): Promise<void> {
    if (!this.store) {
      return;
    }
    const uri: string = this.ensureFileUri(filePath);
    const now: number = Date.now();
    const rs = await this.store.querySql(
      `SELECT id FROM ${RdbManager.T_LOG} WHERE plantId = ? LIMIT 1`, [plantId]
    );
    let logId: number = 0;
    if (rs.goToNextRow()) {
      logId = rs.getLong(0);
    } else {
      const logValues: relationalStore.ValuesBucket = {
        plantId: plantId,
        note: '成长对比照片',
        createdAt: now
      };
      logId = await this.store.insert(RdbManager.T_LOG, logValues) as number;
    }
    rs.close();

    const photoValues: relationalStore.ValuesBucket = {
      logId: logId,
      path: uri,
      thumbPath: uri,
      createdAt: now
    };
    await this.store.insert(RdbManager.T_LOG_PHOTO, photoValues);
  }
}
