// 场景选择器组件

import { AppTheme } from '../common/Theme';
import { SceneType } from '../models/RecommendModel';
import { SCENE_NAMES, SCENE_ICONS } from '../utils/Constants';

// 场景项数据结构
interface SceneItem {
  type: SceneType;
  name: string;
  icon: string;
}

@Component
export struct SceneSelector {
  // 场景列表
  @State sceneList: SceneItem[] = [
    { type: SceneType.BIRTHDAY, name: SCENE_NAMES['birthday'], icon: SCENE_ICONS['birthday'] },
    { type: SceneType.CONFESSION, name: SCENE_NAMES['confession'], icon: SCENE_ICONS['confession'] },
    { type: SceneType.ANNIVERSARY, name: SCENE_NAMES['anniversary'], icon: SCENE_ICONS['anniversary'] },
    { type: SceneType.APOLOGY, name: SCENE_NAMES['apology'], icon: SCENE_ICONS['apology'] },
    { type: SceneType.GRATITUDE, name: SCENE_NAMES['gratitude'], icon: SCENE_ICONS['gratitude'] },
    { type: SceneType.VISIT, name: SCENE_NAMES['visit'], icon: SCENE_ICONS['visit'] }
  ];

  // 选中场景
  @State selectedScene: SceneType = SceneType.BIRTHDAY;
  // 选择回调
  onSceneSelect?: (scene: SceneType) => void;

  build() {
    Grid() {
      ForEach(this.sceneList, (item: SceneItem) => {
        GridItem() {
          Column() {
            // 场景图标
            Text(item.icon)
              .fontSize(28)
              .margin({ bottom: AppTheme.SPACING_SMALL / 2 })

            // 场景名称
            Text(item.name)
              .fontSize(AppTheme.FONT_SIZE_NORMAL)
              .fontColor(this.selectedScene === item.type ? AppTheme.PRIMARY_COLOR : AppTheme.TEXT_PRIMARY)
              .fontWeight(this.selectedScene === item.type ? FontWeight.Bold : FontWeight.Normal)
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor(this.selectedScene === item.type ? AppTheme.PRIMARY_COLOR_ALPHA20 : AppTheme.CARD_BACKGROUND)
          .borderRadius(AppTheme.BORDER_RADIUS_MEDIUM)
          .border(this.selectedScene === item.type ? {
            width: 2,
            color: AppTheme.PRIMARY_COLOR,
            style: BorderStyle.Solid
          } : undefined)
          .onClick(() => {
            this.selectedScene = item.type;
            if (this.onSceneSelect) {
              this.onSceneSelect(item.type);
            }
          })
        }
      }, (item: SceneItem) => item.type)
    }
    .columnsTemplate('1fr 1fr 1fr')
    .rowsGap(AppTheme.SPACING_SMALL)
    .columnsGap(AppTheme.SPACING_SMALL)
    .width('100%')
    .height(160)
  }
}