import { promises as fs } from 'fs';
import path from 'path';
import os from 'os';
import SettingsManager from '../../src/managers/settings-manager';
import type { UserSettings } from '../../src/types';

// Mock fs module
jest.mock('fs', () => ({
  promises: {
    mkdir: jest.fn(),
    readFile: jest.fn(),
    writeFile: jest.fn()
  }
}));

// Mock utils
jest.mock('../../src/utils/utils', () => ({
  logger: {
    debug: jest.fn(),
    info: jest.fn(),
    warn: jest.fn(),
    error: jest.fn()
  }
}));

// Mock js-yaml
jest.mock('js-yaml', () => ({
  load: jest.fn((data: string) => {
    if (data.includes('main: Alt+Space')) {
      return {
        shortcuts: { main: 'Alt+Space', paste: 'Enter', close: 'Escape', search: 'Cmd+f' },
        window: { position: 'center', width: 800, height: 400 }
      };
    }
    return null;
  }),
  dump: jest.fn((data: unknown) => {
    const yaml = `shortcuts:
  main: ${(data as any).shortcuts.main}
  paste: ${(data as any).shortcuts.paste}
  close: ${(data as any).shortcuts.close}
window:
  position: ${(data as any).window.position}
  width: ${(data as any).window.width}
  height: ${(data as any).window.height}`;
    return yaml;
  })
}));

const mockedFs = fs as jest.Mocked<typeof fs>;

