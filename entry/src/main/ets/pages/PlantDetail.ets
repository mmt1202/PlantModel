import { Plant } from '../model/PlantModel';

@ComponentV2
export struct PlantDetail {
  @Local plant: Plant | undefined = undefined;
  @Param @Require pageStack: NavPathStack;

  build() {
    NavDestination() {
      Column() {
        this.Header()
        Scroll() {
          if (this.plant) {
            Column({ space: 16 }) {
              this.PlantInfoCard()
              this.QuickActionGrid()
            }
            .padding({ left: 16, right: 16, top: 8, bottom: 32 })
          }
        }.layoutWeight(1)
      }
    }.width('100%').height('100%')
    .title('植物详情')
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

  @Builder
  Header() {
    Row() {
      Text('植物详情').fontSize(22).fontWeight(FontWeight.Medium).fontColor(0xFF263238)
      Blank()
    }
    .padding({ left: 16, right: 16, top: 12, bottom: 8 })
  }

  @Builder
  PlantInfoCard() {
    Column({ space: 12 }) {
      Text(this.plant!.name).fontSize(28).fontWeight(FontWeight.Bold).fontColor(0xFF1B5E20)
      if (this.plant!.species.length > 0) {
        Text(this.plant!.species).fontSize(16).fontColor(0xFF546E7A)
      }
      if (this.plant!.location.length > 0) {
        Row({ space: 4 }) {
          Image($r('app.media.ic_location')).width(14).height(14)
          Text(this.plant!.location).fontSize(14).fontColor(0xFF78909C)
        }
      }
      Text(`添加于 ${new Date(this.plant!.createdAt).toLocaleDateString()}`)
        .fontSize(12).fontColor(0xFF90A4AE).margin({ top: 4 })
    }
    .width('100%')
    .padding(24)
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .shadow({ radius: 12, color: '#1A000000', offsetX: 0, offsetY: 4 })
  }

  @Builder
  QuickActionGrid() {
    Column({ space: 12 }) {
      Text('快捷功能')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(0xFF263238)
      Grid() {
        GridItem() {
          this.ActionCard($r('app.media.ic_journal'), '养护日志', () => {
            this.pageStack.pushPathByName('PlantLogPage', this.plant!.id)
          })
        }
        GridItem() {
          this.ActionCard($r('app.media.ic_sun'), '光照记录', () => {
            this.pageStack.pushPathByName('LightExposurePage', this.plant!)
          })
        }
        GridItem() {
          this.ActionCard($r('app.media.ic_chart'), '生长指标', () => {
            this.pageStack.pushPathByName('GrowthIndicatorPage', this.plant!)
          })
        }
        GridItem() {
          this.ActionCard($r('app.media.ic_camera'), '成长对比', () => {
            this.pageStack.pushPathByName('GrowthComparePage', this.plant!)
          })
        }
        GridItem() {
          this.ActionCard($r('app.media.ic_water'), '浇水估算', () => {
            this.pageStack.pushPathByName('WaterEstimatorPage', this.plant!.id)
          })
        }
        GridItem() {
          this.ActionCard($r('app.media.ic_refresh'), '应急与轮换', () => {
            this.pageStack.pushPathByName('EmergencyAndRotatePage', this.plant!.id)
          })
        }
      }
      .columnsTemplate('1fr 1fr')
      .columnsGap(12)
      .rowsGap(12)
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  ActionCard(icon: Resource, title: string, onClick: () => void) {
    Column({ space: 8 }) {
      Image(icon)
        .width(32)
        .height(32)
      Text(title)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#263238')
    }
    .width('100%')
    .height(100)
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({ radius: 6, color: '#15000000', offsetX: 0, offsetY: 2 })
    .onClick(onClick)
  }
}
