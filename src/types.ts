export interface EventLog {
  guid: string; // Base32 GUID for unique identification
  timestamp: string;
  eventType: 'open' | 'save';
  filePath: string;
  fileName: string;
  vaultName: string;
  metadata?: {
    lastModified?: string;
    fileSize?: number;
    oldPath?: string;
    newPath?: string;
    sourcePath?: string;
    targetPath?: string;
  };
}

export interface EventFrontmatter {
  OOEvent_GUID: string;
  OOEvent_Timestamp: string;
  OOEvent_LocalTimestamp?: string;
  OOEvent_Timezone?: string;
  OOEvent_Type: 'open' | 'save';
  OOEvent_FilePath: string;
  OOEvent_FileName: string;
  OOEvent_VaultName: string;
  OOEvent_LastModified?: string;
  OOEvent_Created: string;
  OOEvent_OldPath?: string;
  OOEvent_NewPath?: string;
  OOEvent_SourcePath?: string;
  OOEvent_TargetPath?: string;
  OOEvent_PluginVersion?: string;
}

export interface LoggerConfig {
  eventsDirectory: string; // Changed from logFilePath to eventsDirectory
  maxLogSize: number;
  enableConsoleLog: boolean;
  includeMetadata: boolean;
}

export interface ObsidianObserverSettings {
  enableLogging: boolean;
  eventsDirectory: string; // Changed from logFilePath to eventsDirectory
  includeFileMetadata: boolean;
  includeFrontmatter: boolean;
  maxLogEntries: number;
  enableConsoleOutput: boolean;
}
