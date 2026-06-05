// 收花人档案页 - 档案列表、新建/编辑表单、关系进展时间线

import { AppTheme } from '../common/Theme';
import { CommonButton, CustomButtonType, ButtonSize } from '../components/CommonButton';
import { RecipientInfo, CreateRecipientParams } from '../models/UserModel';
import { ApiService } from '../services/ApiService';

// 关系类型选项
const RELATIONSHIP_OPTIONS: string[] = ['伴侣', '朋友', '父母', '子女', '同事', '领导', '其他'];

// 喜欢的颜色选项
const COLOR_OPTIONS: string[] = ['红色', '粉色', '白色', '黄色', '紫色', '蓝色', '橙色', '绿色'];

// 风格偏好选项
const STYLE_OPTIONS: string[] = ['浪漫', '简约', '华丽', '自然', '可爱', '优雅', '清新'];

// 兴趣爱好选项
const HOBBY_OPTIONS: string[] = ['阅读', '旅行', '音乐', '运动', '美食', '摄影', '绘画', '园艺', '手工', '电影'];

// 性格特点选项
const PERSONALITY_OPTIONS: string[] = ['温柔', '开朗', '内向', '活泼', '安静', '独立', '浪漫', '理性', '感性', '幽默'];

// 过敏花材选项
const ALLERGY_OPTIONS: string[] = ['百合', '菊花', '郁金香', '绣球', '康乃馨'];

// 送花记录数据结构
interface FlowerRecord {
  date: string;
  scene: string;
  bouquetName: string;
  feedback: string;
}

@Entry
@Component
struct RecipientProfile {
  // 收花人列表
  @State recipientList: RecipientInfo[] = [];
  // 是否显示新建/编辑表单
  @State showForm: boolean = false;
  // 是否正在编辑（true=编辑，false=新建）
  @State isEditing: boolean = false;
  // 当前编辑的收花人ID
  @State editingId: number = -1;
  // 是否显示时间线
  @State showTimeline: boolean = false;
  // 当前查看时间线的收花人
  @State timelineRecipient: RecipientInfo | null = null;
  // 是否正在加载
  @State isLoading: boolean = false;

  // ====== 表单字段 ======
  @State formName: string = '';
  @State formGender: string = 'female';
  @State formAge: string = '';
  @State formRelationship: string = '';
  @State formLikedColors: string[] = [];
  @State formStyle: string = '';
  @State formAllergies: string[] = [];
  @State formHobbies: string[] = [];
  @State formPersonality: string[] = [];
  @State formOccupation: string = '';
  @State formNotes: string = '';

  // 送花记录（模拟数据）
  @State flowerRecords: FlowerRecord[] = [];

  // 获取收花人列表
  private async loadRecipients(): Promise<void> {
    this.isLoading = true;
    try {
      this.recipientList = await ApiService.getRecipients();
    } catch (error) {
      console.error('加载收花人列表失败:', JSON.stringify(error));
      // 使用模拟数据
      this.recipientList = this.getMockRecipients();
    }
    this.isLoading = false;
  }

  // 模拟收花人数据
  private getMockRecipients(): RecipientInfo[] {
    return [
      { id: 1, userId: 1, name: '李小红', gender: 'female', ageRange: '20-30', relationship: '伴侣', personality: '温柔、浪漫', preferences: '喜欢粉色玫瑰、百合', createdAt: '2025-01-15', updatedAt: '2025-03-20' },
      { id: 2, userId: 1, name: '张妈妈', gender: 'female', ageRange: '50-60', relationship: '父母', personality: '开朗、温和', preferences: '喜欢康乃馨', createdAt: '2025-02-10', updatedAt: '2025-05-10' },
      { id: 3, userId: 1, name: '王大伟', gender: 'male', ageRange: '30-40', relationship: '朋友', personality: '活泼、幽默', preferences: '向日葵', createdAt: '2025-03-01', updatedAt: '2025-04-15' },
      { id: 4, userId: 1, name: '陈同事', gender: 'female', ageRange: '25-35', relationship: '同事', personality: '独立、理性', preferences: '简约风格', createdAt: '2025-04-20', updatedAt: '2025-05-01' }
    ];
  }

