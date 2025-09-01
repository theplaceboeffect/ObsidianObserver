import { Plugin, Notice } from 'obsidian';
import { EventLogger } from './logger';
import { EventHandlers } from './eventHandlers';
import { LoggerConfig } from './types';

export default class ObsidianObserverPlugin extends Plugin {
  private logger!: EventLogger;
  private eventHandlers!: EventHandlers;

  async onload() {
    console.log('[ObsidianObserver] Loading plugin...');

    try {
      // Initialize logger configuration
      const loggerConfig: LoggerConfig = {
        eventsDirectory: '_debug/events',
        maxLogSize: 1024 * 1024, // 1MB
        enableConsoleLog: true,
        includeMetadata: true
      };

      // Create logger instance
      this.logger = new EventLogger(this.app, loggerConfig, this.manifest.version);

      // Ensure events directory exists
      await this.logger.ensureEventsDirectoryExists();

      // Create summary note for DataView queries
      await this.logger.createSummaryNote();

      // Create main summary file in _debug directory
      await this.logger.createMainSummaryNote();

      // Create event handlers
      this.eventHandlers = new EventHandlers(this.app, this.logger);

      // Register event handlers
      this.eventHandlers.registerEventHandlers();

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

      // Add ribbon icon for creating summary note
      this.addRibbonIcon('file-text', 'Create Events Summary', async () => {
        await this.logger.createSummaryNote();
        new Notice('Events summary created!');
      });

      // Add status bar item
      const statusBarItem = this.addStatusBarItem();
      const version = this.manifest.version;
      statusBarItem.setText(`ObsidianObserver v${version}`);

      console.log('[ObsidianObserver] Plugin loaded successfully');
    } catch (error) {
      console.error('[ObsidianObserver] Error loading plugin:', error);
    }
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
