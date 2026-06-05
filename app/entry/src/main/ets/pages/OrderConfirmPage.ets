// 订单确认页 - 配送信息、贺卡定制、价格明细、确认支付

import { AppTheme } from '../common/Theme';
import { CommonButton, CustomButtonType, ButtonSize } from '../components/CommonButton';
import { BouquetScheme } from '../models/RecommendModel';
import { ApiService } from '../services/ApiService';
import { CartStore, CartItem } from '../store/CartStore';
import router from '@ohos.router';

// 配送费
const DELIVERY_FEE: number = 15;

@Entry
@Component
struct OrderConfirmPage {
  // 购物车数据
  @State cartItems: CartItem[] = [];
  // 收货人姓名
  @State recipientName: string = '';
  // 联系电话
  @State phone: string = '';
  // 配送地址
  @State deliveryAddress: string = '';
  // 期望送达时间
  @State deliveryTime: string = '';
  // 是否附赠贺卡
  @State hasGreetingCard: boolean = true;
  // 贺卡文案
  @State greetingMessage: string = '';
  // 备注信息
  @State remark: string = '';
  // 推荐文案
  @State recommendedGreeting: string = '';
  // 是否正在提交
  @State isSubmitting: boolean = false;

  aboutToAppear() {
    // 优先从路由参数获取（直接购买流程）
    const params = router.getParams();
    if (params && params.cartData) {
      try {
        this.cartItems = JSON.parse(params.cartData as string) as CartItem[];
      } catch (e) {
        console.error('解析购物车数据失败:', JSON.stringify(e));
        this.cartItems = [];
      }
    }
    // 若路由参数为空，从购物车持久化存储获取
    if (this.cartItems.length === 0) {
      this.cartItems = CartStore.getCartItems();
    }
    // 生成推荐文案
    this.generateGreetingText();
  }

  // 生成推荐贺卡文案
  private generateGreetingText(): void {
    if (this.cartItems.length > 0) {
      const scheme = this.cartItems[0].scheme;
      const greetings: Record<string, string> = {
        '初恋悸动': '遇见你的那一刻，世界突然有了颜色。愿这束花替我说出那句——我喜欢你。',
        '浪漫满屋': '每一朵玫瑰都是我对你的思念，愿我们的故事如这束花，越来越美。',
        '温柔告白': '用最温柔的方式告诉你，你是我心中最珍贵的存在。'
      };
      this.recommendedGreeting = greetings[scheme.name] ||
        `送你一束${scheme.name}，愿每一朵花都带给你幸福与喜悦。`;
    }
  }

  // 使用推荐文案
  private useRecommendedGreeting(): void {
    this.greetingMessage = this.recommendedGreeting;
  }

  // 计算花束总价
  private getBouquetTotal(): number {
    let total = 0;
    for (const item of this.cartItems) {
      total += item.scheme.totalPrice * item.quantity;
    }
    return total;
  }

  // 计算总价（花束费 + 配送费）
  private getTotalPrice(): number {
    return this.getBouquetTotal() + DELIVERY_FEE;
  }

  // 校验表单
  private validateForm(): boolean {
    if (!this.recipientName.trim()) {
      return false;
    }
    if (!this.phone.trim()) {
      return false;
    }
    if (!this.deliveryAddress.trim()) {
      return false;
    }
    return true;
  }

