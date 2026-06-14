import { AppTheme } from '../common/Theme';
import { UserInfo } from '../models/UserModel';
import { ApiService } from '../services/ApiService';
import { HttpUtil } from '../services/HttpUtil';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct MinePage {
  @State userInfo: UserInfo | null = null;
  @State isLoggedIn: boolean = false;

  private async checkLoginStatus(): Promise<void> {
    try {
      const token = await HttpUtil.getToken();
      this.isLoggedIn = token.length > 0;
      if (this.isLoggedIn) this.loadUserInfo();
    } catch (error) {
      this.isLoggedIn = false;
    }
  }

  private async loadUserInfo(): Promise<void> {
    try {
      const profile = await ApiService.getProfile() as Record<string, Object>;
      this.userInfo = {
        id: profile['id'] as number,
        username: (profile['phone'] as string) || '',
        nickname: (profile['nickname'] as string) || '花语爱好者',
        avatarUrl: (profile['avatar'] as string) || '',
        phone: (profile['phone'] as string) || '',
        email: '',
        createdAt: (profile['created_at'] as string) || '',
        updatedAt: (profile['updated_at'] as string) || ''
      };
    } catch (error) {
      this.isLoggedIn = false;
      await HttpUtil.clearToken();
    }
  }

  private maskPhone(phone: string): string {
    if (phone && phone.length >= 7) return phone.substring(0, 3) + '****' + phone.substring(7);
    return phone;
  }

  aboutToAppear() { this.checkLoginStatus(); }

  build() {
    Column() {
      if (this.isLoggedIn && this.userInfo) {
        // Logged in
        Column() {
          // Avatar
          Circle() {
            Text(this.userInfo.nickname.charAt(0))
              .fontSize(AppTheme.FONT_SIZE_XLARGE)
              .fontColor('#FFFFFF')
              .fontWeight(FontWeight.Bold)
          }
          .width(72)
          .height(72)
          .fill(AppTheme.PRIMARY_COLOR)

          Text(this.userInfo.nickname)
            .fontSize(AppTheme.FONT_SIZE_LARGE)
            .fontColor(AppTheme.TEXT_PRIMARY)
            .fontWeight(FontWeight.Bold)
            .margin({ top: AppTheme.SPACING_MEDIUM })

          Text(this.maskPhone(this.userInfo.phone))
            .fontSize(AppTheme.FONT_SIZE_NORMAL)
            .fontColor(AppTheme.TEXT_SECONDARY)
            .margin({ top: AppTheme.SPACING_SMALL / 2 })
        }
        .width('100%')
        .padding({ top: AppTheme.SPACING_XLARGE, bottom: AppTheme.SPACING_LARGE })
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

        // Menu
        Column() {
          ForEach([
            { icon: '📦', title: '我的订单', route: 'pages/OrderListPage' },
            { icon: '👥', title: '收花人档案', route: 'pages/RecipientProfile' },
          ], (item: { icon: string; title: string; route: string }) => {
            Row() {
              Text(item.icon).fontSize(22).margin({ right: AppTheme.SPACING_MEDIUM })
              Text(item.title).fontSize(AppTheme.FONT_SIZE_NORMAL).fontColor(AppTheme.TEXT_PRIMARY).layoutWeight(1)
              Text('›').fontSize(22).fontColor(AppTheme.TEXT_SECONDARY)
            }
            .width('100%')
            .height(56)
            .padding({ left: AppTheme.SPACING_MEDIUM, right: AppTheme.SPACING_MEDIUM })
            .alignItems(VerticalAlign.Center)
            .onClick(() => router.pushUrl({ url: item.route }))
          }, (item: { icon: string; title: string; route: string }) => item.title)
        }
        .width('100%')
        .backgroundColor(AppTheme.CARD_BACKGROUND)
        .borderRadius(AppTheme.BORDER_RADIUS_MEDIUM)
        .margin({ left: AppTheme.SPACING_MEDIUM, right: AppTheme.SPACING_MEDIUM })
        .padding({ top: AppTheme.SPACING_SMALL, bottom: AppTheme.SPACING_SMALL })

        // Logout
        Button('退出登录')
          .width('90%')
          .height(44)
          .fontSize(AppTheme.FONT_SIZE_MEDIUM)
          .fontColor(AppTheme.ERROR_COLOR)
          .backgroundColor(Color.Transparent)
          .borderRadius(AppTheme.BORDER_RADIUS_MEDIUM)
          .border({ width: 1, color: AppTheme.ERROR_COLOR, style: BorderStyle.Solid })
          .margin({ top: AppTheme.SPACING_LARGE })
          .onClick(async () => {
            await HttpUtil.clearToken();
            this.isLoggedIn = false;
            this.userInfo = null;
          })
      } else {
        // Not logged in
        Column() {
          Circle() {
            Text('👤').fontSize(32).fontColor(AppTheme.TEXT_SECONDARY)
          }
          .width(72).height(72).fill(AppTheme.PRIMARY_COLOR_ALPHA20)

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
        .padding({ top: AppTheme.SPACING_XLARGE })
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

        Button('登录 / 注册')
          .width('90%')
          .height(48)
          .fontSize(AppTheme.FONT_SIZE_MEDIUM)
          .fontColor('#FFFFFF')
          .backgroundColor(AppTheme.PRIMARY_COLOR)
          .borderRadius(AppTheme.BORDER_RADIUS_MEDIUM)
          .margin({ top: AppTheme.SPACING_LARGE })
          .onClick(() => router.pushUrl({ url: 'pages/LoginPage' }))
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppTheme.BACKGROUND_COLOR)
  }
}
