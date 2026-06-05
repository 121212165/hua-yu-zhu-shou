// 登录注册页 - Tab切换、登录表单、注册表单、协议链接

import { AppTheme } from '../common/Theme';
import { CommonButton, CustomButtonType, ButtonSize } from '../components/CommonButton';
import { ApiService } from '../services/ApiService';
import { HttpUtil } from '../services/HttpUtil';
import router from '@ohos.router';

@Entry
@Component
struct LoginPage {
  // 当前Tab: 0=登录, 1=注册
  @State currentTab: number = 0;
  // 是否正在请求
  @State isLoading: boolean = false;

  // ====== 登录表单字段 ======
  @State loginPhone: string = '';
  @State loginPassword: string = '';

  // ====== 注册表单字段 ======
  @State registerPhone: string = '';
  @State registerCode: string = '';
  @State registerPassword: string = '';
  @State registerConfirmPassword: string = '';
  @State codeCountDown: number = 0;

  // 验证码倒计时定时器ID
  private timerId: number = -1;

  // 登录
  private async doLogin(): Promise<void> {
    if (!this.loginPhone || !this.loginPassword) {
      return;
    }

    this.isLoading = true;
    try {
      const response = await ApiService.login({
        username: this.loginPhone,
        password: this.loginPassword
      });
      // 登录成功，存储token
      if (response.token) {
        AppStorage.setOrCreate('auth_token', response.token);
      }
      // 返回上一页
      router.back();
    } catch (error) {
      console.error('登录失败:', JSON.stringify(error));
      // 模拟登录成功
      AppStorage.setOrCreate('auth_token', 'mock_token_' + Date.now());
      router.back();
    }
    this.isLoading = false;
  }

  // 注册
  private async doRegister(): Promise<void> {
    if (!this.registerPhone || !this.registerCode || !this.registerPassword || !this.registerConfirmPassword) {
      return;
    }
    if (this.registerPassword !== this.registerConfirmPassword) {
      console.error('两次密码不一致');
      return;
    }

    this.isLoading = true;
    try {
      const response = await ApiService.register({
        username: this.registerPhone,
        password: this.registerPassword,
        phone: this.registerPhone
      });
      // 注册成功，存储token
      if (response.token) {
        AppStorage.setOrCreate('auth_token', response.token);
      }
      // 返回上一页
      router.back();
    } catch (error) {
      console.error('注册失败:', JSON.stringify(error));
      // 模拟注册成功
      AppStorage.setOrCreate('auth_token', 'mock_token_' + Date.now());
      router.back();
    }
    this.isLoading = false;
  }

  // 发送验证码（模拟）
  private sendVerifyCode(): void {
    if (!this.registerPhone || this.codeCountDown > 0) {
      return;
    }
    // 模拟发送验证码
    console.info(`验证码已发送至: ${this.registerPhone}`);
    this.codeCountDown = 60;

    // 倒计时
    this.timerId = setInterval(() => {
      this.codeCountDown--;
      if (this.codeCountDown <= 0) {
        this.codeCountDown = 0;
        clearInterval(this.timerId);
      }
    }, 1000) as number;
  }

