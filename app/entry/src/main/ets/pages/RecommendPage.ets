// 推荐页 - 分步引导式智能推荐

import { AppTheme } from '../common/Theme';
import { StepIndicator } from '../components/StepIndicator';
import { SceneSelector } from '../components/SceneSelector';
import { CommonButton, CustomButtonType, ButtonSize } from '../components/CommonButton';
import { SceneType, GenerateRecommendationParams } from '../models/RecommendModel';
import { RecipientInfo, CreateRecipientParams } from '../models/UserModel';
import { ApiService } from '../services/ApiService';
import router from '@ohos.router';

// 步骤数据结构（与StepIndicator组件兼容）
interface StepItemData {
  title: string;
  isCompleted: boolean;
  isCurrent: boolean;
}

// ==================== 常量选项定义 ====================

const RELATIONSHIP_OPTIONS: string[] = ['伴侣', '暗恋对象', '朋友', '长辈', '同事', '其他'];
const DURATION_OPTIONS: string[] = ['刚认识', '1周内', '1-3个月', '3-6个月', '半年-1年', '1-3年', '3年以上'];
const FLOWER_EXP_OPTIONS: string[] = ['没送过', '送过1-2次', '经常送'];
const INTERACTION_OPTIONS: string[] = ['甜蜜', '平淡', '刚和好', '热恋期', '老夫老妻'];
const HOBBY_OPTIONS: string[] = ['文艺', '运动', '美食', '旅行', '游戏', '音乐', '阅读', '追剧'];
const PERSONALITY_OPTIONS: string[] = ['温柔', '活泼', '内向', '理性', '感性', '独立', '浪漫'];
const PROFESSION_OPTIONS: string[] = ['学生', 'IT', '金融', '教育', '医疗', '艺术', '自由职业', '其他'];
const STYLE_OPTIONS: string[] = ['简约', '华丽', '可爱', '优雅', '自然'];
const QUICK_TAGS: string[] = ['第一次送花', '想要惊喜', '需要浪漫', '预算有限', '想要大气', '低调内涵'];

interface ColorOption {
  name: string;
  value: string;
}

const COLOR_OPTIONS: ColorOption[] = [
  { name: '红', value: '#E74C3C' },
  { name: '粉', value: '#FF69B4' },
  { name: '白', value: '#FFFFFF' },
  { name: '紫', value: '#9B59B6' },
  { name: '黄', value: '#F1C40F' },
  { name: '蓝', value: '#3498DB' },
  { name: '混搭', value: '#E0E0E0' }
];

@Entry
@Component
export struct RecommendPage {
  // ==================== 步骤控制 ====================
  @State currentStep: number = 0;
  @State isLoading: boolean = false;

  // ==================== Step1: 送花对象 ====================
  @State recipientList: RecipientInfo[] = [];
  @State selectedRecipientId: number = -1;
  @State showNewRecipient: boolean = false;
  @State newRecipientName: string = '';
  @State newRecipientGender: string = 'female';
  @State newRecipientAge: string = '';
  @State newRecipientRelationship: string = '伴侣';

  // ==================== Step2: 场景选择 ====================
  @State selectedScene: SceneType = SceneType.BIRTHDAY;
  @State sceneDescription: string = '';

  // ==================== Step3: 关系背景 ====================
  @State relationshipDuration: string = '';
  @State sentFlowersBefore: string = '';
  @State recentEvents: string = '';
  @State interactionModes: string[] = [];

  // ==================== Step4: 对方画像 ====================
  @State hobbies: string[] = [];
  @State personality: string[] = [];
  @State profession: string = '';
  @State cultureNote: string = '';

  // ==================== Step5: 预算配送 ====================
  @State budget: number = 200;
  @State preferredColors: string[] = [];
  @State stylePreference: string = '';
  @State needDelivery: boolean = false;
  @State deliveryAddress: string = '';
  @State deliveryDate: string = '';

  // 步骤标题
  private stepTitles: string[] = ['送花对象', '场景选择', '关系背景', '对方画像', '预算配送'];

  // ==================== 生命周期 ====================

