import { Plant } from '../model/PlantModel';
import { GrowthComparePage } from './GrowthComparePage';
import { LightExposurePage } from './LightExposurePage';

@ComponentV2
export struct PlantDetail {
  @Local plant: Plant | undefined = undefined;

  build() {
    NavDestination() {
      Scroll() {
        if (this.plant) {
          Column() {
            // 头图
            // LightExposurePage({ plantId: this.plant.id })
            GrowthComparePage({ plantId: this.plant.id })
            // Image(this.plant.cover).height(220).objectFit(ImageFit.Cover)
            // 基本信息
            Text(this.plant.name).fontSize(22).fontWeight(FontWeight.Medium).padding(16)

            // 快捷操作区
            Row({ space: 12 }) {
              // PrimaryButton('记录浇水', () => this.quickLog('WATER'))
              // GhostButton('添加照片', () => this.addPhoto())
              // GhostButton('二维码', () => this.showQRCode())
            }.padding({ left: 16, right: 16, bottom: 12 })

            // 时间线
            // Timeline(this.plant.logs)
          }
        }
      }.edgeEffect(EdgeEffect.Spring)
    }.width('100%').height('100%')
    .padding({
      top: AppStorage.get<number>('topRectHeight'),
      bottom: AppStorage.get<number>('bottomRectHeight')
    })
    .linearGradient({
      direction: GradientDirection.Top,
      colors: [[0xFFF1F8E9, 0], [0xFFE8F5E9, 0.5], [0xFFE3F2FD, 1.0]]
    })
    .onReady((param) => {
      const plant = param.pathInfo.param as Plant
      this.plant = plant
    })
  }
}
