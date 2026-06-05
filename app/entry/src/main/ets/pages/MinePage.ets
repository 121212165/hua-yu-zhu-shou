// 我的页面 - 用户信息、数据统计、功能菜单、登录登出

import { AppTheme } from '../common/Theme';
import { UserInfo } from '../models/UserModel';
import { ApiService } from '../services/ApiService';
import { HttpUtil } from '../services/HttpUtil';
import router from '@ohos.router';

// 菜单项数据结构
interface MenuItem {
  icon: string;
  title: string;
  route?: string;
}

@Entry
@Component
struct MinePage {
  // 用户信息
  @State userInfo: UserInfo | null = null;
  // 是否已登录
  @State isLoggedIn: boolean = false;
  // 统计数据
  @State flowerCount: number = 0;
  @State recipientCount: number = 0;
  @State favoriteCount: number = 0;

  // 功能菜单列表
  private menuItems: MenuItem[] = [
    { icon: '📦', title: '我的订单', route: 'pages/OrderListPage' },
    { icon: '⭐', title: '收藏的方案' },
    { icon: '📅', title: '送花日历提醒' },
    { icon: '👥', title: '收花人档案', route: 'pages/RecipientProfile' },
    { icon: '🔔', title: '消息通知' },
    { icon: '⚙️', title: '设置' }
  ];

  // 检查登录状态
  private async checkLoginStatus(): Promise<void> {
    try {
      const token = await HttpUtil.getToken();
      this.isLoggedIn = token.length > 0;
      if (this.isLoggedIn) {
        // 已登录，加载用户信息
        this.loadUserInfo();
      }
    } catch (error) {
      this.isLoggedIn = false;
    }
  }

  // 加载用户信息
  private async loadUserInfo(): Promise<void> {
    try {
      // 目前API没有获取当前用户信息接口，使用模拟数据
      this.userInfo = {
        id: 1,
        username: 'flower_lover',
        nickname: '花语爱好者',
        avatarUrl: '',
        phone: '138****8888',
        email: 'flower@example.com',
        createdAt: '2025-01-01',
        updatedAt: '2025-05-01'
      };
      this.flowerCount = 12;
      this.recipientCount = 4;
      this.favoriteCount = 8;
    } catch (error) {
      console.error('加载用户信息失败:', JSON.stringify(error));
    }
  }

  // 隐藏手机号中间4位
  private maskPhone(phone: string): string {
    if (phone && phone.length >= 7) {
      return phone.substring(0, 3) + '****' + phone.substring(7);
    }
    return phone;
  }

  // 退出登录
  private async logout(): Promise<void> {
    try {
      await HttpUtil.clearToken();
      this.isLoggedIn = false;
      this.userInfo = null;
      this.flowerCount = 0;
      this.recipientCount = 0;
      this.favoriteCount = 0;
    } catch (error) {
      console.error('退出登录失败:', JSON.stringify(error));
    }
  }

  // 点击菜单项
  private onMenuItemClick(item: MenuItem): void {
    if (item.route) {
      router.pushUrl({ url: item.route }).catch((error: Error) => {
        console.error(`跳转失败: ${item.route}`, JSON.stringify(error));
      });
    } else {
      console.info(`点击: ${item.title}`);
    }
  }

  aboutToAppear() {
    this.checkLoginStatus();
  }

