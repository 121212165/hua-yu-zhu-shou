import { AppTheme } from '../common/Theme';
import { SceneSelector } from '../components/SceneSelector';
import { CommonButton, CustomButtonType, ButtonSize } from '../components/CommonButton';
import { SceneType, GenerateRecommendationParams } from '../models/RecommendModel';
import { ApiService } from '../services/ApiService';
import router from '@ohos.router';

const RELATIONSHIP_OPTIONS: string[] = ['伴侣', '暗恋对象', '朋友', '长辈', '同事', '其他'];

@Entry
@Component
export struct RecommendPage {
  @State recipientName: string = '';
  @State relationship: string = '伴侣';
  @State selectedScene: SceneType = SceneType.BIRTHDAY;
  @State notes: string = '';
  @State isLoading: boolean = false;

  aboutToAppear() {
    const preScene = AppStorage.get<string>('selectedScene');
    if (preScene) {
      this.selectedScene = preScene as SceneType;
      AppStorage.setOrCreate('selectedScene', '');
    }
  }

  private async submit(): Promise<void> {
    if (!this.recipientName.trim() || !this.selectedScene) return;
    this.isLoading = true;
    try {
      const params: GenerateRecommendationParams = {
        occasion: this.selectedScene,
        recipientName: this.recipientName.trim(),
        recipientRelationship: this.relationship,
        notes: this.notes.trim() || undefined,
      };
      const response = await ApiService.generateRecommendation(params);
      router.pushUrl({
        url: 'pages/ResultPage',
        params: { schemesData: JSON.stringify(response.schemes), reason: response.reason }
      });
    } catch (error) {
      console.error('Recommendation failed:', JSON.stringify(error));
    }
    this.isLoading = false;
  }

  build() {
    Column() {
      // Header
      Text('智能推荐')
        .fontSize(AppTheme.FONT_SIZE_XLARGE)
        .fontColor(AppTheme.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .padding({ left: AppTheme.SPACING_MEDIUM, right: AppTheme.SPACING_MEDIUM, top: AppTheme.SPACING_LARGE, bottom: AppTheme.SPACING_MEDIUM })

      Scroll() {
        Column() {
          // Name
          Text('送给谁')
            .fontSize(AppTheme.FONT_SIZE_NORMAL)
            .fontColor(AppTheme.TEXT_PRIMARY)
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: AppTheme.SPACING_SMALL })

          TextInput({ placeholder: '请输入收花人姓名', text: this.recipientName })
            .width('100%')
            .height(44)
            .fontSize(AppTheme.FONT_SIZE_NORMAL)
            .fontColor(AppTheme.TEXT_PRIMARY)
            .backgroundColor(AppTheme.CARD_BACKGROUND)
            .borderRadius(AppTheme.BORDER_RADIUS_MEDIUM)
            .padding({ left: 12, right: 12 })
            .onChange((value: string) => { this.recipientName = value; })

          // Relationship
          Text('你们的关系')
            .fontSize(AppTheme.FONT_SIZE_NORMAL)
            .fontColor(AppTheme.TEXT_PRIMARY)
            .fontWeight(FontWeight.Medium)
            .margin({ top: AppTheme.SPACING_MEDIUM, bottom: AppTheme.SPACING_SMALL })

          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(RELATIONSHIP_OPTIONS, (opt: string) => {
              Text(opt)
                .fontSize(AppTheme.FONT_SIZE_SMALL)
                .fontColor(this.relationship === opt ? '#FFFFFF' : AppTheme.TEXT_PRIMARY)
                .backgroundColor(this.relationship === opt ? AppTheme.PRIMARY_COLOR : AppTheme.CARD_BACKGROUND)
                .borderRadius(AppTheme.BORDER_RADIUS_CIRCLE)
                .padding({ left: 14, right: 14, top: 6, bottom: 6 })
                .margin({ right: AppTheme.SPACING_SMALL, bottom: AppTheme.SPACING_SMALL })
                .border({ width: 1, color: this.relationship === opt ? AppTheme.PRIMARY_COLOR : AppTheme.DIVIDER_COLOR, style: BorderStyle.Solid })
                .onClick(() => { this.relationship = opt; })
            }, (opt: string) => opt)
          }
          .width('100%')

          // Scene
          Text('送花场景')
            .fontSize(AppTheme.FONT_SIZE_NORMAL)
            .fontColor(AppTheme.TEXT_PRIMARY)
            .fontWeight(FontWeight.Medium)
            .margin({ top: AppTheme.SPACING_MEDIUM, bottom: AppTheme.SPACING_SMALL })

          SceneSelector({ onSceneSelect: (scene: SceneType) => { this.selectedScene = scene; } })

          // Notes
          Text('补充说明（可选）')
            .fontSize(AppTheme.FONT_SIZE_NORMAL)
            .fontColor(AppTheme.TEXT_PRIMARY)
            .fontWeight(FontWeight.Medium)
            .margin({ top: AppTheme.SPACING_MEDIUM, bottom: AppTheme.SPACING_SMALL })

          TextArea({ placeholder: '如：刚交往3天的第一个生日、对方喜欢粉色...' })
            .width('100%')
            .height(80)
            .fontSize(AppTheme.FONT_SIZE_NORMAL)
            .fontColor(AppTheme.TEXT_PRIMARY)
            .placeholderColor(AppTheme.TEXT_SECONDARY)
            .backgroundColor(AppTheme.CARD_BACKGROUND)
            .borderRadius(AppTheme.BORDER_RADIUS_MEDIUM)
            .padding(12)
            .onChange((value: string) => { this.notes = value; })
        }
        .width('100%')
        .padding(AppTheme.SPACING_MEDIUM)
      }
      .layoutWeight(1)
      .scrollable(ScrollDirection.Vertical)

      // Submit button
      CommonButton({
        text: this.isLoading ? '生成中...' : '生成专属花束方案',
        type: CustomButtonType.PRIMARY,
        size: ButtonSize.LARGE,
        disabled: !this.recipientName.trim() || this.isLoading,
        onClick: () => this.submit()
      })
      .width('100%')
      .padding({ left: AppTheme.SPACING_MEDIUM, right: AppTheme.SPACING_MEDIUM, bottom: AppTheme.SPACING_MEDIUM })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppTheme.BACKGROUND_COLOR)
  }
}
