import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { dataSharePredicates } from '@kit.ArkData';
import { fileIo as fs } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { image } from '@kit.ImageKit';
import { hilog } from '@kit.PerformanceAnalysisKit';


// const TARGET_SIZE = 100 * 1024; // 目标压缩大小：100KB

export interface CompressedImage {
  path: string; // 处理后的路径（无file://前缀）
  pathFileName?: string; // 压缩后的本地路径
}

export class AddImageFileViewModel {
  private static instance: AddImageFileViewModel;
  private context: common.UIAbilityContext;

  private constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

  public static getInstance(context: common.UIAbilityContext): AddImageFileViewModel {
    if (!AddImageFileViewModel.instance) {
      AddImageFileViewModel.instance = new AddImageFileViewModel(context);
    }
    return AddImageFileViewModel.instance;
  }

  /**
   * 转换路径（去除file://前缀）
   */
  public transformPath(originalUri: string): string {
    return originalUri.replace('file:/', '');
  }

  /*
   * 选择图片并处理
   */
  public async selectAndProcessImages(
    existingImages: CompressedImage[],
    callback: (newImages: CompressedImage[]) => void,
    selectCount: number = 1
  ): Promise<void> {
    try {
      const uri: Array<ResourceStr> = await this.fileSelect(selectCount);
      // hilog.info(0x0000, 'HTTPUtil', '%{public}s', `liheng uri:${JSON.stringify(uri)}`);
      // if ((existingImages.length + uri.length) > CommonConstants.MAX_ADD_PIC) {
      //   const maxAdd = CommonConstants.MAX_ADD_PIC - existingImages.length;
      //   uri.length = maxAdd;
      // }

      // 直接将数据处理成一个array ArrayBuffer的数据


      const newImages: CompressedImage[] = [];
      for (const item of uri) {
        const imageInfo = await this.processImage(item as string);
        if (imageInfo) {
          newImages.push(imageInfo);
        }
      }
      callback(newImages);
    } catch (error) {
      hilog.error(0x0000, '[AddImageFileViewModel]', `selectAndProcessImages failed: ${JSON.stringify(error)}`);
    }
  }

  /*
   * 文件选择
   */
  private async fileSelect(selectCount: number = 1): Promise<Array<ResourceStr>> {
    let imgUri: Array<string> = [];
    let PhotoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
    // PhotoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
    PhotoSelectOptions.maxSelectNumber = selectCount;
    let photoPicker = new photoAccessHelper.PhotoViewPicker();
    try {
      let PhotoSelectResult = await photoPicker.select(PhotoSelectOptions);
      if (PhotoSelectResult && PhotoSelectResult.photoUris && PhotoSelectResult.photoUris.length > 0) {
        imgUri = PhotoSelectResult.photoUris;
        // await this.uploadFiles()
        return imgUri;
      } else {
        return [];
      }
    } catch (error) {
      return [];
    }
  }

  /*
   * 处理单张图片
   */
  private async processImage(originalUri: string): Promise<CompressedImage | null> {
    try {
      // const transformedPath = this.transformPath(originalUri);

      const phAccessHelper = photoAccessHelper.getPhotoAccessHelper(this.context);
      const predicates: dataSharePredicates.DataSharePredicates = new dataSharePredicates.DataSharePredicates();
      predicates.equalTo('uri', originalUri);

      const fetchOption: photoAccessHelper.FetchOptions = {
        fetchColumns: [],
        predicates: predicates
      };

      const fetchResult: photoAccessHelper.FetchResult<photoAccessHelper.PhotoAsset> =
        await phAccessHelper.getAssets(fetchOption);

      const asset: photoAccessHelper.PhotoAsset = await fetchResult.getFirstObject();
      const pixelMap = await new Promise<image.PixelMap>((resolve, reject) => {
        asset.getThumbnail((err, pixelMap) => {
          if (err) {
            reject(err);
          } else {
            resolve(pixelMap);
          }
        });
      });

      const imageName = asset.displayName.substring(0, asset.displayName.indexOf('.'));
      this.PixelMapToBuffer(pixelMap, imageName);


      return {
        path: originalUri,
        pathFileName: asset.displayName
      };
    } catch (error) {
      hilog.error(0x0000, '[AddImageFileViewModel]', `processImage failed: ${JSON.stringify(error)}`);
      return null;
    }
  }

