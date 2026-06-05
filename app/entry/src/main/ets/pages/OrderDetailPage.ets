// 订单详情页 - 订单信息展示、状态跟踪、操作按钮

import { AppTheme } from '../common/Theme';
import { CommonButton, CustomButtonType, ButtonSize } from '../components/CommonButton';
import { OrderInfo } from '../models/RecommendModel';
import { ApiService } from '../services/ApiService';
import { ORDER_STATUS_MAP } from '../utils/Constants';
import router from '@ohos.router';

@Entry
@Component
struct OrderDetailPage {
  // 订单ID
  @State orderId: string = '';
  // 订单信息
  @State order: OrderInfo | null = null;
  // 是否正在加载
  @State isLoading: boolean = true;
  // 操作提示
  @State actionTip: string = '';

  aboutToAppear() {
    const params = router.getParams();
    if (params && params.orderId) {
      this.orderId = params.orderId as string;
    }
    this.loadOrderDetail();
  }

  // 加载订单详情
  private async loadOrderDetail(): Promise<void> {
    this.isLoading = true;
    try {
      const result = await ApiService.getOrderDetail(this.orderId);
      this.order = result as unknown as OrderInfo;
    } catch (error) {
      console.error('加载订单详情失败:', JSON.stringify(error));
      this.order = this.getMockOrder();
    }
    this.isLoading = false;
  }

  // 模拟订单数据
  private getMockOrder(): OrderInfo {
    return {
      id: this.orderId || '1',
      user_id: 'u1',
      recommendation_id: null,
      status: 'pending',
      total_price: 123,
      delivery_address: '北京市朝阳区xxx路1号',
      delivery_time: '2025-06-15',
      greeting_card_message: '生日快乐！愿这束花带给你一整天的好心情。',
      created_at: '2025-06-01T10:00:00Z',
      updated_at: '2025-06-01T10:00:00Z'
    };
  }

  // 获取状态显示文本
  private getStatusLabel(status: string): string {
    return ORDER_STATUS_MAP[status] || status;
  }

  // 获取状态标签颜色
  private getStatusColor(status: string): string {
    const map: Record<string, string> = {
      'pending': '#FF9800',
      'confirmed': '#2196F3',
      'paid': '#2196F3',
      'preparing': '#9C27B0',
      'delivering': '#4CAF50',
      'completed': AppTheme.TEXT_SECONDARY,
      'cancelled': AppTheme.ERROR_COLOR
    };
    return map[status] || AppTheme.TEXT_SECONDARY;
  }

  // 获取状态图标
  private getStatusIcon(status: string): string {
    const map: Record<string, string> = {
      'pending': '⏳',
      'confirmed': '✅',
      'paid': '💳',
      'preparing': '💐',
      'delivering': '🚚',
      'completed': '🎉',
      'cancelled': '❌'
    };
    return map[status] || '📋';
  }

  // 格式化时间
  private formatTime(timeStr: string | null): string {
    if (!timeStr) return '暂无';
    try {
      const date = new Date(timeStr);
      const year = date.getFullYear();
      const month = String(date.getMonth() + 1).padStart(2, '0');
      const day = String(date.getDate()).padStart(2, '0');
      const hour = String(date.getHours()).padStart(2, '0');
      const minute = String(date.getMinutes()).padStart(2, '0');
      return `${year}-${month}-${day} ${hour}:${minute}`;
    } catch (e) {
      return timeStr;
    }
  }

  // 取消订单
  private async cancelOrder(): Promise<void> {
    if (!this.order) return;
    try {
      await ApiService.cancelOrder(this.order.id);
      this.actionTip = '订单已取消';
      this.loadOrderDetail();
    } catch (error) {
      console.error('取消订单失败:', JSON.stringify(error));
      this.actionTip = '取消订单失败，请稍后重试';
    }
    setTimeout(() => { this.actionTip = ''; }, 2000);
  }

  // 状态步骤列表
  private getStatusSteps(): string[] {
    return ['待确认', '已确认', '制作中', '配送中', '已完成'];
  }