  // 模拟送花记录数据
  private getMockRecords(): FlowerRecord[] {
    return [
      { date: '2025-01-14', scene: '生日', bouquetName: '粉色浪漫花束', feedback: '非常喜欢，感动落泪' },
      { date: '2025-02-14', scene: '情人节', bouquetName: '红玫瑰99朵', feedback: '惊喜满分，拍了好多照片' },
      { date: '2025-03-20', scene: '纪念日', bouquetName: '白百合+粉玫瑰混搭', feedback: '优雅漂亮，很满意' }
    ];
  }

  // 重置表单
  private resetForm(): void {
    this.formName = '';
    this.formGender = 'female';
    this.formAge = '';
    this.formRelationship = '';
    this.formLikedColors = [];
    this.formStyle = '';
    this.formAllergies = [];
    this.formHobbies = [];
    this.formPersonality = [];
    this.formOccupation = '';
    this.formNotes = '';
  }

  // 打开新建表单
  private openNewForm(): void {
    this.resetForm();
    this.isEditing = false;
    this.editingId = -1;
    this.showForm = true;
  }

  // 打开编辑表单
  private openEditForm(recipient: RecipientInfo): void {
    this.isEditing = true;
    this.editingId = recipient.id;
    this.formName = recipient.name;
    this.formGender = recipient.gender;
    this.formAge = recipient.ageRange;
    this.formRelationship = recipient.relationship;
    this.formPersonality = recipient.personality ? recipient.personality.split('、') : [];
    this.formNotes = recipient.preferences || '';
    this.showForm = true;
  }

  // 保存收花人
  private async saveRecipient(): Promise<void> {
    if (!this.formName || !this.formRelationship) {
      return;
    }

    this.isLoading = true;
    try {
      const params: CreateRecipientParams = {
        name: this.formName,
        gender: this.formGender as 'male' | 'female' | 'other',
        ageRange: this.formAge,
        relationship: this.formRelationship,
        personality: this.formPersonality.join('、'),
        preferences: this.formLikedColors.join('、') + (this.formStyle ? '；风格:' + this.formStyle : '') + (this.formAllergies.length > 0 ? '；过敏:' + this.formAllergies.join('、') : '')
      };

      if (this.isEditing) {
        // 编辑已有收花人 - 目前API无update，模拟
        console.info('编辑收花人:', JSON.stringify(params));
      } else {
        await ApiService.createRecipient(params);
      }
      this.showForm = false;
      this.loadRecipients();
    } catch (error) {
      console.error('保存收花人失败:', JSON.stringify(error));
      this.showForm = false;
    }
    this.isLoading = false;
  }

  // 查看时间线
  private openTimeline(recipient: RecipientInfo): void {
    this.timelineRecipient = recipient;
    this.flowerRecords = this.getMockRecords();
    this.showTimeline = true;
  }

  // 切换多选项
  private toggleItem(list: string[], item: string): string[] {
    const idx = list.indexOf(item);
    if (idx >= 0) {
      return list.filter(i => i !== item);
    } else {
      return [...list, item];
    }
  }

  // 获取姓名首字母（简化取第一个字）
  private getInitial(name: string): string {
    return name.charAt(0);
  }

  aboutToAppear() {
    this.loadRecipients();
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Text('收花人档案')
          .fontSize(AppTheme.FONT_SIZE_XLARGE)
          .fontColor(AppTheme.TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)

        // 新建按钮
        Text('+ 新建')
          .fontSize(AppTheme.FONT_SIZE_NORMAL)
          .fontColor(AppTheme.PRIMARY_COLOR)
          .fontWeight(FontWeight.Medium)
          .margin({ left: 'auto' })
          .onClick(() => {
            this.openNewForm();
          })
      }
      .width('100%')
      .padding({ left: AppTheme.SPACING_MEDIUM, right: AppTheme.SPACING_MEDIUM, top: AppTheme.SPACING_LARGE, bottom: AppTheme.SPACING_SMALL })