  // private async compressPixelMap(pixelMap: image.PixelMap, originalName: string): Promise<string | null> {
  //   try {
  //     // 4.1 获取原始尺寸
  //     const imageInfo = await pixelMap.getImageInfo();
  //     let { width, height } = imageInfo.size;
  //
  //     // 4.2 计算缩放比例（按面积压缩）
  //     let scale = 1.0;
  //     // 估算原始大小（简化计算：假设每个像素4字节）
  //     const estimatedOriginalSize = width * height * 4;
  //     if (estimatedOriginalSize > TARGET_SIZE * 2) {
  //       // 按目标大小的2倍计算缩放（留有余地）
  //       scale = Math.sqrt((TARGET_SIZE * 2) / estimatedOriginalSize);
  //     }
  //
  //     // 4.3 压缩配置
  //     const encodeConfig: image.EncodeOptions = {
  //       format: image.ImageFormat.JPEG,
  //       quality: 0.8, // 初始质量，可根据实际大小微调
  //       size: {
  //         width: Math.floor(width * scale),
  //         height: Math.floor(height * scale)
  //       }
  //     };
  //
  //     // 4.4 编码为缓冲区
  //     const compressedBuffer = await image.encodeToBuffer(pixelMap, encodeConfig);
  //
  //     // 4.5 如果仍超过目标大小，降低质量重试（最多2次）
  //     if (compressedBuffer.byteLength > TARGET_SIZE) {
  //       encodeConfig.quality = 0.5;
  //       const reCompressedBuffer = await image.encodeToBuffer(pixelMap, encodeConfig);
  //       if (reCompressedBuffer.byteLength <= TARGET_SIZE) {
  //         compressedBuffer = reCompressedBuffer;
  //       }
  //     }
  //
  //     // 4.6 保存到应用沙箱缓存目录
  //     const cacheDir = this.context.cacheDir;
  //     const fileName = `compressed_${Date.now()}_${originalName.replace(/\s+/g, '_')}`;
  //     const savePath = `${cacheDir}/${fileName}`;
  //
  //     // 4.7 写入文件
  //     const file = await fileio.open(savePath, fileio.OpenMode.WRITE_ONLY | fileio.OpenMode.CREATE);
  //     await fileio.write(file.fd, compressedBuffer);
  //     await fileio.close(file.fd);
  //
  //     // 释放PixelMap
  //     pixelMap.release();
  //
  //     return savePath;
  //   } catch (error) {
  //     hilog.error(0x0000, TAG, `压缩图片失败: ${JSON.stringify(error)}`);
  //     return null;
  //   }
  // }

  /*
   * 转换PixelMap为Buffer
   */
  private PixelMapToBuffer(pixelMap: image.PixelMap, displayName: string): void {
    const imagePackerApi: image.ImagePacker = image.createImagePacker();
    let packOpts: image.PackingOption = { format: 'image/jpeg', quality: 100 };

    imagePackerApi.packToData(pixelMap, packOpts).then((data: ArrayBuffer) => {
      this.writeDistributedFile(data, displayName);
    });
  }

  /*
   * 写入分布式文件
   */
  private writeDistributedFile(buf: ArrayBuffer, displayName: string): void {
    const distributedDir: string = this.context.distributedFilesDir;
    const fileName: string = '/' + displayName;
    const filePath: string = distributedDir + fileName;

    try {
      const file = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      fs.writeSync(file.fd, buf);
      fs.closeSync(file.fd);
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      hilog.error(0x0000, '[AddImageFileViewModel]',
        `writeDistributedFile failed: Code ${err.code}, ${err.message}`);
    }
  }

  /*
   * 插入图片到TextArea
   */
  // public insertImageToTextArea(
  //   pixelMap: image.PixelMap,
  //   callback: (markdown: string) => void
  // ): void {
  //   const uuid = util.generateRandomUUID();
  //   this.PixelMapToBuffer(pixelMap, uuid);
  //
  //   // 生成Markdown格式的图片引用
  //   const markdown = `![${uuid}](distributed:///${uuid})`;
  //   callback(markdown);
  // }
}