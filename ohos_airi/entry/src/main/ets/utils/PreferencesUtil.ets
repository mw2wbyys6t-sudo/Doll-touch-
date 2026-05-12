import { Preferences, BusinessError } from '@kit.DataStorageKit';

export class PreferencesUtil {
  private static preferences: Preferences | null = null;
  private static readonly PREFERENCES_NAME = 'airi_prefs';
  
  static async init(context: Context): Promise<void> {
    try {
      this.preferences = await Preferences.getPreferences(context, this.PREFERENCES_NAME);
    } catch (err) {
      console.error('PreferencesUtil init failed:', err);
    }
  }

  static async getString(key: string, defaultValue: string = ''): Promise<string> {
    if (!this.preferences) return defaultValue;
    try {
      return await this.preferences.get(key, defaultValue) as string;
    } catch (err) {
      console.error('PreferencesUtil getString failed:', err);
      return defaultValue;
    }
  }

  static async putString(key: string, value: string): Promise<void> {
    if (!this.preferences) return;
    try {
      await this.preferences.put(key, value);
      await this.preferences.flush();
    } catch (err) {
      console.error('PreferencesUtil putString failed:', err);
    }
  }

  static async getBoolean(key: string, defaultValue: boolean = false): Promise<boolean> {
    if (!this.preferences) return defaultValue;
    try {
      return await this.preferences.get(key, defaultValue) as boolean;
    } catch (err) {
      console.error('PreferencesUtil getBoolean failed:', err);
      return defaultValue;
    }
  }

  static async putBoolean(key: string, value: boolean): Promise<void> {
    if (!this.preferences) return;
    try {
      await this.preferences.put(key, value);
      await this.preferences.flush();
    } catch (err) {
      console.error('PreferencesUtil putBoolean failed:', err);
    }
  }

  static async getNumber(key: string, defaultValue: number = 0): Promise<number> {
    if (!this.preferences) return defaultValue;
    try {
      return await this.preferences.get(key, defaultValue) as number;
    } catch (err) {
      console.error('PreferencesUtil getNumber failed:', err);
      return defaultValue;
    }
  }

  static async putNumber(key: string, value: number): Promise<void> {
    if (!this.preferences) return;
    try {
      await this.preferences.put(key, value);
      await this.preferences.flush();
    } catch (err) {
      console.error('PreferencesUtil putNumber failed:', err);
    }
  }

  static async delete(key: string): Promise<void> {
    if (!this.preferences) return;
    try {
      await this.preferences.delete(key);
      await this.preferences.flush();
    } catch (err) {
      console.error('PreferencesUtil delete failed:', err);
    }
  }

  static async clear(): Promise<void> {
    if (!this.preferences) return;
    try {
      await this.preferences.clear();
      await this.preferences.flush();
    } catch (err) {
      console.error('PreferencesUtil clear failed:', err);
    }
  }
}