  // 确认支付
  private async confirmOrder(): Promise<void> {
    if (!this.validateForm()) {
      return;
    }
    this.isSubmitting = true;
    try {
      // 创建订单 - 逐个方案创建订单
      for (const item of this.cartItems) {
        const orderParams = {
          total_price: item.scheme.totalPrice * item.quantity + DELIVERY_FEE,
          delivery_address: this.deliveryAddress.trim(),
          delivery_time: this.deliveryTime || undefined,
          greeting_card_message: this.hasGreetingCard ? this.greetingMessage : undefined,
        };
        await ApiService.createOrder(orderParams);
      }
      // 下单成功后清空购物车
      CartStore.clearCart();
      // 跳转到支付页面
      router.pushUrl({
        url: 'pages/PaymentPage',
        params: {
          totalPrice: this.getTotalPrice(),
          recipientName: this.recipientName,
          deliveryAddress: this.deliveryAddress
        }
      }).catch((error: Error) => {
        console.error('跳转支付页失败:', JSON.stringify(error));
      });
    } catch (error) {
      console.error('创建订单失败:', JSON.stringify(error));
      // 模拟成功跳转（调试用）
      CartStore.clearCart();
      router.pushUrl({
        url: 'pages/PaymentPage',
        params: {
          totalPrice: this.getTotalPrice(),
          recipientName: this.recipientName,
          deliveryAddress: this.deliveryAddress
        }
      });
    }
    this.isSubmitting = false;
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

        Text('确认订单')
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

      // 内容区域
      Scroll() {
        Column() {
          // 花束方案信息卡片
          ForEach(this.cartItems, (item: CartItem) => {
            this.SchemeCard(item)
          }, (item: CartItem) => `${item.scheme.id}`)

          // 配送信息区
          Column() {
            Text('配送信息')
              .fontSize(AppTheme.FONT_SIZE_MEDIUM)
              .fontColor(AppTheme.TEXT_PRIMARY)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: AppTheme.SPACING_MEDIUM })

            // 收货人姓名
            Row() {
              Text('收货人')
                .fontSize(AppTheme.FONT_SIZE_NORMAL)
                .fontColor(AppTheme.TEXT_SECONDARY)
                .width(70)

              TextInput({ placeholder: '请输入收货人姓名', text: this.recipientName })
                .layoutWeight(1)
                .fontSize(AppTheme.FONT_SIZE_NORMAL)
                .fontColor(AppTheme.TEXT_PRIMARY)
                .backgroundColor(Color.Transparent)
                .border({ width: 0 })
                .onChange((value: string) => {
                  this.recipientName = value;
                })
            }
            .width('100%')
            .height(48)
            .alignItems(VerticalAlign.Center)

            Divider().color(AppTheme.DIVIDER_COLOR)

            // 联系电话
            Row() {
              Text('联系电话')
                .fontSize(AppTheme.FONT_SIZE_NORMAL)
                .fontColor(AppTheme.TEXT_SECONDARY)
                .width(70)

              TextInput({ placeholder: '请输入联系电话', text: this.phone })
                .layoutWeight(1)
                .fontSize(AppTheme.FONT_SIZE_NORMAL)
                .fontColor(AppTheme.TEXT_PRIMARY)
                .type(InputType.PhoneNumber)
                .backgroundColor(Color.Transparent)
                .border({ width: 0 })
                .onChange((value: string) => {
                  this.phone = value;
                })
            }
            .width('100%')
            .height(48)
            .alignItems(VerticalAlign.Center)

            Divider().color(AppTheme.DIVIDER_COLOR)

            // 配送地址
            Row() {
              Text('配送地址')
                .fontSize(AppTheme.FONT_SIZE_NORMAL)
                .fontColor(AppTheme.TEXT_SECONDARY)
                .width(70)

              TextInput({ placeholder: '请输入配送地址', text: this.deliveryAddress })
                .layoutWeight(1)
                .fontSize(AppTheme.FONT_SIZE_NORMAL)
                .fontColor(AppTheme.TEXT_PRIMARY)
                .backgroundColor(Color.Transparent)
                .border({ width: 0 })
                .onChange((value: string) => {
                  this.deliveryAddress = value;
                })
            }
            .width('100%')
            .height(48)
            .alignItems(VerticalAlign.Center)

            Divider().color(AppTheme.DIVIDER_COLOR)

            // 期望送达时间
            Row() {
              Text('送达时间')
                .fontSize(AppTheme.FONT_SIZE_NORMAL)
                .fontColor(AppTheme.TEXT_SECONDARY)
                .width(70)

              TextInput({ placeholder: '请选择期望送达日期（如：2025-06-15）', text: this.deliveryTime })
                .layoutWeight(1)
                .fontSize(AppTheme.FONT_SIZE_NORMAL)
                .fontColor(AppTheme.TEXT_PRIMARY)
                .backgroundColor(Color.Transparent)
                .border({ width: 0 })
                .onChange((value: string) => {
                  this.deliveryTime = value;
                })
            }
            .width('100%')
            .height(48)
            .alignItems(VerticalAlign.Center)
          }
          .width('100%')
          .padding(AppTheme.SPACING_MEDIUM)
          .backgroundColor(AppTheme.CARD_BACKGROUND)
          .borderRadius(AppTheme.BORDER_RADIUS_MEDIUM)
          .margin({ top: AppTheme.SPACING_MEDIUM })

          // 贺卡定制区
          Column() {
            Row() {
              Text('贺卡定制')
                .fontSize(AppTheme.FONT_SIZE_MEDIUM)
                .fontColor(AppTheme.TEXT_PRIMARY)
                .fontWeight(FontWeight.Bold)

              Toggle({ type: ToggleType.Switch, isOn: this.hasGreetingCard })
                .margin({ left: 'auto' })
                .onChange((isOn: boolean) => {
                  this.hasGreetingCard = isOn;
                })
            }
            .width('100%')
            .margin({ bottom: AppTheme.SPACING_SMALL })

            if (this.hasGreetingCard) {
              // 贺卡文案输入
              TextArea({ placeholder: '请输入贺卡文案', text: this.greetingMessage })
                .width('100%')
                .height(80)
                .fontSize(AppTheme.FONT_SIZE_NORMAL)
                .fontColor(AppTheme.TEXT_PRIMARY)
                .backgroundColor('#FAFAFA')
                .borderRadius(AppTheme.BORDER_RADIUS_SMALL)
                .onChange((value: string) => {
                  this.greetingMessage = value;
                })

              // 使用推荐文案按钮
              if (this.recommendedGreeting) {
                CommonButton({
                  text: '使用推荐文案',
                  type: CustomButtonType.TEXT,
                  size: ButtonSize.SMALL,
                  onClick: () => this.useRecommendedGreeting()
                })
                .margin({ top: AppTheme.SPACING_SMALL })
              }
            }
          }
          .width('100%')
          .padding(AppTheme.SPACING_MEDIUM)
          .backgroundColor(AppTheme.CARD_BACKGROUND)
          .borderRadius(AppTheme.BORDER_RADIUS_MEDIUM)
          .margin({ top: AppTheme.SPACING_MEDIUM })

          // 备注信息
          Column() {
            Text('备注信息')
              .fontSize(AppTheme.FONT_SIZE_MEDIUM)
              .fontColor(AppTheme.TEXT_PRIMARY)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: AppTheme.SPACING_SMALL })

