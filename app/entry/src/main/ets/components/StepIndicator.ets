// 步骤指示器组件

import { AppTheme } from '../common/Theme';

// 步骤数据结构
interface StepItem {
  title: string;
  isCompleted: boolean;
  isCurrent: boolean;
}

@Component
export struct StepIndicator {
  // 步骤列表
  @Prop steps: StepItem[] = [];
  // 当前步骤索引
  @Prop currentStep: number = 0;

  build() {
    Row() {
      ForEach(this.steps, (step: StepItem, index?: number) => {
        // 步骤圆点 + 标题
        Row() {
          // 圆点
          Circle()
            .width(step.isCurrent ? 24 : 20)
            .height(step.isCurrent ? 24 : 20)
            .fill(step.isCurrent ? AppTheme.PRIMARY_COLOR :
              step.isCompleted ? AppTheme.SECONDARY_COLOR : AppTheme.DISABLED_COLOR)
            .stroke(step.isCurrent ? AppTheme.PRIMARY_COLOR :
              step.isCompleted ? AppTheme.SECONDARY_COLOR : AppTheme.DISABLED_COLOR)
            .strokeWidth(2)

          // 连接线（非最后一个步骤）- 使用Rect代替Line
          if (index !== undefined && index < this.steps.length - 1) {
            Row()
              .width(30)
              .height(2)
              .backgroundColor(step.isCompleted ? AppTheme.SECONDARY_COLOR : AppTheme.DISABLED_COLOR)
              .margin({ left: AppTheme.SPACING_SMALL, right: AppTheme.SPACING_SMALL })
          }

          // 步骤标题
          Text(step.title)
            .fontSize(AppTheme.FONT_SIZE_SMALL)
            .fontColor(step.isCurrent ? AppTheme.PRIMARY_COLOR :
              step.isCompleted ? AppTheme.SECONDARY_COLOR : AppTheme.TEXT_SECONDARY)
            .fontWeight(step.isCurrent ? FontWeight.Bold : FontWeight.Normal)
            .margin({ left: 4 })
        }
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
      }, (step: StepItem, index?: number) => `${index}`)
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .padding({ top: AppTheme.SPACING_MEDIUM, bottom: AppTheme.SPACING_MEDIUM })
  }
}