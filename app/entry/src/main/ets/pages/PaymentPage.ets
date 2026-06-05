// 支付页面 - 模拟支付流程（选择支付方式、模拟延时、支付成功动画）

import { AppTheme } from '../common/Theme';
import { CommonButton, CustomButtonType, ButtonSize } from '../components/CommonButton';
import { ApiService } from '../services/ApiService';
import router from '@ohos.router';

// 支付方式
interface PaymentMethod {
  name: string;
  icon: string;
  value: string;
}

@Entry
@Component
struct PaymentPage {
  // 订单金额
  @State totalPrice: number = 0;
  // 收货人
  @State recipientName: string = '';
  // 配送地址
  @State deliveryAddress: string = '';
  // 选中的支付方式
  @State selectedPayment: string = 'alipay';
  // 是否正在支付
  @State isPaying: boolean = false;
  // 是否支付成功
  @State isPaymentSuccess: boolean = false;
  // 订单ID（支付成功后获取）
  @State orderId: string = '';

  // 支付方式列表
  private paymentMethods: PaymentMethod[] = [
    { name: '支付宝', icon: '🔵', value: 'alipay' },
    { name: '微信支付', icon: '🟢', value: 'wechat' },
    { name: '银行卡', icon: '🏦', value: 'bankcard' }
  ];

  aboutToAppear() {
    const params = router.getParams();
    if (params) {
      this.totalPrice = params.totalPrice as number || 0;
      this.recipientName = params.recipientName as string || '';
      this.deliveryAddress = params.deliveryAddress as string || '';
      this.orderId = params.orderId as string || '';
    }
  }

  // 确认支付（模拟延时2秒）
  private async confirmPayment(): Promise<void> {
    this.isPaying = true;
    try {
      // 如果有订单ID，更新状态为已支付
      if (this.orderId) {
        await ApiService.updateOrderStatus(this.orderId, 'paid');
      }
    } catch (error) {
      console.error('更新订单状态失败:', JSON.stringify(error));
    }
    // 模拟支付延时2秒
    setTimeout(() => {
      this.isPaying = false;
      this.isPaymentSuccess = true;
      // 1.5秒后跳转到订单详情页
      setTimeout(() => {
        router.replaceUrl({
          url: 'pages/OrderListPage'
        }).catch((error: Error) => {
          console.error('跳转订单列表页失败:', JSON.stringify(error));
        });
      }, 1500);
    }, 2000);
  }

  build() {
    Column() {
      // 顶部标题栏
      Row() {
        if (!this.isPaymentSuccess) {
          Text('<')
            .fontSize(AppTheme.FONT_SIZE_LARGE)
            .fontColor(AppTheme.TEXT_PRIMARY)
            .fontWeight(FontWeight.Bold)
            .padding(AppTheme.SPACING_SMALL)
            .onClick(() => {
              router.back();
            })
        }

        Text(this.isPaymentSuccess ? '支付结果' : '收银台')
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

      if (this.isPaymentSuccess) {
        // 支付成功状态
        Column() {
          // 成功图标
          Column() {
            Text('✓')
              .fontSize(48)
              .fontColor('#FFFFFF')
              .fontWeight(FontWeight.Bold)
          }
          .width(80)
          .height(80)
          .borderRadius(AppTheme.BORDER_RADIUS_CIRCLE)
          .backgroundColor(AppTheme.SUCCESS_COLOR)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .margin({ bottom: AppTheme.SPACING_LARGE })

          Text('支付成功')
            .fontSize(AppTheme.FONT_SIZE_XLARGE)
            .fontColor(AppTheme.TEXT_PRIMARY)
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: AppTheme.SPACING_SMALL })

          Text(`¥${this.totalPrice}`)
            .fontSize(AppTheme.FONT_SIZE_TITLE)
            .fontColor(AppTheme.ACCENT_COLOR)
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: AppTheme.SPACING_MEDIUM })

          Text('正在为您跳转到订单列表...')
            .fontSize(AppTheme.FONT_SIZE_NORMAL)
            .fontColor(AppTheme.TEXT_SECONDARY)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.isPaying) {
        // 支付中状态
        Column() {
          // Loading动画
          LoadingProgress()
            .width(60)
            .height(60)
            .color(AppTheme.PRIMARY_COLOR)
            .margin({ bottom: AppTheme.SPACING_LARGE })

          Text('支付处理中...')
            .fontSize(AppTheme.FONT_SIZE_MEDIUM)
            .fontColor(AppTheme.TEXT_PRIMARY)
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: AppTheme.SPACING_SMALL })

