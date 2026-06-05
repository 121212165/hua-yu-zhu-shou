// 购物车页面 - 已选花束方案管理、数量调整、去结算

import { AppTheme } from '../common/Theme';
import { CommonButton, CustomButtonType, ButtonSize } from '../components/CommonButton';
import { CartStore, CartItem } from '../store/CartStore';
import router from '@ohos.router';

@Entry
@Component
struct CartPage {
  // 购物车列表 - 通过 StorageLink 自动同步 AppStorage 中的持久化数据
  @StorageLink('cartItems') cartItems: CartItem[] = [];

  aboutToAppear() {
    // 初始化 AppStorage 并从磁盘恢复购物车数据
    CartStore.initAppStorage();
    CartStore.loadFromDisk();
  }

  // 增加数量
  private increaseQuantity(index: number): void {
    CartStore.increaseQuantity(index);
  }

  // 减少数量
  private decreaseQuantity(index: number): void {
    CartStore.decreaseQuantity(index);
  }

  // 删除购物车项
  private removeItem(index: number): void {
    CartStore.removeItem(index);
  }

  // 去结算
  private goToCheckout(): void {
    router.pushUrl({
      url: 'pages/OrderConfirmPage',
      params: {
        cartData: JSON.stringify(this.cartItems)
      }
    }).catch((error: Error) => {
      console.error('跳转订单确认页失败:', JSON.stringify(error));
    });
  }