      if (this.showForm) {
        // ====== 新建/编辑档案表单 ======
        this.FormBuilder()
      } else if (this.showTimeline && this.timelineRecipient) {
        // ====== 关系进展时间线 ======
        this.TimelineBuilder()
      } else {
        // ====== 档案列表 ======
        this.RecipientListBuilder()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppTheme.BACKGROUND_COLOR)
  }

  // ====== 档案列表构建 ======
  @Builder
  RecipientListBuilder() {
    if (this.isLoading && this.recipientList.length === 0) {
      Column() {
        Text('👥')
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
    } else if (this.recipientList.length === 0) {
      Column() {
        Text('📋')
          .fontSize(40)
          .margin({ bottom: AppTheme.SPACING_MEDIUM })
        Text('还没有收花人档案')
          .fontSize(AppTheme.FONT_SIZE_MEDIUM)
          .fontColor(AppTheme.TEXT_SECONDARY)
        Text('点击右上角新建档案')
          .fontSize(AppTheme.FONT_SIZE_NORMAL)
          .fontColor(AppTheme.TEXT_SECONDARY)
          .margin({ top: AppTheme.SPACING_SMALL })
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    } else {
      List() {
        ForEach(this.recipientList, (recipient: RecipientInfo) => {
          ListItem() {
            // 滑动删除容器
            Row() {
              // 收花人卡片
              Row() {
                // 头像占位（首字母圆形）
                Circle() {
                  Text(this.getInitial(recipient.name))
                    .fontSize(AppTheme.FONT_SIZE_LARGE)
                    .fontColor('#FFFFFF')
                    .fontWeight(FontWeight.Bold)
                }
                .width(48)
                .height(48)
                .fill(AppTheme.PRIMARY_COLOR)

                // 信息区
                Column() {
                  Text(recipient.name)
                    .fontSize(AppTheme.FONT_SIZE_MEDIUM)
                    .fontColor(AppTheme.TEXT_PRIMARY)
                    .fontWeight(FontWeight.Medium)

                  Row() {
                    Text(recipient.relationship)
                      .fontSize(AppTheme.FONT_SIZE_SMALL)
                      .fontColor(AppTheme.PRIMARY_COLOR)
                      .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                      .backgroundColor(AppTheme.PRIMARY_COLOR_ALPHA20)
                      .borderRadius(AppTheme.BORDER_RADIUS_SMALL)

                    Text(`上次送花: ${recipient.updatedAt || '暂无'}`)
                      .fontSize(AppTheme.FONT_SIZE_SMALL)
                      .fontColor(AppTheme.TEXT_SECONDARY)
                      .margin({ left: AppTheme.SPACING_SMALL })
                  }
                  .margin({ top: AppTheme.SPACING_SMALL / 2 })
                }
                .alignItems(HorizontalAlign.Start)
                .margin({ left: AppTheme.SPACING_MEDIUM })
                .layoutWeight(1)

                // 操作按钮
                Column() {
                  Text('编辑')
                    .fontSize(AppTheme.FONT_SIZE_SMALL)
                    .fontColor(AppTheme.PRIMARY_COLOR)
                    .onClick(() => {
                      this.openEditForm(recipient);
                    })

                  Text('时间线')
                    .fontSize(AppTheme.FONT_SIZE_SMALL)
                    .fontColor(AppTheme.SECONDARY_COLOR)
                    .margin({ top: AppTheme.SPACING_SMALL })
                    .onClick(() => {
                      this.openTimeline(recipient);
                    })
                }
                .alignItems(HorizontalAlign.Center)
              }
              .width('100%')
              .padding(AppTheme.SPACING_MEDIUM)
              .backgroundColor(AppTheme.CARD_BACKGROUND)
              .borderRadius(AppTheme.BORDER_RADIUS_MEDIUM)
              .shadow({
                radius: AppTheme.CARD_SHADOW_RADIUS,
                color: AppTheme.CARD_SHADOW_COLOR,
                offsetY: AppTheme.CARD_SHADOW_OFFSETY
              })
            }
            .width('100%')
            .margin({ bottom: AppTheme.SPACING_SMALL })
          }
          .swipeAction({ end: {
            builder: () => {
              this.DeleteButtonBuilder()
            }
          }})
        }, (recipient: RecipientInfo) => `${recipient.id}`)
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: AppTheme.SPACING_MEDIUM, right: AppTheme.SPACING_MEDIUM, top: AppTheme.SPACING_SMALL })
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)
    }
  }

  // 滑动删除按钮
  @Builder
  DeleteButtonBuilder() {
    Button('删除')
      .width(70)
      .height('100%')
      .fontSize(AppTheme.FONT_SIZE_NORMAL)
      .fontColor('#FFFFFF')
      .backgroundColor(AppTheme.ERROR_COLOR)
      .borderRadius(0)
      .onClick(() => {
        console.info('删除收花人');
      })
  }

  // ====== 新建/编辑档案表单构建 ======
  @Builder
  FormBuilder() {
    Scroll() {
      Column() {
        // 返回按钮
        Row() {
          Text('← 返回列表')
            .fontSize(AppTheme.FONT_SIZE_NORMAL)
            .fontColor(AppTheme.PRIMARY_COLOR)
            .onClick(() => {
              this.showForm = false;
            })
        }
        .width('100%')
        .margin({ bottom: AppTheme.SPACING_MEDIUM })

        // 基本信息区标题
        Text('基本信息')
          .fontSize(AppTheme.FONT_SIZE_MEDIUM)
          .fontColor(AppTheme.TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .width('100%')
          .margin({ bottom: AppTheme.SPACING_SMALL })

        // 姓名
        Row() {
          Text('姓名')
            .fontSize(AppTheme.FONT_SIZE_NORMAL)
            .fontColor(AppTheme.TEXT_PRIMARY)
            .width(60)
          TextInput({ placeholder: '请输入姓名', text: this.formName })
            .layoutWeight(1)
            .height(40)
            .fontSize(AppTheme.FONT_SIZE_NORMAL)
            .fontColor(AppTheme.TEXT_PRIMARY)
            .backgroundColor(AppTheme.CARD_BACKGROUND)
            .borderRadius(AppTheme.BORDER_RADIUS_SMALL)
            .padding({ left: 10 })
            .onChange((value: string) => { this.formName = value; })
        }
        .width('100%')
        .margin({ bottom: AppTheme.SPACING_SMALL })

        // 性别
        Row() {
          Text('性别')
            .fontSize(AppTheme.FONT_SIZE_NORMAL)
            .fontColor(AppTheme.TEXT_PRIMARY)
            .width(60)
          Row() {
            Text('女')
              .fontSize(AppTheme.FONT_SIZE_NORMAL)
              .fontColor(this.formGender === 'female' ? '#FFFFFF' : AppTheme.TEXT_PRIMARY)
              .backgroundColor(this.formGender === 'female' ? AppTheme.PRIMARY_COLOR : AppTheme.CARD_BACKGROUND)
              .borderRadius(AppTheme.BORDER_RADIUS_SMALL)
              .padding({ left: 16, right: 16, top: 6, bottom: 6 })
              .margin({ right: AppTheme.SPACING_SMALL })
              .onClick(() => { this.formGender = 'female'; })

            Text('男')
              .fontSize(AppTheme.FONT_SIZE_NORMAL)
              .fontColor(this.formGender === 'male' ? '#FFFFFF' : AppTheme.TEXT_PRIMARY)
              .backgroundColor(this.formGender === 'male' ? AppTheme.PRIMARY_COLOR : AppTheme.CARD_BACKGROUND)
              .borderRadius(AppTheme.BORDER_RADIUS_SMALL)
              .padding({ left: 16, right: 16, top: 6, bottom: 6 })
              .margin({ right: AppTheme.SPACING_SMALL })
              .onClick(() => { this.formGender = 'male'; })

            Text('其他')
              .fontSize(AppTheme.FONT_SIZE_NORMAL)
              .fontColor(this.formGender === 'other' ? '#FFFFFF' : AppTheme.TEXT_PRIMARY)
              .backgroundColor(this.formGender === 'other' ? AppTheme.PRIMARY_COLOR : AppTheme.CARD_BACKGROUND)
              .borderRadius(AppTheme.BORDER_RADIUS_SMALL)
              .padding({ left: 16, right: 16, top: 6, bottom: 6 })
              .onClick(() => { this.formGender = 'other'; })
          }
        }
        .width('100%')
        .margin({ bottom: AppTheme.SPACING_SMALL })

        // 年龄
        Row() {
          Text('年龄')
            .fontSize(AppTheme.FONT_SIZE_NORMAL)
            .fontColor(AppTheme.TEXT_PRIMARY)
            .width(60)
          TextInput({ placeholder: '如 20-30', text: this.formAge })
            .layoutWeight(1)
            .height(40)
            .fontSize(AppTheme.FONT_SIZE_NORMAL)
            .fontColor(AppTheme.TEXT_PRIMARY)
            .backgroundColor(AppTheme.CARD_BACKGROUND)
            .borderRadius(AppTheme.BORDER_RADIUS_SMALL)
            .padding({ left: 10 })
            .onChange((value: string) => { this.formAge = value; })
        }
        .width('100%')
        .margin({ bottom: AppTheme.SPACING_SMALL })

        // 关系类型
        Row() {
          Text('关系')
            .fontSize(AppTheme.FONT_SIZE_NORMAL)
            .fontColor(AppTheme.TEXT_PRIMARY)
            .width(60)
          Scroll() {
            Row() {
              ForEach(RELATIONSHIP_OPTIONS, (opt: string) => {
                Text(opt)
                  .fontSize(AppTheme.FONT_SIZE_SMALL)
                  .fontColor(this.formRelationship === opt ? '#FFFFFF' : AppTheme.TEXT_PRIMARY)
                  .backgroundColor(this.formRelationship === opt ? AppTheme.PRIMARY_COLOR : AppTheme.CARD_BACKGROUND)
                  .borderRadius(AppTheme.BORDER_RADIUS_CIRCLE)
                  .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                  .margin({ right: AppTheme.SPACING_SMALL })
                  .onClick(() => { this.formRelationship = opt; })
              }, (opt: string) => opt)
            }
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
          .layoutWeight(1)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .margin({ bottom: AppTheme.SPACING_MEDIUM })

        // 偏好区标题
        Divider().color(AppTheme.DIVIDER_COLOR).margin({ top: AppTheme.SPACING_SMALL, bottom: AppTheme.SPACING_SMALL })
        Text('偏好设置')
          .fontSize(AppTheme.FONT_SIZE_MEDIUM)
          .fontColor(AppTheme.TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .width('100%')
          .margin({ bottom: AppTheme.SPACING_SMALL })

        // 喜欢的颜色（多选）
        Text('喜欢的颜色')
          .fontSize(AppTheme.FONT_SIZE_NORMAL)
          .fontColor(AppTheme.TEXT_PRIMARY)
          .width('100%')
          .margin({ bottom: AppTheme.SPACING_SMALL / 2 })
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(COLOR_OPTIONS, (color: string) => {
            Text(color)
              .fontSize(AppTheme.FONT_SIZE_SMALL)
              .fontColor(this.formLikedColors.includes(color) ? '#FFFFFF' : AppTheme.TEXT_PRIMARY)
              .backgroundColor(this.formLikedColors.includes(color) ? AppTheme.PRIMARY_COLOR : AppTheme.CARD_BACKGROUND)
              .borderRadius(AppTheme.BORDER_RADIUS_CIRCLE)
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
              .margin({ right: AppTheme.SPACING_SMALL, bottom: AppTheme.SPACING_SMALL })
              .onClick(() => {
                this.formLikedColors = this.toggleItem(this.formLikedColors, color);
              })
          }, (color: string) => color)
        }
        .width('100%')
        .margin({ bottom: AppTheme.SPACING_SMALL })

        // 风格偏好
        Row() {
          Text('风格偏好')
            .fontSize(AppTheme.FONT_SIZE_NORMAL)
            .fontColor(AppTheme.TEXT_PRIMARY)
            .width(60)
          Scroll() {
            Row() {
              ForEach(STYLE_OPTIONS, (style: string) => {
                Text(style)
                  .fontSize(AppTheme.FONT_SIZE_SMALL)
                  .fontColor(this.formStyle === style ? '#FFFFFF' : AppTheme.TEXT_PRIMARY)
                  .backgroundColor(this.formStyle === style ? AppTheme.PRIMARY_COLOR : AppTheme.CARD_BACKGROUND)
                  .borderRadius(AppTheme.BORDER_RADIUS_CIRCLE)
                  .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                  .margin({ right: AppTheme.SPACING_SMALL })
                  .onClick(() => { this.formStyle = style; })
              }, (style: string) => style)
            }
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
          .layoutWeight(1)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .margin({ bottom: AppTheme.SPACING_SMALL })

        // 过敏花材（多选）
        Text('过敏花材')
          .fontSize(AppTheme.FONT_SIZE_NORMAL)
          .fontColor(AppTheme.TEXT_PRIMARY)
          .width('100%')
          .margin({ bottom: AppTheme.SPACING_SMALL / 2 })
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(ALLERGY_OPTIONS, (item: string) => {
            Text(item)
              .fontSize(AppTheme.FONT_SIZE_SMALL)
              .fontColor(this.formAllergies.includes(item) ? '#FFFFFF' : AppTheme.TEXT_PRIMARY)
              .backgroundColor(this.formAllergies.includes(item) ? AppTheme.ERROR_COLOR : AppTheme.CARD_BACKGROUND)
              .borderRadius(AppTheme.BORDER_RADIUS_CIRCLE)
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
              .margin({ right: AppTheme.SPACING_SMALL, bottom: AppTheme.SPACING_SMALL })
              .onClick(() => {
                this.formAllergies = this.toggleItem(this.formAllergies, item);
              })
          }, (item: string) => item)
        }
        .width('100%')
        .margin({ bottom: AppTheme.SPACING_MEDIUM })

        // 画像区标题
        Divider().color(AppTheme.DIVIDER_COLOR).margin({ top: AppTheme.SPACING_SMALL, bottom: AppTheme.SPACING_SMALL })
        Text('画像信息')
          .fontSize(AppTheme.FONT_SIZE_MEDIUM)
          .fontColor(AppTheme.TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .width('100%')
          .margin({ bottom: AppTheme.SPACING_SMALL })

        // 兴趣爱好（多选Tag）
        Text('兴趣爱好')
          .fontSize(AppTheme.FONT_SIZE_NORMAL)
          .fontColor(AppTheme.TEXT_PRIMARY)
          .width('100%')
          .margin({ bottom: AppTheme.SPACING_SMALL / 2 })
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(HOBBY_OPTIONS, (hobby: string) => {
            Text(hobby)
              .fontSize(AppTheme.FONT_SIZE_SMALL)
              .fontColor(this.formHobbies.includes(hobby) ? '#FFFFFF' : AppTheme.TEXT_PRIMARY)
              .backgroundColor(this.formHobbies.includes(hobby) ? AppTheme.SECONDARY_COLOR : AppTheme.CARD_BACKGROUND)
              .borderRadius(AppTheme.BORDER_RADIUS_CIRCLE)
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
              .margin({ right: AppTheme.SPACING_SMALL, bottom: AppTheme.SPACING_SMALL })
              .onClick(() => {
                this.formHobbies = this.toggleItem(this.formHobbies, hobby);
              })
          }, (hobby: string) => hobby)
        }
        .width('100%')
        .margin({ bottom: AppTheme.SPACING_SMALL })

        // 性格特点（多选Tag）
        Text('性格特点')
          .fontSize(AppTheme.FONT_SIZE_NORMAL)
          .fontColor(AppTheme.TEXT_PRIMARY)
          .width('100%')
          .margin({ bottom: AppTheme.SPACING_SMALL / 2 })
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(PERSONALITY_OPTIONS, (trait: string) => {
            Text(trait)
              .fontSize(AppTheme.FONT_SIZE_SMALL)
              .fontColor(this.formPersonality.includes(trait) ? '#FFFFFF' : AppTheme.TEXT_PRIMARY)
              .backgroundColor(this.formPersonality.includes(trait) ? AppTheme.PRIMARY_COLOR : AppTheme.CARD_BACKGROUND)
              .borderRadius(AppTheme.BORDER_RADIUS_CIRCLE)
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
              .margin({ right: AppTheme.SPACING_SMALL, bottom: AppTheme.SPACING_SMALL })
              .onClick(() => {
                this.formPersonality = this.toggleItem(this.formPersonality, trait);
              })
          }, (trait: string) => trait)
        }
        .width('100%')
        .margin({ bottom: AppTheme.SPACING_SMALL })

        // 职业
        Row() {
          Text('职业')
            .fontSize(AppTheme.FONT_SIZE_NORMAL)
            .fontColor(AppTheme.TEXT_PRIMARY)
            .width(60)
          TextInput({ placeholder: '请输入职业', text: this.formOccupation })
            .layoutWeight(1)
            .height(40)
            .fontSize(AppTheme.FONT_SIZE_NORMAL)
            .fontColor(AppTheme.TEXT_PRIMARY)
            .backgroundColor(AppTheme.CARD_BACKGROUND)
            .borderRadius(AppTheme.BORDER_RADIUS_SMALL)
            .padding({ left: 10 })
            .onChange((value: string) => { this.formOccupation = value; })
        }
        .width('100%')
        .margin({ bottom: AppTheme.SPACING_MEDIUM })

        // 备注区标题
        Divider().color(AppTheme.DIVIDER_COLOR).margin({ top: AppTheme.SPACING_SMALL, bottom: AppTheme.SPACING_SMALL })
        Text('备注')
          .fontSize(AppTheme.FONT_SIZE_MEDIUM)
          .fontColor(AppTheme.TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .width('100%')
          .margin({ bottom: AppTheme.SPACING_SMALL })

        TextArea({ placeholder: '添加备注信息...', text: this.formNotes })
          .width('100%')
          .height(80)
          .fontSize(AppTheme.FONT_SIZE_NORMAL)
          .fontColor(AppTheme.TEXT_PRIMARY)
          .backgroundColor(AppTheme.CARD_BACKGROUND)
          .borderRadius(AppTheme.BORDER_RADIUS_SMALL)
          .padding(AppTheme.SPACING_SMALL)
          .onChange((value: string) => { this.formNotes = value; })

        // 保存按钮
        CommonButton({
          text: this.isEditing ? '保存修改' : '创建档案',
          type: CustomButtonType.PRIMARY,
          size: ButtonSize.LARGE,
          disabled: !this.formName || !this.formRelationship,
          onClick: () => {
            this.saveRecipient();
          }
        })
        .margin({ top: AppTheme.SPACING_LARGE, bottom: AppTheme.SPACING_XLARGE })
      }
      .padding(AppTheme.SPACING_MEDIUM)
    }
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Auto)
    .edgeEffect(EdgeEffect.Spring)
    .layoutWeight(1)
  }

  // ====== 关系进展时间线构建 ======
  @Builder
  TimelineBuilder() {
    Column() {
      // 返回按钮和标题
      Row() {
        Text('← 返回')
          .fontSize(AppTheme.FONT_SIZE_NORMAL)
          .fontColor(AppTheme.PRIMARY_COLOR)
          .onClick(() => {
            this.showTimeline = false;
          })

        Text(`${this.timelineRecipient?.name || ''} 的送花记录`)
          .fontSize(AppTheme.FONT_SIZE_MEDIUM)
          .fontColor(AppTheme.TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .margin({ left: AppTheme.SPACING_MEDIUM })
          .layoutWeight(1)
      }
      .width('100%')
      .margin({ bottom: AppTheme.SPACING_MEDIUM })

      // 时间线
      if (this.flowerRecords.length === 0) {
        Column() {
          Text('💐')
            .fontSize(40)
            .margin({ bottom: AppTheme.SPACING_MEDIUM })
          Text('暂无送花记录')
            .fontSize(AppTheme.FONT_SIZE_MEDIUM)
            .fontColor(AppTheme.TEXT_SECONDARY)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        Scroll() {
          Column() {
            ForEach(this.flowerRecords, (record: FlowerRecord, index: number) => {
              // 时间线项
              Row() {
                // 左侧时间线
                Column() {
                  // 圆点
                  Circle()
                    .width(12)
                    .height(12)
                    .fill(AppTheme.PRIMARY_COLOR)
                    .margin({ top: 4 })

                  // 竖线（非最后一项）
                  if (index < this.flowerRecords.length - 1) {
                    Line()
                      .width(2)
                      .height(60)
                      .backgroundColor(AppTheme.PRIMARY_COLOR_ALPHA20)
                      .margin({ top: 4 })
                  }
                }
                .alignItems(HorizontalAlign.Center)
                .margin({ right: AppTheme.SPACING_MEDIUM })

                // 右侧内容卡片
                Column() {
                  Text(record.date)
                    .fontSize(AppTheme.FONT_SIZE_SMALL)
                    .fontColor(AppTheme.TEXT_SECONDARY)

                  Text(`场景: ${record.scene}`)
                    .fontSize(AppTheme.FONT_SIZE_NORMAL)
                    .fontColor(AppTheme.TEXT_PRIMARY)
                    .fontWeight(FontWeight.Medium)
                    .margin({ top: AppTheme.SPACING_SMALL / 2 })

                  Text(`花束: ${record.bouquetName}`)
                    .fontSize(AppTheme.FONT_SIZE_NORMAL)
                    .fontColor(AppTheme.TEXT_PRIMARY)
                    .margin({ top: AppTheme.SPACING_SMALL / 2 })

                  Text(`反馈: ${record.feedback}`)
                    .fontSize(AppTheme.FONT_SIZE_SMALL)
                    .fontColor(AppTheme.TEXT_SECONDARY)
                    .margin({ top: AppTheme.SPACING_SMALL / 2 })
                }
                .padding(AppTheme.SPACING_MEDIUM)
                .backgroundColor(AppTheme.CARD_BACKGROUND)
                .borderRadius(AppTheme.BORDER_RADIUS_MEDIUM)
                .shadow({
                  radius: AppTheme.CARD_SHADOW_RADIUS,
                  color: AppTheme.CARD_SHADOW_COLOR,
                  offsetY: AppTheme.CARD_SHADOW_OFFSETY
                })
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
              }
              .width('100%')
              .margin({ bottom: AppTheme.SPACING_SMALL })
            }, (record: FlowerRecord, index: number) => `${index}`)

            // 添加记录按钮
            CommonButton({
              text: '+ 添加送花记录',
              type: CustomButtonType.OUTLINE,
              size: ButtonSize.MEDIUM,
              onClick: () => {
                console.info('添加送花记录');
              }
            })
            .margin({ top: AppTheme.SPACING_MEDIUM, bottom: AppTheme.SPACING_XLARGE })
          }
          .padding(AppTheme.SPACING_MEDIUM)
        }
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.Spring)
        .layoutWeight(1)
      }
    }
    .layoutWeight(1)
  }
}
