import { AppTheme } from '../common/Theme';
import { SceneSelector } from '../components/SceneSelector';
import { FlowerCard } from '../components/FlowerCard';
import { SceneType } from '../models/RecommendModel';
import { FlowerInfo } from '../models/FlowerModel';
import { ApiService } from '../services/ApiService';
import { BANNER_INTERVAL } from '../utils/Constants';

@Entry
@Component
export struct HomePage {
  @State searchKeyword: string = '';
  @State hotFlowers: FlowerInfo[] = [];
  @State isLoading: boolean = false;

  private bannerData: string[] = [
    '🌸 春日樱花季 - 浪漫之选',
    '🌹 经典红玫瑰 - 永恒的爱',
    '🌻 向日葵季 - 阳光祝福',
  ];

  private onSceneSelect(scene: SceneType): void {
    AppStorage.setOrCreate('selectedScene', scene);
    AppStorage.setOrCreate('currentTab', 1);
  }

  private async loadHotFlowers(): Promise<void> {
    this.isLoading = true;
    try {
      const response = await ApiService.getFlowers({ page: 1, pageSize: 10 });
      this.hotFlowers = response.flowers;
    } catch (error) {
      console.error('Failed to load flowers:', JSON.stringify(error));
    }
    this.isLoading = false;
  }

  aboutToAppear() {
    this.loadHotFlowers();
  }

  build() {
    Column() {
      // Search bar
      Row() {
        TextInput({ placeholder: '搜索花材...', text: this.searchKeyword })
          .width('85%')
          .height(40)
          .fontSize(AppTheme.FONT_SIZE_NORMAL)
          .fontColor(AppTheme.TEXT_PRIMARY)
          .placeholderColor(AppTheme.TEXT_SECONDARY)
          .backgroundColor(AppTheme.CARD_BACKGROUND)
          .borderRadius(AppTheme.BORDER_RADIUS_MEDIUM)
          .padding({ left: 12, right: 12 })
          .onChange((value: string) => { this.searchKeyword = value; })

        Text('🔍')
          .fontSize(20)
          .margin({ left: AppTheme.SPACING_SMALL })
          .onClick(() => {
            if (this.searchKeyword.trim()) {
              AppStorage.setOrCreate('searchKeyword', this.searchKeyword.trim());
              AppStorage.setOrCreate('currentTab', 2);
            }
          })
      }
      .width('100%')
      .padding({ left: AppTheme.SPACING_MEDIUM, right: AppTheme.SPACING_MEDIUM, top: AppTheme.SPACING_SMALL })

      Scroll() {
        Column() {
          // Banner
          Swiper() {
            ForEach(this.bannerData, (item: string) => {
              Column() {
                Text(item)
                  .fontSize(AppTheme.FONT_SIZE_LARGE)
                  .fontColor('#FFFFFF')
                  .fontWeight(FontWeight.Bold)
              }
              .width('100%')
              .height(140)
              .justifyContent(FlexAlign.Center)
              .backgroundColor(AppTheme.PRIMARY_COLOR)
              .borderRadius(AppTheme.BORDER_RADIUS_MEDIUM)
            }, (item: string) => item)
          }
          .width('100%')
          .height(140)
          .autoPlay(true)
          .interval(BANNER_INTERVAL)
          .indicator(true)
          .loop(true)
          .margin({ top: AppTheme.SPACING_MEDIUM })

          // Scene selector
          Text('选择送花场景')
            .fontSize(AppTheme.FONT_SIZE_MEDIUM)
            .fontColor(AppTheme.TEXT_PRIMARY)
            .fontWeight(FontWeight.Bold)
            .margin({ top: AppTheme.SPACING_LARGE })

          SceneSelector({ onSceneSelect: (scene: SceneType) => this.onSceneSelect(scene) })
            .margin({ top: AppTheme.SPACING_SMALL, left: AppTheme.SPACING_MEDIUM, right: AppTheme.SPACING_MEDIUM })

          // Hot flowers
          Text('热门推荐')
            .fontSize(AppTheme.FONT_SIZE_MEDIUM)
            .fontColor(AppTheme.TEXT_PRIMARY)
            .fontWeight(FontWeight.Bold)
            .margin({ top: AppTheme.SPACING_LARGE })
            .padding({ left: AppTheme.SPACING_MEDIUM })
            .alignSelf(ItemAlign.Start)

          if (this.isLoading) {
            Text('加载中...')
              .fontSize(AppTheme.FONT_SIZE_NORMAL)
              .fontColor(AppTheme.TEXT_SECONDARY)
              .margin({ top: AppTheme.SPACING_LARGE })
          } else if (this.hotFlowers.length > 0) {
            Grid() {
              ForEach(this.hotFlowers, (flower: FlowerInfo) => {
                GridItem() {
                  FlowerCard({ flower: flower })
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