describe('SettingsManager', () => {
  let settingsManager: SettingsManager;
  const settingsPath = path.join(os.homedir(), '.prompt-line', 'settings.yml');

  beforeEach(() => {
    jest.clearAllMocks();
    settingsManager = new SettingsManager();
  });

  describe('initialization', () => {
    it('should create settings directory and initialize with defaults when no file exists', async () => {
      mockedFs.readFile.mockRejectedValue({ code: 'ENOENT' });
      mockedFs.mkdir.mockResolvedValue(undefined);
      mockedFs.writeFile.mockResolvedValue();

      await settingsManager.init();

      expect(mockedFs.mkdir).toHaveBeenCalledWith(path.dirname(settingsPath), { recursive: true });
      expect(mockedFs.writeFile).toHaveBeenCalled();
    });

    it('should load existing settings file', async () => {
      mockedFs.mkdir.mockResolvedValue(undefined);
      const yamlSettings = `shortcuts:
  main: Alt+Space
  paste: Enter
  close: Escape
window:
  position: center
  width: 800
  height: 400`;
      mockedFs.readFile.mockResolvedValue(yamlSettings);

      await settingsManager.init();

      const settings = settingsManager.getSettings();
      expect(settings.shortcuts.main).toBe('Alt+Space');
      expect(settings.window.position).toBe('center');
    });

    it('should handle corrupted settings file and use defaults', async () => {
      mockedFs.mkdir.mockResolvedValue(undefined);
      mockedFs.readFile.mockResolvedValue('invalid json');
      mockedFs.writeFile.mockResolvedValue();

      await settingsManager.init();

      const settings = settingsManager.getSettings();
      // Platform-specific defaults after corruption recovery
      const expectedMain = process.platform === 'win32' ? 'Ctrl+Alt+Space' : 'Cmd+Shift+Space';
      const expectedPosition = process.platform === 'win32' ? 'cursor' : 'active-text-field';
      expect(settings.shortcuts.main).toBe(expectedMain);
      expect(settings.window.position).toBe(expectedPosition);
    });
  });

  describe('settings management', () => {
    beforeEach(async () => {
      mockedFs.readFile.mockRejectedValue({ code: 'ENOENT' });
      mockedFs.mkdir.mockResolvedValue(undefined);
      mockedFs.writeFile.mockResolvedValue();
      await settingsManager.init();
    });

    it('should return default settings', () => {
      const settings = settingsManager.getSettings();
      
      // Platform-specific default settings
      const expectedSettings = {
        shortcuts: {
          main: process.platform === 'win32' ? 'Ctrl+Alt+Space' : 'Cmd+Shift+Space',
          paste: process.platform === 'win32' ? 'Ctrl+Enter' : 'Cmd+Enter',
          close: 'Escape',
          historyNext: 'Ctrl+j',
          historyPrev: 'Ctrl+k',
          search: process.platform === 'win32' ? 'Ctrl+f' : 'Cmd+f'
        },
        window: {
          position: process.platform === 'win32' ? 'cursor' : 'active-text-field',
          width: 1000,
          height: 600
        }
      };
      
      expect(settings).toEqual(expectedSettings);
    });

    it('should update settings partially', async () => {
      const partialUpdate: Partial<UserSettings> = {
        shortcuts: {
          main: 'Ctrl+Shift+P',
          paste: 'Enter',
          close: 'Escape',
          historyNext: 'Ctrl+j',
          historyPrev: 'Ctrl+k',
          search: 'Cmd+f'
        }
      };

      await settingsManager.updateSettings(partialUpdate);

      const settings = settingsManager.getSettings();
      expect(settings.shortcuts.main).toBe('Ctrl+Shift+P');
      expect(settings.window.width).toBe(1000); // Should remain unchanged (new default)
    });

    it('should reset settings to defaults', async () => {
      // First update settings
      await settingsManager.updateSettings({
        window: { position: 'center', width: 800, height: 400 }
      });

      // Then reset
      await settingsManager.resetSettings();

      const settings = settingsManager.getSettings();
      // Platform-specific defaults after reset
      const expectedPosition = process.platform === 'win32' ? 'cursor' : 'active-text-field';
      expect(settings.window.position).toBe(expectedPosition);
      expect(settings.window.width).toBe(1000);
    });
  });

  describe('specific settings sections', () => {
    beforeEach(async () => {
      mockedFs.readFile.mockRejectedValue({ code: 'ENOENT' });
      mockedFs.mkdir.mockResolvedValue(undefined);
      mockedFs.writeFile.mockResolvedValue();
      await settingsManager.init();
    });

    it('should get and update shortcuts', async () => {
      const shortcuts = settingsManager.getShortcuts();
      // Platform-specific default main shortcut
      const expectedMain = process.platform === 'win32' ? 'Ctrl+Alt+Space' : 'Cmd+Shift+Space';
      expect(shortcuts.main).toBe(expectedMain);

      await settingsManager.updateShortcuts({ main: 'Alt+Space' });
      
      const updatedShortcuts = settingsManager.getShortcuts();
      expect(updatedShortcuts.main).toBe('Alt+Space');
    });

    it('should get and update window settings', async () => {
      const windowSettings = settingsManager.getWindowSettings();
      // Default position is now platform-specific: Windows uses 'cursor', macOS uses 'active-text-field'
      const expectedPosition = process.platform === 'win32' ? 'cursor' : 'active-text-field';
      expect(windowSettings.position).toBe(expectedPosition);

      await settingsManager.updateWindowSettings({ position: 'center', width: 800 });
      
      const updatedWindowSettings = settingsManager.getWindowSettings();
      expect(updatedWindowSettings.position).toBe('center');
      expect(updatedWindowSettings.width).toBe(800);
      expect(updatedWindowSettings.height).toBe(600); // Should remain unchanged (new default)
    });

  });

  describe('utility methods', () => {
    beforeEach(async () => {
      mockedFs.readFile.mockRejectedValue({ code: 'ENOENT' });
      mockedFs.mkdir.mockResolvedValue(undefined);
      mockedFs.writeFile.mockResolvedValue();
      await settingsManager.init();
    });

    it('should return default settings copy', () => {
      const defaults = settingsManager.getDefaultSettings();
      
      // Expected defaults are platform-specific
      const expectedDefaults = {
        shortcuts: {
          main: process.platform === 'win32' ? 'Ctrl+Alt+Space' : 'Cmd+Shift+Space',
          paste: process.platform === 'win32' ? 'Ctrl+Enter' : 'Cmd+Enter',
          close: 'Escape',
          historyNext: 'Ctrl+j',
          historyPrev: 'Ctrl+k',
          search: process.platform === 'win32' ? 'Ctrl+f' : 'Cmd+f'
        },
        window: {
          position: process.platform === 'win32' ? 'cursor' : 'active-text-field',
          width: 1000,
          height: 600
        }
      };
      
      expect(defaults).toEqual(expectedDefaults);

      // Ensure it's a copy and not reference
      const originalMain = defaults.shortcuts.main;
      defaults.shortcuts.main = 'modified';
      const newDefaults = settingsManager.getDefaultSettings();
      expect(newDefaults.shortcuts.main).toBe(originalMain);
    });

    it('should return settings file path', () => {
      const filePath = settingsManager.getSettingsFilePath();
      expect(filePath).toBe(settingsPath);
    });
  });

  describe('error handling', () => {
    it('should handle file write errors', async () => {
      mockedFs.readFile.mockRejectedValue({ code: 'ENOENT' });
      mockedFs.mkdir.mockResolvedValue(undefined);
      mockedFs.writeFile.mockRejectedValue(new Error('Write failed'));

      await expect(settingsManager.init()).rejects.toThrow('Write failed');
    });

    it('should handle directory creation errors', async () => {
      mockedFs.mkdir.mockRejectedValue(new Error('Permission denied'));

      await expect(settingsManager.init()).rejects.toThrow('Permission denied');
    });
  });

});