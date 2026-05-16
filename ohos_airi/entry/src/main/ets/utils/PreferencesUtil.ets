import { preferences } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';

export class PreferencesUtil {
  private static dataPreferences: preferences.Preferences | null = null;
  private static readonly PREFERENCES_NAME = 'airi_prefs';
  private static isInitialized: boolean = false;
  
  static async init(context: Context): Promise<void> {
    if (this.isInitialized && this.dataPreferences) {
      return;
    }
    
    try {
      this.dataPreferences = await preferences.getPreferences(context, this.PREFERENCES_NAME);
      this.isInitialized = true;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`PreferencesUtil init failed, code: ${error.code}, message: ${error.message}`);
    }
  }

  static async getString(key: string, defaultValue: string = ''): Promise<string> {
    if (!this.dataPreferences) {
      console.warn('PreferencesUtil: preferences not initialized');
      return defaultValue;
    }
    
    try {
      return await this.dataPreferences.get(key, defaultValue) as string;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`PreferencesUtil getString failed, key: ${key}, code: ${error.code}`);
      return defaultValue;
    }
  }

  static async putString(key: string, value: string): Promise<void> {
    if (!this.dataPreferences) {
      console.warn('PreferencesUtil: preferences not initialized');
      return;
    }
    
    try {
      await this.dataPreferences.put(key, value);
      await this.dataPreferences.flush();
    } catch (err) {
      const error = err as BusinessError;
      console.error(`PreferencesUtil putString failed, key: ${key}, code: ${error.code}`);
    }
  }

  static async getBoolean(key: string, defaultValue: boolean = false): Promise<boolean> {
    if (!this.dataPreferences) {
      return defaultValue;
    }
    
    try {
      return await this.dataPreferences.get(key, defaultValue) as boolean;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`PreferencesUtil getBoolean failed, key: ${key}, code: ${error.code}`);
      return defaultValue;
    }
  }

  static async putBoolean(key: string, value: boolean): Promise<void> {
    if (!this.dataPreferences) {
      return;
    }
    
    try {
      await this.dataPreferences.put(key, value);
      await this.dataPreferences.flush();
    } catch (err) {
      const error = err as BusinessError;
      console.error(`PreferencesUtil putBoolean failed, key: ${key}, code: ${error.code}`);
    }
  }

  static async getNumber(key: string, defaultValue: number = 0): Promise<number> {
    if (!this.dataPreferences) {
      return defaultValue;
    }
    
    try {
      return await this.dataPreferences.get(key, defaultValue) as number;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`PreferencesUtil getNumber failed, key: ${key}, code: ${error.code}`);
      return defaultValue;
    }
  }

  static async putNumber(key: string, value: number): Promise<void> {
    if (!this.dataPreferences) {
      return;
    }
    
    try {
      await this.dataPreferences.put(key, value);
      await this.dataPreferences.flush();
    } catch (err) {
      const error = err as BusinessError;
      console.error(`PreferencesUtil putNumber failed, key: ${key}, code: ${error.code}`);
    }
  }

  static async getObject<T>(key: string, defaultValue?: T): Promise<T | undefined> {
    if (!this.dataPreferences) {
      return defaultValue;
    }
    try {
      const data = await this.dataPreferences.get(key, '') as string;
      if (!data) {
        return defaultValue;
      }
      return JSON.parse(data) as T;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`PreferencesUtil getObject failed, key: ${key}, code: ${error.code}`);
      return defaultValue;
    }
  }

  static async putObject<T>(key: string, value: T): Promise<void> {
    if (!this.dataPreferences) {
      return;
    }
    try {
      await this.dataPreferences.put(key, JSON.stringify(value));
      await this.dataPreferences.flush();
    } catch (err) {
      const error = err as BusinessError;
      console.error(`PreferencesUtil putObject failed, key: ${key}, code: ${error.code}`);
    }
  }

  static async delete(key: string): Promise<void> {
    if (!this.dataPreferences) {
      return;
    }
    
    try {
      await this.dataPreferences.delete(key);
      await this.dataPreferences.flush();
    } catch (err) {
      const error = err as BusinessError;
      console.error(`PreferencesUtil delete failed, key: ${key}, code: ${error.code}`);
    }
  }

  static async clear(): Promise<void> {
    if (!this.dataPreferences) {
      return;
    }
    
    try {
      await this.dataPreferences.clear();
      await this.dataPreferences.flush();
    } catch (err) {
      const error = err as BusinessError;
      console.error(`PreferencesUtil clear failed, code: ${error.code}`);
    }
  }
}