// hvigor构建脚本

export default {
  // 构建系统配置
  system: {
    // 构建工具版本
    hvigorVersion: '4.0.2',
    // 构建插件配置
    plugins: [
      {
        name: 'entry',
        moduleType: 'entry',
        srcPath: './entry'
      }
    ]
  },
  // 模块配置
  modules: {
    // entry模块
    'entry': {
      buildMode: 'default'
    }
  }
}