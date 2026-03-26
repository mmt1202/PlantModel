import { resourceManager } from '@kit.LocalizationKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { image } from '@kit.ImageKit';
import { fileIo } from '@kit.CoreFileKit';

@Entry
@Component
struct SavePixelMapToAlbum {
  @State saveButtonOptions: SaveButtonOptions = {
    icon: SaveIconStyle.FULL_FILLED,
    text: SaveDescription.SAVE,
    buttonType: ButtonType.Capsule
  };
  @State pixel: image.PixelMap | undefined = undefined;
  @State albumPath: string = '';
  @State photoSize: number = 0;
  private context: Context = this.getUIContext().getHostContext()!;

  async aboutToAppear() {
    // 这个页面更像一个独立示例：加载 rawfile 里的图片，再演示如何保存到系统相册。
    const resourceMgr: resourceManager.ResourceManager = this.context.resourceManager;
    // "beer.jpeg" is the name of the image file under the rawfile directory, which can be modified and used according to your own needs
    const fileData: Uint8Array = await resourceMgr.getRawFileContent('beer.jpeg');
    let buffer = new Uint8Array(fileData).buffer as object as ArrayBuffer;
    let imageResource = image.createImageSource(buffer);
    let opts: image.DecodingOptions = { editable: true };
    this.pixel = await imageResource.createPixelMap(opts);
  }

  async savePixelMapToAlbum() {
    // 保存流程分三步：申请媒体资产 URI、把 PixelMap 编码成 JPEG、写入册目录。
    // Obtain the save path of the album
    let helper = photoAccessHelper.getPhotoAccessHelper(this.context);
    let uri = await helper.createAsset(photoAccessHelper.PhotoType.IMAGE, 'jpeg');
    let file = await fileIo.open(uri, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
    let imagePackerApi = image.createImagePacker();
    let packOpts: image.PackingOption = { format: 'image/jpeg', quality: 98 };

    imagePackerApi.packToFile(this.pixel, file.fd, packOpts, (err: BusinessError) => {
      if (err) {
        console.error(`Failed to pack the image to file.code ${err.code},message is ${err.message}`);
      } else {
        console.info('Succeeded in packing the image to file.');
        imagePackerApi.release((err: BusinessError) => {
          if (err) {
            console.error(`Failed to release the image source instance.code ${err.code},message is ${err.message}`);
          } else {
            console.info('Succeeded in releasing the image source instance.');
            fileIo.close(file.fd);
          }
        })
        this.getUIContext().getPromptAction().showToast({ message: '已保存至相册！' });
      }
    })
  }

  build() {
    // UI 很简单，只保留预览图和系统 SaveButton，重点在前面的媒体保存流程示例。
    Row() {
      Column() {
        Image(this.pixel)
          .objectFit(ImageFit.None)
          .height('30%')

        SaveButton(this.saveButtonOptions)
          .onClick(async (event, result: SaveButtonOnClickResult) => {
            if (result === SaveButtonOnClickResult.SUCCESS) {
              this.savePixelMapToAlbum();
            }
          })
      }
      .width('100%')
    }
    .height('100%')
  }
}
