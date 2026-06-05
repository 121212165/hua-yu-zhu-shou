// 花材卡片组件

import { AppTheme } from '../common/Theme';
import { FlowerInfo } from '../models/FlowerModel';

@Component
export struct FlowerCard {
  // 花材数据
  @Prop flower: FlowerInfo;
  // 点击回调
  onCardClick?: (flower: FlowerInfo) => void;

  build() {
    Column() {
      // 花材图片
      Image(this.flower.imageUrl)
        .width('100%')
        .height(120)
        .objectFit(ImageFit.Cover)
        .borderRadius({ topLeft: AppTheme.BORDER_RADIUS_MEDIUM, topRight: AppTheme.BORDER_RADIUS_MEDIUM })
        .backgroundColor(AppTheme.DIVIDER_COLOR)

      // 花材信息区域
      Column() {
        // 花材名称
        Text(this.flower.name)
          .fontSize(AppTheme.FONT_SIZE_MEDIUM)
          .fontColor(AppTheme.TEXT_PRIMARY)
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        // 花语含义
        Text(this.flower.meaning)
          .fontSize(AppTheme.FONT_SIZE_SMALL)
          .fontColor(AppTheme.TEXT_SECONDARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: AppTheme.SPACING_SMALL / 2 })

        // 价格
        Row() {
          Text(`¥${this.flower.price}`)
            .fontSize(AppTheme.FONT_SIZE_NORMAL)
            .fontColor(AppTheme.ACCENT_COLOR)
            .fontWeight(FontWeight.Bold)

          Text('/支')
            .fontSize(AppTheme.FONT_SIZE_SMALL)
            .fontColor(AppTheme.TEXT_SECONDARY)
        }
        .margin({ top: AppTheme.SPACING_SMALL / 2 })
      }
      .padding(AppTheme.SPACING_SMALL)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .backgroundColor(AppTheme.CARD_BACKGROUND)
    .borderRadius(AppTheme.BORDER_RADIUS_MEDIUM)
    .shadow({
      radius: AppTheme.CARD_SHADOW_RADIUS,
      color: AppTheme.CARD_SHADOW_COLOR,
      offsetY: AppTheme.CARD_SHADOW_OFFSETY
    })
    .onClick(() => {
      if (this.onCardClick) {
        this.onCardClick(this.flower);
      }
    })
  }
}