import { Plugin, Notice, PluginSettingTab, Setting, App } from 'obsidian';
import { EventLogger } from './logger';
import { EventHandlers } from './eventHandlers';
import { LoggerConfig, PluginSettings } from './types';

export const DEFAULT_SETTINGS: PluginSettings = {
  eventsFolder: 'ObsidianObserver',
  enableConsoleLog: true
};

export default class ObsidianObserverPlugin extends Plugin {
  private logger!: EventLogger;
  private eventHandlers!: EventHandlers;
  public settings: PluginSettings;

  constructor(app: any, manifest: any) {
    super(app, manifest);
    this.settings = { ...DEFAULT_SETTINGS };
  }

  async onload() {
    console.log('[ObsidianObserver] Loading plugin...');

    try {
      // Load settings
      await this.loadSettings();

      // Initialize logger configuration from settings
      const loggerConfig: LoggerConfig = {
        eventsFolder: this.settings.eventsFolder,
        enableConsoleLog: this.settings.enableConsoleLog
      };

      // Create logger instance
      this.logger = new EventLogger(this.app, loggerConfig, this.manifest.version);

      // Ensure events directory exists
      await this.logger.ensureEventsDirectoryExists();

      // Create summary note for DataView queries
      await this.logger.createSummaryNote();

      // Create main summary file in configured directory
      await this.logger.createMainSummaryNote();

      // Create event handlers
      this.eventHandlers = new EventHandlers(this.app, this.logger);

      // Register event handlers
      this.eventHandlers.registerEventHandlers();

      // Register application quit detection events
      this.registerQuitDetectionEvents();

      // Add settings tab
      this.addSettingTab(new ObsidianObserverSettingTab(this.app, this));

      // Add ribbon icon for manual testing
      this.addRibbonIcon('bug', 'Test ObsidianObserver Logging', async () => {
        await this.eventHandlers.testLogging();
        new Notice('Test event note created!');
      });

      // Add command palette command for manual buffer flush
      this.addCommand({
        id: 'flush-obsidian-observer-buffer',
        name: 'Flush ObsidianObserver Buffer',
        callback: async () => {
          await this.logger.flushBuffer();
          new Notice('Buffer flushed to event notes!');
        }
      });

      // Add command palette command for refreshing summary file
      this.addCommand({
        id: 'obsidian-observer-refresh-summary',
        name: 'ObsidianObserver: Refresh Summary',
        callback: async () => {
          await this.logger.refreshMainSummaryNote();
          new Notice('Events summary refreshed!');
        }
      });

      // Add ribbon icon for creating summary note
      this.addRibbonIcon('file-text', 'Create Events Summary', async () => {
        await this.logger.createSummaryNote();
        new Notice('Events summary created!');
      });

      // Add status bar item
      const statusBarItem = this.addStatusBarItem();
      const version = this.manifest.version;
      statusBarItem.setText(`ObsidianObserver v${version}`);

      // Log PluginLoaded event after successful initialization
      const { generateBase32Guid } = await import('./utils');
      const pluginLoadedEvent = {
        guid: generateBase32Guid(),
        timestamp: new Date().toISOString(),
        eventType: 'PluginLoaded' as const,
        filePath: '',
        fileName: '',
        vaultName: this.app.vault.getName(),
        metadata: {
          lastModified: new Date().toISOString(),
          pluginVersion: this.manifest.version
        }
      };
      await this.logger.logEvent(pluginLoadedEvent);

      console.log('[ObsidianObserver] Plugin loaded successfully');
    } catch (error) {
      console.error('[ObsidianObserver] Error loading plugin:', error);
    }
  }

  async loadSettings() {
    this.settings = Object.assign({}, DEFAULT_SETTINGS, await this.loadData());
  }

  async saveSettings() {
    await this.saveData(this.settings);
  }

  async updateSettings(updates: Partial<PluginSettings>) {
    Object.assign(this.settings, updates);
    await this.saveSettings();
    
    // Update logger configuration with new settings
    await this.updateLoggerConfiguration();
  }

  private async updateLoggerConfiguration() {
    if (!this.logger) return;
    
    // Create new logger configuration from updated settings
    const newLoggerConfig: LoggerConfig = {
      eventsFolder: this.settings.eventsFolder,
      enableConsoleLog: this.settings.enableConsoleLog
    };
    
    // Update the logger's configuration
    this.logger.updateConfig(newLoggerConfig);
    
    // Update event handlers with new configuration
    if (this.eventHandlers) {
      this.eventHandlers.updateLoggerConfig(newLoggerConfig);
    }
    
    // Ensure the new events directory exists
    await this.logger.ensureEventsDirectoryExists();
    
    // Refresh the file explorer to show the new directory
    this.app.workspace.trigger('file-explorer:refresh');
    
  }

