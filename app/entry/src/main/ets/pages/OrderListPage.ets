// 订单列表页 - Tab筛选、订单卡片列表、点击跳转详情

import { AppTheme } from '../common/Theme';
import { OrderInfo } from '../models/RecommendModel';
import { ApiService } from '../services/ApiService';
import router from '@ohos.router';

// Tab筛选项
interface TabItem {
  label: string;
  status: string; // '' 表示全部
}

@Entry
@Component
struct OrderListPage {
  // Tab列表
  private tabs: TabItem[] = [
    { label: '全部', status: '' },
    { label: '待支付', status: 'pending' },
    { label: '已支付', status: 'paid' },
    { label: '制作中', status: 'preparing' },
    { label: '配送中', status: 'delivering' },
    { label: '已完成', status: 'completed' }
  ];
  // 当前选中的Tab索引
  @State currentTabIndex: number = 0;
  // 订单列表
  @State orders: OrderInfo[] = [];
  // 是否正在加载
  @State isLoading: boolean = false;
  // 当前页码
  @State currentPage: number = 1;
  // 总页数
  @State totalPages: number = 1;

  aboutToAppear() {
    this.loadOrders();
  }

  // 加载订单列表
  private async loadOrders(): Promise<void> {
    this.isLoading = true;
    try {
      const status = this.tabs[this.currentTabIndex].status;
      const response = await ApiService.getOrders(this.currentPage, 10, status || undefined);
      this.orders = response.items;
      this.totalPages = response.pagination.totalPages;
    } catch (error) {
      console.error('加载订单列表失败:', JSON.stringify(error));
      // 使用模拟数据
      this.orders = this.getMockOrders();
    }
    this.isLoading = false;
  }

  // 模拟订单数据
  private getMockOrders(): OrderInfo[] {
    return [
      {
        id: '1',
        user_id: 'u1',
        recommendation_id: null,
        status: 'pending',
        total_price: 123,
        delivery_address: '北京市朝阳区xxx路1号',
        delivery_time: '2025-06-15',
        greeting_card_message: '生日快乐！',
        created_at: '2025-06-01T10:00:00Z',
        updated_at: '2025-06-01T10:00:00Z'
      },
      {
        id: '2',
        user_id: 'u1',
        recommendation_id: null,
        status: 'paid',
        total_price: 88,
        delivery_address: '上海市浦东新区xxx路2号',
        delivery_time: '2025-06-10',
        greeting_card_message: null,
        created_at: '2025-05-28T14:30:00Z',
        updated_at: '2025-05-28T15:00:00Z'
      },
      {
        id: '3',
        user_id: 'u1',
        recommendation_id: null,
        status: 'delivering',
        total_price: 256,
        delivery_address: '广州市天河区xxx路3号',
        delivery_time: null,
        greeting_card_message: '永远爱你',
        created_at: '2025-05-20T09:00:00Z',
        updated_at: '2025-05-22T08:00:00Z'
      },
      {
        id: '4',
        user_id: 'u1',
        recommendation_id: null,
        status: 'completed',
        total_price: 168,
        delivery_address: '深圳市南山区xxx路4号',
        delivery_time: null,
        greeting_card_message: null,
        created_at: '2025-05-10T11:00:00Z',
        updated_at: '2025-05-12T16:00:00Z'
      }
    ];
  }

  // 切换Tab
  private onTabChange(index: number): void {
    this.currentTabIndex = index;
    this.currentPage = 1;
    this.loadOrders();
  }

  // 获取状态显示文本
  private getStatusLabel(status: string): string {
    const map: Record<string, string> = {
      'pending': '待支付',
      'paid': '已支付',
      'preparing': '制作中',
      'delivering': '配送中',
      'completed': '已完成',
      'cancelled': '已取消'
    };
    return map[status] || status;
  }

  // 获取状态标签颜色
  private getStatusColor(status: string): string {
    const map: Record<string, string> = {
      'pending': '#FF9800',
      'paid': '#2196F3',
      'preparing': '#9C27B0',
      'delivering': '#4CAF50',
      'completed': AppTheme.TEXT_SECONDARY,
      'cancelled': AppTheme.ERROR_COLOR
    };
    return map[status] || AppTheme.TEXT_SECONDARY;
  }

