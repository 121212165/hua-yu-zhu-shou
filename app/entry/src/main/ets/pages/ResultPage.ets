// 结果页 - 推荐方案展示

import { AppTheme } from '../common/Theme';
import { CommonButton, CustomButtonType, ButtonSize } from '../components/CommonButton';
import { BouquetScheme, FlowerItem, GenerateRecommendationParams } from '../models/RecommendModel';
import { ApiService } from '../services/ApiService';
import { CartStore } from '../store/CartStore';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';

@Entry
@Component
export struct ResultPage {
  // 推荐方案列表
  @State schemes: BouquetScheme[] = [];
  // 推荐理由
  @State reason: string = '';
  // 场景分析
  @State sceneAnalysis: string = '';
  // 当前Swiper索引
  @State currentSchemeIndex: number = 0;
  // 是否正在加载
  @State isLoading: boolean = false;
  // 复制成功提示
  @State copyTip: string = '';

  // 原始请求参数（用于重新推荐）
  @State requestParamsJson: string = '';

  aboutToAppear() {
    // 从路由参数获取推荐数据
    const params = router.getParams();
    if (params) {
      if (params.schemesData) {
        try {
          this.schemes = JSON.parse(params.schemesData as string) as BouquetScheme[];
        } catch (e) {
          console.error('解析推荐数据失败:', JSON.stringify(e));
          this.schemes = this.getMockSchemes();
        }
      } else {
        this.schemes = this.getMockSchemes();
      }
      if (params.reason) {
        this.reason = params.reason as string;
      }
      if (params.sceneAnalysis) {
        this.sceneAnalysis = params.sceneAnalysis as string;
      }
      if (params.requestParams) {
        this.requestParamsJson = params.requestParams as string;
      }
    } else {
      this.schemes = this.getMockSchemes();
    }
  }

  // 模拟方案数据
  private getMockSchemes(): BouquetScheme[] {
    return [
      {
        id: 1,
        name: '初恋悸动',
        description: '粉白交织的温柔花束，如同初见时心跳加速的感觉',
        flowers: [
          { flowerId: 1, flowerName: '粉玫瑰', quantity: 9, unitPrice: 8, color: '粉色', meaning: '初恋' },
          { flowerId: 2, flowerName: '白百合', quantity: 3, unitPrice: 12, color: '白色', meaning: '纯洁' },
          { flowerId: 3, flowerName: '满天星', quantity: 5, unitPrice: 3, color: '白色', meaning: '真心喜欢' }
        ],
        totalPrice: 108,
        style: '简约',
        meaning: '初恋的悸动，如同这束粉白交织的花朵，纯真而心动。九朵粉玫瑰代表长久的期待，白百合守护着这份纯洁的心意。',
        imageUrl: '',
        matchScore: 95
      },
      {
        id: 2,
        name: '浪漫满屋',
        description: '红粉相伴的热情花束，诉说内心深处的爱意',
        flowers: [
          { flowerId: 4, flowerName: '红玫瑰', quantity: 11, unitPrice: 8, color: '红色', meaning: '一心一意' },
          { flowerId: 5, flowerName: '粉色绣球', quantity: 2, unitPrice: 15, color: '粉色', meaning: '浪漫' },
          { flowerId: 6, flowerName: '尤加利叶', quantity: 3, unitPrice: 5, color: '绿色', meaning: '回忆' }
        ],
        totalPrice: 133,
        style: '华丽',
        meaning: '十一朵红玫瑰诉说一心一意的深情，绣球花增添浪漫氛围，每一片花瓣都是爱的告白。',
        imageUrl: '',
        matchScore: 88
      },
      {
        id: 3,
        name: '温柔告白',
        description: '紫色梦幻的优雅花束，用最温柔的方式说出爱',
        flowers: [
          { flowerId: 7, flowerName: '紫玫瑰', quantity: 9, unitPrice: 10, color: '紫色', meaning: '浪漫真情' },
          { flowerId: 8, flowerName: '白色桔梗', quantity: 5, unitPrice: 6, color: '白色', meaning: '永恒不变的爱' },
          { flowerId: 9, flowerName: '银叶菊', quantity: 3, unitPrice: 4, color: '银色', meaning: '珍贵' }
        ],
        totalPrice: 127,
        style: '优雅',
        meaning: '紫色玫瑰代表浪漫真情，白色桔梗象征永恒不变的爱，银叶菊点缀其间，诉说你在我心中的珍贵。',
        imageUrl: '',
        matchScore: 82
      }
    ];
  }