  // 获取当前状态步骤索引
  private getCurrentStepIndex(status: string): number {
    const stepMap: Record<string, number> = {
      'pending': 0,
      'confirmed': 1,
      'paid': 1,
      'preparing': 2,
      'delivering': 3,
      'completed': 4,
      'cancelled': -1
    };
    return stepMap[status] ?? -1;
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

        Text('订单详情')
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

      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
            .color(AppTheme.PRIMARY_COLOR)
            .margin({ bottom: AppTheme.SPACING_MEDIUM })

          Text('加载中...')
            .fontSize(AppTheme.FONT_SIZE_NORMAL)
            .fontColor(AppTheme.TEXT_SECONDARY)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.order) {
        Scroll() {
          Column() {
            // 订单状态头部
            Column() {
              Text(this.getStatusIcon(this.order.status))
                .fontSize(48)
                .margin({ bottom: AppTheme.SPACING_SMALL })

              Text(this.getStatusLabel(this.order.status))
                .fontSize(AppTheme.FONT_SIZE_XLARGE)
                .fontColor(this.getStatusColor(this.order.status))
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: AppTheme.SPACING_SMALL })

              Text(`订单号：${this.order.id}`)
                .fontSize(AppTheme.FONT_SIZE_SMALL)
                .fontColor(AppTheme.TEXT_SECONDARY)
            }
            .width('100%')
            .padding({ top: AppTheme.SPACING_LARGE, bottom: AppTheme.SPACING_LARGE })
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)

            // 状态进度条
            if (this.order.status !== 'cancelled') {
              Column() {
                Text('订单进度')
                  .fontSize(AppTheme.FONT_SIZE_MEDIUM)
                  .fontColor(AppTheme.TEXT_PRIMARY)
                  .fontWeight(FontWeight.Bold)
                  .margin({ bottom: AppTheme.SPACING_MEDIUM })
                  .alignSelf(ItemAlign.Start)

                Row() {
                  ForEach(this.getStatusSteps(), (step: string, index: number) => {
                    Column() {
                      // 圆点
                      Circle()
                        .width(24)
                        .height(24)
                        .fill(index <= this.getCurrentStepIndex(this.order!.status)
                          ? AppTheme.PRIMARY_COLOR : AppTheme.DIVIDER_COLOR)

                      // 步骤名
                      Text(step)
                        .fontSize(10)
                        .fontColor(index <= this.getCurrentStepIndex(this.order!.status)
                          ? AppTheme.PRIMARY_COLOR : AppTheme.TEXT_SECONDARY)
                        .margin({ top: 4 })
                        .textAlign(TextAlign.Center)
                    }
                    .layoutWeight(1)
                    .alignItems(HorizontalAlign.Center)
                  }, (step: string) => step)
                }
                .width('100%')
              }
              .width('100%')
              .padding(AppTheme.SPACING_MEDIUM)
              .backgroundColor(AppTheme.CARD_BACKGROUND)
              .borderRadius(AppTheme.BORDER_RADIUS_MEDIUM)
              .margin({ bottom: AppTheme.SPACING_MEDIUM })
            }