  // 格式化时间
  private formatTime(timeStr: string): string {
    if (!timeStr) return '';
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

  // 截取订单编号
  private getShortOrderId(id: string): string {
    if (!id) return '';
    if (id.length > 8) {
      return id.substring(0, 8);
    }
    return id;
  }

  // 点击订单卡片
  private onOrderClick(order: OrderInfo): void {
    router.pushUrl({
      url: 'pages/OrderDetailPage',
      params: {
        orderId: order.id
      }
    }).catch((error: Error) => {
      console.error('跳转订单详情失败:', JSON.stringify(error));
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

        Text('我的订单')
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

      // Tab筛选栏
      Scroll() {
        Row() {
          ForEach(this.tabs, (tab: TabItem, index: number) => {
            Text(tab.label)
              .fontSize(AppTheme.FONT_SIZE_NORMAL)
              .fontColor(this.currentTabIndex === index ? AppTheme.PRIMARY_COLOR : AppTheme.TEXT_SECONDARY)
              .fontWeight(this.currentTabIndex === index ? FontWeight.Bold : FontWeight.Normal)
              .padding({ left: 12, right: 12, top: 8, bottom: 8 })
              .borderRadius(AppTheme.BORDER_RADIUS_CIRCLE)
              .backgroundColor(this.currentTabIndex === index ? AppTheme.PRIMARY_COLOR_ALPHA20 : Color.Transparent)
              .onClick(() => this.onTabChange(index))
          }, (tab: TabItem) => tab.status)
        }
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
      .padding({ left: AppTheme.SPACING_MEDIUM, right: AppTheme.SPACING_MEDIUM, top: AppTheme.SPACING_SMALL, bottom: AppTheme.SPACING_SMALL })
      .backgroundColor(AppTheme.CARD_BACKGROUND)

      // 订单列表
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
      } else if (this.orders.length === 0) {
        // 空状态
        Column() {
          Text('📋')
            .fontSize(64)
            .margin({ bottom: AppTheme.SPACING_MEDIUM })

          Text('暂无订单')
            .fontSize(AppTheme.FONT_SIZE_MEDIUM)
            .fontColor(AppTheme.TEXT_SECONDARY)
            .margin({ bottom: AppTheme.SPACING_SMALL })

          Text('快去挑选心仪的花束吧')
            .fontSize(AppTheme.FONT_SIZE_NORMAL)
            .fontColor(AppTheme.TEXT_SECONDARY)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        List({ space: AppTheme.SPACING_MEDIUM }) {
          ForEach(this.orders, (order: OrderInfo) => {
            ListItem() {
              this.OrderCard(order)
            }
          }, (order: OrderInfo) => order.id)
        }
        .width('100%')
        .layoutWeight(1)
        .padding(AppTheme.SPACING_MEDIUM)
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppTheme.BACKGROUND_COLOR)
  }

  // 订单卡片
  @Builder
  OrderCard(order: OrderInfo) {
    Column() {
      // 顶部：订单编号 + 状态
      Row() {
        Text(`订单号：${this.getShortOrderId(order.id)}`)
          .fontSize(AppTheme.FONT_SIZE_SMALL)
          .fontColor(AppTheme.TEXT_SECONDARY)

        Text(this.getStatusLabel(order.status))
          .fontSize(AppTheme.FONT_SIZE_SMALL)
          .fontColor(this.getStatusColor(order.status))
          .fontWeight(FontWeight.Bold)
          .margin({ left: 'auto' })
      }
      .width('100%')
      .margin({ bottom: AppTheme.SPACING_SMALL })

      Divider().color(AppTheme.DIVIDER_COLOR)

      // 花束名称
      Row() {
        Column() {
          Text('💐')
            .fontSize(28)
        }
        .width(50)
        .height(50)
        .backgroundColor(AppTheme.PRIMARY_COLOR_ALPHA20)
        .borderRadius(AppTheme.BORDER_RADIUS_SMALL)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .margin({ right: AppTheme.SPACING_MEDIUM })

        Column() {
          Text('花束方案')
            .fontSize(AppTheme.FONT_SIZE_NORMAL)
            .fontColor(AppTheme.TEXT_PRIMARY)
            .fontWeight(FontWeight.Medium)

          Text(this.formatTime(order.created_at))
            .fontSize(AppTheme.FONT_SIZE_SMALL)
            .fontColor(AppTheme.TEXT_SECONDARY)
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        // 总价
        Text(`¥${order.total_price}`)
          .fontSize(AppTheme.FONT_SIZE_LARGE)
          .fontColor(AppTheme.ACCENT_COLOR)
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .margin({ top: AppTheme.SPACING_SMALL })
      .alignItems(VerticalAlign.Center)

      // 底部操作区
      Row() {
        // 配送地址简略
        if (order.delivery_address) {
          Text(order.delivery_address.length > 20 ?
            order.delivery_address.substring(0, 20) + '...' : order.delivery_address)
            .fontSize(AppTheme.FONT_SIZE_SMALL)
            .fontColor(AppTheme.TEXT_SECONDARY)
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }

        Text('查看详情 ›')
          .fontSize(AppTheme.FONT_SIZE_SMALL)
          .fontColor(AppTheme.PRIMARY_COLOR)
          .margin({ left: AppTheme.SPACING_SMALL })
      }
      .width('100%')
      .margin({ top: AppTheme.SPACING_SMALL })
    }
    .width('100%')
    .padding(AppTheme.SPACING_MEDIUM)
    .backgroundColor(AppTheme.CARD_BACKGROUND)
    .borderRadius(AppTheme.BORDER_RADIUS_MEDIUM)
    .onClick(() => this.onOrderClick(order))
  }
}
