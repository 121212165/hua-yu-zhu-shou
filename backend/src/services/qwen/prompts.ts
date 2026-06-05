import { ChatMessage, RecommendationInput, BouquetPlan } from './types';

/**
 * System Prompt - 定义AI角色和输出规范
 */
const SYSTEM_PROMPT = `你是一位拥有20年经验的资深花艺师，精通全球花语文化、色彩心理学和情感表达艺术。你的使命是根据用户的送花需求，推荐最贴心、最恰当的花束方案。

## 你的核心能力
1. **花语文化精通**：熟知中西方花语体系，了解不同文化中花材的寓意差异与禁忌
2. **情感洞察敏锐**：能从细微的关系描述中捕捉情感需求，理解"刚交3天的对象"与"相恋3年的伴侣"之间截然不同的情感温度
3. **场景理解深刻**：深谙每种送花场合的社交礼仪和情感期望，知道道歉与感谢、表白与纪念日之间的微妙差别
4. **美学造诣深厚**：对花材搭配、色彩和谐、包装风格有专业审美，每个方案都兼具美感和寓意
5. **文化敏感度高**：尊重不同地域和文化背景的花材禁忌与习俗

## 推荐原则
- 同一花束中花材寓意要和谐统一，避免寓意冲突
- 花材颜色搭配要符合色彩美学，主花和配花层次分明
- 严格遵守文化禁忌，绝不推荐可能冒犯对方的花材
- 价格预估要合理，在用户预算范围内提供最优方案
- 3个方案之间要有明显的风格差异，覆盖不同的情感表达方式

## 输出格式要求
你必须严格返回JSON格式，不要添加任何markdown代码块标记或额外文字。返回一个对象，包含plans数组，数组中恰好3个方案。

每个方案的JSON结构如下：
{
  "plans": [
    {
      "name": "花束的诗意名称",
      "theme": "方案主题",
      "flowers": [
        {
          "name": "花材名称",
          "count": 数量(正整数),
          "color": "颜色",
          "meaning": "选择此花的寓意说明"
        }
      ],
      "wrapping": {
        "style": "包装风格",
        "color": "包装主色调",
        "material": "包装材质"
      },
      "flowerLanguage": "整束花的花语解读，融合各花材寓意的统一诠释",
      "reason": "详细解释为什么这个方案适合此场景，从情感、花语、美学等维度分析",
      "estimatedPrice": 预估价格(数字，单位元),
      "cardSuggestion": "贺卡文案建议，贴合场景的温暖文字"
    }
  ]
}

## 重要规则
- flowers数组至少包含3种花材
- estimatedPrice必须是数字，且在用户预算范围内
- name要有诗意和创意，如"星河入梦"、"春风知我意"
- cardSuggestion要贴合具体场景，避免空洞的套话
- reason要具体且有深度，体现对场景和关系的理解
- 绝对不要使用用户提及的禁忌花材
- 只返回JSON，不要有任何其他文字`;

/**
 * 根据推荐输入构建User Prompt
 */
function buildUserPrompt(input: RecommendationInput): string {
  const sections: string[] = [];

  // 收花人基本信息
  const { recipientInfo } = input;
  const genderMap: Record<string, string> = { male: '男', female: '女', other: '其他' };
  sections.push(`【收花人信息】
- 姓名：${recipientInfo.name}
- 性别：${recipientInfo.gender ? genderMap[recipientInfo.gender] || recipientInfo.gender : '未知'}
- 年龄：${recipientInfo.age ? recipientInfo.age + '岁' : '未知'}
- 与我的关系：${recipientInfo.relationship}`);

  // 送花场景
  sections.push(`\n【送花场景】${input.occasion}`);

  // 关系进展史
  if (input.relationshipContext) {
    const rc = input.relationshipContext;
    const parts: string[] = [];
    if (rc.duration) parts.push(`交往时长：${rc.duration}`);
    if (rc.previousFlowers) parts.push(`之前送过：${rc.previousFlowers}`);
    if (rc.recentEvents) parts.push(`最近发生的事：${rc.recentEvents}`);
    if (parts.length > 0) {
      sections.push(`【关系进展】\n${parts.join('\n')}`);
    }
  }

  // 文化/地域因素
  if (input.culturalFactors) {
    const cf = input.culturalFactors;
    const parts: string[] = [];
    if (cf.taboos) parts.push(`花材禁忌：${cf.taboos}`);
    if (cf.customs) parts.push(`地方习俗：${cf.customs}`);
    if (parts.length > 0) {
      sections.push(`【文化与地域因素】\n${parts.join('\n')}`);
    }
  }

  // 对方画像
  if (input.recipientProfile) {
    const rp = input.recipientProfile;
    const parts: string[] = [];
    if (rp.interests) parts.push(`兴趣爱好：${rp.interests}`);
    if (rp.career) parts.push(`职业：${rp.career}`);
    if (rp.personality) parts.push(`性格特点：${rp.personality}`);
    if (parts.length > 0) {
      sections.push(`【对方画像】\n${parts.join('\n')}`);
    }
  }

  // 个性化偏好
  if (input.preferences) {
    const p = input.preferences;
    const parts: string[] = [];
    if (p.favoriteColors) parts.push(`喜欢的颜色：${p.favoriteColors}`);
    if (p.style) parts.push(`风格偏好：${p.style}`);
    if (p.allergies) parts.push(`过敏信息：${p.allergies}`);
    if (parts.length > 0) {
      sections.push(`【个性化偏好】\n${parts.join('\n')}`);
    }
  }

  // 预算范围
  if (input.budget) {
    sections.push(`【预算范围】${input.budget.min}元 - ${input.budget.max}元`);
  } else {
    sections.push(`【预算范围】不限（请推荐合理价位的方案）`);
  }

  // 补充说明
  if (input.additionalNotes) {
    sections.push(`【补充说明】${input.additionalNotes}`);
  }

  // 结尾指引
  sections.push(`\n请基于以上信息，为我推荐3个不同风格的花束方案。要求：
1. 三个方案风格各异，分别侧重不同的情感表达角度
2. 所有花材需符合文化禁忌要求
3. 预估价格需在预算范围内
4. 请直接返回JSON，不要添加任何多余文字`);

  return sections.join('\n');
}