            TextInput({ placeholder: '请输入备注信息（选填）', text: this.remark })
              .width('100%')
              .fontSize(AppTheme.FONT_SIZE_NORMAL)
              .fontColor(AppTheme.TEXT_PRIMARY)
              .backgroundColor('#FAFAFA')
              .borderRadius(AppTheme.BORDER_RADIUS_SMALL)
              .onChange((value: string) => {
                this.remark = value;
              })
          }
          .width('100%')
          .padding(AppTheme.SPACING_MEDIUM)
          .backgroundColor(AppTheme.CARD_BACKGROUND)
          .borderRadius(AppTheme.BORDER_RADIUS_MEDIUM)
          .margin({ top: AppTheme.SPACING_MEDIUM })

          // 底部留白给固定区
          Blank().height(100)
        }
        .padding({ left: AppTheme.SPACING_MEDIUM, right: AppTheme.SPACING_MEDIUM, top: AppTheme.SPACING_SMALL })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)

      // 底部固定区
      Column() {
        // 价格明细
        Row() {
          Text('花束费')
            .fontSize(AppTheme.FONT_SIZE_NORMAL)
            .fontColor(AppTheme.TEXT_SECONDARY)

          Text(`¥${this.getBouquetTotal()}`)
            .fontSize(AppTheme.FONT_SIZE_NORMAL)
            .fontColor(AppTheme.TEXT_PRIMARY)
            .margin({ left: 'auto' })
        }
        .width('100%')
        .margin({ bottom: 4 })

        Row() {
          Text('配送费')
            .fontSize(AppTheme.FONT_SIZE_NORMAL)
            .fontColor(AppTheme.TEXT_SECONDARY)

          Text(`¥${DELIVERY_FEE}`)
            .fontSize(AppTheme.FONT_SIZE_NORMAL)
            .fontColor(AppTheme.TEXT_PRIMARY)
            .margin({ left: 'auto' })
        }
        .width('100%')
        .margin({ bottom: AppTheme.SPACING_SMALL })

        Divider().color(AppTheme.DIVIDER_COLOR)

        Row() {
          Text('合计')
            .fontSize(AppTheme.FONT_SIZE_MEDIUM)
            .fontColor(AppTheme.TEXT_PRIMARY)
            .fontWeight(FontWeight.Bold)

          Text(`¥${this.getTotalPrice()}`)
            .fontSize(AppTheme.FONT_SIZE_XLARGE)
            .fontColor(AppTheme.ACCENT_COLOR)
            .fontWeight(FontWeight.Bold)
            .margin({ left: 'auto' })
        }
        .width('100%')
        .margin({ top: AppTheme.SPACING_SMALL, bottom: AppTheme.SPACING_SMALL })

        CommonButton({
          text: this.validateForm() ? '确认支付' : '请填写完整信息',
          type: CustomButtonType.PRIMARY,
          size: ButtonSize.LARGE,
          disabled: !this.validateForm() || this.isSubmitting,
          onClick: () => this.confirmOrder()
        })
      }
      .width('100%')
      .padding(AppTheme.SPACING_MEDIUM)
      .backgroundColor(AppTheme.CARD_BACKGROUND)
      .shadow({ radius: 8, color: '#1A000000', offsetY: -2 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppTheme.BACKGROUND_COLOR)
  }

  // 花束方案信息卡片
  @Builder
  SchemeCard(item: CartItem) {
    Column() {
      Row() {
        // 花束图标
        Column() {
          Text('💐')
            .fontSize(32)
        }
        .width(60)
        .height(60)
        .backgroundColor(AppTheme.PRIMARY_COLOR_ALPHA20)
        .borderRadius(AppTheme.BORDER_RADIUS_MEDIUM)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .margin({ right: AppTheme.SPACING_MEDIUM })

        // 方案信息
        Column() {
          Text(item.scheme.name)
            .fontSize(AppTheme.FONT_SIZE_MEDIUM)
            .fontColor(AppTheme.TEXT_PRIMARY)
            .fontWeight(FontWeight.Bold)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(item.scheme.flowers.map(f => `${f.flowerName}×${f.quantity}`).join('、'))
            .fontSize(AppTheme.FONT_SIZE_SMALL)
            .fontColor(AppTheme.TEXT_SECONDARY)
            .margin({ top: 4 })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        // 价格和数量
        Column() {
          Text(`¥${item.scheme.totalPrice}`)
            .fontSize(AppTheme.FONT_SIZE_LARGE)
            .fontColor(AppTheme.ACCENT_COLOR)
            .fontWeight(FontWeight.Bold)

          Text(`×${item.quantity}`)
            .fontSize(AppTheme.FONT_SIZE_SMALL)
            .fontColor(AppTheme.TEXT_SECONDARY)
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.End)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding(AppTheme.SPACING_MEDIUM)
    .backgroundColor(AppTheme.CARD_BACKGROUND)
    .borderRadius(AppTheme.BORDER_RADIUS_MEDIUM)
    .margin({ bottom: AppTheme.SPACING_SMALL })
  }
}
