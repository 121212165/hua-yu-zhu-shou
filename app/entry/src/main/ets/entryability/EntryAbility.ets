// EntryAbility - 应用入口能力

import { UIAbility, AbilityConstant, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';

export class EntryAbility extends UIAbility {
  // Ability创建回调
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    console.info('[EntryAbility] onCreate');
  }

  // 窗户创建回调 - 设置主窗口
  onWindowStageCreate(windowStage: window.WindowStage): void {
    console.info('[EntryAbility] onWindowStageCreate');

    // 设置主窗口内容
    windowStage.loadContent('pages/Index', (err, data) => {
      if (err.code) {
        console.error('[EntryAbility] loadContent failed: ' + JSON.stringify(err));
        return;
      }
      console.info('[EntryAbility] loadContent success');
    });
  }

  // Ability进入前台回调
  onForeground(): void {
    console.info('[EntryAbility] onForeground');
  }

  // Ability进入后台回调
  onBackground(): void {
    console.info('[EntryAbility] onBackground');
  }

  // 窗口销毁回调
  onWindowStageDestroy(): void {
    console.info('[EntryAbility] onWindowStageDestroy');
  }

  // Ability销毁回调
  onDestroy(): void {
    console.info('[EntryAbility] onDestroy');
  }
}