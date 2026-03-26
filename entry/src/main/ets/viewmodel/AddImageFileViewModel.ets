import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { dataSharePredicates } from '@kit.ArkData';
import { fileIo as fs } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { image } from '@kit.ImageKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

export interface CompressedImage {
  path: string;
  pathFileName?: string;
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

  // 把 URI 统一转成应用内部更容易处理的路径格式。
  public transformPath(originalUri: string): string {
    return originalUri.replace('file:/', '');
  }

  // 统一封装“选图 -> 逐张处理 -> 回调新图列表”的异步流程，供多个页面复用。
  public async selectAndProcessImages(
    existingImages: CompressedImage[],
    callback: (newImages: CompressedImage[]) => void,
    selectCount: number = 1
  ): Promise<void> {
    try {
      const uriList: Array<ResourceStr> = await this.fileSelect(selectCount);
      const newImages: CompressedImage[] = [];

      for (const item of uriList) {
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

  // 选图层只返回 URI，不负责后续复制或落库，职责保持单一。
  private async fileSelect(selectCount: number = 1): Promise<Array<ResourceStr>> {
    let imgUri: Array<string> = [];
    const selectOptions = new photoAccessHelper.PhotoSelectOptions();
    selectOptions.maxSelectNumber = selectCount;
    const photoPicker = new photoAccessHelper.PhotoViewPicker();

    try {
      const result = await photoPicker.select(selectOptions);
      if (result && result.photoUris && result.photoUris.length > 0) {
        imgUri = result.photoUris;
        return imgUri;
      }
      return [];
    } catch (_error) {
      return [];
    }
  }

  // 当前处理流程主要是拿到缩略图并写入分布式目录，为后续共享或预览预留出口。
  private async processImage(originalUri: string): Promise<CompressedImage | null> {
    try {
      const helper = photoAccessHelper.getPhotoAccessHelper(this.context);
      const predicates: dataSharePredicates.DataSharePredicates = new dataSharePredicates.DataSharePredicates();
      predicates.equalTo('uri', originalUri);

      const fetchOption: photoAccessHelper.FetchOptions = {
        fetchColumns: [],
        predicates: predicates
      };

      const fetchResult: photoAccessHelper.FetchResult<photoAccessHelper.PhotoAsset> =
        await helper.getAssets(fetchOption);

      const asset: photoAccessHelper.PhotoAsset = await fetchResult.getFirstObject();
      const pixelMap = await new Promise<image.PixelMap>((resolve, reject) => {
        asset.getThumbnail((err, pm) => {
          if (err) {
            reject(err);
          } else {
            resolve(pm);
          }
        });
      });

      const imageName = asset.displayName.substring(0, asset.displayName.indexOf('.'));
      this.pixelMapToBuffer(pixelMap, imageName);

      return {
        path: originalUri,
        pathFileName: asset.displayName
      };
    } catch (error) {
      hilog.error(0x0000, '[AddImageFileViewModel]', `processImage failed: ${JSON.stringify(error)}`);
      return null;
    }
  }

  // 把 PixelMap 转成 JPEG 二进制，再交给统一写文件逻辑。
  private pixelMapToBuffer(pixelMap: image.PixelMap, displayName: string): void {
    const imagePackerApi: image.ImagePacker = image.createImagePacker();
    const packOpts: image.PackingOption = { format: 'image/jpeg', quality: 100 };

    imagePackerApi.packToData(pixelMap, packOpts).then((data: ArrayBuffer) => {
      this.writeDistributedFile(data, displayName);
    });
  }

  // 文件落到 distributedFilesDir，后续如果需要跨设备或富文本引用会更方便。
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
}