            // 花束信息卡片
            Column() {
              Text('花束信息')
                .fontSize(AppTheme.FONT_SIZE_MEDIUM)
                .fontColor(AppTheme.TEXT_PRIMARY)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: AppTheme.SPACING_MEDIUM })

              Row() {
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

                Column() {
                  Text('花束方案')
                    .fontSize(AppTheme.FONT_SIZE_MEDIUM)
                    .fontColor(AppTheme.TEXT_PRIMARY)
                    .fontWeight(FontWeight.Medium)

                  Text(`下单时间：${this.formatTime(this.order.created_at)}`)
                    .fontSize(AppTheme.FONT_SIZE_SMALL)
                    .fontColor(AppTheme.TEXT_SECONDARY)
                    .margin({ top: 4 })
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)

                Text(`¥${this.order.total_price}`)
                  .fontSize(AppTheme.FONT_SIZE_LARGE)
                  .fontColor(AppTheme.ACCENT_COLOR)
                  .fontWeight(FontWeight.Bold)
              }
              .width('100%')
              .alignItems(VerticalAlign.Center)
            }
            .width('100%')
            .padding(AppTheme.SPACING_MEDIUM)
            .backgroundColor(AppTheme.CARD_BACKGROUND)
            .borderRadius(AppTheme.BORDER_RADIUS_MEDIUM)
            .margin({ bottom: AppTheme.SPACING_MEDIUM })

            // 配送信息
            Column() {
              Text('配送信息')
                .fontSize(AppTheme.FONT_SIZE_MEDIUM)
                .fontColor(AppTheme.TEXT_PRIMARY)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: AppTheme.SPACING_MEDIUM })

              this.InfoRow('配送地址', this.order.delivery_address || '暂无')
              Divider().color(AppTheme.DIVIDER_COLOR).margin({ top: 8, bottom: 8 })
              this.InfoRow('期望送达', this.order.delivery_time || '尽快送达')
              Divider().color(AppTheme.DIVIDER_COLOR).margin({ top: 8, bottom: 8 })
              this.InfoRow('更新时间', this.formatTime(this.order.updated_at))
            }
            .width('100%')
            .padding(AppTheme.SPACING_MEDIUM)
            .backgroundColor(AppTheme.CARD_BACKGROUND)
            .borderRadius(AppTheme.BORDER_RADIUS_MEDIUM)
            .margin({ bottom: AppTheme.SPACING_MEDIUM })

            // 贺卡信息
            if (this.order.greeting_card_message) {
              Column() {
                Text('贺卡文案')
                  .fontSize(AppTheme.FONT_SIZE_MEDIUM)
                  .fontColor(AppTheme.TEXT_PRIMARY)
                  .fontWeight(FontWeight.Bold)
                  .margin({ bottom: AppTheme.SPACING_SMALL })

                Text(this.order.greeting_card_message)
                  .fontSize(AppTheme.FONT_SIZE_NORMAL)
                  .fontColor(AppTheme.TEXT_PRIMARY)
                  .lineHeight(22)
              }
              .width('100%')
              .padding(AppTheme.SPACING_MEDIUM)
              .backgroundColor(AppTheme.PRIMARY_COLOR_ALPHA20)
              .borderRadius(AppTheme.BORDER_RADIUS_MEDIUM)
              .margin({ bottom: AppTheme.SPACING_MEDIUM })
            }

            // 操作提示
            if (this.actionTip) {
              Text(this.actionTip)
                .fontSize(AppTheme.FONT_SIZE_NORMAL)
                .fontColor(AppTheme.SUCCESS_COLOR)
                .textAlign(TextAlign.Center)
                .margin({ top: AppTheme.SPACING_SMALL })
            }

            // 底部留白
            Blank().height(80)
          }
          .padding(AppTheme.SPACING_MEDIUM)
        }
        .layoutWeight(1)
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.Spring)

        // 底部操作按钮
        if (this.order.status === 'pending') {
          Row() {
            CommonButton({
              text: '取消订单',
              type: CustomButtonType.OUTLINE,
              size: ButtonSize.LARGE,
              onClick: () => this.cancelOrder()
            })
            .width('45%')

            CommonButton({
              text: '去支付',
              type: CustomButtonType.PRIMARY,
              size: ButtonSize.LARGE,
              onClick: () => {
                router.pushUrl({
                  url: 'pages/PaymentPage',
                  params: {
                    totalPrice: this.order!.total_price,
                    orderId: this.order!.id
                  }
                }).catch((error: Error) => {
                  console.error('跳转支付页失败:', JSON.stringify(error));
                });
              }
            })
            .width('45%')
          }
          .width('100%')
          .padding({ left: AppTheme.SPACING_MEDIUM, right: AppTheme.SPACING_MEDIUM, top: AppTheme.SPACING_SMALL, bottom: AppTheme.SPACING_MEDIUM })
          .justifyContent(FlexAlign.SpaceBetween)
          .backgroundColor(AppTheme.CARD_BACKGROUND)
          .shadow({ radius: 8, color: '#1A000000', offsetY: -2 })
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppTheme.BACKGROUND_COLOR)
  }

  // 信息行构建器
  @Builder
  InfoRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(AppTheme.FONT_SIZE_NORMAL)
        .fontColor(AppTheme.TEXT_SECONDARY)
        .width(70)

      Text(value)
        .fontSize(AppTheme.FONT_SIZE_NORMAL)
        .fontColor(AppTheme.TEXT_PRIMARY)
        .layoutWeight(1)
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }
}