  private registerQuitDetectionEvents() {
    // Use Obsidian's proper event registration methods for reliable cleanup
    
    // Listen for window beforeunload event using registerDomEvent
    this.registerDomEvent(window, 'beforeunload', async (event: BeforeUnloadEvent) => {
      console.log('[ObsidianObserver] Application quitting detected via beforeunload...');
      
      try {
        // Log quit event
        if (this.logger) {
          const { generateBase32Guid } = await import('./utils');
          const eventLog = {
            guid: generateBase32Guid(),
            timestamp: new Date().toISOString(),
            eventType: 'quit' as const,
            filePath: '',
            fileName: '',
            vaultName: this.app.vault.getName(),
            metadata: {
              lastModified: new Date().toISOString(),
              quitMethod: 'beforeunload'
            }
          };
          
          // Log the event and force flush immediately
          await this.logger.logEvent(eventLog);
          await this.logger.flushBuffer();
        }
      } catch (error) {
        console.error('[ObsidianObserver] Error logging quit event:', error);
      }
    });

    // Listen for Obsidian workspace close events
    this.registerEvent(
      this.app.workspace.on('quit', async () => {
        console.log('[ObsidianObserver] Workspace quit event detected...');
        
        try {
          if (this.logger) {
            const { generateBase32Guid } = await import('./utils');
            const eventLog = {
              guid: generateBase32Guid(),
              timestamp: new Date().toISOString(),
              eventType: 'quit' as const,
              filePath: '',
              fileName: '',
              vaultName: this.app.vault.getName(),
              metadata: {
                lastModified: new Date().toISOString(),
                quitMethod: 'workspace-quit'
              }
            };
            
            await this.logger.logEvent(eventLog);
            await this.logger.flushBuffer();
          }
        } catch (error) {
          console.error('[ObsidianObserver] Error logging workspace quit event:', error);
        }
      })
    );


  }

  async onunload() {
    console.log('[ObsidianObserver] Unloading plugin...');

    try {
      // Unregister event handlers
      if (this.eventHandlers) {
        this.eventHandlers.unregisterEventHandlers();
      }

      // Flush any remaining log entries
      if (this.logger) {
        await this.logger.flushBuffer();
      }

      console.log('[ObsidianObserver] Plugin unloaded successfully');
    } catch (error) {
      console.error('[ObsidianObserver] Error unloading plugin:', error);
    }
  }
}

class ObsidianObserverSettingTab extends PluginSettingTab {
  plugin: ObsidianObserverPlugin;

  constructor(app: App, plugin: ObsidianObserverPlugin) {
    super(app, plugin);
    this.plugin = plugin;
  }

  display(): void {
    const { containerEl } = this;
    containerEl.empty();

    containerEl.createEl('h2', { text: 'ObsidianObserver Settings' });

    // Events Folder Setting
    new Setting(containerEl)
      .setName('Events Folder')
      .setDesc('The base folder where ObsidianObserver will create its structure. Events will be stored in EventsFolder/events and EventSummary.md will be created automatically.')
      .addText(text => text
        .setPlaceholder('ObsidianObserver')
        .setValue(this.plugin.settings.eventsFolder)
        .onChange(async (value) => {
          await this.plugin.updateSettings({ eventsFolder: value });
        }));

    // Enable Console Log Setting
    new Setting(containerEl)
      .setName('Enable Console Logging')
      .setDesc('Log events to the browser console for debugging.')
      .addToggle(toggle => toggle
        .setValue(this.plugin.settings.enableConsoleLog)
        .onChange(async (value) => {
          await this.plugin.updateSettings({ enableConsoleLog: value });
        }));

    // Reset to Defaults Button
    new Setting(containerEl)
      .setName('Reset to Defaults')
      .setDesc('Reset all settings to their default values.')
      .addButton(button => button
        .setButtonText('Reset')
        .setWarning()
        .onClick(async () => {
          this.plugin.settings = { ...DEFAULT_SETTINGS };
          await this.plugin.saveSettings();
          this.display(); // Refresh the settings display
        }));
  }
}
