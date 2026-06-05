// 主入口 - Tab容器页面

import { AppTheme } from '../common/Theme';
import { CartStore } from '../store/CartStore';
import { HomePage } from './HomePage';
import { RecommendPage } from './RecommendPage';
import { FlowerLibrary } from './FlowerLibrary';
import { MinePage } from './MinePage';

@Entry
@Component
struct Index {
  // 当前选中Tab索引（通过AppStorage可跨页面切换Tab）
  @StorageLink('currentTab') currentIndex: number = 0;
  @StorageLink('cartItemCount') cartCount: number = 0;

  // Tab项数据
  private tabItems: string[] = ['首页', '推荐', '花材库', '我的'];

  aboutToAppear() {
    CartStore.initAppStorage();
    CartStore.loadFromDisk();
  }

  build() {
    Column() {
      // Tabs组件 - 底部导航
      Tabs({ barPosition: BarPosition.End, index: this.currentIndex }) {
        // 首页Tab
        TabContent() {
          HomePage()
        }
        .tabBar(this.TabBuilder(0, '首页', $r('app.string.tab_home')))

        // 推荐Tab
        TabContent() {
          RecommendPage()
        }
        .tabBar(this.TabBuilder(1, '推荐', $r('app.string.tab_recommend')))

        // 花材库Tab
        TabContent() {
          FlowerLibrary()
        }
        .tabBar(this.TabBuilder(2, '花材库', $r('app.string.tab_library')))

        // 我的Tab
        TabContent() {
          MinePage()
        }
        .tabBar(this.TabBuilder(3, '我的', $r('app.string.tab_mine')))
      }
      .scrollable(true)
      .barBackgroundColor(AppTheme.CARD_BACKGROUND)
      .barHeight(56)
      .onChange((index: number) => {
        this.currentIndex = index;
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppTheme.BACKGROUND_COLOR)
  }

  // Tab底部导航项构建器
  @Builder
  TabBuilder(index: number, title: string, iconResource: Resource) {
    Column() {
      Stack() {
        // Tab图标 - 使用文字占位(实际项目中应使用图片资源)
        Text(this.getTabIcon(index))
          .fontSize(20)
          .fontColor(this.currentIndex === index ? AppTheme.PRIMARY_COLOR : AppTheme.TEXT_SECONDARY)

        // 购物车角标（仅在cartCount > 0时显示）
        if (this.cartCount > 0) {
          Text(this.cartCount >= 100 ? '99+' : `${this.cartCount}`)
            .fontSize(10)
            .fontColor(Color.White)
            .backgroundColor(Color.Red)
            .borderRadius(10)
            .padding({ left: 4, right: 4, top: 1, bottom: 1 })
            .position({ x: '60%', y: -6 })
            .constraintSize({ minWidth: 16 })
            .textAlign(TextAlign.Center)
        }
      }
      .alignContent(Alignment.TopEnd)

      // Tab标题
      Text(title)
        .fontSize(12)
        .fontColor(this.currentIndex === index ? AppTheme.PRIMARY_COLOR : AppTheme.TEXT_SECONDARY)
        .margin({ top: 4 })
        .fontWeight(this.currentIndex === index ? FontWeight.Bold : FontWeight.Normal)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  // 获取Tab图标占位文字
  private getTabIcon(index: number): string {
    const icons: string[] = ['🏠', '💡', '🌺', '👤'];
    return icons[index] || '';
  }
}
