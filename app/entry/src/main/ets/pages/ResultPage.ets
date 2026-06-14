import { AppTheme } from '../common/Theme';
import { CommonButton, CustomButtonType, ButtonSize } from '../components/CommonButton';
import { BouquetScheme, FlowerItem } from '../models/RecommendModel';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';

@Entry
@Component
export struct ResultPage {
  @State schemes: BouquetScheme[] = [];
  @State reason: string = '';
  @State currentSchemeIndex: number = 0;

  aboutToAppear() {
    const params = router.getParams();
    if (params?.schemesData) {
      try {
        this.schemes = JSON.parse(params.schemesData as string) as BouquetScheme[];
      } catch (e) {
        console.error('Parse error:', JSON.stringify(e));
      }
    }
    if (params?.reason) this.reason = params.reason as string;
  }

  private getOrderParams(scheme: BouquetScheme): string {
    return JSON.stringify({
      cartData: JSON.stringify([{ scheme, quantity: 1 }])
    });
  }

  build() {
    Column() {
      // Header
      Row() {
        Text('<')
          .fontSize(AppTheme.FONT_SIZE_LARGE)
          .fontColor(AppTheme.TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .padding(AppTheme.SPACING_SMALL)
          .onClick(() => router.back())

        Text('为你推荐的花束')
          .fontSize(AppTheme.FONT_SIZE_LARGE)
          .fontColor(AppTheme.TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .margin({ left: AppTheme.SPACING_SMALL })
      }
      .width('100%')
      .height(56)
      .padding({ left: AppTheme.SPACING_MEDIUM, right: AppTheme.SPACING_MEDIUM })
      .alignItems(VerticalAlign.Center)
      .backgroundColor(AppTheme.CARD_BACKGROUND)

      if (this.schemes.length === 0) {
        Column() {
          Text('暂无推荐结果')
            .fontSize(AppTheme.FONT_SIZE_MEDIUM)
            .fontColor(AppTheme.TEXT_SECONDARY)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        // Scheme swiper
        Swiper() {
          ForEach(this.schemes, (scheme: BouquetScheme) => {
            Scroll() {
              Column() {
                // Name
                Text(scheme.name)
                  .fontSize(AppTheme.FONT_SIZE_XLARGE)
                  .fontColor(AppTheme.TEXT_PRIMARY)
                  .fontWeight(FontWeight.Bold)
                  .margin({ bottom: AppTheme.SPACING_SMALL })

                // Price & style
                Row() {
                  Text(scheme.style || '花束')
                    .fontSize(AppTheme.FONT_SIZE_SMALL)
                    .fontColor('#FFFFFF')
                    .backgroundColor(AppTheme.PRIMARY_COLOR)
                    .borderRadius(AppTheme.BORDER_RADIUS_CIRCLE)
                    .padding({ left: 10, right: 10, top: 3, bottom: 3 })

                  Text(`¥${scheme.totalPrice}`)
                    .fontSize(AppTheme.FONT_SIZE_LARGE)
                    .fontColor(AppTheme.ACCENT_COLOR)
                    .fontWeight(FontWeight.Bold)
                    .margin({ left: 'auto' })
                }
                .width('100%')
                .margin({ bottom: AppTheme.SPACING_MEDIUM })

                // Flowers
                Text('花材搭配')
                  .fontSize(AppTheme.FONT_SIZE_MEDIUM)
                  .fontColor(AppTheme.TEXT_PRIMARY)
                  .fontWeight(FontWeight.Bold)
                  .margin({ bottom: AppTheme.SPACING_SMALL })

                ForEach(scheme.flowers, (flower: FlowerItem) => {
                  Row() {
                    Text(`${flower.flowerName} ×${flower.quantity}`)
                      .fontSize(AppTheme.FONT_SIZE_NORMAL)
                      .fontColor(AppTheme.TEXT_PRIMARY)
                      .layoutWeight(1)
                    Text(flower.meaning)
                      .fontSize(AppTheme.FONT_SIZE_SMALL)
                      .fontColor(AppTheme.PRIMARY_COLOR)
                  }
                  .width('100%')
                  .padding({ top: 4, bottom: 4 })
                }, (flower: FlowerItem) => `${flower.flowerId}`)

                // Flower language
                Text('花语解读')
                  .fontSize(AppTheme.FONT_SIZE_MEDIUM)
                  .fontColor(AppTheme.TEXT_PRIMARY)
                  .fontWeight(FontWeight.Bold)
                  .margin({ top: AppTheme.SPACING_MEDIUM, bottom: AppTheme.SPACING_SMALL })

                Text(scheme.meaning)
                  .fontSize(AppTheme.FONT_SIZE_NORMAL)
                  .fontColor(AppTheme.TEXT_PRIMARY)
                  .fontStyle(FontStyle.Italic)
                  .lineHeight(22)

                // Reason
                if (this.reason) {
                  Text('推荐理由')
                    .fontSize(AppTheme.FONT_SIZE_MEDIUM)
                    .fontColor(AppTheme.TEXT_PRIMARY)
                    .fontWeight(FontWeight.Bold)
                    .margin({ top: AppTheme.SPACING_MEDIUM, bottom: AppTheme.SPACING_SMALL })

                  Text(this.reason)
                    .fontSize(AppTheme.FONT_SIZE_NORMAL)
                    .fontColor(AppTheme.TEXT_SECONDARY)
                    .lineHeight(22)
                }
              }
              .width('100%')
              .padding(AppTheme.SPACING_MEDIUM)
            }
            .scrollable(ScrollDirection.Vertical)
          }, (scheme: BouquetScheme) => `${scheme.id}`)
        }
        .width('100%')
        .layoutWeight(1)
        .indicator(true)

        // Bottom buttons
        CommonButton({
          text: '换一批方案',
          type: CustomButtonType.OUTLINE,
          size: ButtonSize.LARGE,
          onClick: () => router.back()
        })
        .width('100%')
        .padding({ left: AppTheme.SPACING_MEDIUM, right: AppTheme.SPACING_MEDIUM, bottom: AppTheme.SPACING_MEDIUM })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppTheme.BACKGROUND_COLOR)
  }
}
