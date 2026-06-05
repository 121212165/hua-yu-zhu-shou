// 花材库页面 - 花材浏览、搜索、筛选、详情

import { AppTheme } from '../common/Theme';
import { FlowerCard } from '../components/FlowerCard';
import { FlowerInfo, FlowerCategory, FlowerColor, GetFlowersParams } from '../models/FlowerModel';
import { ApiService } from '../services/ApiService';

// 筛选标签数据结构
interface FilterTag {
  label: string;
  value: string;
}

// 颜色筛选标签
const COLOR_FILTERS: FilterTag[] = [
  { label: '全部', value: '' },
  { label: '红色', value: FlowerColor.RED },
  { label: '粉色', value: FlowerColor.PINK },
  { label: '白色', value: FlowerColor.WHITE },
  { label: '黄色', value: FlowerColor.YELLOW },
  { label: '紫色', value: FlowerColor.PURPLE },
  { label: '蓝色', value: FlowerColor.BLUE }
];

// 类别筛选标签
const CATEGORY_FILTERS: FilterTag[] = [
  { label: '全部', value: '' },
  { label: '玫瑰', value: FlowerCategory.ROSE },
  { label: '百合', value: FlowerCategory.LILY },
  { label: '康乃馨', value: FlowerCategory.CARNATION },
  { label: '向日葵', value: FlowerCategory.SUNFLOWER },
  { label: '其他', value: FlowerCategory.OTHER }
];

// 季节筛选标签
const SEASON_FILTERS: FilterTag[] = [
  { label: '全部', value: '' },
  { label: '春季', value: '春季' },
  { label: '夏季', value: '夏季' },
  { label: '秋季', value: '秋季' },
  { label: '冬季', value: '冬季' },
  { label: '四季', value: '全年' }
];

// 花材详情弹窗
@CustomDialog
struct FlowerDetailDialog {
  controller: CustomDialogController;
  @Prop flower: FlowerInfo;
  @State isFavorited: boolean = false;

  // 花材英文名映射
  private englishNameMap: Record<string, string> = {
    '红玫瑰': 'Red Rose', '粉玫瑰': 'Pink Rose', '白玫瑰': 'White Rose',
    '黄玫瑰': 'Yellow Rose', '白百合': 'White Lily', '粉色康乃馨': 'Pink Carnation',
    '向日葵': 'Sunflower', '紫色绣球': 'Purple Hydrangea', '粉色郁金香': 'Pink Tulip',
    '牡丹': 'Peony', '兰花': 'Orchid', '菊花': 'Chrysanthemum',
    '红康乃馨': 'Red Carnation', '蓝色绣球': 'Blue Hydrangea', '白郁金香': 'White Tulip'
  };

  // 养护建议映射
  private careAdviceMap: Record<string, string> = {
    [FlowerCategory.ROSE]: '斜切花枝，每日换水，避免阳光直射，可加入保鲜剂延长花期',
    [FlowerCategory.LILY]: '去除下部叶片，深水养护，避免与水果同放，花粉勿沾染衣物',
    [FlowerCategory.CARNATION]: '浅水养护，避免向花头喷水，远离暖气和空调出风口',
    [FlowerCategory.SUNFLOWER]: '深水养护，每天换水剪根，适合通风阴凉处摆放',
    [FlowerCategory.HYDRANGEA]: '深水浸泡，整枝倒置入水恢复活力，避免强光照射',
    [FlowerCategory.TULIP]: '少量清水，包住花头整形，避免与水仙同瓶',
    [FlowerCategory.OTHER]: '清水养护，定期换水剪根，摆放于阴凉通风处'
  };

