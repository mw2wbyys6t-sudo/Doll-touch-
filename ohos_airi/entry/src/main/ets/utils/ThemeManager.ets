import { PreferencesUtil } from './PreferencesUtil';

export type ThemeMode = 'light' | 'dark' | 'system';

export class ThemeManager {
  private static currentTheme: ThemeMode = 'light';
  private static listeners: Array<() => void> = [];
  
  private static readonly THEME_KEY = 'app_theme';

  static async init(): Promise<void> {
    const savedTheme = await PreferencesUtil.getString(this.THEME_KEY, 'light');
    this.currentTheme = savedTheme as ThemeMode || 'light';
  }

  static getCurrentTheme(): ThemeMode {
    return this.currentTheme;
  }

  static async setTheme(theme: ThemeMode): Promise<void> {
    this.currentTheme = theme;
    await PreferencesUtil.putString(this.THEME_KEY, theme);
    this.notifyListeners();
  }

  static toggleTheme(): Promise<void> {
    const themes: ThemeMode[] = ['light', 'dark', 'system'];
    const currentIndex = themes.indexOf(this.currentTheme);
    const nextIndex = (currentIndex + 1) % themes.length;
    return this.setTheme(themes[nextIndex]);
  }

  static isDarkMode(): boolean {
    if (this.currentTheme === 'system') {
      return window.matchMedia('(prefers-color-scheme: dark)').matches;
    }
    return this.currentTheme === 'dark';
  }

  static addListener(listener: () => void): void {
    if (!this.listeners.includes(listener)) {
      this.listeners.push(listener);
    }
  }

  static removeListener(listener: () => void): void {
    const index = this.listeners.indexOf(listener);
    if (index > -1) {
      this.listeners.splice(index, 1);
    }
  }

  private static notifyListeners(): void {
    this.listeners.forEach(listener => {
      try {
        listener();
      } catch (err) {
        console.error('ThemeManager notify listener error:', err);
      }
    });
  }

  static getThemeColors(): Record<string, string> {
    const isDark = this.isDarkMode();
    
    return isDark ? {
      primaryPink: '#ffb6c1',
      primaryPurple: '#dda0dd',
      primaryDarkPurple: '#8b5cf6',
      primaryRed: '#e91e63',
      bg: '#1a1a2e',
      bgCard: '#2d2d44',
      bgGradient: '#16213e',
      textPrimary: '#ffffff',
      textSecondary: '#b0b0b0',
      textTertiary: '#808080',
      border: '#3d3d5c',
      shadow: 'rgba(0, 0, 0, 0.3)'
    } : {
      primaryPink: '#ffb6c1',
      primaryPurple: '#dda0dd',
      primaryDarkPurple: '#8b5cf6',
      primaryRed: '#e91e63',
      bg: '#f3e5f5',
      bgCard: '#ffffff',
      bgGradient: '#fff0f5',
      textPrimary: '#333333',
      textSecondary: '#666666',
      textTertiary: '#999999',
      border: '#f0f0f0',
      shadow: 'rgba(0, 0, 0, 0.08)'
    };
  }
}