  // 重新推荐
  private async refreshSchemes(): Promise<void> {
    if (!this.requestParamsJson) {
      return;
    }
    this.isLoading = true;
    try {
      const params = JSON.parse(this.requestParamsJson) as GenerateRecommendationParams;
      const response = await ApiService.generateRecommendation(params);
      this.schemes = response.schemes;
      this.reason = response.reason;
      this.sceneAnalysis = response.sceneAnalysis;
      this.currentSchemeIndex = 0;
    } catch (error) {
      console.error('重新推荐失败:', JSON.stringify(error));
    }
    this.isLoading = false;
  }

  // 选择方案加入购物车
  private selectScheme(scheme: BouquetScheme): void {
    CartStore.addItem(scheme, 1);
    promptAction.showToast({ message: '已添加到购物车', duration: 1500 });
    router.pushUrl({ url: 'pages/CartPage' }).catch((error: Error) => {
      console.error('跳转购物车页失败:', JSON.stringify(error));
    });
  }

  // 直接下单
  private selectSchemeDirect(scheme: BouquetScheme): void {
    const cartItem = {
      scheme: scheme,
      quantity: 1
    };
    router.pushUrl({
      url: 'pages/OrderConfirmPage',
      params: {
        cartData: JSON.stringify([cartItem])
      }
    }).catch((error: Error) => {
      console.error('跳转订单确认页失败:', JSON.stringify(error));
    });
  }

  // 复制贺卡文案
  private copyGreetingText(text: string): void {
    // 在实际项目中使用剪贴板API
    this.copyTip = '已复制到剪贴板';
    setTimeout(() => { this.copyTip = ''; }, 2000);
  }

  // 生成贺卡文案
  private getGreetingText(scheme: BouquetScheme): string {
    const greetings: Record<string, string> = {
      '初恋悸动': '遇见你的那一刻，世界突然有了颜色。愿这束花替我说出那句——我喜欢你。',
      '浪漫满屋': '每一朵玫瑰都是我对你的思念，愿我们的故事如这束花，越来越美。',
      '温柔告白': '用最温柔的方式告诉你，你是我心中最珍贵的存在。'
    };
    return greetings[scheme.name] || `送你一束${scheme.name}，愿每一朵花都带给你幸福与喜悦。`;
  }

  // 获取风格标签颜色
  private getStyleColor(style: string): string {
    const colorMap: Record<string, string> = {
      '简约': '#4CAF50',
      '华丽': '#FF69B4',
      '可爱': '#FFB6C1',
      '优雅': '#9B59B6',
      '自然': '#8BC34A'
    };
    return colorMap[style] || AppTheme.PRIMARY_COLOR;
  }

  // ==================== 方案卡片构建器 ====================

