// 花束方案卡片组件

import { AppTheme } from '../common/Theme';
import { BouquetScheme } from '../models/RecommendModel';

@Component
export struct BouquetCard {
  // 花束方案数据
  @Prop scheme: BouquetScheme;
  // 点击回调
  onCardClick?: (scheme: BouquetScheme) => void;

  build() {
    Column() {
      // 方案效果图
      Image(this.scheme.imageUrl)
        .width('100%')
        .height(140)
        .objectFit(ImageFit.Cover)
        .borderRadius({ topLeft: AppTheme.BORDER_RADIUS_MEDIUM, topRight: AppTheme.BORDER_RADIUS_MEDIUM })
        .backgroundColor(AppTheme.DIVIDER_COLOR)

      // 方案信息区域
      Column() {
        // 方案名称
        Text(this.scheme.name)
          .fontSize(AppTheme.FONT_SIZE_MEDIUM)
          .fontColor(AppTheme.TEXT_PRIMARY)
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        // 方案描述
        Text(this.scheme.description)
          .fontSize(AppTheme.FONT_SIZE_SMALL)
          .fontColor(AppTheme.TEXT_SECONDARY)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: AppTheme.SPACING_SMALL / 2 })

        // 底部信息：匹配度 + 价格
        Row() {
          // 匹配度标签
          Text(`匹配度 ${this.scheme.matchScore}%`)
            .fontSize(AppTheme.FONT_SIZE_SMALL)
            .fontColor(AppTheme.SECONDARY_COLOR)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .borderRadius(AppTheme.BORDER_RADIUS_SMALL)
            .backgroundColor(AppTheme.SECONDARY_COLOR_ALPHA20)

          // 价格
          Text(`¥${this.scheme.totalPrice}`)
            .fontSize(AppTheme.FONT_SIZE_NORMAL)
            .fontColor(AppTheme.ACCENT_COLOR)
            .fontWeight(FontWeight.Bold)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .margin({ top: AppTheme.SPACING_SMALL })
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
        this.onCardClick(this.scheme);
      }
    })
  }
}