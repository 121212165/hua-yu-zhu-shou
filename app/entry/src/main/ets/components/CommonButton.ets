// 通用按钮组件

import { AppTheme } from '../common/Theme';

// 自定义按钮样式枚举（避免与系统ButtonType冲突）
export enum CustomButtonType {
  PRIMARY,    // 主按钮 - 粉色背景
  SECONDARY,  // 辅按钮 - 绿色背景
  OUTLINE,    // 线框按钮 - 粉色边框
  TEXT        // 文字按钮 - 无背景
}

// 按钮尺寸枚举
export enum ButtonSize {
  LARGE,      // 大按钮
  MEDIUM,     // 中按钮
  SMALL       // 小按钮
}

@Component
export struct CommonButton {
  // 按钮文字
  @Prop text: string = '';
  // 按钮类型
  @Prop type: CustomButtonType = CustomButtonType.PRIMARY;
  // 按钮尺寸
  @Prop size: ButtonSize = ButtonSize.MEDIUM;
  // 是否禁用
  @Prop disabled: boolean = false;
  // 点击回调
  onClick?: () => void;

  // 获取按钮背景色
  private getBackgroundColor(): ResourceColor {
    if (this.disabled) {
      return AppTheme.DISABLED_COLOR;
    }
    switch (this.type) {
      case CustomButtonType.PRIMARY:
        return AppTheme.PRIMARY_COLOR;
      case CustomButtonType.SECONDARY:
        return AppTheme.SECONDARY_COLOR;
      case CustomButtonType.OUTLINE:
        return Color.Transparent;
      case CustomButtonType.TEXT:
        return Color.Transparent;
      default:
        return AppTheme.PRIMARY_COLOR;
    }
  }

  // 获取按钮文字颜色
  private getTextColor(): ResourceColor {
    if (this.disabled) {
      return '#FFFFFF';
    }
    switch (this.type) {
      case CustomButtonType.PRIMARY:
        return '#FFFFFF';
      case CustomButtonType.SECONDARY:
        return '#FFFFFF';
      case CustomButtonType.OUTLINE:
        return AppTheme.PRIMARY_COLOR;
      case CustomButtonType.TEXT:
        return AppTheme.PRIMARY_COLOR;
      default:
        return '#FFFFFF';
    }
  }

  // 获取按钮高度
  private getButtonHeight(): number {
    switch (this.size) {
      case ButtonSize.LARGE:
        return 48;
      case ButtonSize.MEDIUM:
        return 40;
      case ButtonSize.SMALL:
        return 32;
      default:
        return 40;
    }
  }

  // 获取按钮字体大小
  private getFontSize(): number {
    switch (this.size) {
      case ButtonSize.LARGE:
        return AppTheme.FONT_SIZE_MEDIUM;
      case ButtonSize.MEDIUM:
        return AppTheme.FONT_SIZE_NORMAL;
      case ButtonSize.SMALL:
        return AppTheme.FONT_SIZE_SMALL;
      default:
        return AppTheme.FONT_SIZE_NORMAL;
    }
  }

  build() {
    Button(this.text)
      .width(this.size === ButtonSize.LARGE ? '100%' : undefined)
      .height(this.getButtonHeight())
      .fontSize(this.getFontSize())
      .fontColor(this.getTextColor())
      .backgroundColor(this.getBackgroundColor())
      .borderRadius(AppTheme.BORDER_RADIUS_MEDIUM)
      .border(this.type === CustomButtonType.OUTLINE && !this.disabled ? {
        width: 1,
        color: AppTheme.PRIMARY_COLOR,
        style: BorderStyle.Solid
      } : undefined)
      .type(ButtonType.Capsule)
      .enabled(!this.disabled)
      .onClick(() => {
        if (!this.disabled && this.onClick) {
          this.onClick();
        }
      })
  }
}