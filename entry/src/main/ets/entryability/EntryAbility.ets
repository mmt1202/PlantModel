import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { formInfo } from '@kit.FormKit';
import { RdbManager } from '../viewmodel/RdbManager';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      const error = err as BusinessError;
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(error));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');
    let windowClass: window.Window = windowStage.getMainWindowSync();
    let isLayoutFullScreen = true;
    windowClass.setWindowLayoutFullScreen(isLayoutFullScreen).then(() => {
      hilog.info(0x0000, 'testTag', 'Succeeded in setting the window layout to full-screen mode.');
    }).catch((err: BusinessError) => {
      hilog.error(0x0000, 'testTag',
        'Failed to set the window layout to full-screen mode. Cause:' + JSON.stringify(err));
    });
    let type_1 = window.AvoidAreaType.TYPE_SYSTEM;
    let avoidArea_1 = windowClass.getWindowAvoidArea(type_1);

    let topRectHeight = avoidArea_1.topRect.height;
    hilog.info(0x0000, 'testTag', '%{public}s', `liheng topRectHeight${px2vp(topRectHeight)}`);
    AppStorage.setOrCreate('topRectHeight', px2vp(topRectHeight));

    let type_2 = window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR;
    let avoidArea_2 = windowClass.getWindowAvoidArea(type_2);
    let bottomRectHeight = avoidArea_2.bottomRect.height
    AppStorage.setOrCreate('bottomRectHeight', px2vp(bottomRectHeight))

    windowClass.on('avoidAreaChange', (data) => {
      if (data.type === window.AvoidAreaType.TYPE_SYSTEM) {
        let topRectHeight = data.area.topRect.height;
        AppStorage.setOrCreate('topRectHeight', px2vp(topRectHeight));
      } else if (data.type === window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR) {
        let bottomRectHeight = data.area.bottomRect.height
        AppStorage.setOrCreate('bottomRectHeight', px2vp(bottomRectHeight))
      }
    });

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
    this.refreshFormCards();
  }

  onBackground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }

  private async refreshFormCards(): Promise<void> {
    try {
      const want: Want = {
        bundleName: 'com.example.plantdiary',
        abilityName: 'PlantFormExtension'
      };

      await formInfo.requestFormReady(this.context, want);
      hilog.info(DOMAIN, 'testTag', 'Form cards refresh requested');
    } catch (err) {
      const error = err as BusinessError;
      hilog.error(DOMAIN, 'testTag', 'Failed to refresh form cards: %{public}s', JSON.stringify(error));
    }
  }
}