  build() {
    Column() {
      // 顶部标题栏
      Row() {
        Text('<')
          .fontSize(AppTheme.FONT_SIZE_LARGE)
          .fontColor(AppTheme.TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .padding(AppTheme.SPACING_SMALL)
          .onClick(() => {
            router.back();
          })

        Text('购物车')
          .fontSize(AppTheme.FONT_SIZE_LARGE)
          .fontColor(AppTheme.TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .margin({ left: AppTheme.SPACING_SMALL })

        if (this.cartItems.length > 0) {
          Text(`(${this.cartItems.length})`)
            .fontSize(AppTheme.FONT_SIZE_NORMAL)
            .fontColor(AppTheme.TEXT_SECONDARY)
            .margin({ left: 4 })
        }
      }
      .width('100%')
      .height(56)
      .padding({ left: AppTheme.SPACING_MEDIUM, right: AppTheme.SPACING_MEDIUM })
      .alignItems(VerticalAlign.Center)
      .backgroundColor(AppTheme.CARD_BACKGROUND)

      if (this.cartItems.length === 0) {
        // 空购物车状态
        Column() {
          Text('🛒')
            .fontSize(64)
            .margin({ bottom: AppTheme.SPACING_MEDIUM })

          Text('购物车空空如也')
            .fontSize(AppTheme.FONT_SIZE_MEDIUM)
            .fontColor(AppTheme.TEXT_SECONDARY)
            .margin({ bottom: AppTheme.SPACING_SMALL })

          Text('去推荐页面挑选心仪的花束吧')
            .fontSize(AppTheme.FONT_SIZE_NORMAL)
            .fontColor(AppTheme.TEXT_SECONDARY)

          CommonButton({
            text: '去选花',
            type: CustomButtonType.PRIMARY,
            size: ButtonSize.LARGE,
            onClick: () => {
              router.back();
            }
          })
          .width('60%')
          .margin({ top: AppTheme.SPACING_XLARGE })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        // 购物车列表
        List({ space: AppTheme.SPACING_MEDIUM }) {
          ForEach(this.cartItems, (item: CartItem, index: number) => {
            ListItem() {
              this.CartItemCard(item, index)
            }
            .swipeAction({ end: this.DeleteButton(index) })
          }, (item: CartItem) => `${item.scheme.id}`)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({
          left: AppTheme.SPACING_MEDIUM,
          right: AppTheme.SPACING_MEDIUM,
          top: AppTheme.SPACING_SMALL
        })
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.Spring)

        // 底部结算区
        Row() {
          Column() {
            Text('合计')
              .fontSize(AppTheme.FONT_SIZE_SMALL)
              .fontColor(AppTheme.TEXT_SECONDARY)

            Text(`¥${CartStore.getTotalPrice()}`)
              .fontSize(AppTheme.FONT_SIZE_XLARGE)
              .fontColor(AppTheme.ACCENT_COLOR)
              .fontWeight(FontWeight.Bold)
          }
          .alignItems(HorizontalAlign.Start)

          CommonButton({
            text: `去结算(${this.cartItems.length})`,
            type: CustomButtonType.PRIMARY,
            size: ButtonSize.LARGE,
            onClick: () => this.goToCheckout()
          })
          .width('45%')
        }
        .width('100%')
        .padding({ left: AppTheme.SPACING_MEDIUM, right: AppTheme.SPACING_MEDIUM, top: AppTheme.SPACING_SMALL, bottom: AppTheme.SPACING_MEDIUM })
        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(VerticalAlign.Center)
        .backgroundColor(AppTheme.CARD_BACKGROUND)
        .shadow({ radius: 8, color: '#1A000000', offsetY: -2 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppTheme.BACKGROUND_COLOR)
  }

  // 删除按钮（左滑显示）
  @Builder
  DeleteButton(index: number) {
    Button('删除')
      .width(80)
      .height('100%')
      .fontSize(AppTheme.FONT_SIZE_NORMAL)
      .fontColor('#FFFFFF')
      .backgroundColor(AppTheme.ERROR_COLOR)
      .borderRadius(0)
      .onClick(() => {
        this.removeItem(index);
      })
  }

  // 购物车项卡片
  @Builder
  CartItemCard(item: CartItem, index: number) {
    Column() {
      Row() {
        // 左侧花束图标
        Column() {
          Text('💐')
            .fontSize(36)
        }
        .width(70)
        .height(70)
        .backgroundColor(AppTheme.PRIMARY_COLOR_ALPHA20)
        .borderRadius(AppTheme.BORDER_RADIUS_MEDIUM)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .margin({ right: AppTheme.SPACING_MEDIUM })

        // 右侧信息
        Column() {
          // 方案名称
          Text(item.scheme.name)
            .fontSize(AppTheme.FONT_SIZE_MEDIUM)
            .fontColor(AppTheme.TEXT_PRIMARY)
            .fontWeight(FontWeight.Bold)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          // 花材简述
          Text(item.scheme.flowers.map(f => f.flowerName).join('、'))
            .fontSize(AppTheme.FONT_SIZE_SMALL)
            .fontColor(AppTheme.TEXT_SECONDARY)
            .margin({ top: 4 })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          // 价格行 + 数量调整
          Row() {
            Text(`¥${item.scheme.totalPrice}`)
              .fontSize(AppTheme.FONT_SIZE_LARGE)
              .fontColor(AppTheme.ACCENT_COLOR)
              .fontWeight(FontWeight.Bold)

            // 数量调整
            Row() {
              // 减号按钮
              Text('-')
                .fontSize(AppTheme.FONT_SIZE_MEDIUM)
                .fontColor(item.quantity <= 1 ? AppTheme.DISABLED_COLOR : AppTheme.TEXT_PRIMARY)
                .width(28)
                .height(28)
                .textAlign(TextAlign.Center)
                .borderRadius(AppTheme.BORDER_RADIUS_SMALL)
                .backgroundColor('#F5F5F5')
                .onClick(() => this.decreaseQuantity(index))

              // 数量
              Text(`${item.quantity}`)
                .fontSize(AppTheme.FONT_SIZE_NORMAL)
                .fontColor(AppTheme.TEXT_PRIMARY)
                .width(36)
                .textAlign(TextAlign.Center)

              // 加号按钮
              Text('+')
                .fontSize(AppTheme.FONT_SIZE_MEDIUM)
                .fontColor(AppTheme.TEXT_PRIMARY)
                .width(28)
                .height(28)
                .textAlign(TextAlign.Center)
                .borderRadius(AppTheme.BORDER_RADIUS_SMALL)
                .backgroundColor('#F5F5F5')
                .onClick(() => this.increaseQuantity(index))
            }
            .margin({ left: 'auto' })
          }
          .width('100%')
          .margin({ top: AppTheme.SPACING_SMALL })
          .alignItems(VerticalAlign.Center)
        }
        .layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
    }
    .width('100%')
    .padding(AppTheme.SPACING_MEDIUM)
    .backgroundColor(AppTheme.CARD_BACKGROUND)
    .borderRadius(AppTheme.BORDER_RADIUS_MEDIUM)
  }
}
