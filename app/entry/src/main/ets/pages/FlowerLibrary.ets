import { AppTheme } from '../common/Theme';
import { FlowerCard } from '../components/FlowerCard';
import { FlowerInfo, FlowerCategory, FlowerColor, GetFlowersParams } from '../models/FlowerModel';
import { ApiService } from '../services/ApiService';

interface FilterTag { label: string; value: string; }

const COLOR_FILTERS: FilterTag[] = [
  { label: '全部', value: '' }, { label: '红色', value: FlowerColor.RED }, { label: '粉色', value: FlowerColor.PINK },
  { label: '白色', value: FlowerColor.WHITE }, { label: '黄色', value: FlowerColor.YELLOW }, { label: '紫色', value: FlowerColor.PURPLE },
];

const CATEGORY_FILTERS: FilterTag[] = [
  { label: '全部', value: '' }, { label: '玫瑰', value: FlowerCategory.ROSE }, { label: '百合', value: FlowerCategory.LILY },
  { label: '康乃馨', value: FlowerCategory.CARNATION }, { label: '向日葵', value: FlowerCategory.SUNFLOWER },
];

@Entry
@Component
struct FlowerLibrary {
  @State flowerList: FlowerInfo[] = [];
  @State searchKeyword: string = '';
  @State selectedColor: string = '';
  @State selectedCategory: string = '';
  @State isLoading: boolean = false;
  @State currentPage: number = 1;
  @State hasMore: boolean = true;
  @State filterType: number = 0;

  private async loadFlowers(reset: boolean = false): Promise<void> {
    if (this.isLoading) return;
    this.isLoading = true;
    if (reset) { this.currentPage = 1; this.hasMore = true; }

    try {
      const params: GetFlowersParams = { page: this.currentPage, pageSize: 12 };
      if (this.selectedColor) params.color = this.selectedColor as FlowerColor;
      if (this.selectedCategory) params.category = this.selectedCategory as FlowerCategory;
      if (this.searchKeyword) params.keyword = this.searchKeyword;

      const response = await ApiService.getFlowers(params);
      if (reset) this.flowerList = response.flowers;
      else this.flowerList = [...this.flowerList, ...response.flowers];
      this.hasMore = response.flowers.length >= 12;
    } catch (error) {
      console.error('Load flowers failed:', JSON.stringify(error));
    }
    this.isLoading = false;
  }

  aboutToAppear() { this.loadFlowers(true); }

  build() {
    Column() {
      // Search
      Row() {
        TextInput({ placeholder: '搜索花材...', text: this.searchKeyword })
          .width('85%')
          .height(40)
          .fontSize(AppTheme.FONT_SIZE_NORMAL)
          .fontColor(AppTheme.TEXT_PRIMARY)
          .backgroundColor(AppTheme.CARD_BACKGROUND)
          .borderRadius(AppTheme.BORDER_RADIUS_MEDIUM)
          .padding({ left: 12, right: 12 })
          .onChange((value: string) => { this.searchKeyword = value; })
          .onSubmit(() => this.loadFlowers(true))

        Text('🔍')
          .fontSize(22)
          .margin({ left: AppTheme.SPACING_SMALL })
          .onClick(() => this.loadFlowers(true))
      }
      .width('100%')
      .padding({ left: AppTheme.SPACING_MEDIUM, right: AppTheme.SPACING_MEDIUM, top: AppTheme.SPACING_SMALL })

      // Filter tabs
      Row() {
        Text('颜色')
          .fontSize(AppTheme.FONT_SIZE_NORMAL)
          .fontColor(this.filterType === 0 ? AppTheme.PRIMARY_COLOR : AppTheme.TEXT_SECONDARY)
          .fontWeight(this.filterType === 0 ? FontWeight.Bold : FontWeight.Normal)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor(this.filterType === 0 ? AppTheme.PRIMARY_COLOR_ALPHA20 : Color.Transparent)
          .borderRadius(AppTheme.BORDER_RADIUS_SMALL)
          .onClick(() => { this.filterType = 0; })

        Text('类别')
          .fontSize(AppTheme.FONT_SIZE_NORMAL)
          .fontColor(this.filterType === 1 ? AppTheme.PRIMARY_COLOR : AppTheme.TEXT_SECONDARY)
          .fontWeight(this.filterType === 1 ? FontWeight.Bold : FontWeight.Normal)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor(this.filterType === 1 ? AppTheme.PRIMARY_COLOR_ALPHA20 : Color.Transparent)
          .borderRadius(AppTheme.BORDER_RADIUS_SMALL)
          .margin({ left: AppTheme.SPACING_SMALL })
          .onClick(() => { this.filterType = 1; })
      }
      .width('100%')
      .padding({ left: AppTheme.SPACING_MEDIUM, top: AppTheme.SPACING_SMALL, bottom: AppTheme.SPACING_SMALL })

      // Filter tags
      Scroll() {
        Row() {
          ForEach(this.filterType === 0 ? COLOR_FILTERS : CATEGORY_FILTERS, (tag: FilterTag) => {
            Text(tag.label)
              .fontSize(AppTheme.FONT_SIZE_SMALL)
              .fontColor((this.filterType === 0 ? this.selectedColor : this.selectedCategory) === tag.value ? '#FFFFFF' : AppTheme.TEXT_PRIMARY)
              .backgroundColor((this.filterType === 0 ? this.selectedColor : this.selectedCategory) === tag.value ? AppTheme.PRIMARY_COLOR : AppTheme.CARD_BACKGROUND)
              .borderRadius(AppTheme.BORDER_RADIUS_CIRCLE)
              .padding({ left: 14, right: 14, top: 6, bottom: 6 })
              .margin({ right: AppTheme.SPACING_SMALL })
              .onClick(() => {
                if (this.filterType === 0) this.selectedColor = tag.value;
                else this.selectedCategory = tag.value;
                this.loadFlowers(true);
              })
          }, (tag: FilterTag) => tag.value)
        }
        .padding({ left: AppTheme.SPACING_MEDIUM })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')

      // Flower grid
      if (this.isLoading && this.flowerList.length === 0) {
        Text('加载中...')
          .fontSize(AppTheme.FONT_SIZE_NORMAL)
          .fontColor(AppTheme.TEXT_SECONDARY)
          .margin({ top: AppTheme.SPACING_XLARGE })
      } else {
        Scroll() {
          Column() {
            Grid() {
              ForEach(this.flowerList, (flower: FlowerInfo) => {
                GridItem() { FlowerCard({ flower: flower }) }
              }, (flower: FlowerInfo) => `${flower.id}`)
            }
            .columnsTemplate('1fr 1fr')
            .rowsGap(AppTheme.SPACING_MEDIUM)
            .columnsGap(AppTheme.SPACING_MEDIUM)
            .width('100%')

            if (this.hasMore) {
              Text('加载更多...')
                .fontSize(AppTheme.FONT_SIZE_SMALL)
                .fontColor(AppTheme.TEXT_SECONDARY)
                .margin({ top: AppTheme.SPACING_SMALL })
            }
          }
          .padding(AppTheme.SPACING_MEDIUM)
        }
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Auto)
        .layoutWeight(1)
        .onReachEnd(() => {
          if (this.hasMore && !this.isLoading) { this.currentPage++; this.loadFlowers(false); }
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppTheme.BACKGROUND_COLOR)
  }
}