  aboutToAppear() {
    this.loadRecipients();
    // 检查AppStorage中是否有从首页传来的预选场景
    const preScene = AppStorage.get<string>('selectedScene');
    if (preScene) {
      this.selectedScene = preScene as SceneType;
      AppStorage.setOrCreate('selectedScene', '');
      this.currentStep = 1;
    }
  }

  // 加载收件人列表
  private async loadRecipients(): Promise<void> {
    try {
      this.recipientList = await ApiService.getRecipients();
    } catch (error) {
      console.error('加载收件人列表失败:', JSON.stringify(error));
      this.recipientList = [];
    }
  }

  // ==================== 工具方法 ====================

  // 切换数组中的标签
  private toggleInArray(arr: string[], item: string): string[] {
    const newArr: string[] = [];
    for (let i = 0; i < arr.length; i++) {
      newArr.push(arr[i]);
    }
    const idx = newArr.indexOf(item);
    if (idx >= 0) {
      newArr.splice(idx, 1);
    } else {
      newArr.push(item);
    }
    return newArr;
  }

  // 获取步骤数据
  private getStepItems(): StepItemData[] {
    const items: StepItemData[] = [];
    for (let i = 0; i < this.stepTitles.length; i++) {
      items.push({
        title: this.stepTitles[i],
        isCompleted: i < this.currentStep,
        isCurrent: i === this.currentStep
      });
    }
    return items;
  }

  // 构建推荐请求参数
  private buildRecommendParams(): GenerateRecommendationParams {
    const extraInfo: Record<string, string> = {};
    if (this.sceneDescription) extraInfo['sceneDescription'] = this.sceneDescription;
    if (this.relationshipDuration) extraInfo['relationshipDuration'] = this.relationshipDuration;
    if (this.sentFlowersBefore) extraInfo['sentFlowersBefore'] = this.sentFlowersBefore;
    if (this.recentEvents) extraInfo['recentEvents'] = this.recentEvents;
    if (this.interactionModes.length > 0) extraInfo['interactionModes'] = this.interactionModes.join(',');
    if (this.hobbies.length > 0) extraInfo['hobbies'] = this.hobbies.join(',');
    if (this.personality.length > 0) extraInfo['personality'] = this.personality.join(',');
    if (this.profession) extraInfo['profession'] = this.profession;
    if (this.cultureNote) extraInfo['cultureNote'] = this.cultureNote;
    if (this.preferredColors.length > 0) extraInfo['preferredColors'] = this.preferredColors.join(',');
    if (this.needDelivery) extraInfo['needDelivery'] = 'true';
    if (this.deliveryAddress) extraInfo['deliveryAddress'] = this.deliveryAddress;
    if (this.deliveryDate) extraInfo['deliveryDate'] = this.deliveryDate;

    return {
      recipientId: this.selectedRecipientId > 0 ? this.selectedRecipientId : undefined,
      scene: this.selectedScene,
      budget: this.budget,
      stylePreference: this.stylePreference || undefined,
      specialRequirements: JSON.stringify(extraInfo)
    };
  }

  // 提交推荐请求
  private async submitRecommendation(): Promise<void> {
    this.isLoading = true;
    try {
      // 如果新建了收件人，先创建
      if (this.showNewRecipient && this.selectedRecipientId <= 0 && this.newRecipientName) {
        const newRecipient: CreateRecipientParams = {
          name: this.newRecipientName,
          gender: this.newRecipientGender as 'male' | 'female' | 'other',
          ageRange: this.newRecipientAge,
          relationship: this.newRecipientRelationship,
          personality: this.personality.join(','),
          preferences: this.hobbies.join(',')
        };
        const created = await ApiService.createRecipient(newRecipient);
        this.selectedRecipientId = created.id;
      }

      const params = this.buildRecommendParams();
      const response = await ApiService.generateRecommendation(params);

      // 导航到结果页，传递推荐数据和请求参数
      router.pushUrl({
        url: 'pages/ResultPage',
        params: {
          schemesData: JSON.stringify(response.schemes),
          reason: response.reason,
          sceneAnalysis: response.sceneAnalysis,
          requestParams: JSON.stringify(params)
        }
      });
    } catch (error) {
      console.error('生成推荐失败:', JSON.stringify(error));
    }
    this.isLoading = false;
  }

