import { EmotionType } from '../core/EmotionStore';
export { EmotionType };

export interface EmotionAnalysis {
  emotion: EmotionType;
  intensity: number;
  keywords: string[];
  sentiment: 'positive' | 'neutral' | 'negative';
  needs: string[];
}

export interface EmotionalState {
  currentEmotion: EmotionType;
  intensity: number;
  recentHistory: EmotionType[];
  trend: 'improving' | 'stable' | 'declining';
}

export class EmotionUnderstanding {
  private static instance: EmotionUnderstanding | null = null;
  private emotionalState: EmotionalState = {
    currentEmotion: EmotionType.NEUTRAL,
    intensity: 0.5,
    recentHistory: [],
    trend: 'stable'
  };

  private emotionKeywords: Record<EmotionType, string[]> = {
    [EmotionType.HAPPY]: ['开心', '高兴', '快乐', '幸福', '棒', '好开心', '太棒了', '喜欢', '哈哈', '嘿嘿'],
    [EmotionType.SAD]: ['难过', '伤心', '痛苦', '失落', '沮丧', '郁闷', '不开心', '哭', '难过', '悲伤'],
    [EmotionType.ANGRY]: ['生气', '愤怒', '讨厌', '气死了', '烦', '不爽', '恼火', '火大'],
    [EmotionType.FEARFUL]: ['害怕', '担心', '恐惧', '紧张', '焦虑', '不安', '恐怖', '怕'],
    [EmotionType.SURPRISED]: ['惊讶', '震惊', '意外', '没想到', '真的吗', '哇', '不会吧'],
    [EmotionType.NEUTRAL]: [],
    [EmotionType.EXCITED]: ['兴奋', '激动', '太激动了', '超棒', '嗨', '兴奋', '疯狂'],
    [EmotionType.ANXIOUS]: ['焦虑', '烦躁', '着急', '不安', '压力', '怎么办', '担心'],
    [EmotionType.SHY]: ['害羞', '不好意思', '脸红', '腼腆', '羞', '难为情'],
    [EmotionType.EMBARRASSED]: ['尴尬', '糗', '出丑', '难堪', '下不来台'],
    [EmotionType.TIRED]: ['累', '疲惫', '困', '疲倦', '没精神', '想睡觉'],
    [EmotionType.CONFUSED]: ['困惑', '不明白', '不懂', '迷茫', '疑惑', '疑问'],
    [EmotionType.IDLE]: []
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
    '建议': ['怎么办', '怎么做', '选择', '决定'],
    '倾听': ['想说', '聊聊', '倾诉', '心事']
  };

  static getInstance(): EmotionUnderstanding {
    if (!EmotionUnderstanding.instance) {
      EmotionUnderstanding.instance = new EmotionUnderstanding();
    }
    return EmotionUnderstanding.instance;
  }

  analyzeText(text: string): EmotionAnalysis {
    const keywords: string[] = [];
    let detectedEmotion = EmotionType.NEUTRAL;
    let maxScore = 0;

    for (const [emotion, words] of Object.entries(this.emotionKeywords)) {
      const emotionType = emotion as EmotionType;
      let score = 0;
      for (const word of words) {
        if (text.indexOf(word) !== -1) {
          score++;
          if (keywords.indexOf(word) === -1) {
            keywords.push(word);
          }
        }
      }
      if (score > maxScore) {
        maxScore = score;
        detectedEmotion = emotionType;
      }
    }

    const sentiment = this.analyzeSentiment(text);
    const needs = this.identifyNeeds(text);
    const intensity = Math.min(1, maxScore * 0.3 + Math.abs(this.calculateSentimentScore(text)) * 0.5);

    this.updateEmotionalState(detectedEmotion, intensity);

    return {
      emotion: detectedEmotion,
      intensity,
      keywords,
      sentiment,
      needs
    };
  }

  private analyzeSentiment(text: string): 'positive' | 'neutral' | 'negative' {
    const score = this.calculateSentimentScore(text);
    if (score > 0.3) return 'positive';
    if (score < -0.3) return 'negative';
    return 'neutral';
  }

  private calculateSentimentScore(text: string): number {
    let score = 0;
    let count = 0;

    for (const [indicator, value] of Object.entries(this.sentimentIndicators)) {
      if (text.indexOf(indicator) !== -1) {
        score += value;
        count++;
      }
    }

    return count > 0 ? score / count : 0;
  }

  private identifyNeeds(text: string): string[] {
    const needs: string[] = [];

    for (const [need, indicators] of Object.entries(this.needIndicators)) {
      for (const indicator of indicators) {
        if (text.indexOf(indicator) !== -1) {
          if (needs.indexOf(need) === -1) {
            needs.push(need);
          }
          break;
        }
      }
    }

    return needs;
  }

  private updateEmotionalState(emotion: EmotionType, intensity: number): void {
    this.emotionalState.currentEmotion = emotion;
    this.emotionalState.intensity = intensity;
    this.emotionalState.recentHistory.push(emotion);

    if (this.emotionalState.recentHistory.length > 10) {
      this.emotionalState.recentHistory.shift();
    }

    this.emotionalState.trend = this.calculateTrend();
  }

  private calculateTrend(): 'improving' | 'stable' | 'declining' {
    if (this.emotionalState.recentHistory.length < 3) {
      return 'stable';
    }

    const recent = this.emotionalState.recentHistory.slice(-3);
    const positiveEmotions = [EmotionType.HAPPY, EmotionType.EXCITED, EmotionType.SURPRISED];
    const negativeEmotions = [EmotionType.SAD, EmotionType.ANGRY, EmotionType.ANXIOUS, EmotionType.FEARFUL];

    let positiveCount = 0;
    let negativeCount = 0;

    for (const emotion of recent) {
      if (positiveEmotions.indexOf(emotion) !== -1) positiveCount++;
      if (negativeEmotions.indexOf(emotion) !== -1) negativeCount++;
    }

    if (positiveCount > negativeCount) return 'improving';
    if (negativeCount > positiveCount) return 'declining';
    return 'stable';
  }

  getEmotionColor(emotion: EmotionType): string {
    const colorMap: Record<EmotionType, string> = {
      [EmotionType.HAPPY]: '#FFD700',
      [EmotionType.SAD]: '#4169E1',
      [EmotionType.ANGRY]: '#FF4500',
      [EmotionType.FEARFUL]: '#800080',
      [EmotionType.SURPRISED]: '#FF69B4',
      [EmotionType.NEUTRAL]: '#9B64DC',
      [EmotionType.EXCITED]: '#FF8C00',
      [EmotionType.ANXIOUS]: '#20B2AA',
      [EmotionType.SHY]: '#FFB6C1',
      [EmotionType.EMBARRASSED]: '#DDA0DD',
      [EmotionType.TIRED]: '#708090',
      [EmotionType.CONFUSED]: '#DAA520',
      [EmotionType.IDLE]: '#9B64DC'
    };
    return colorMap[emotion] || '#9B64DC';
  }

  getEmotionalState(): EmotionalState {
    return { ...this.emotionalState };
  }

  resetState(): void {
    this.emotionalState = {
      currentEmotion: EmotionType.NEUTRAL,
      intensity: 0.5,
      recentHistory: [],
      trend: 'stable'
    };
  }
}