  // 适合场景映射
  private sceneMap: Record<string, string[]> = {
    [FlowerCategory.ROSE]: ['表白', '纪念日', '求婚', '婚礼'],
    [FlowerCategory.LILY]: ['婚礼', '探望', '慰问', '乔迁'],
    [FlowerCategory.CARNATION]: ['母亲节', '感恩', '探望', '教师节'],
    [FlowerCategory.SUNFLOWER]: ['生日', '祝贺', '毕业', '开业'],
    [FlowerCategory.HYDRANGEA]: ['婚礼', '表白', '纪念日', '装饰'],
    [FlowerCategory.TULIP]: ['表白', '春季祝福', '乔迁', '装饰'],
    [FlowerCategory.OTHER]: ['日常', '祝福', '装饰', '慰问']
  };

  private getEnglishName(): string {
    return this.englishNameMap[this.flower.name] || this.flower.name;
  }

  private getCareAdvice(): string {
    return this.careAdviceMap[this.flower.category] || this.careAdviceMap[FlowerCategory.OTHER] || '';
  }

  private getScenes(): string[] {
    return this.sceneMap[this.flower.category] || this.sceneMap[FlowerCategory.OTHER] || [];
  }

  build() {
    Scroll() {
      Column() {
        // 顶部关闭按钮
        Row() {
          Text('✕')
            .fontSize(20)
            .fontColor(AppTheme.TEXT_SECONDARY)
            .padding(AppTheme.SPACING_SMALL)
            .onClick(() => {
              this.controller.close();
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.End)
        .padding({ right: AppTheme.SPACING_SMALL, top: AppTheme.SPACING_SMALL })

        // 花材大图
        Image(this.flower.imageUrl || '')
          .width('100%')
          .height(220)
          .objectFit(ImageFit.Cover)
          .borderRadius(AppTheme.BORDER_RADIUS_MEDIUM)
          .backgroundColor(AppTheme.DIVIDER_COLOR)

        // 名称（中英文）
        Column() {
          Text(this.flower.name)
            .fontSize(AppTheme.FONT_SIZE_XLARGE)
            .fontColor(AppTheme.TEXT_PRIMARY)
            .fontWeight(FontWeight.Bold)

          Text(this.getEnglishName())
            .fontSize(AppTheme.FONT_SIZE_NORMAL)
            .fontColor(AppTheme.TEXT_SECONDARY)
            .margin({ top: AppTheme.SPACING_SMALL / 2 })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .margin({ top: AppTheme.SPACING_MEDIUM })

        // 分割线
        Divider()
          .color(AppTheme.DIVIDER_COLOR)
          .margin({ top: AppTheme.SPACING_MEDIUM, bottom: AppTheme.SPACING_MEDIUM })

        // 花语详解
        this.DetailSectionBuilder('🌸 花语详解', this.flower.meaning)

        // 适合场景
        this.DetailSectionBuilder('🎯 适合场景', this.getScenes().join('、'))

        // 当前价格
        Row() {
          Text('💰 当前价格')
            .fontSize(AppTheme.FONT_SIZE_NORMAL)
            .fontColor(AppTheme.TEXT_PRIMARY)
            .fontWeight(FontWeight.Medium)

          Text(`¥${this.flower.price}/支`)
            .fontSize(AppTheme.FONT_SIZE_MEDIUM)
            .fontColor(AppTheme.ACCENT_COLOR)
            .fontWeight(FontWeight.Bold)
            .margin({ left: AppTheme.SPACING_SMALL })
        }
        .width('100%')
        .margin({ top: AppTheme.SPACING_SMALL })

        // 可用季节
        this.DetailSectionBuilder('📅 可用季节', this.flower.season || '全年')

        // 养护建议
        this.DetailSectionBuilder('🌿 养护建议', this.getCareAdvice())

        // 加入收藏按钮
        Button(this.isFavorited ? '已收藏 ♥' : '加入收藏')
          .width('100%')
          .height(44)
          .fontSize(AppTheme.FONT_SIZE_MEDIUM)
          .fontColor('#FFFFFF')
          .backgroundColor(this.isFavorited ? AppTheme.SECONDARY_COLOR : AppTheme.PRIMARY_COLOR)
          .borderRadius(AppTheme.BORDER_RADIUS_MEDIUM)
          .margin({ top: AppTheme.SPACING_LARGE, bottom: AppTheme.SPACING_LARGE })
          .onClick(() => {
            this.isFavorited = !this.isFavorited;
          })
      }
      .padding(AppTheme.SPACING_MEDIUM)
    }
    .width('100%')
    .height('85%')
    .backgroundColor(AppTheme.CARD_BACKGROUND)
    .borderRadius({ topLeft: AppTheme.BORDER_RADIUS_LARGE, topRight: AppTheme.BORDER_RADIUS_LARGE })
  }

  @Builder
  DetailSectionBuilder(title: string, content: string) {
    Column() {
      Text(title)
        .fontSize(AppTheme.FONT_SIZE_NORMAL)
        .fontColor(AppTheme.TEXT_PRIMARY)
        .fontWeight(FontWeight.Medium)
        .width('100%')

      Text(content)
        .fontSize(AppTheme.FONT_SIZE_NORMAL)
        .fontColor(AppTheme.TEXT_SECONDARY)
        .margin({ top: AppTheme.SPACING_SMALL / 2 })
        .width('100%')
    }
    .width('100%')
    .margin({ top: AppTheme.SPACING_SMALL })
    .alignItems(HorizontalAlign.Start)
  }
}

@Entry
@Component
struct FlowerLibrary {
  // 花材列表
  @State flowerList: FlowerInfo[] = [];
  // 搜索关键词
  @State searchKeyword: string = '';
  // 当前颜色筛选
  @State selectedColor: string = '';
  // 当前类别筛选
  @State selectedCategory: string = '';
  // 当前季节筛选
  @State selectedSeason: string = '';
  // 是否正在加载
  @State isLoading: boolean = false;
  // 当前页码
  @State currentPage: number = 1;
  // 是否还有更多数据
  @State hasMore: boolean = true;
  // 当前查看的花材
  @State currentFlower: FlowerInfo | null = null;
  // 筛选类型切换：0=颜色 1=类别 2=季节
  @State filterType: number = 0;

  // 详情弹窗控制器
  private detailDialogController: CustomDialogController = new CustomDialogController({
    builder: FlowerDetailDialog({ flower: { id: 0, name: '', category: FlowerCategory.OTHER, color: FlowerColor.RED, description: '', meaning: '', price: 0, season: '', imageUrl: '', popularity: 0, createdAt: '', updatedAt: '' } }),
    autoCancel: true,
    alignment: DialogAlignment.Bottom,
    customStyle: true
  });

  // 模拟花材数据
  private getMockFlowers(): FlowerInfo[] {
    return [
      { id: 1, name: '红玫瑰', category: FlowerCategory.ROSE, color: FlowerColor.RED, description: '经典红玫瑰，表达热烈的爱', meaning: '热烈的爱、我爱你', price: 8, season: '全年', imageUrl: '', popularity: 95, createdAt: '', updatedAt: '' },
      { id: 2, name: '粉玫瑰', category: FlowerCategory.ROSE, color: FlowerColor.PINK, description: '温柔粉玫瑰，表达初恋般的心动', meaning: '初恋、感动', price: 8, season: '全年', imageUrl: '', popularity: 90, createdAt: '', updatedAt: '' },
      { id: 3, name: '白玫瑰', category: FlowerCategory.ROSE, color: FlowerColor.WHITE, description: '纯洁白玫瑰，象征天真与尊敬', meaning: '纯洁、尊敬', price: 10, season: '全年', imageUrl: '', popularity: 85, createdAt: '', updatedAt: '' },
      { id: 4, name: '粉色康乃馨', category: FlowerCategory.CARNATION, color: FlowerColor.PINK, description: '温馨的粉色康乃馨，送给妈妈', meaning: '母爱、温馨', price: 5, season: '全年', imageUrl: '', popularity: 88, createdAt: '', updatedAt: '' },
      { id: 5, name: '白百合', category: FlowerCategory.LILY, color: FlowerColor.WHITE, description: '纯洁优雅的白百合', meaning: '纯洁、高贵、百年好合', price: 12, season: '全年', imageUrl: '', popularity: 82, createdAt: '', updatedAt: '' },
      { id: 6, name: '向日葵', category: FlowerCategory.SUNFLOWER, color: FlowerColor.YELLOW, description: '阳光灿烂的向日葵', meaning: '阳光、希望、崇拜', price: 6, season: '夏季', imageUrl: '', popularity: 78, createdAt: '', updatedAt: '' },
      { id: 7, name: '紫色绣球', category: FlowerCategory.HYDRANGEA, color: FlowerColor.PURPLE, description: '梦幻的紫色绣球花', meaning: '浪漫、梦幻、团聚', price: 15, season: '夏季', imageUrl: '', popularity: 75, createdAt: '', updatedAt: '' },
      { id: 8, name: '粉色郁金香', category: FlowerCategory.TULIP, color: FlowerColor.PINK, description: '优雅的粉色郁金香', meaning: '幸福、美好', price: 10, season: '春季', imageUrl: '', popularity: 70, createdAt: '', updatedAt: '' },
      { id: 9, name: '黄玫瑰', category: FlowerCategory.ROSE, color: FlowerColor.YELLOW, description: '明亮的黄玫瑰，象征友谊', meaning: '友谊、祝福', price: 8, season: '全年', imageUrl: '', popularity: 65, createdAt: '', updatedAt: '' },
      { id: 10, name: '蓝色绣球', category: FlowerCategory.HYDRANGEA, color: FlowerColor.BLUE, description: '清新的蓝色绣球花', meaning: '浪漫、圆满', price: 18, season: '夏季', imageUrl: '', popularity: 72, createdAt: '', updatedAt: '' },
      { id: 11, name: '红康乃馨', category: FlowerCategory.CARNATION, color: FlowerColor.RED, description: '热情红康乃馨，表达深深的爱', meaning: '深深的爱、关怀', price: 5, season: '全年', imageUrl: '', popularity: 68, createdAt: '', updatedAt: '' },
      { id: 12, name: '白郁金香', category: FlowerCategory.TULIP, color: FlowerColor.WHITE, description: '纯洁白郁金香', meaning: '纯真、宽恕', price: 12, season: '春季', imageUrl: '', popularity: 60, createdAt: '', updatedAt: '' }
    ];
  }

  // 加载花材数据
  private async loadFlowers(reset: boolean = false): Promise<void> {
    if (this.isLoading) {
      return;
    }
    if (!reset && !this.hasMore) {
      return;
    }

    this.isLoading = true;
    if (reset) {
      this.currentPage = 1;
      this.hasMore = true;
    }

    try {
      const params: GetFlowersParams = {
        page: this.currentPage,
        pageSize: 12
      };
      if (this.selectedColor) {
        params.color = this.selectedColor as FlowerColor;
      }
      if (this.selectedCategory) {
        params.category = this.selectedCategory as FlowerCategory;
      }
      if (this.searchKeyword) {
        params.keyword = this.searchKeyword;
      }
      const response = await ApiService.getFlowers(params);
      if (reset) {
        this.flowerList = response.flowers;
      } else {
        this.flowerList = [...this.flowerList, ...response.flowers];
      }
      this.hasMore = response.flowers.length >= 12;
    } catch (error) {
      console.error('加载花材数据失败:', JSON.stringify(error));
      if (reset) {
        this.flowerList = this.getMockFlowers();
      } else {
        this.flowerList = [...this.flowerList, ...this.getMockFlowers().slice(0, 4).map(f => ({
          ...f, id: this.flowerList.length + f.id
        }))];
        this.hasMore = false;
      }
    }

    this.isLoading = false;
  }

  // 点击花材卡片 - 打开详情弹窗
  private onFlowerClick(flower: FlowerInfo): void {
    this.currentFlower = flower;
    this.detailDialogController = new CustomDialogController({
      builder: FlowerDetailDialog({ flower: flower }),
      autoCancel: true,
      alignment: DialogAlignment.Bottom,
      customStyle: true
    });
    this.detailDialogController.open();
  }

  aboutToAppear() {
    this.loadFlowers(true);
  }

  build() {
    Column() {
      // 顶部搜索栏
      Row() {
        TextInput({ placeholder: '搜索花材名称...', text: this.searchKeyword })
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
          .onSubmit(() => {
            this.loadFlowers(true);
          })

        Text('🔍')
          .fontSize(22)
          .margin({ left: AppTheme.SPACING_SMALL })
          .onClick(() => {
            this.loadFlowers(true);
          })
      }
      .width('100%')
      .padding({ left: AppTheme.SPACING_MEDIUM, right: AppTheme.SPACING_MEDIUM, top: AppTheme.SPACING_SMALL })
      .justifyContent(FlexAlign.Center)

      // 筛选类型切换标签
      Row() {
        Text('颜色')
          .fontSize(AppTheme.FONT_SIZE_NORMAL)
          .fontColor(this.filterType === 0 ? AppTheme.PRIMARY_COLOR : AppTheme.TEXT_SECONDARY)
          .fontWeight(this.filterType === 0 ? FontWeight.Bold : FontWeight.Normal)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .borderRadius(AppTheme.BORDER_RADIUS_SMALL)
          .backgroundColor(this.filterType === 0 ? AppTheme.PRIMARY_COLOR_ALPHA20 : Color.Transparent)
          .onClick(() => { this.filterType = 0; })

        Text('类别')
          .fontSize(AppTheme.FONT_SIZE_NORMAL)
          .fontColor(this.filterType === 1 ? AppTheme.PRIMARY_COLOR : AppTheme.TEXT_SECONDARY)
          .fontWeight(this.filterType === 1 ? FontWeight.Bold : FontWeight.Normal)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .borderRadius(AppTheme.BORDER_RADIUS_SMALL)
          .backgroundColor(this.filterType === 1 ? AppTheme.PRIMARY_COLOR_ALPHA20 : Color.Transparent)
          .margin({ left: AppTheme.SPACING_SMALL })
          .onClick(() => { this.filterType = 1; })

        Text('季节')
          .fontSize(AppTheme.FONT_SIZE_NORMAL)
          .fontColor(this.filterType === 2 ? AppTheme.PRIMARY_COLOR : AppTheme.TEXT_SECONDARY)
          .fontWeight(this.filterType === 2 ? FontWeight.Bold : FontWeight.Normal)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .borderRadius(AppTheme.BORDER_RADIUS_SMALL)
          .backgroundColor(this.filterType === 2 ? AppTheme.PRIMARY_COLOR_ALPHA20 : Color.Transparent)
          .margin({ left: AppTheme.SPACING_SMALL })
          .onClick(() => { this.filterType = 2; })
      }
      .width('100%')
      .padding({ left: AppTheme.SPACING_MEDIUM, top: AppTheme.SPACING_SMALL, bottom: AppTheme.SPACING_SMALL })

      // 筛选标签区 - 横向滚动
      Scroll() {
        Row() {
          if (this.filterType === 0) {
            ForEach(COLOR_FILTERS, (tag: FilterTag) => {
              Text(tag.label)
                .fontSize(AppTheme.FONT_SIZE_SMALL)
                .fontColor(this.selectedColor === tag.value ? '#FFFFFF' : AppTheme.TEXT_PRIMARY)
                .backgroundColor(this.selectedColor === tag.value ? AppTheme.PRIMARY_COLOR : AppTheme.CARD_BACKGROUND)
                .borderRadius(AppTheme.BORDER_RADIUS_CIRCLE)
                .padding({ left: 14, right: 14, top: 6, bottom: 6 })
                .margin({ right: AppTheme.SPACING_SMALL })
                .onClick(() => {
                  this.selectedColor = tag.value;
                  this.loadFlowers(true);
                })
            }, (tag: FilterTag) => tag.value)
          } else if (this.filterType === 1) {
            ForEach(CATEGORY_FILTERS, (tag: FilterTag) => {
              Text(tag.label)
                .fontSize(AppTheme.FONT_SIZE_SMALL)
                .fontColor(this.selectedCategory === tag.value ? '#FFFFFF' : AppTheme.TEXT_PRIMARY)
                .backgroundColor(this.selectedCategory === tag.value ? AppTheme.PRIMARY_COLOR : AppTheme.CARD_BACKGROUND)
                .borderRadius(AppTheme.BORDER_RADIUS_CIRCLE)
                .padding({ left: 14, right: 14, top: 6, bottom: 6 })
                .margin({ right: AppTheme.SPACING_SMALL })
                .onClick(() => {
                  this.selectedCategory = tag.value;
                  this.loadFlowers(true);
                })
            }, (tag: FilterTag) => tag.value)
          } else {
            ForEach(SEASON_FILTERS, (tag: FilterTag) => {
              Text(tag.label)
                .fontSize(AppTheme.FONT_SIZE_SMALL)
                .fontColor(this.selectedSeason === tag.value ? '#FFFFFF' : AppTheme.TEXT_PRIMARY)
                .backgroundColor(this.selectedSeason === tag.value ? AppTheme.PRIMARY_COLOR : AppTheme.CARD_BACKGROUND)
                .borderRadius(AppTheme.BORDER_RADIUS_CIRCLE)
                .padding({ left: 14, right: 14, top: 6, bottom: 6 })
                .margin({ right: AppTheme.SPACING_SMALL })
                .onClick(() => {
                  this.selectedSeason = tag.value;
                  this.loadFlowers(true);
                })
            }, (tag: FilterTag) => tag.value)
          }
        }
        .padding({ left: AppTheme.SPACING_MEDIUM })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')

      // 花材Grid展示
      if (this.isLoading && this.flowerList.length === 0) {
        // 首次加载状态
        Column() {
          Text('🌺')
            .fontSize(40)
            .margin({ bottom: AppTheme.SPACING_MEDIUM })
          Text('加载中...')
            .fontSize(AppTheme.FONT_SIZE_NORMAL)
            .fontColor(AppTheme.TEXT_SECONDARY)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.flowerList.length === 0) {
        // 空状态
        Column() {
          Text('🔍')
            .fontSize(40)
            .margin({ bottom: AppTheme.SPACING_MEDIUM })
          Text('未找到匹配的花材')
            .fontSize(AppTheme.FONT_SIZE_MEDIUM)
            .fontColor(AppTheme.TEXT_SECONDARY)
          Text('请尝试其他搜索条件')
            .fontSize(AppTheme.FONT_SIZE_NORMAL)
            .fontColor(AppTheme.TEXT_SECONDARY)
            .margin({ top: AppTheme.SPACING_SMALL })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        // 花材Grid列表
        Scroll() {
          Column() {
            Grid() {
              ForEach(this.flowerList, (flower: FlowerInfo) => {
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

            // 底部加载提示
            Row() {
              if (this.hasMore) {
                Text('上拉加载更多...')
                  .fontSize(AppTheme.FONT_SIZE_SMALL)
                  .fontColor(AppTheme.TEXT_SECONDARY)
              } else {
                Text('— 已经到底了 —')
                  .fontSize(AppTheme.FONT_SIZE_SMALL)
                  .fontColor(AppTheme.TEXT_SECONDARY)
              }
            }
            .width('100%')
            .height(50)
            .justifyContent(FlexAlign.Center)
            .margin({ top: AppTheme.SPACING_SMALL })
          }
          .padding(AppTheme.SPACING_MEDIUM)
        }
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.Spring)
        .layoutWeight(1)
        .onReachEnd(() => {
          if (this.hasMore && !this.isLoading) {
            this.currentPage++;
            this.loadFlowers(false);
          }
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppTheme.BACKGROUND_COLOR)
  }
}
