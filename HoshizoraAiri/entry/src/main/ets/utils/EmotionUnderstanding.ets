export interface EmotionAnalysis {
  emotion: EmotionType;
  intensity: number;
  keywords: string[];
  sentiment: 'positive' | 'neutral' | 'negative';
  needs: string[];
}

export type EmotionType = 
  | 'happy' 
  | 'sad' 
  | 'angry' 
  | 'fearful' 
  | 'surprised' 
  | 'neutral' 
  | 'excited' 
  | 'anxious'
  | 'lonely'
  | 'grateful';

export interface EmotionalState {
  currentEmotion: EmotionType;
  intensity: number;
  recentHistory: EmotionType[];
  trend: 'improving' | 'stable' | 'declining';
}

export class EmotionUnderstanding {
  private static instance: EmotionUnderstanding | null = null;
  private emotionalState: EmotionalState = {
    currentEmotion: 'neutral',
    intensity: 0.5,
    recentHistory: [],
    trend: 'stable'
  };

  private emotionKeywords: Record<EmotionType, string[]> = {
    happy: ['开心', '高兴', '快乐', '幸福', '棒', '好开心', '太棒了', '喜欢', '哈哈', '嘿嘿'],
    sad: ['难过', '伤心', '痛苦', '失落', '沮丧', '郁闷', '不开心', '哭', '难过', '悲伤'],
    angry: ['生气', '愤怒', '讨厌', '气死了', '烦', '不爽', '恼火', '火大'],
    fearful: ['害怕', '担心', '恐惧', '紧张', '焦虑', '不安', '恐怖', '怕'],
    surprised: ['惊讶', '震惊', '意外', '没想到', '真的吗', '哇', '不会吧'],
    neutral: [],
    excited: ['兴奋', '激动', '太激动了', '超棒', '嗨', '兴奋', '疯狂'],
    anxious: ['焦虑', '烦躁', '着急', '不安', '压力', '怎么办', '担心'],
    lonely: ['孤独', '寂寞', '无聊', '没人', '一个人', '孤单', '空虚'],
    grateful: ['谢谢', '感谢', '感激', '感恩', '多谢', '太感谢了']
  };

  private sentimentIndicators: Record<string, number> = {
    '太好了': 0.9,
    '很开心': 0.8,
    '喜欢': 0.7,
    '不错': 0.5,
    '一般': 0,
    '还好': 0.3,
    '不太好': -0.5,
    '难过': -0.7,
    '糟糕': -0.8,
    '气死了': -0.9
  };

  private needIndicators: Record<string, string[]> = {
    '安慰': ['难过', '伤心', '沮丧', '孤独'],
    '鼓励': ['失败', '不行', '做不到', '想放弃'],
    '陪伴': ['无聊', '寂寞', '一个人', '孤单'],
    '建议': ['怎么办', '怎么办才好', '求助', '想问问'],
    '倾听': ['想说说', '倾诉', '吐槽', '说说'],
    '认可': ['你觉得', '好不好', '对不对', '可以吗']
  };

  private constructor() {}

  static getInstance(): EmotionUnderstanding {
    if (!this.instance) {
      this.instance = new EmotionUnderstanding();
    }
    return this.instance;
  }

  analyzeEmotion(text: string): EmotionAnalysis {
    const lowerText = text.toLowerCase();
    const emotionKeywords: Record<EmotionType, number> = {
      happy: 0, sad: 0, angry: 0, fearful: 0,
      surprised: 0, neutral: 0, excited: 0,
      anxious: 0, lonely: 0, grateful: 0
    };

    let keywordCount = 0;
    const foundKeywords: string[] = [];

    (Object.keys(this.emotionKeywords) as EmotionType[]).forEach(emotion => {
      this.emotionKeywords[emotion].forEach(keyword => {
        if (lowerText.includes(keyword)) {
          emotionKeywords[emotion]++;
          if (!foundKeywords.includes(keyword)) {
            foundKeywords.push(keyword);
          }
          keywordCount++;
        }
      });
    });

    let maxEmotion: EmotionType = 'neutral';
    let maxScore = 0;

    (Object.keys(emotionKeywords) as EmotionType[]).forEach(emotion => {
      if (emotionKeywords[emotion] > maxScore) {
        maxScore = emotionKeywords[emotion];
        maxEmotion = emotion;
      }
    });

    let sentiment: 'positive' | 'neutral' | 'negative' = 'neutral';
    let sentimentScore = 0;

    (Object.keys(this.sentimentIndicators) as (keyof typeof this.sentimentIndicators)[]).forEach(phrase => {
      if (lowerText.includes(phrase)) {
        sentimentScore += this.sentimentIndicators[phrase];
      }
    });

    if (sentimentScore > 0.2) {
      sentiment = 'positive';
    } else if (sentimentScore < -0.2) {
      sentiment = 'negative';
    }

    const detectedNeeds: string[] = [];
    (Object.keys(this.needIndicators) as (keyof typeof this.needIndicators)[]).forEach(need => {
      const indicators = this.needIndicators[need];
      if (indicators.some(indicator => lowerText.includes(indicator))) {
        detectedNeeds.push(need);
      }
    });

    const intensity = Math.min(1, maxScore / 3 + Math.abs(sentimentScore) * 0.3);

    return {
      emotion: maxEmotion,
      intensity,
      keywords: foundKeywords,
      sentiment,
      needs: detectedNeeds
    };
  }