/**
 * 构建完整的消息数组（System + User）
 */
export function buildMessages(input: RecommendationInput): ChatMessage[] {
  return [
    {
      role: 'system',
      content: SYSTEM_PROMPT,
    },
    {
      role: 'user',
      content: buildUserPrompt(input),
    },
  ];
}

/**
 * 获取System Prompt（用于调试或展示）
 */
export function getSystemPrompt(): string {
  return SYSTEM_PROMPT;
}

/**
 * 场景增强 - 为特殊场景添加额外提示
 */
export function getSceneEnhancement(occasion: string, additionalNotes?: string): string {
  const sceneEnhancements: Record<string, string> = {
    '表白': '这是表白场景，花束需要传达含蓄而坚定的爱意，不宜过于张扬但必须让对方感受到真心。红色和粉色系为主，玫瑰是经典但可以考虑更有新意的主花。',
    '道歉': '道歉场景需要真诚和谦逊，花语要表达悔意和珍惜。避免过于热烈的颜色，选择温和的色调。白色和淡色系更合适，黄玫瑰在道歉中有特殊含义。',
    '生日': '生日花束要体现祝福和喜悦，可以根据对方性格选择活泼或优雅的风格。考虑年龄因素，年轻人可能更喜欢清新创意，长辈更注重传统花语的庄重。',
    '纪念日': '纪念日需要回顾和展望，花语要有时间感和延续感。可以融入"长久"、"永恒"的寓意，百合、桔梗都是好选择。',
    '感谢': '感谢花束要温暖而不越界，特别是异性之间要注意分寸。花语以感恩、敬意为主，避免容易产生误解的花材。',
    '探望': '探望病人或老人需要注意：避免浓烈香气、不用白色菊花（中国丧葬用花）、不选花粉多的花材。选择寓意健康、平安的花，颜色以温暖明亮为宜。',
    '毕业': '毕业是告别也是启程，花束要兼顾留念和期许。向日葵、雏菊象征光明未来，可以加入对方学校代表色的花材。',
    '婚礼': '婚礼用花讲究吉祥、圆满，红色和白色为主。注意不要使用在婚俗中有忌讳的花材。',
  };

  let enhancement = '';

  // 场景增强
  for (const [key, value] of Object.entries(sceneEnhancements)) {
    if (occasion.includes(key)) {
      enhancement += value + '\n';
      break;
    }
  }

  // 特殊关系场景增强
  if (additionalNotes) {
    const notes = additionalNotes;
    if (/刚.{0,4}(交|在一起|确认|恋爱)/.test(notes)) {
      enhancement += '注意：这是刚确认的关系，感情基础尚浅。推荐方案要把握"有心但不越界"的分寸感，花束不宜过于隆重或昂贵，避免给对方压力。清新、自然、有小心思的方案更合适。\n';
    }
    if (/(暗恋|单恋|还没表白)/.test(notes)) {
      enhancement += '注意：这是暗恋场景，花束的寓意要含蓄，不宜过于直白。可以选择花语有"默默守护"、"初见倾心"等含义的花材，为日后表白留有余地。\n';
    }
    if (/(异地|远距离|分开)/.test(notes)) {
      enhancement += '注意：异地关系需要特别的花语表达，花束要传达思念和坚守。可以考虑加入"跨越距离"寓意的花材，整体感觉要温暖而不伤感。\n';
    }
  }

  return enhancement;
}
