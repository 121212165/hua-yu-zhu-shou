// 首页 - 包含搜索栏、Banner、场景快捷入口、热门推荐

import { AppTheme } from '../common/Theme';
import { SceneSelector } from '../components/SceneSelector';
import { FlowerCard } from '../components/FlowerCard';
import { SceneType } from '../models/RecommendModel';
import { FlowerInfo, FlowerCategory, FlowerColor } from '../models/FlowerModel';
import { ApiService } from '../services/ApiService';
import { BANNER_INTERVAL } from '../utils/Constants';
import { CartStore } from '../store/CartStore';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';

@Entry
@Component
export struct HomePage {
  // 搜索关键词
  @State searchKeyword: string = '';
  // Banner当前索引
  @State bannerIndex: number = 0;
  // 热门花材列表
  @State hotFlowers: FlowerInfo[] = [];
  // 是否正在加载
  @State isLoading: boolean = false;

  // Banner数据（模拟当季推荐）
  private bannerData: string[] = [
    '🌸 春日樱花季 - 浪漫之选',
    '🌹 经典红玫瑰 - 永恒的爱',
    '🌻 向日葵季 - 阳光祝福',
    '🌷 郁金香季 - 优雅之选'
  ];

  // 场景选择回调 - 切换到推荐Tab并预选场景
  private onSceneSelect(scene: SceneType): void {
    AppStorage.setOrCreate('selectedScene', scene);
    AppStorage.setOrCreate('currentTab', 1);
  }

  // 花材卡片点击回调 - 加入购物车
  private onFlowerClick(flower: FlowerInfo): void {
    console.info(`点击花材: ${flower.name}`);
    CartStore.addItem({
      id: flower.id,
      name: flower.name,
      description: flower.description,
      flowers: [{ flowerId: flower.id, flowerName: flower.name, quantity: 1, unitPrice: flower.price, color: flower.color, meaning: flower.meaning }],
      totalPrice: flower.price,
      style: '简约',
      meaning: flower.meaning,
      imageUrl: flower.imageUrl,
      matchScore: flower.popularity
    });
    promptAction.showToast({ message: `${flower.name} 已加入购物车`, duration: 1500 });
  }

  // 加载热门花材数据
  private async loadHotFlowers(): Promise<void> {
    this.isLoading = true;
    try {
      const response = await ApiService.getFlowers({
        page: 1,
        pageSize: 10
      });
      this.hotFlowers = response.flowers;
    } catch (error) {
      console.error('加载花材数据失败:', JSON.stringify(error));
      // 使用模拟数据
      this.hotFlowers = this.getMockFlowers();
    }
    this.isLoading = false;
  }

  // 模拟花材数据（开发阶段使用）
  private getMockFlowers(): FlowerInfo[] {
    return [
      {
        id: 1, name: '红玫瑰', category: FlowerCategory.ROSE, color: FlowerColor.RED,
        description: '经典红玫瑰，表达热烈的爱', meaning: '热烈的爱',
        price: 8, season: '全年', imageUrl: '', popularity: 95,
        createdAt: '', updatedAt: ''
      },
      {
        id: 2, name: '粉色康乃馨', category: FlowerCategory.CARNATION, color: FlowerColor.PINK,
        description: '温馨的粉色康乃馨，送给妈妈', meaning: '母爱、温馨',
        price: 5, season: '全年', imageUrl: '', popularity: 88,
        createdAt: '', updatedAt: ''
      },
      {
        id: 3, name: '白百合', category: FlowerCategory.LILY, color: FlowerColor.WHITE,
        description: '纯洁优雅的白百合', meaning: '纯洁、高贵',
        price: 12, season: '全年', imageUrl: '', popularity: 82,
        createdAt: '', updatedAt: ''
      },
      {
        id: 4, name: '向日葵', category: FlowerCategory.SUNFLOWER, color: FlowerColor.YELLOW,
        description: '阳光灿烂的向日葵', meaning: '阳光、希望',
        price: 6, season: '夏季', imageUrl: '', popularity: 78,
        createdAt: '', updatedAt: ''
      },
      {
        id: 5, name: '紫色绣球', category: FlowerCategory.HYDRANGEA, color: FlowerColor.PURPLE,
        description: '梦幻的紫色绣球花', meaning: '浪漫、梦幻',
        price: 15, season: '夏季', imageUrl: '', popularity: 75,
        createdAt: '', updatedAt: ''
      },
      {
        id: 6, name: '粉色郁金香', category: FlowerCategory.TULIP, color: FlowerColor.PINK,
        description: '优雅的粉色郁金香', meaning: '幸福、美好',
        price: 10, season: '春季', imageUrl: '', popularity: 70,
        createdAt: '', updatedAt: ''
      }
    ];
  }

  aboutToAppear() {
    this.loadHotFlowers();
  }

