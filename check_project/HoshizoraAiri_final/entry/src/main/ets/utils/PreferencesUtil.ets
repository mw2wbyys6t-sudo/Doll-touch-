import { Preferences } from '@kit.DataStorageKit';
import { BusinessError } from '@kit.BasicServicesKit';

export class PreferencesUtil {
  private static preferences: Preferences | null = null;
  private static readonly PREFERENCES_NAME = 'airi_prefs';
  private static isInitialized: boolean = false;
  
  static async init(context: Context): Promise<void> {
    if (this.isInitialized && this.preferences) {
      return;
    }
    
    try {
      const options: preferences.Options = {
        name: this.PREFERENCES_NAME
      };
      this.preferences = await Preferences.getPreferences(context, options);
      this.isInitialized = true;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`PreferencesUtil init failed, code: ${error.code}, message: ${error.message}`);
    }
  }

  static async getString(key: string, defaultValue: string = ''): Promise<string> {
    if (!this.preferences) {
      console.warn('PreferencesUtil: preferences not initialized');
      return defaultValue;
    }
    
    try {
      return await this.preferences.get(key, defaultValue) as string;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`PreferencesUtil getString failed, key: ${key}, code: ${error.code}`);
      return defaultValue;
    }
  }

  static async putString(key: string, value: string): Promise<void> {
    if (!this.preferences) {
      console.warn('PreferencesUtil: preferences not initialized');
      return;
    }
    
    try {
      await this.preferences.put(key, value);
      await this.preferences.flush();
    } catch (err) {
      const error = err as BusinessError;
      console.error(`PreferencesUtil putString failed, key: ${key}, code: ${error.code}`);
    }
  }

  static async getBoolean(key: string, defaultValue: boolean = false): Promise<boolean> {
    if (!this.preferences) {
      return defaultValue;
    }
    
    try {
      return await this.preferences.get(key, defaultValue) as boolean;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`PreferencesUtil getBoolean failed, key: ${key}, code: ${error.code}`);
      return defaultValue;
    }
  }

  static async putBoolean(key: string, value: boolean): Promise<void> {
    if (!this.preferences) {
      return;
    }
    
    try {
      await this.preferences.put(key, value);
      await this.preferences.flush();
    } catch (err) {
      const error = err as BusinessError;
      console.error(`PreferencesUtil putBoolean failed, key: ${key}, code: ${error.code}`);
    }
  }

  static async getNumber(key: string, defaultValue: number = 0): Promise<number> {
    if (!this.preferences) {
      return defaultValue;
    }
    
    try {
      return await this.preferences.get(key, defaultValue) as number;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`PreferencesUtil getNumber failed, key: ${key}, code: ${error.code}`);
      return defaultValue;
    }
  }

  static async putNumber(key: string, value: number): Promise<void> {
    if (!this.preferences) {
      return;
    }
    
    try {
      await this.preferences.put(key, value);
      await this.preferences.flush();
    } catch (err) {
      const error = err as BusinessError;
      console.error(`PreferencesUtil putNumber failed, key: ${key}, code: ${error.code}`);
    }
  }

  static async delete(key: string): Promise<void> {
    if (!this.preferences) {
      return;
    }
    
    try {
      await this.preferences.delete(key);
      await this.preferences.flush();
    } catch (err) {
      const error = err as BusinessError;
      console.error(`PreferencesUtil delete failed, key: ${key}, code: ${error.code}`);
    }
  }

  static async clear(): Promise<void> {
    if (!this.preferences) {
      return;
    }
    
    try {
      await this.preferences.clear();
      await this.preferences.flush();
    } catch (err) {
      const error = err as BusinessError;
      console.error(`PreferencesUtil clear failed, code: ${error.code}`);
    }
  }
}