  // 上一步
  private prevStep(): void {
    if (this.currentStep > 0) {
      this.currentStep--;
    }
  }

  // 下一步
  private nextStep(): void {
    if (this.currentStep < this.stepTitles.length - 1) {
      this.currentStep++;
    } else {
      this.submitRecommendation();
    }
  }

  // ==================== 标签构建器 ====================

  // 多选标签组构建器
  @Builder
  TagGroup(title: string, options: string[], selectedArr: string[], onToggle: (item: string) => void) {
    // 标题
    Text(title)
      .fontSize(AppTheme.FONT_SIZE_NORMAL)
      .fontColor(AppTheme.TEXT_PRIMARY)
      .fontWeight(FontWeight.Medium)
      .margin({ top: AppTheme.SPACING_MEDIUM, bottom: AppTheme.SPACING_SMALL })

    // 标签列表
    Flex({ wrap: FlexWrap.Wrap }) {
      ForEach(options, (option: string) => {
        Text(option)
          .fontSize(AppTheme.FONT_SIZE_SMALL)
          .fontColor(selectedArr.indexOf(option) >= 0 ? '#FFFFFF' : AppTheme.TEXT_PRIMARY)
          .backgroundColor(selectedArr.indexOf(option) >= 0 ? AppTheme.PRIMARY_COLOR : AppTheme.CARD_BACKGROUND)
          .borderRadius(AppTheme.BORDER_RADIUS_CIRCLE)
          .padding({ left: 14, right: 14, top: 6, bottom: 6 })
          .margin({ right: AppTheme.SPACING_SMALL, bottom: AppTheme.SPACING_SMALL })
          .border({
            width: 1,
            color: selectedArr.indexOf(option) >= 0 ? AppTheme.PRIMARY_COLOR : AppTheme.DIVIDER_COLOR,
            style: BorderStyle.Solid
          })
          .onClick(() => onToggle(option))
      }, (option: string) => option)
    }
    .width('100%')
  }

  // 区块标题构建器
  @Builder
  SectionTitle(title: string) {
    Text(title)
      .fontSize(AppTheme.FONT_SIZE_NORMAL)
      .fontColor(AppTheme.TEXT_PRIMARY)
      .fontWeight(FontWeight.Medium)
      .margin({ top: AppTheme.SPACING_MEDIUM, bottom: AppTheme.SPACING_SMALL })
  }

  // ==================== 步骤内容构建器 ====================