          Text('请勿关闭页面')
            .fontSize(AppTheme.FONT_SIZE_NORMAL)
            .fontColor(AppTheme.TEXT_SECONDARY)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        // 正常支付界面
        Scroll() {
          Column() {
            // 金额展示
            Column() {
              Text('支付金额')
                .fontSize(AppTheme.FONT_SIZE_NORMAL)
                .fontColor(AppTheme.TEXT_SECONDARY)
                .margin({ bottom: AppTheme.SPACING_SMALL })

              Text(`¥${this.totalPrice}`)
                .fontSize(40)
                .fontColor(AppTheme.ACCENT_COLOR)
                .fontWeight(FontWeight.Bold)

              if (this.recipientName) {
                Text(`收货人：${this.recipientName}`)
                  .fontSize(AppTheme.FONT_SIZE_SMALL)
                  .fontColor(AppTheme.TEXT_SECONDARY)
                  .margin({ top: AppTheme.SPACING_SMALL })
              }
            }
            .width('100%')
            .padding({ top: AppTheme.SPACING_XLARGE, bottom: AppTheme.SPACING_XLARGE })
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)

            // 支付方式选择
            Column() {
              Text('选择支付方式')
                .fontSize(AppTheme.FONT_SIZE_MEDIUM)
                .fontColor(AppTheme.TEXT_PRIMARY)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: AppTheme.SPACING_MEDIUM })

              ForEach(this.paymentMethods, (method: PaymentMethod) => {
                Row() {
                  // 支付方式图标
                  Text(method.icon)
                    .fontSize(28)
                    .margin({ right: AppTheme.SPACING_MEDIUM })

                  // 支付方式名称
                  Text(method.name)
                    .fontSize(AppTheme.FONT_SIZE_NORMAL)
                    .fontColor(AppTheme.TEXT_PRIMARY)
                    .layoutWeight(1)

                  // 单选按钮
                  Radio({ value: method.value, group: 'payment' })
                    .checked(this.selectedPayment === method.value)
                    .onChange((isChecked: boolean) => {
                      if (isChecked) {
                        this.selectedPayment = method.value;
                      }
                    })
                }
                .width('100%')
                .height(56)
                .padding({ left: AppTheme.SPACING_MEDIUM, right: AppTheme.SPACING_MEDIUM })
                .alignItems(VerticalAlign.Center)
                .borderRadius(AppTheme.BORDER_RADIUS_MEDIUM)
                .backgroundColor(this.selectedPayment === method.value ? AppTheme.PRIMARY_COLOR_ALPHA20 : Color.Transparent)
                .onClick(() => {
                  this.selectedPayment = method.value;
                })
              }, (method: PaymentMethod) => method.value)
            }
            .width('100%')
            .padding(AppTheme.SPACING_MEDIUM)
            .backgroundColor(AppTheme.CARD_BACKGROUND)
            .borderRadius(AppTheme.BORDER_RADIUS_MEDIUM)
            .margin({ top: AppTheme.SPACING_MEDIUM })

            // 安全提示
            Row() {
              Text('🔒')
                .fontSize(16)
                .margin({ right: 6 })

              Text('支付环境安全，请放心支付')
                .fontSize(AppTheme.FONT_SIZE_SMALL)
                .fontColor(AppTheme.TEXT_SECONDARY)
            }
            .margin({ top: AppTheme.SPACING_MEDIUM })
            .justifyContent(FlexAlign.Center)
          }
          .padding({ left: AppTheme.SPACING_MEDIUM, right: AppTheme.SPACING_MEDIUM })
        }
        .layoutWeight(1)

        // 底部确认支付按钮
        Column() {
          CommonButton({
            text: `确认支付 ¥${this.totalPrice}`,
            type: CustomButtonType.PRIMARY,
            size: ButtonSize.LARGE,
            onClick: () => this.confirmPayment()
          })
        }
        .width('100%')
        .padding(AppTheme.SPACING_MEDIUM)
        .backgroundColor(AppTheme.CARD_BACKGROUND)
        .shadow({ radius: 8, color: '#1A000000', offsetY: -2 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppTheme.BACKGROUND_COLOR)
  }
}