  build() {
    Column() {
      // 顶部搜索栏
      Row() {
        // 搜索输入框
        TextInput({ placeholder: '搜索花材或场景...', text: this.searchKeyword })
          .width('85%')
          .height(40)
          .fontSize(AppTheme.FONT_SIZE_NORMAL)
          .fontColor(AppTheme.TEXT_PRIMARY)
          .placeholderColor(AppTheme.TEXT_SECONDARY)
          .backgroundColor(AppTheme.CARD_BACKGROUND)
          .borderRadius(AppTheme.BORDER_RADIUS_MEDIUM)
          .padding({ left: 12, right: 12 })
          .onChange((value: string) => {
            this.searchKeyword = value;
          })

        // 搜索按钮
        Text('🔍')
          .fontSize(20)
          .margin({ left: AppTheme.SPACING_SMALL })
          .onClick(() => {
            console.info(`搜索: ${this.searchKeyword}`);
          })
      }
      .width('100%')
      .padding({ left: AppTheme.SPACING_MEDIUM, right: AppTheme.SPACING_MEDIUM, top: AppTheme.SPACING_SMALL })
      .justifyContent(FlexAlign.Center)

      // 内容滚动区域
      Scroll() {
        Column() {
          // Banner区域 - 当季推荐 Swiper
          Swiper() {
            ForEach(this.bannerData, (item: string) => {
              // Banner项
              Column() {
                Text(item)
                  .fontSize(AppTheme.FONT_SIZE_LARGE)
                  .fontColor('#FFFFFF')
                  .fontWeight(FontWeight.Bold)
                  .textAlign(TextAlign.Center)
              }
              .width('100%')
              .height(160)
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
              .backgroundColor(AppTheme.PRIMARY_COLOR)
              .borderRadius(AppTheme.BORDER_RADIUS_MEDIUM)
              .padding(AppTheme.SPACING_LARGE)
            }, (item: string) => item)
          }
          .width('100%')
          .height(160)
          .autoPlay(true)
          .interval(BANNER_INTERVAL)
          .indicator(true)
          .loop(true)
          .borderRadius(AppTheme.BORDER_RADIUS_MEDIUM)
          .margin({ top: AppTheme.SPACING_MEDIUM })

          // 场景快捷入口标题
          Text('选择送花场景')
            .fontSize(AppTheme.FONT_SIZE_MEDIUM)
            .fontColor(AppTheme.TEXT_PRIMARY)
            .fontWeight(FontWeight.Bold)
            .margin({ top: AppTheme.SPACING_LARGE })
            .padding({ left: AppTheme.SPACING_MEDIUM })

          // 场景选择器 Grid（6个场景：生日、表白、纪念日、道歉、感谢、探望）
          SceneSelector({
            onSceneSelect: (scene: SceneType) => {
              this.onSceneSelect(scene);
            }
          })
          .margin({ top: AppTheme.SPACING_SMALL, left: AppTheme.SPACING_MEDIUM, right: AppTheme.SPACING_MEDIUM })

          // 热门推荐标题
          Row() {
            Text('热门推荐')
              .fontSize(AppTheme.FONT_SIZE_MEDIUM)
              .fontColor(AppTheme.TEXT_PRIMARY)
              .fontWeight(FontWeight.Bold)

            Text('查看更多 >')
              .fontSize(AppTheme.FONT_SIZE_SMALL)
              .fontColor(AppTheme.PRIMARY_COLOR)
              .margin({ left: AppTheme.SPACING_SMALL })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .padding({ left: AppTheme.SPACING_MEDIUM, right: AppTheme.SPACING_MEDIUM })
          .margin({ top: AppTheme.SPACING_LARGE })

          // 热门花材列表
          if (this.isLoading) {
            // 加载状态
            Column() {
              Text('加载中...')
                .fontSize(AppTheme.FONT_SIZE_NORMAL)
                .fontColor(AppTheme.TEXT_SECONDARY)
            }
            .width('100%')
            .height(200)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
          } else {
            // 花材卡片列表 - 2列网格布局
            Grid() {
              ForEach(this.hotFlowers, (flower: FlowerInfo) => {
                GridItem() {
                  FlowerCard({
                    flower: flower,
                    onCardClick: (f: FlowerInfo) => {
                      this.onFlowerClick(f);
                    }
                  })
                }
              }, (flower: FlowerInfo) => `${flower.id}`)
            }
            .columnsTemplate('1fr 1fr')
            .rowsGap(AppTheme.SPACING_MEDIUM)
            .columnsGap(AppTheme.SPACING_MEDIUM)
            .width('100%')
            .padding(AppTheme.SPACING_MEDIUM)
          }
        }
        .width('100%')
      }
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppTheme.BACKGROUND_COLOR)
  }
}