  @Builder
  SchemeCard(scheme: BouquetScheme) {
    Scroll() {
      Column() {
        // 方案名称
        Text(scheme.name)
          .fontSize(AppTheme.FONT_SIZE_XLARGE)
          .fontColor(AppTheme.TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: AppTheme.SPACING_SMALL })

        // 主题标签行
        Row() {
          // 风格标签
          Text(scheme.style)
            .fontSize(AppTheme.FONT_SIZE_SMALL)
            .fontColor('#FFFFFF')
            .backgroundColor(this.getStyleColor(scheme.style))
            .borderRadius(AppTheme.BORDER_RADIUS_CIRCLE)
            .padding({ left: 10, right: 10, top: 3, bottom: 3 })

          // 匹配度标签
          Text(`匹配度 ${scheme.matchScore}%`)
            .fontSize(AppTheme.FONT_SIZE_SMALL)
            .fontColor(AppTheme.SECONDARY_COLOR)
            .backgroundColor(AppTheme.SECONDARY_COLOR_ALPHA20)
            .borderRadius(AppTheme.BORDER_RADIUS_CIRCLE)
            .padding({ left: 10, right: 10, top: 3, bottom: 3 })
            .margin({ left: AppTheme.SPACING_SMALL })

          // 价格
          Text(`¥${scheme.totalPrice}`)
            .fontSize(AppTheme.FONT_SIZE_LARGE)
            .fontColor(AppTheme.ACCENT_COLOR)
            .fontWeight(FontWeight.Bold)
            .margin({ left: 'auto' })
        }
        .width('100%')
        .margin({ bottom: AppTheme.SPACING_MEDIUM })

        // 方案描述
        Text(scheme.description)
          .fontSize(AppTheme.FONT_SIZE_NORMAL)
          .fontColor(AppTheme.TEXT_SECONDARY)
          .margin({ bottom: AppTheme.SPACING_MEDIUM })

        // 花材列表
        Text('花材搭配')
          .fontSize(AppTheme.FONT_SIZE_MEDIUM)
          .fontColor(AppTheme.TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: AppTheme.SPACING_SMALL })

        Column() {
          ForEach(scheme.flowers, (flower: FlowerItem) => {
            Row() {
              // 花材名称 + 数量
              Text(`${flower.flowerName} ×${flower.quantity}`)
                .fontSize(AppTheme.FONT_SIZE_NORMAL)
                .fontColor(AppTheme.TEXT_PRIMARY)
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)

              // 颜色
              Text(flower.color)
                .fontSize(AppTheme.FONT_SIZE_SMALL)
                .fontColor(AppTheme.TEXT_SECONDARY)
                .margin({ right: AppTheme.SPACING_MEDIUM })

              // 寓意
              Text(flower.meaning)
                .fontSize(AppTheme.FONT_SIZE_SMALL)
                .fontColor(AppTheme.PRIMARY_COLOR)

              // 单价
              Text(`¥${flower.unitPrice * flower.quantity}`)
                .fontSize(AppTheme.FONT_SIZE_SMALL)
                .fontColor(AppTheme.TEXT_SECONDARY)
                .margin({ left: AppTheme.SPACING_SMALL })
            }
            .width('100%')
            .padding({ top: AppTheme.SPACING_SMALL, bottom: AppTheme.SPACING_SMALL })
          }, (flower: FlowerItem) => `${flower.flowerId}`)
        }
        .width('100%')
        .padding(AppTheme.SPACING_SMALL)
        .backgroundColor('#FAFAFA')
        .borderRadius(AppTheme.BORDER_RADIUS_SMALL)
        .margin({ bottom: AppTheme.SPACING_MEDIUM })