  // 步骤1：选择送花对象
  @Builder
  Step1Content() {
    Column() {
      Text('选择送花对象')
        .fontSize(AppTheme.FONT_SIZE_LARGE)
        .fontColor(AppTheme.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: AppTheme.SPACING_MEDIUM })

      // 已有档案列表
      if (this.recipientList.length > 0) {
        this.SectionTitle('已有档案')

        List() {
          ForEach(this.recipientList, (recipient: RecipientInfo) => {
            ListItem() {
              Row() {
                Circle()
                  .width(40)
                  .height(40)
                  .fill(AppTheme.PRIMARY_COLOR_ALPHA20)

                Column() {
                  Text(recipient.name)
                    .fontSize(AppTheme.FONT_SIZE_NORMAL)
                    .fontColor(AppTheme.TEXT_PRIMARY)
                    .fontWeight(FontWeight.Medium)

                  Text(`${recipient.relationship} · ${recipient.gender === 'male' ? '男' : recipient.gender === 'female' ? '女' : '其他'}`)
                    .fontSize(AppTheme.FONT_SIZE_SMALL)
                    .fontColor(AppTheme.TEXT_SECONDARY)
                    .margin({ top: 2 })
                }
                .alignItems(HorizontalAlign.Start)
                .margin({ left: AppTheme.SPACING_MEDIUM })

                if (this.selectedRecipientId === recipient.id) {
                  Text('✓')
                    .fontSize(18)
                    .fontColor(AppTheme.PRIMARY_COLOR)
                    .fontWeight(FontWeight.Bold)
                    .margin({ left: 'auto' })
                }
              }
              .width('100%')
              .padding(AppTheme.SPACING_MEDIUM)
              .backgroundColor(this.selectedRecipientId === recipient.id ? AppTheme.PRIMARY_COLOR_ALPHA20 : AppTheme.CARD_BACKGROUND)
              .borderRadius(AppTheme.BORDER_RADIUS_MEDIUM)
              .margin({ bottom: AppTheme.SPACING_SMALL })
              .onClick(() => {
                this.selectedRecipientId = recipient.id;
                this.showNewRecipient = false;
              })
            }
          }, (recipient: RecipientInfo) => `${recipient.id}`)
        }
        .width('100%')
        .margin({ bottom: AppTheme.SPACING_MEDIUM })
      }

      // 新建档案按钮
      CommonButton({
        text: this.showNewRecipient ? '收起新建表单' : '+ 新建收件人档案',
        type: CustomButtonType.OUTLINE,
        size: ButtonSize.MEDIUM,
        onClick: () => {
          this.showNewRecipient = !this.showNewRecipient;
          if (this.showNewRecipient) {
            this.selectedRecipientId = -1;
          }
        }
      })

      // 新建档案表单
      if (this.showNewRecipient) {
        Column() {
          this.SectionTitle('姓名')
          TextInput({ placeholder: '请输入姓名' })
            .width('100%')
            .height(40)
            .fontSize(AppTheme.FONT_SIZE_NORMAL)
            .fontColor(AppTheme.TEXT_PRIMARY)
            .backgroundColor('#F5F5F5')
            .borderRadius(AppTheme.BORDER_RADIUS_SMALL)
            .padding({ left: 12, right: 12 })
            .onChange((value: string) => { this.newRecipientName = value; })
            .margin({ bottom: AppTheme.SPACING_MEDIUM })

          this.SectionTitle('性别')
          Row() {
            Radio({ value: 'male', group: 'recipientGender' })
              .checked(this.newRecipientGender === 'male')
              .onChange((checked: boolean) => { if (checked) this.newRecipientGender = 'male'; })
            Text('男')
              .fontSize(AppTheme.FONT_SIZE_NORMAL)
              .fontColor(AppTheme.TEXT_PRIMARY)
              .margin({ left: 4, right: AppTheme.SPACING_LARGE })

            Radio({ value: 'female', group: 'recipientGender' })
              .checked(this.newRecipientGender === 'female')
              .onChange((checked: boolean) => { if (checked) this.newRecipientGender = 'female'; })
            Text('女')
              .fontSize(AppTheme.FONT_SIZE_NORMAL)
              .fontColor(AppTheme.TEXT_PRIMARY)
              .margin({ left: 4, right: AppTheme.SPACING_LARGE })

            Radio({ value: 'other', group: 'recipientGender' })
              .checked(this.newRecipientGender === 'other')
              .onChange((checked: boolean) => { if (checked) this.newRecipientGender = 'other'; })
            Text('其他')
              .fontSize(AppTheme.FONT_SIZE_NORMAL)
              .fontColor(AppTheme.TEXT_PRIMARY)
              .margin({ left: 4 })
          }
          .margin({ bottom: AppTheme.SPACING_MEDIUM })

          this.SectionTitle('年龄')
          TextInput({ placeholder: '请输入年龄' })
            .width('100%')
            .height(40)
            .fontSize(AppTheme.FONT_SIZE_NORMAL)
            .fontColor(AppTheme.TEXT_PRIMARY)
            .backgroundColor('#F5F5F5')
            .borderRadius(AppTheme.BORDER_RADIUS_SMALL)
            .padding({ left: 12, right: 12 })
            .type(InputType.Number)
            .onChange((value: string) => { this.newRecipientAge = value; })
            .margin({ bottom: AppTheme.SPACING_MEDIUM })

          this.SectionTitle('与你的关系')
          Select(RELATIONSHIP_OPTIONS.map((v: string) => ({ value: v })))
            .selected(0)
            .value('请选择关系')
            .width('100%')
            .height(40)
            .fontColor(AppTheme.TEXT_PRIMARY)
            .fontSize(AppTheme.FONT_SIZE_NORMAL)
            .onSelect((index: number) => {
              this.newRecipientRelationship = RELATIONSHIP_OPTIONS[index];
            })
        }
        .width('100%')
        .padding(AppTheme.SPACING_MEDIUM)
        .backgroundColor(AppTheme.CARD_BACKGROUND)
        .borderRadius(AppTheme.BORDER_RADIUS_MEDIUM)
        .margin({ top: AppTheme.SPACING_MEDIUM })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  // 步骤2：场景选择
  @Builder
  Step2Content() {
    Column() {
      Text('选择送花场景')
        .fontSize(AppTheme.FONT_SIZE_LARGE)
        .fontColor(AppTheme.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: AppTheme.SPACING_MEDIUM })

      // 场景选择器
      SceneSelector({
        onSceneSelect: (scene: SceneType) => {
          this.selectedScene = scene;
        }
      })

      // 补充描述
      this.SectionTitle('描述具体情况')
      TextArea({ placeholder: '描述具体情况，如：刚交往3天的女朋友第一个生日' })
        .width('100%')
        .height(80)
        .fontSize(AppTheme.FONT_SIZE_NORMAL)
        .fontColor(AppTheme.TEXT_PRIMARY)
        .placeholderColor(AppTheme.TEXT_SECONDARY)
        .backgroundColor('#F5F5F5')
        .borderRadius(AppTheme.BORDER_RADIUS_SMALL)
        .padding(12)
        .onChange((value: string) => { this.sceneDescription = value; })

      // 快捷标签
      this.SectionTitle('常用标签')
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(QUICK_TAGS, (tag: string) => {
          Text(tag)
            .fontSize(AppTheme.FONT_SIZE_SMALL)
            .fontColor(AppTheme.PRIMARY_COLOR)
            .backgroundColor(AppTheme.PRIMARY_COLOR_ALPHA20)
            .borderRadius(AppTheme.BORDER_RADIUS_CIRCLE)
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .margin({ right: AppTheme.SPACING_SMALL, bottom: AppTheme.SPACING_SMALL })
            .onClick(() => {
              this.sceneDescription = this.sceneDescription ? `${this.sceneDescription} ${tag}` : tag;
            })
        }, (tag: string) => tag)
      }
      .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  // 步骤3：关系背景
  @Builder
  Step3Content() {
    Column() {
      Text('关系背景')
        .fontSize(AppTheme.FONT_SIZE_LARGE)
        .fontColor(AppTheme.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: AppTheme.SPACING_MEDIUM })

      // 交往/认识时长
      this.SectionTitle('交往/认识时长')
      Select(DURATION_OPTIONS.map((v: string) => ({ value: v })))
        .selected(0)
        .value('请选择时长')
        .width('100%')
        .height(40)
        .fontColor(AppTheme.TEXT_PRIMARY)
        .fontSize(AppTheme.FONT_SIZE_NORMAL)
        .onSelect((index: number) => {
          this.relationshipDuration = DURATION_OPTIONS[index];
        })

      // 之前送过花吗
      this.SectionTitle('之前送过花吗')
      Row() {
        ForEach(FLOWER_EXP_OPTIONS, (option: string) => {
          Text(option)
            .fontSize(AppTheme.FONT_SIZE_SMALL)
            .fontColor(this.sentFlowersBefore === option ? '#FFFFFF' : AppTheme.TEXT_PRIMARY)
            .backgroundColor(this.sentFlowersBefore === option ? AppTheme.PRIMARY_COLOR : AppTheme.CARD_BACKGROUND)
            .borderRadius(AppTheme.BORDER_RADIUS_CIRCLE)
            .padding({ left: 14, right: 14, top: 6, bottom: 6 })
            .margin({ right: AppTheme.SPACING_SMALL })
            .border({
              width: 1,
              color: this.sentFlowersBefore === option ? AppTheme.PRIMARY_COLOR : AppTheme.DIVIDER_COLOR,
              style: BorderStyle.Solid
            })
            .onClick(() => { this.sentFlowersBefore = option; })
        }, (option: string) => option)
      }

      // 最近发生的事
      this.SectionTitle('最近发生的事（可选）')
      TextArea({ placeholder: '如：刚吵了一架、升职了、心情低落...' })
        .width('100%')
        .height(70)
        .fontSize(AppTheme.FONT_SIZE_NORMAL)
        .fontColor(AppTheme.TEXT_PRIMARY)
        .placeholderColor(AppTheme.TEXT_SECONDARY)
        .backgroundColor('#F5F5F5')
        .borderRadius(AppTheme.BORDER_RADIUS_SMALL)
        .padding(12)
        .onChange((value: string) => { this.recentEvents = value; })

      // 相处模式（多选）
      this.TagGroup('你们的相处模式', INTERACTION_OPTIONS, this.interactionModes, (item: string) => {
        this.interactionModes = this.toggleInArray(this.interactionModes, item);
      })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  // 步骤4：对方画像
  @Builder
  Step4Content() {
    Column() {
      Text('对方画像')
        .fontSize(AppTheme.FONT_SIZE_LARGE)
        .fontColor(AppTheme.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: AppTheme.SPACING_MEDIUM })

      // 兴趣爱好
      this.TagGroup('兴趣爱好', HOBBY_OPTIONS, this.hobbies, (item: string) => {
        this.hobbies = this.toggleInArray(this.hobbies, item);
      })

      // 性格特点
      this.TagGroup('性格特点', PERSONALITY_OPTIONS, this.personality, (item: string) => {
        this.personality = this.toggleInArray(this.personality, item);
      })

      // 职业领域
      this.SectionTitle('职业领域')
      Select(PROFESSION_OPTIONS.map((v: string) => ({ value: v })))
        .selected(0)
        .value('请选择职业')
        .width('100%')
        .height(40)
        .fontColor(AppTheme.TEXT_PRIMARY)
        .fontSize(AppTheme.FONT_SIZE_NORMAL)
        .onSelect((index: number) => {
          this.profession = PROFESSION_OPTIONS[index];
        })

      // 文化背景备注
      this.SectionTitle('文化背景备注（可选）')
      TextInput({ placeholder: '如：留学归国、少数民族等' })
        .width('100%')
        .height(40)
        .fontSize(AppTheme.FONT_SIZE_NORMAL)
        .fontColor(AppTheme.TEXT_PRIMARY)
        .backgroundColor('#F5F5F5')
        .borderRadius(AppTheme.BORDER_RADIUS_SMALL)
        .padding({ left: 12, right: 12 })
        .onChange((value: string) => { this.cultureNote = value; })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  // 步骤5：预算和配送
  @Builder
  Step5Content() {
    Column() {
      Text('预算和配送')
        .fontSize(AppTheme.FONT_SIZE_LARGE)
        .fontColor(AppTheme.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: AppTheme.SPACING_MEDIUM })

      // 预算范围滑块
      this.SectionTitle(`预算范围：¥${this.budget}`)
      Slider({
        value: this.budget,
        min: 50,
        max: 2000,
        step: 50,
        style: SliderStyle.InSet
      })
        .width('100%')
        .trackColor(AppTheme.DIVIDER_COLOR)
        .selectedColor(AppTheme.PRIMARY_COLOR)
        .blockColor(AppTheme.PRIMARY_COLOR)
        .showTips(false)
        .onChange((value: number) => {
          this.budget = Math.round(value);
        })

      // 喜欢的颜色（多选色块）
      this.SectionTitle('喜欢的颜色')
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(COLOR_OPTIONS, (option: ColorOption) => {
          Column() {
            Circle()
              .width(36)
              .height(36)
              .fill(option.value)
              .stroke(this.preferredColors.indexOf(option.name) >= 0 ? AppTheme.PRIMARY_COLOR : AppTheme.DIVIDER_COLOR)
              .strokeWidth(this.preferredColors.indexOf(option.name) >= 0 ? 3 : 1)

            Text(option.name)
              .fontSize(AppTheme.FONT_SIZE_SMALL)
              .fontColor(AppTheme.TEXT_SECONDARY)
              .margin({ top: 4 })
          }
          .margin({ right: AppTheme.SPACING_MEDIUM, bottom: AppTheme.SPACING_SMALL })
          .onClick(() => {
            this.preferredColors = this.toggleInArray(this.preferredColors, option.name);
          })
        }, (option: ColorOption) => option.name)
      }

      // 风格偏好（单选）
      this.SectionTitle('风格偏好')
      Row() {
        ForEach(STYLE_OPTIONS, (option: string) => {
          Text(option)
            .fontSize(AppTheme.FONT_SIZE_SMALL)
            .fontColor(this.stylePreference === option ? '#FFFFFF' : AppTheme.TEXT_PRIMARY)
            .backgroundColor(this.stylePreference === option ? AppTheme.PRIMARY_COLOR : AppTheme.CARD_BACKGROUND)
            .borderRadius(AppTheme.BORDER_RADIUS_CIRCLE)
            .padding({ left: 14, right: 14, top: 6, bottom: 6 })
            .margin({ right: AppTheme.SPACING_SMALL })
            .border({
              width: 1,
              color: this.stylePreference === option ? AppTheme.PRIMARY_COLOR : AppTheme.DIVIDER_COLOR,
              style: BorderStyle.Solid
            })
            .onClick(() => { this.stylePreference = option; })
        }, (option: string) => option)
      }

      // 是否需要配送
      Row() {
        Text('是否需要配送')
          .fontSize(AppTheme.FONT_SIZE_NORMAL)
          .fontColor(AppTheme.TEXT_PRIMARY)
          .layoutWeight(1)

        Toggle({ type: ToggleType.Switch, isOn: this.needDelivery })
          .selectedColor(AppTheme.PRIMARY_COLOR)
          .onChange((isOn: boolean) => {
            this.needDelivery = isOn;
          })
      }
      .width('100%')
      .margin({ top: AppTheme.SPACING_MEDIUM })
      .justifyContent(FlexAlign.SpaceBetween)

      // 配送地址（条件显示）
      if (this.needDelivery) {
        this.SectionTitle('配送地址')
        TextInput({ placeholder: '请输入配送地址' })
          .width('100%')
          .height(40)
          .fontSize(AppTheme.FONT_SIZE_NORMAL)
          .fontColor(AppTheme.TEXT_PRIMARY)
          .backgroundColor('#F5F5F5')
          .borderRadius(AppTheme.BORDER_RADIUS_SMALL)
          .padding({ left: 12, right: 12 })
          .onChange((value: string) => { this.deliveryAddress = value; })

        this.SectionTitle('期望送达时间')
        DatePicker({
          start: new Date('2024-01-01'),
          end: new Date('2027-12-31'),
          selected: new Date()
        })
          .onDateChange((value: DatePickerResult) => {
            this.deliveryDate = `${value.year}-${value.month + 1}-${value.day}`;
          })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  // ==================== 主构建函数 ====================

  build() {
    Column() {
      // 顶部步骤指示器
      StepIndicator({
        steps: this.getStepItems(),
        currentStep: this.currentStep
      })

      // 步骤内容（可滚动区域）
      Scroll() {
        Column() {
          if (this.currentStep === 0) {
            this.Step1Content()
          } else if (this.currentStep === 1) {
            this.Step2Content()
          } else if (this.currentStep === 2) {
            this.Step3Content()
          } else if (this.currentStep === 3) {
            this.Step4Content()
          } else if (this.currentStep === 4) {
            this.Step5Content()
          }
        }
        .width('100%')
        .padding(AppTheme.SPACING_MEDIUM)
      }
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)
      .layoutWeight(1)

      // 底部固定按钮区
      Row() {
        // 上一步按钮
        if (this.currentStep > 0) {
          CommonButton({
            text: '上一步',
            type: CustomButtonType.OUTLINE,
            size: ButtonSize.LARGE,
            onClick: () => this.prevStep()
          })
          .width('45%')
        }

        // 下一步 / 生成方案 按钮
        CommonButton({
          text: this.currentStep === this.stepTitles.length - 1 ? '生成专属花束方案' : '下一步',
          type: CustomButtonType.PRIMARY,
          size: ButtonSize.LARGE,
          disabled: this.isLoading,
          onClick: () => this.nextStep()
        })
        .width(this.currentStep > 0 ? '45%' : '100%')
      }
      .width('100%')
      .padding({ left: AppTheme.SPACING_MEDIUM, right: AppTheme.SPACING_MEDIUM, top: AppTheme.SPACING_SMALL, bottom: AppTheme.SPACING_MEDIUM })
      .justifyContent(FlexAlign.SpaceBetween)
      .backgroundColor(AppTheme.CARD_BACKGROUND)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppTheme.BACKGROUND_COLOR)
  }
}