  build() {
    Column() {
      Scroll() {
        Column() {
          if (this.isLoggedIn && this.userInfo) {
            // ====== 已登录状态 ======
            // 用户信息区
            Column() {
              // 头像（圆形）
              if (this.userInfo.avatarUrl) {
                Image(this.userInfo.avatarUrl)
                  .width(72)
                  .height(72)
                  .borderRadius(AppTheme.BORDER_RADIUS_CIRCLE)
                  .objectFit(ImageFit.Cover)
              } else {
                Circle() {
                  Text(this.userInfo.nickname.charAt(0))
                    .fontSize(AppTheme.FONT_SIZE_XLARGE)
                    .fontColor('#FFFFFF')
                    .fontWeight(FontWeight.Bold)
                }
                .width(72)
                .height(72)
                .fill(AppTheme.PRIMARY_COLOR)
              }

              // 昵称
              Text(this.userInfo.nickname)
                .fontSize(AppTheme.FONT_SIZE_LARGE)
                .fontColor(AppTheme.TEXT_PRIMARY)
                .fontWeight(FontWeight.Bold)
                .margin({ top: AppTheme.SPACING_MEDIUM })

              // 手机号（部分隐藏）
              Text(this.maskPhone(this.userInfo.phone))
                .fontSize(AppTheme.FONT_SIZE_NORMAL)
                .fontColor(AppTheme.TEXT_SECONDARY)
                .margin({ top: AppTheme.SPACING_SMALL / 2 })

              // 编辑资料按钮
              Text('编辑资料')
                .fontSize(AppTheme.FONT_SIZE_SMALL)
                .fontColor(AppTheme.PRIMARY_COLOR)
                .margin({ top: AppTheme.SPACING_SMALL })
                .padding({ left: 12, right: 12, top: 4, bottom: 4 })
                .borderRadius(AppTheme.BORDER_RADIUS_CIRCLE)
                .border({ width: 1, color: AppTheme.PRIMARY_COLOR, style: BorderStyle.Solid })
                .onClick(() => {
                  console.info('编辑资料');
                })
            }
            .width('100%')
            .padding({ top: AppTheme.SPACING_XLARGE, bottom: AppTheme.SPACING_LARGE })
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)

            // 数据统计行
            Row() {
              // 送花次数
              Column() {
                Text(`${this.flowerCount}`)
                  .fontSize(AppTheme.FONT_SIZE_XLARGE)
                  .fontColor(AppTheme.PRIMARY_COLOR)
                  .fontWeight(FontWeight.Bold)

                Text('送花次数')
                  .fontSize(AppTheme.FONT_SIZE_SMALL)
                  .fontColor(AppTheme.TEXT_SECONDARY)
                  .margin({ top: 4 })
              }
              .layoutWeight(1)

              // 分割线
              Divider()
                .vertical(true)
                .height(30)
                .color(AppTheme.DIVIDER_COLOR)

              // 收花人数
              Column() {
                Text(`${this.recipientCount}`)
                  .fontSize(AppTheme.FONT_SIZE_XLARGE)
                  .fontColor(AppTheme.PRIMARY_COLOR)
                  .fontWeight(FontWeight.Bold)

                Text('收花人数')
                  .fontSize(AppTheme.FONT_SIZE_SMALL)
                  .fontColor(AppTheme.TEXT_SECONDARY)
                  .margin({ top: 4 })
              }
              .layoutWeight(1)

              // 分割线
              Divider()
                .vertical(true)
                .height(30)
                .color(AppTheme.DIVIDER_COLOR)

              // 收藏方案
              Column() {
                Text(`${this.favoriteCount}`)
                  .fontSize(AppTheme.FONT_SIZE_XLARGE)
                  .fontColor(AppTheme.PRIMARY_COLOR)
                  .fontWeight(FontWeight.Bold)

                Text('收藏方案')
                  .fontSize(AppTheme.FONT_SIZE_SMALL)
                  .fontColor(AppTheme.TEXT_SECONDARY)
                  .margin({ top: 4 })
              }
              .layoutWeight(1)
            }
            .width('100%')
            .padding(AppTheme.SPACING_MEDIUM)
            .backgroundColor(AppTheme.CARD_BACKGROUND)
            .borderRadius(AppTheme.BORDER_RADIUS_MEDIUM)
            .margin({ left: AppTheme.SPACING_MEDIUM, right: AppTheme.SPACING_MEDIUM, top: AppTheme.SPACING_SMALL })
            .justifyContent(FlexAlign.SpaceAround)

            // 功能菜单列表
            Column() {
              ForEach(this.menuItems, (item: MenuItem, index: number) => {
                Row() {
                  Text(item.icon)
                    .fontSize(22)
                    .margin({ right: AppTheme.SPACING_MEDIUM })

                  Text(item.title)
                    .fontSize(AppTheme.FONT_SIZE_NORMAL)
                    .fontColor(AppTheme.TEXT_PRIMARY)
                    .layoutWeight(1)

                  // 右侧箭头图标
                  Text('›')
                    .fontSize(22)
                    .fontColor(AppTheme.TEXT_SECONDARY)
                }
                .width('100%')
                .height(56)
                .padding({ left: AppTheme.SPACING_MEDIUM, right: AppTheme.SPACING_MEDIUM })
                .alignItems(VerticalAlign.Center)
                .onClick(() => {
                  this.onMenuItemClick(item);
                })

                // 菜单项间分割线（非最后一项）
                if (index < this.menuItems.length - 1) {
                  Divider()
                    .color(AppTheme.DIVIDER_COLOR)
                    .margin({ left: 52 })
                }
              }, (item: MenuItem) => item.title)
            }
            .width('100%')
            .backgroundColor(AppTheme.CARD_BACKGROUND)
            .borderRadius(AppTheme.BORDER_RADIUS_MEDIUM)
            .margin({ left: AppTheme.SPACING_MEDIUM, right: AppTheme.SPACING_MEDIUM, top: AppTheme.SPACING_MEDIUM })
            .padding({ top: AppTheme.SPACING_SMALL, bottom: AppTheme.SPACING_SMALL })

            // 退出登录按钮
            Button('退出登录')
              .width('90%')
              .height(44)
              .fontSize(AppTheme.FONT_SIZE_MEDIUM)
              .fontColor(AppTheme.ERROR_COLOR)
              .backgroundColor(Color.Transparent)
              .borderRadius(AppTheme.BORDER_RADIUS_MEDIUM)
              .border({ width: 1, color: AppTheme.ERROR_COLOR, style: BorderStyle.Solid })
              .margin({ top: AppTheme.SPACING_LARGE, bottom: AppTheme.SPACING_LARGE })
              .onClick(() => {
                this.logout();
              })
          } else {
            // ====== 未登录状态 ======
            Column() {
              // 头像占位
              Circle() {
                Text('👤')
                  .fontSize(32)
                  .fontColor(AppTheme.TEXT_SECONDARY)
              }
              .width(72)
              .height(72)
              .fill(AppTheme.PRIMARY_COLOR_ALPHA20)
              .stroke(AppTheme.PRIMARY_COLOR)
              .strokeWidth(2)

              Text('未登录')
                .fontSize(AppTheme.FONT_SIZE_LARGE)
                .fontColor(AppTheme.TEXT_PRIMARY)
                .fontWeight(FontWeight.Bold)
                .margin({ top: AppTheme.SPACING_MEDIUM })

              Text('登录后享受更多服务')
                .fontSize(AppTheme.FONT_SIZE_NORMAL)
                .fontColor(AppTheme.TEXT_SECONDARY)
                .margin({ top: AppTheme.SPACING_SMALL })
            }
            .width('100%')
            .padding({ top: AppTheme.SPACING_XLARGE, bottom: AppTheme.SPACING_LARGE })
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)

            // 登录按钮
            Button('登录 / 注册')
              .width('90%')
              .height(48)
              .fontSize(AppTheme.FONT_SIZE_MEDIUM)
              .fontColor('#FFFFFF')
              .backgroundColor(AppTheme.PRIMARY_COLOR)
              .borderRadius(AppTheme.BORDER_RADIUS_MEDIUM)
              .margin({ top: AppTheme.SPACING_LARGE, bottom: AppTheme.SPACING_XLARGE })
              .onClick(() => {
                router.pushUrl({ url: 'pages/LoginPage' }).catch((error: Error) => {
                  console.error('跳转登录页失败:', JSON.stringify(error));
                });
              })

            // 未登录也显示部分菜单（灰色不可点击样式）
            Column() {
              ForEach(this.menuItems, (item: MenuItem, index: number) => {
                Row() {
                  Text(item.icon)
                    .fontSize(22)
                    .margin({ right: AppTheme.SPACING_MEDIUM })

                  Text(item.title)
                    .fontSize(AppTheme.FONT_SIZE_NORMAL)
                    .fontColor(AppTheme.DISABLED_COLOR)
                    .layoutWeight(1)

                  Text('›')
                    .fontSize(22)
                    .fontColor(AppTheme.DISABLED_COLOR)
                }
                .width('100%')
                .height(56)
                .padding({ left: AppTheme.SPACING_MEDIUM, right: AppTheme.SPACING_MEDIUM })
                .alignItems(VerticalAlign.Center)

                if (index < this.menuItems.length - 1) {
                  Divider()
                    .color(AppTheme.DIVIDER_COLOR)
                    .margin({ left: 52 })
                }
              }, (item: MenuItem) => item.title)
            }
            .width('100%')
            .backgroundColor(AppTheme.CARD_BACKGROUND)
            .borderRadius(AppTheme.BORDER_RADIUS_MEDIUM)
            .margin({ left: AppTheme.SPACING_MEDIUM, right: AppTheme.SPACING_MEDIUM, top: AppTheme.SPACING_MEDIUM })
            .padding({ top: AppTheme.SPACING_SMALL, bottom: AppTheme.SPACING_SMALL })
          }
        }
      }
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppTheme.BACKGROUND_COLOR)
  }
}