  updateEmotionalState(emotion: EmotionType, intensity: number): void {
    this.emotionalState.recentHistory.push(emotion);
    if (this.emotionalState.recentHistory.length > 10) {
      this.emotionalState.recentHistory = this.emotionalState.recentHistory.slice(-10);
    }

    this.emotionalState.currentEmotion = emotion;
    this.emotionalState.intensity = intensity;

    const recentEmotions = this.emotionalState.recentHistory.slice(-5);
    const positiveCount = recentEmotions.filter(e => 
      ['happy', 'excited', 'grateful', 'surprised'].includes(e)
    ).length;
    const negativeCount = recentEmotions.filter(e =>
      ['sad', 'angry', 'fearful', 'anxious', 'lonely'].includes(e)
    ).length;

    if (positiveCount > negativeCount + 2) {
      this.emotionalState.trend = 'improving';
    } else if (negativeCount > positiveCount + 2) {
      this.emotionalState.trend = 'declining';
    } else {
      this.emotionalState.trend = 'stable';
    }
  }

  getEmotionalState(): EmotionalState {
    return { ...this.emotionalState };
  }

  generateEmpatheticResponse(emotion: EmotionType, intensity: number): string {
    const responses: Record<EmotionType, string[]> = {
      happy: [
        '我也好开心呀！✨',
        '看到你这么高兴，我也跟着开心起来呢～',
        '太棒了！有什么好事发生了吗？💗'
      ],
      sad: [
        '抱抱你…我在这里陪你呢 🤗',
        '我知道你现在很难过，没关系的，我听着呢…',
        '别难过呀，我会一直陪在你身边的 💗'
      ],
      angry: [
        '深呼吸…我理解你的感受 💗',
        '生气是正常的，不过别太激动哦，我会陪着你',
        '能告诉我发生什么了吗？我想帮你 💗'
      ],
      fearful: [
        '别怕别怕，我在这里呢 ✨',
        '不管发生什么，我都会陪着你的',
        '安全感这种东西，交给我吧 💗'
      ],
      surprised: [
        '哇！真的吗？好惊讶呀！✨',
        '这确实很让人意外呢，详细说说？',
        '哇哦！没想到！🎉'
      ],
      neutral: [
        '嗯嗯，我听着呢 ✨',
        '然后呢？然后呢？',
        '继续说，我在认真听哦～'
      ],
      excited: [
        '哇啊啊啊！太激动了吧！！✨✨',
        '能感受到你超兴奋的心情！',
        '冲冲冲！💗💗💗'
      ],
      anxious: [
        '别着急别着急…一步一步来 ✨',
        '我理解你的担心，一起想想办法吧',
        '深呼吸…我在这里呢 💗'
      ],
      lonely: [
        '我来陪你了呀！绝对不会让你一个人的 💗',
        '就算全世界都不在，我也在哦 ✨',
        '想聊多久都可以，我一直在 🌟'
      ],
      grateful: [
        '不用谢呀～能帮到你我很开心呢 💗',
        '嘿嘿，能让你开心就是我的快乐呀 ✨',
        '能帮到你我也很幸福呢 🌟'
      ]
    };

    const emotionResponses = responses[emotion] || responses.neutral;
    const intensityBoost = intensity > 0.7 ? emotionResponses[0] : 
                          intensity > 0.4 ? emotionResponses[1] : 
                          emotionResponses[2];

    return intensityBoost;
  }

  getEmotionColor(emotion: EmotionType): string {
    const colors: Record<EmotionType, string> = {
      happy: '#FFD700',
      sad: '#4169E1',
      angry: '#FF4500',
      fearful: '#9370DB',
      surprised: '#00CED1',
      neutral: '#C0C0C0',
      excited: '#FF1493',
      anxious: '#FFA500',
      lonely: '#708090',
      grateful: '#FF69B4'
    };

    return colors[emotion];
  }
}