        // 花语解读
        Text('花语解读')
          .fontSize(AppTheme.FONT_SIZE_MEDIUM)
          .fontColor(AppTheme.TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: AppTheme.SPACING_SMALL })

        Row() {
          // 装饰引号
          Text('"')
            .fontSize(AppTheme.FONT_SIZE_TITLE)
            .fontColor(AppTheme.PRIMARY_COLOR)
            .fontWeight(FontWeight.Bold)
            .margin({ right: AppTheme.SPACING_SMALL })

          Text(scheme.meaning)
            .fontSize(AppTheme.FONT_SIZE_NORMAL)
            .fontColor(AppTheme.TEXT_PRIMARY)
            .fontStyle(FontStyle.Italic)
            .layoutWeight(1)
            .lineHeight(22)
        }
        .width('100%')
        .padding(AppTheme.SPACING_MEDIUM)
        .backgroundColor(AppTheme.PRIMARY_COLOR_ALPHA20)
        .borderRadius(AppTheme.BORDER_RADIUS_MEDIUM)
        .margin({ bottom: AppTheme.SPACING_MEDIUM })

        // 推荐理由
        if (this.reason) {
          Text('推荐理由')
            .fontSize(AppTheme.FONT_SIZE_MEDIUM)
            .fontColor(AppTheme.TEXT_PRIMARY)
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: AppTheme.SPACING_SMALL })

          Text(this.reason)
            .fontSize(AppTheme.FONT_SIZE_NORMAL)
            .fontColor(AppTheme.TEXT_SECONDARY)
            .lineHeight(22)
            .margin({ bottom: AppTheme.SPACING_MEDIUM })
        }

        // 贺卡文案建议
        Text('贺卡文案建议')
          .fontSize(AppTheme.FONT_SIZE_MEDIUM)
          .fontColor(AppTheme.TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: AppTheme.SPACING_SMALL })

        Row() {
          Text(this.getGreetingText(scheme))
            .fontSize(AppTheme.FONT_SIZE_NORMAL)
            .fontColor(AppTheme.TEXT_PRIMARY)
            .lineHeight(22)
            .layoutWeight(1)

          // 复制按钮
          Text('复制')
            .fontSize(AppTheme.FONT_SIZE_SMALL)
            .fontColor(AppTheme.PRIMARY_COLOR)
            .padding({ left: 10, right: 10, top: 4, bottom: 4 })
            .backgroundColor(AppTheme.PRIMARY_COLOR_ALPHA20)
            .borderRadius(AppTheme.BORDER_RADIUS_SMALL)
            .onClick(() => this.copyGreetingText(this.getGreetingText(scheme)))
        }
        .width('100%')
        .padding(AppTheme.SPACING_MEDIUM)
        .backgroundColor('#FAFAFA')
        .borderRadius(AppTheme.BORDER_RADIUS_MEDIUM)

        // 复制成功提示
        if (this.copyTip) {
          Text(this.copyTip)
            .fontSize(AppTheme.FONT_SIZE_SMALL)
            .fontColor(AppTheme.SUCCESS_COLOR)
            .margin({ top: AppTheme.SPACING_SMALL })
            .textAlign(TextAlign.Center)
        }
      }
      .width('100%')
      .padding(AppTheme.SPACING_MEDIUM)
    }
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Auto)
    .edgeEffect(EdgeEffect.Spring)
  }

  // ==================== 主构建函数 ====================

  build() {
    Column() {
      // 顶部标题栏
      Row() {
        // 返回按钮
        Text('<')
          .fontSize(AppTheme.FONT_SIZE_LARGE)
          .fontColor(AppTheme.TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .padding(AppTheme.SPACING_SMALL)
          .onClick(() => {
            router.back();
          })

        Text('为TA定制的花束方案')
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

      // 方案Swiper
      Swiper() {
        ForEach(this.schemes, (scheme: BouquetScheme) => {
          this.SchemeCard(scheme)
        }, (scheme: BouquetScheme) => `${scheme.id}`)
      }
      .width('100%')
      .layoutWeight(1)
      .indicator(true)
      .loop(false)
      .onChange((index: number) => {
        this.currentSchemeIndex = index;
      })

      // 底部按钮组
      Column() {
        Row() {
          CommonButton({
            text: '换一批方案',
            type: CustomButtonType.OUTLINE,
            size: ButtonSize.LARGE,
            disabled: this.isLoading,
            onClick: () => this.refreshSchemes()
          })
          .width('45%')

          CommonButton({
            text: '加入购物车',
            type: CustomButtonType.PRIMARY,
            size: ButtonSize.LARGE,
            onClick: () => {
              if (this.schemes.length > 0) {
                this.selectScheme(this.schemes[this.currentSchemeIndex]);
              }
            }
          })
          .width('45%')
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)

        CommonButton({
          text: '直接下单',
          type: CustomButtonType.OUTLINE,
          size: ButtonSize.LARGE,
          onClick: () => {
            if (this.schemes.length > 0) {
              this.selectSchemeDirect(this.schemes[this.currentSchemeIndex]);
            }
          }
        })
        .width('100%')
        .margin({ top: AppTheme.SPACING_SMALL })
      }
      .width('100%')
      .padding({ left: AppTheme.SPACING_MEDIUM, right: AppTheme.SPACING_MEDIUM, top: AppTheme.SPACING_SMALL, bottom: AppTheme.SPACING_MEDIUM })
      .backgroundColor(AppTheme.CARD_BACKGROUND)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppTheme.BACKGROUND_COLOR)
  }
}