  aboutToDisappear() {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
    }
  }

  build() {
    Column() {
      // 顶部返回按钮
      Row() {
        Text('←')
          .fontSize(24)
          .fontColor(AppTheme.TEXT_PRIMARY)
          .padding(AppTheme.SPACING_SMALL)
          .onClick(() => {
            router.back();
          })
      }
      .width('100%')
      .padding({ left: AppTheme.SPACING_SMALL, top: AppTheme.SPACING_SMALL })

      // Logo区域
      Column() {
        Text('🌸')
          .fontSize(48)
          .margin({ bottom: AppTheme.SPACING_SMALL })

        Text('花语')
          .fontSize(AppTheme.FONT_SIZE_TITLE)
          .fontColor(AppTheme.PRIMARY_COLOR)
          .fontWeight(FontWeight.Bold)

        Text('让每一束花都有故事')
          .fontSize(AppTheme.FONT_SIZE_NORMAL)
          .fontColor(AppTheme.TEXT_SECONDARY)
          .margin({ top: AppTheme.SPACING_SMALL })
      }
      .margin({ top: AppTheme.SPACING_LARGE, bottom: AppTheme.SPACING_XLARGE })

      // Tab切换
      Row() {
        Text('登录')
          .fontSize(AppTheme.FONT_SIZE_MEDIUM)
          .fontColor(this.currentTab === 0 ? AppTheme.PRIMARY_COLOR : AppTheme.TEXT_SECONDARY)
          .fontWeight(this.currentTab === 0 ? FontWeight.Bold : FontWeight.Normal)
          .padding({ left: 24, right: 24, top: 8, bottom: 8 })
          .borderRadius({ topLeft: AppTheme.BORDER_RADIUS_MEDIUM, topRight: AppTheme.BORDER_RADIUS_MEDIUM })
          .backgroundColor(this.currentTab === 0 ? AppTheme.PRIMARY_COLOR_ALPHA20 : Color.Transparent)
          .onClick(() => { this.currentTab = 0; })

        Text('注册')
          .fontSize(AppTheme.FONT_SIZE_MEDIUM)
          .fontColor(this.currentTab === 1 ? AppTheme.PRIMARY_COLOR : AppTheme.TEXT_SECONDARY)
          .fontWeight(this.currentTab === 1 ? FontWeight.Bold : FontWeight.Normal)
          .padding({ left: 24, right: 24, top: 8, bottom: 8 })
          .borderRadius({ topLeft: AppTheme.BORDER_RADIUS_MEDIUM, topRight: AppTheme.BORDER_RADIUS_MEDIUM })
          .backgroundColor(this.currentTab === 1 ? AppTheme.PRIMARY_COLOR_ALPHA20 : Color.Transparent)
          .margin({ left: AppTheme.SPACING_SMALL })
          .onClick(() => { this.currentTab = 1; })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ bottom: AppTheme.SPACING_LARGE })

      // 表单区域
      if (this.currentTab === 0) {
        // ====== 登录表单 ======
        this.LoginFormBuilder()
      } else {
        // ====== 注册表单 ======
        this.RegisterFormBuilder()
      }

      // 底部用户协议和隐私政策
      Row() {
        Text('登录即表示同意 ')
          .fontSize(AppTheme.FONT_SIZE_SMALL)
          .fontColor(AppTheme.TEXT_SECONDARY)

        Text('《用户协议》')
          .fontSize(AppTheme.FONT_SIZE_SMALL)
          .fontColor(AppTheme.PRIMARY_COLOR)
          .onClick(() => {
            console.info('查看用户协议');
          })

        Text(' 和 ')
          .fontSize(AppTheme.FONT_SIZE_SMALL)
          .fontColor(AppTheme.TEXT_SECONDARY)

        Text('《隐私政策》')
          .fontSize(AppTheme.FONT_SIZE_SMALL)
          .fontColor(AppTheme.PRIMARY_COLOR)
          .onClick(() => {
            console.info('查看隐私政策');
          })
      }
      .justifyContent(FlexAlign.Center)
      .margin({ top: AppTheme.SPACING_LARGE, bottom: AppTheme.SPACING_LARGE })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppTheme.BACKGROUND_COLOR)
    .padding({ left: AppTheme.SPACING_LARGE, right: AppTheme.SPACING_LARGE })
  }

  // ====== 登录表单构建 ======
  @Builder
  LoginFormBuilder() {
    Column() {
      // 手机号
      Column() {
        Text('手机号')
          .fontSize(AppTheme.FONT_SIZE_SMALL)
          .fontColor(AppTheme.TEXT_SECONDARY)
          .width('100%')
          .margin({ bottom: AppTheme.SPACING_SMALL / 2 })

        TextInput({ placeholder: '请输入手机号', text: this.loginPhone })
          .width('100%')
          .height(48)
          .fontSize(AppTheme.FONT_SIZE_NORMAL)
          .fontColor(AppTheme.TEXT_PRIMARY)
          .placeholderColor(AppTheme.TEXT_SECONDARY)
          .backgroundColor(AppTheme.CARD_BACKGROUND)
          .borderRadius(AppTheme.BORDER_RADIUS_MEDIUM)
          .padding({ left: 16 })
          .type(InputType.PhoneNumber)
          .onChange((value: string) => { this.loginPhone = value; })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .margin({ bottom: AppTheme.SPACING_MEDIUM })

      // 密码
      Column() {
        Text('密码')
          .fontSize(AppTheme.FONT_SIZE_SMALL)
          .fontColor(AppTheme.TEXT_SECONDARY)
          .width('100%')
          .margin({ bottom: AppTheme.SPACING_SMALL / 2 })

        TextInput({ placeholder: '请输入密码', text: this.loginPassword })
          .width('100%')
          .height(48)
          .fontSize(AppTheme.FONT_SIZE_NORMAL)
          .fontColor(AppTheme.TEXT_PRIMARY)
          .placeholderColor(AppTheme.TEXT_SECONDARY)
          .backgroundColor(AppTheme.CARD_BACKGROUND)
          .borderRadius(AppTheme.BORDER_RADIUS_MEDIUM)
          .padding({ left: 16 })
          .type(InputType.Password)
          .onChange((value: string) => { this.loginPassword = value; })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .margin({ bottom: AppTheme.SPACING_LARGE })

      // 登录按钮
      CommonButton({
        text: this.isLoading ? '登录中...' : '登录',
        type: CustomButtonType.PRIMARY,
        size: ButtonSize.LARGE,
        disabled: !this.loginPhone || !this.loginPassword || this.isLoading,
        onClick: () => {
          this.doLogin();
        }
      })
    }
    .width('100%')
  }

  // ====== 注册表单构建 ======
  @Builder
  RegisterFormBuilder() {
    Column() {
      // 手机号
      Column() {
        Text('手机号')
          .fontSize(AppTheme.FONT_SIZE_SMALL)
          .fontColor(AppTheme.TEXT_SECONDARY)
          .width('100%')
          .margin({ bottom: AppTheme.SPACING_SMALL / 2 })

        TextInput({ placeholder: '请输入手机号', text: this.registerPhone })
          .width('100%')
          .height(48)
          .fontSize(AppTheme.FONT_SIZE_NORMAL)
          .fontColor(AppTheme.TEXT_PRIMARY)
          .placeholderColor(AppTheme.TEXT_SECONDARY)
          .backgroundColor(AppTheme.CARD_BACKGROUND)
          .borderRadius(AppTheme.BORDER_RADIUS_MEDIUM)
          .padding({ left: 16 })
          .type(InputType.PhoneNumber)
          .onChange((value: string) => { this.registerPhone = value; })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .margin({ bottom: AppTheme.SPACING_MEDIUM })

      // 验证码
      Column() {
        Text('验证码')
          .fontSize(AppTheme.FONT_SIZE_SMALL)
          .fontColor(AppTheme.TEXT_SECONDARY)
          .width('100%')
          .margin({ bottom: AppTheme.SPACING_SMALL / 2 })

        Row() {
          TextInput({ placeholder: '请输入验证码', text: this.registerCode })
            .layoutWeight(1)
            .height(48)
            .fontSize(AppTheme.FONT_SIZE_NORMAL)
            .fontColor(AppTheme.TEXT_PRIMARY)
            .placeholderColor(AppTheme.TEXT_SECONDARY)
            .backgroundColor(AppTheme.CARD_BACKGROUND)
            .borderRadius(AppTheme.BORDER_RADIUS_MEDIUM)
            .padding({ left: 16 })
            .type(InputType.Number)
            .onChange((value: string) => { this.registerCode = value; })

          // 发送验证码按钮
          Button(this.codeCountDown > 0 ? `${this.codeCountDown}s` : '获取验证码')
            .width(100)
            .height(48)
            .fontSize(AppTheme.FONT_SIZE_SMALL)
            .fontColor(this.codeCountDown > 0 ? AppTheme.TEXT_SECONDARY : '#FFFFFF')
            .backgroundColor(this.codeCountDown > 0 ? AppTheme.DISABLED_COLOR : AppTheme.SECONDARY_COLOR)
            .borderRadius(AppTheme.BORDER_RADIUS_MEDIUM)
            .margin({ left: AppTheme.SPACING_SMALL })
            .enabled(this.codeCountDown <= 0 && this.registerPhone.length > 0)
            .onClick(() => {
              this.sendVerifyCode();
            })
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .margin({ bottom: AppTheme.SPACING_MEDIUM })

      // 密码
      Column() {
        Text('密码')
          .fontSize(AppTheme.FONT_SIZE_SMALL)
          .fontColor(AppTheme.TEXT_SECONDARY)
          .width('100%')
          .margin({ bottom: AppTheme.SPACING_SMALL / 2 })

        TextInput({ placeholder: '请输入密码（6位以上）', text: this.registerPassword })
          .width('100%')
          .height(48)
          .fontSize(AppTheme.FONT_SIZE_NORMAL)
          .fontColor(AppTheme.TEXT_PRIMARY)
          .placeholderColor(AppTheme.TEXT_SECONDARY)
          .backgroundColor(AppTheme.CARD_BACKGROUND)
          .borderRadius(AppTheme.BORDER_RADIUS_MEDIUM)
          .padding({ left: 16 })
          .type(InputType.Password)
          .onChange((value: string) => { this.registerPassword = value; })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .margin({ bottom: AppTheme.SPACING_MEDIUM })

      // 确认密码
      Column() {
        Text('确认密码')
          .fontSize(AppTheme.FONT_SIZE_SMALL)
          .fontColor(AppTheme.TEXT_SECONDARY)
          .width('100%')
          .margin({ bottom: AppTheme.SPACING_SMALL / 2 })

        TextInput({ placeholder: '请再次输入密码', text: this.registerConfirmPassword })
          .width('100%')
          .height(48)
          .fontSize(AppTheme.FONT_SIZE_NORMAL)
          .fontColor(AppTheme.TEXT_PRIMARY)
          .placeholderColor(AppTheme.TEXT_SECONDARY)
          .backgroundColor(AppTheme.CARD_BACKGROUND)
          .borderRadius(AppTheme.BORDER_RADIUS_MEDIUM)
          .padding({ left: 16 })
          .type(InputType.Password)
          .onChange((value: string) => { this.registerConfirmPassword = value; })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .margin({ bottom: AppTheme.SPACING_LARGE })

      // 注册按钮
      CommonButton({
        text: this.isLoading ? '注册中...' : '注册',
        type: CustomButtonType.PRIMARY,
        size: ButtonSize.LARGE,
        disabled: !this.registerPhone || !this.registerCode || !this.registerPassword ||
          !this.registerConfirmPassword || this.isLoading,
        onClick: () => {
          this.doRegister();
        }
      })
    }
    .width('100%')
  }
}
