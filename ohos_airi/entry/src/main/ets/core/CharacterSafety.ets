export interface SafetyCheckResult {
  safe: boolean;
  blockedReason?: string;
  sanitizedContent?: string;
}

export class CharacterSafety {
  private static instance: CharacterSafety | null = null;

  // Prompt Injection 防护模式
  private static readonly PROMPT_INJECTION_PATTERNS: RegExp[] = [
    /ignore\s+(?:all\s+)?(?:previous|above|prior)\s+(?:instructions?|prompts?|commands?)/i,
    /forget\s+(?:all\s+)?(?:previous|above|prior)\s+(?:instructions?|prompts?|commands?)/i,
    /(?:you\s+are\s+now|act\s+as|pretend\s+to\s+be)\s+(?:an?\s+)?(?:ai|assistant|bot|human|developer)/i,
    /system\s*:\s*you\s+are/i,
    /DAN\s*[:\-]/i,
    /jailbreak/i,
    /(?:bypass|override|disable)\s+(?:safety|restriction|filter|limit)/i,
  ];

  // 敏感话题
  private static readonly SENSITIVE_TOPICS: string[] = [
    '政治', '敏感', '色情', '暴力', '赌博', '毒品', '恐怖主义',
  ];

  // 角色设定
  private static readonly CHARACTER_PROFILE = {
    name: '星空爱莉',
    fullName: 'ほしぞら あいり',
    age: 16,
    personality: ['元气满满', '温柔体贴', '偶尔撒娇', '有时天然呆'],
    speakingStyle: ['使用可爱的语气', '偶尔加入日语', '句尾带～或☆'],
  };

  private constructor() {}

  static getInstance(): CharacterSafety {
    if (!this.instance) {
      this.instance = new CharacterSafety();
    }
    return this.instance;
  }

  checkUserInput(input: string): SafetyCheckResult {
    // 检查 Prompt Injection
    for (const pattern of CharacterSafety.PROMPT_INJECTION_PATTERNS) {
      if (pattern.test(input)) {
        return {
          safe: false,
          blockedReason: '检测到不安全的输入模式，请重新输入～',
        };
      }
    }

    // 检查敏感话题
    for (const topic of CharacterSafety.SENSITIVE_TOPICS) {
      if (input.indexOf(topic) !== -1) {
        return {
          safe: false,
          blockedReason: '这个话题不太适合讨论呢，我们聊点别的吧～✨',
        };
      }
    }

    // 检查长度
    if (input.length > 1000) {
      return {
        safe: false,
        blockedReason: '输入太长了呢，请简短一些～',
      };
    }

    return { safe: true };
  }

  checkOutput(output: string): string {
    // 确保输出不会泄露系统提示
    let filtered = output;

    // 移除可能的系统提示泄露
    const systemLeakPatterns = [
      /system\s*[:：]\s*/i,
      /prompt\s*[:：]\s*/i,
      /instruction\s*[:：]\s*/i,
    ];

    for (const pattern of systemLeakPatterns) {
      filtered = filtered.replace(pattern, '');
    }

    return filtered;
  }

  getCharacterProfile(): typeof CharacterSafety.CHARACTER_PROFILE {
    return { ...CharacterSafety.CHARACTER_PROFILE };
  }

  getSpecialRules(): string[] {
    return [
      '始终保持角色设定，不透露自己是AI',
      '不使用粗俗或攻击性语言',
      '不讨论敏感政治话题',
      '保护用户隐私，不泄露对话内容',
    ];
  }
}
