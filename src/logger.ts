import { App, TFile } from 'obsidian';
import { EventLog, EventFrontmatter, LoggerConfig } from './types';

export class EventLogger {
  private app: App;
  private config: LoggerConfig;
  private logBuffer: EventLog[] = [];
  private maxBufferSize = 3; // Reduced from 10 to 3 for more frequent writes

  constructor(app: App, config: LoggerConfig) {
    this.app = app;
    this.config = config;
  }

  private getPluginVersion(): string {
    try {
      // Try to get version from manifest.json
      const manifest = require('../../manifest.json');
      return manifest.version || 'unknown';
    } catch (error) {
      console.warn('[ObsidianObserver] Could not read plugin version from manifest.json');
      return 'unknown';
    }
  }

  async ensureEventsDirectoryExists(): Promise<void> {
    try {
      const eventsDir = this.config.eventsDirectory;
      
      // Check if the directory exists
      const dirExists = this.app.vault.getAbstractFileByPath(eventsDir);
      
      if (!dirExists) {
        // Create the events directory
        try {
          await this.app.vault.createFolder(eventsDir);
          console.log(`[ObsidianObserver] Created events directory: ${eventsDir}`);
        } catch (createError: any) {
          if (createError.message && createError.message.includes('already exists')) {
            console.log(`[ObsidianObserver] Events directory already exists: ${eventsDir}`);
          } else {
            throw createError;
          }
        }
      } else {
        console.log(`[ObsidianObserver] Events directory already exists: ${eventsDir}`);
      }
    } catch (error) {
      console.error('[ObsidianObserver] Error ensuring events directory exists:', error);
    }
  }

  async logEvent(eventLog: EventLog): Promise<void> {
    try {
      // Add to buffer
      this.logBuffer.push(eventLog);

      // Flush buffer if it's full
      if (this.logBuffer.length >= this.maxBufferSize) {
        await this.flushBuffer();
      }

      // Console output if enabled
      if (this.config.enableConsoleLog) {
        console.log(`[ObsidianObserver] ${eventLog.eventType}: ${eventLog.filePath}`);
      }
    } catch (error) {
      console.error('[ObsidianObserver] Error logging event:', error);
    }
  }

  async flushBuffer(): Promise<void> {
    if (this.logBuffer.length === 0) return;

    try {
      // Create individual note files for each event
      for (const eventLog of this.logBuffer) {
        await this.createEventNote(eventLog);
      }
      
      console.log(`[ObsidianObserver] Buffer flushed: ${this.logBuffer.length} event notes created`);
      this.logBuffer = [];
    } catch (error) {
      console.error('[ObsidianObserver] Error flushing log buffer:', error);
    }
  }

  private async createEventNote(eventLog: EventLog): Promise<void> {
    try {
      const eventsDir = this.config.eventsDirectory;
      const fileName = `${eventLog.guid}.md`;
      const filePath = `${eventsDir}/${fileName}`;
      
      // Get local timezone information
      const utcDate = new Date(eventLog.timestamp);
      const localDate = new Date(utcDate.getTime() - (utcDate.getTimezoneOffset() * 60000));
      const timezone = Intl.DateTimeFormat().resolvedOptions().timeZone;
      
          // Convert EventLog to EventFrontmatter
    const frontmatter: EventFrontmatter = {
      OOEvent_GUID: eventLog.guid,
      OOEvent_Timestamp: eventLog.timestamp,
      OOEvent_LocalTimestamp: localDate.toISOString(),
      OOEvent_Timezone: timezone,
      OOEvent_Type: eventLog.eventType,
      OOEvent_FilePath: eventLog.filePath,
      OOEvent_FileName: eventLog.fileName,
      OOEvent_VaultName: eventLog.vaultName,
      OOEvent_LastModified: eventLog.metadata?.lastModified || '',
      OOEvent_Created: new Date().toISOString(),
      OOEvent_OldPath: eventLog.metadata?.oldPath,
      OOEvent_NewPath: eventLog.metadata?.newPath,
      OOEvent_SourcePath: eventLog.metadata?.sourcePath,
      OOEvent_TargetPath: eventLog.metadata?.targetPath,
      OOEvent_PluginVersion: this.getPluginVersion()
    };

      // Create the note content with frontmatter
      const noteContent = this.createNoteContent(frontmatter, eventLog);
      
      // Check if file already exists
      const existingFile = this.app.vault.getAbstractFileByPath(filePath);
      
      if (existingFile) {
        console.log(`[ObsidianObserver] Event note already exists: ${filePath}`);
        return;
      }

      // Create the note file
      await this.app.vault.create(filePath, noteContent);
      console.log(`[ObsidianObserver] Created event note: ${filePath}`);
      
    } catch (error) {
      console.error(`[ObsidianObserver] Error creating event note:`, error);
    }
  }

  private createNoteContent(frontmatter: EventFrontmatter, eventLog: EventLog): string {
    // Create frontmatter string with conditional fields
    let frontmatterFields = `---
aliases: [${eventLog.eventType.toUpperCase()} Event, ${eventLog.fileName}]
tags: [obsidian-explorer, event, ${eventLog.eventType}]
type: obsidian-event
OOEvent_GUID: ${frontmatter.OOEvent_GUID}
OOEvent_Timestamp: ${frontmatter.OOEvent_Timestamp}
OOEvent_LocalTimestamp: ${frontmatter.OOEvent_LocalTimestamp}
OOEvent_Timezone: ${frontmatter.OOEvent_Timezone}
OOEvent_Type: ${frontmatter.OOEvent_Type}
OOEvent_FilePath: ${frontmatter.OOEvent_FilePath}
OOEvent_FileName: ${frontmatter.OOEvent_FileName}
OOEvent_VaultName: ${frontmatter.OOEvent_VaultName}
OOEvent_LastModified: ${frontmatter.OOEvent_LastModified}
OOEvent_Created: ${frontmatter.OOEvent_Created}
OOEvent_PluginVersion: ${frontmatter.OOEvent_PluginVersion}`;

    // Add optional fields if they exist
    if (frontmatter.OOEvent_OldPath) {
      frontmatterFields += `\nOOEvent_OldPath: ${frontmatter.OOEvent_OldPath}`;
    }
    if (frontmatter.OOEvent_NewPath) {
      frontmatterFields += `\nOOEvent_NewPath: ${frontmatter.OOEvent_NewPath}`;
    }
    if (frontmatter.OOEvent_SourcePath) {
      frontmatterFields += `\nOOEvent_SourcePath: ${frontmatter.OOEvent_SourcePath}`;
    }
    if (frontmatter.OOEvent_TargetPath) {
      frontmatterFields += `\nOOEvent_TargetPath: ${frontmatter.OOEvent_TargetPath}`;
    }

    frontmatterFields += `\n---\n\n`;

    // Create the note content - simplified to just frontmatter and link
    const noteContent = `${frontmatterFields}[[${eventLog.fileName}]]`;

    return noteContent;
  }

  // Legacy method for backward compatibility - now creates a summary note
  async createSummaryNote(): Promise<void> {
    try {
      const summaryPath = `${this.config.eventsDirectory}/_summary.md`;
      
      const summaryContent = `---
aliases: [ObsidianObserver Events Summary, Events Summary]
tags: [obsidian-explorer, summary, events]
type: events-summary
---

# ObsidianObserver Events Summary

This file provides a summary of all ObsidianObserver events.

## DataView Query Examples

### Basic Event Queries
\`\`\`dataview
TABLE OOEvent_GUID, OOEvent_Type, OOEvent_FileName, OOEvent_VaultName, OOEvent_Timestamp
FROM "${this.config.eventsDirectory}"
WHERE OOEvent_Type = "open"
SORT OOEvent_Timestamp DESC
LIMIT 10
\`\`\`

\`\`\`dataview
TABLE OOEvent_GUID, OOEvent_Type, OOEvent_FileName, OOEvent_VaultName, OOEvent_Timestamp
FROM "${this.config.eventsDirectory}"
WHERE OOEvent_Type = "save"
SORT OOEvent_Timestamp DESC
LIMIT 5
\`\`\`

\`\`\`dataview
TABLE OOEvent_GUID, OOEvent_Type, OOEvent_FileName, OOEvent_VaultName, OOEvent_Timestamp
FROM "${this.config.eventsDirectory}"
WHERE OOEvent_Type = "close"
SORT OOEvent_Timestamp DESC
LIMIT 5
\`\`\`

### File Management Events
\`\`\`dataview
TABLE OOEvent_GUID, OOEvent_Type, OOEvent_FileName, OOEvent_VaultName, OOEvent_Timestamp
FROM "${this.config.eventsDirectory}"
WHERE OOEvent_Type = "create"
SORT OOEvent_Timestamp DESC
LIMIT 10
\`\`\`

\`\`\`dataview
TABLE OOEvent_GUID, OOEvent_Type, OOEvent_FileName, OOEvent_VaultName, OOEvent_Timestamp
FROM "${this.config.eventsDirectory}"
WHERE OOEvent_Type = "delete"
SORT OOEvent_Timestamp DESC
LIMIT 10
\`\`\`

\`\`\`dataview
TABLE OOEvent_GUID, OOEvent_Type, OOEvent_FileName, OOEvent_OldPath, OOEvent_NewPath, OOEvent_Timestamp
FROM "${this.config.eventsDirectory}"
WHERE OOEvent_Type = "rename"
SORT OOEvent_Timestamp DESC
LIMIT 10
\`\`\`

### Advanced Queries
\`\`\`dataview
TABLE OOEvent_GUID, OOEvent_Type, OOEvent_FileName, OOEvent_VaultName, OOEvent_Timestamp
FROM "${this.config.eventsDirectory}"
WHERE contains(OOEvent_FilePath, "Projects")
SORT OOEvent_Timestamp DESC
\`\`\`

\`\`\`dataview
TABLE OOEvent_GUID, OOEvent_Type, OOEvent_FileName, OOEvent_VaultName, OOEvent_Timestamp
FROM "${this.config.eventsDirectory}"
WHERE OOEvent_GUID = "ABC123DEF456GHI789JKL012"
\`\`\`

### File Size Analysis
\`\`\`dataview
TABLE OOEvent_FileName, OOEvent_FileSize, OOEvent_Type, OOEvent_Timestamp
FROM "${this.config.eventsDirectory}"
WHERE OOEvent_FileSize
SORT OOEvent_FileSize DESC
LIMIT 10
\`\`\`

### Recent Activity
\`\`\`dataview
TABLE OOEvent_FileName, OOEvent_Type, OOEvent_Timestamp
FROM "${this.config.eventsDirectory}"
SORT OOEvent_Timestamp DESC
LIMIT 20
\`\`\`

## Event Statistics

### Event Type Distribution
\`\`\`dataview
TABLE length(rows) as "Count"
FROM "${this.config.eventsDirectory}"
GROUP BY OOEvent_Type
SORT Count DESC
\`\`\`

### Vault Activity
\`\`\`dataview
TABLE length(rows) as "Count"
FROM "${this.config.eventsDirectory}"
GROUP BY OOEvent_VaultName
SORT Count DESC
\`\`\`

### File Activity
\`\`\`dataview
TABLE OOEvent_FileName, length(rows) as "Event Count"
FROM "${this.config.eventsDirectory}"
GROUP BY OOEvent_FileName
SORT "Event Count" DESC
LIMIT 20
\`\`\`

### Daily Activity
\`\`\`dataview
TABLE date(OOEvent_Timestamp) as "Date", length(rows) as "Events"
FROM "${this.config.eventsDirectory}"
GROUP BY date(OOEvent_Timestamp)
SORT "Date" DESC
LIMIT 30
\`\`\`
`;

      // Check if summary file already exists
      const existingFile = this.app.vault.getAbstractFileByPath(summaryPath);
      
      if (existingFile) {
        console.log(`[ObsidianObserver] Summary file already exists: ${summaryPath}`);
        return;
      }

      // Create the summary file
      await this.app.vault.create(summaryPath, summaryContent);
      console.log(`[ObsidianObserver] Created summary file: ${summaryPath}`);
      
    } catch (error) {
      console.error(`[ObsidianObserver] Error creating summary file:`, error);
    }
  }

  // Create the main summary file in _debug directory
  async createMainSummaryNote(): Promise<void> {
    try {
      const summaryPath = '_debug/EventsSummary.md';
      
      const summaryContent = `---
aliases: [ObsidianObserver Main Summary, Events Summary]
tags: [obsidian-explorer, summary, events, main]
type: events-summary
---

# ObsidianObserver Events Summary

This file provides comprehensive DataView reports for common use-cases with ObsidianObserver events.

## Quick Overview

### Recent Activity (Last 20 Events)
\`\`\`dataview
TABLE OOEvent_FileName, OOEvent_Type, OOEvent_Timestamp
FROM "_debug/events"
SORT OOEvent_Timestamp DESC
LIMIT 20
\`\`\`

### Event Type Distribution
\`\`\`dataview
TABLE length(rows) as "Count"
FROM "_debug/events"
GROUP BY OOEvent_Type
SORT Count DESC
\`\`\`

### Most Active Files
\`\`\`dataview
TABLE OOEvent_FileName, length(rows) as "Total Events", 
  length(filter(rows, r => r.OOEvent_Type = "open")) as "Opens",
  length(filter(rows, r => r.OOEvent_Type = "save")) as "Saves",
  length(filter(rows, r => r.OOEvent_Type = "close")) as "Closes"
FROM "_debug/events"
GROUP BY OOEvent_FileName
SORT "Total Events" DESC
LIMIT 15
\`\`\`

## File Operations

### Recent File Opens
\`\`\`dataview
TABLE OOEvent_GUID, OOEvent_FileName, OOEvent_Timestamp
FROM "_debug/events"
WHERE OOEvent_Type = "open"
SORT OOEvent_Timestamp DESC
LIMIT 10
\`\`\`

### Recent File Saves
\`\`\`dataview
TABLE OOEvent_GUID, OOEvent_FileName, OOEvent_Timestamp
FROM "_debug/events"
WHERE OOEvent_Type = "save"
SORT OOEvent_Timestamp DESC
LIMIT 10
\`\`\`

### Recent File Closes
\`\`\`dataview
TABLE OOEvent_GUID, OOEvent_FileName, OOEvent_Timestamp
FROM "_debug/events"
WHERE OOEvent_Type = "close"
SORT OOEvent_Timestamp DESC
LIMIT 10
\`\`\`

## File Management

### Recently Created Files
\`\`\`dataview
TABLE OOEvent_GUID, OOEvent_FileName, OOEvent_Timestamp
FROM "_debug/events"
WHERE OOEvent_Type = "create"
SORT OOEvent_Timestamp DESC
LIMIT 10
\`\`\`

### Recently Deleted Files
\`\`\`dataview
TABLE OOEvent_GUID, OOEvent_FileName, OOEvent_Timestamp
FROM "_debug/events"
WHERE OOEvent_Type = "delete"
SORT OOEvent_Timestamp DESC
LIMIT 10
\`\`\`

### Recently Renamed Files
\`\`\`dataview
TABLE OOEvent_GUID, OOEvent_FileName, OOEvent_OldPath, OOEvent_NewPath, OOEvent_Timestamp
FROM "_debug/events"
WHERE OOEvent_Type = "rename"
SORT OOEvent_Timestamp DESC
LIMIT 10
\`\`\`

## Advanced Analysis

### Project-Related Activity
\`\`\`dataview
TABLE OOEvent_GUID, OOEvent_Type, OOEvent_FileName, OOEvent_Timestamp
FROM "_debug/events"
WHERE contains(OOEvent_FilePath, "Projects")
SORT OOEvent_Timestamp DESC
LIMIT 15
\`\`\`

### People-Related Activity
\`\`\`dataview
TABLE OOEvent_GUID, OOEvent_Type, OOEvent_FileName, OOEvent_Timestamp
FROM "_debug/events"
WHERE contains(OOEvent_FilePath, "People")
SORT OOEvent_Timestamp DESC
LIMIT 15
\`\`\`

### Meeting-Related Activity
\`\`\`dataview
TABLE OOEvent_GUID, OOEvent_Type, OOEvent_FileName, OOEvent_Timestamp
FROM "_debug/events"
WHERE contains(OOEvent_FileName, "Meeting")
SORT OOEvent_Timestamp DESC
LIMIT 15
\`\`\`

## Time-Based Analysis

### Today's Activity
\`\`\`dataview
TABLE OOEvent_FileName, OOEvent_Type, OOEvent_Timestamp
FROM "_debug/events"
WHERE date(OOEvent_Timestamp) = date(today)
SORT OOEvent_Timestamp DESC
\`\`\`

### This Week's Activity
\`\`\`dataview
TABLE OOEvent_FileName, OOEvent_Type, OOEvent_Timestamp
FROM "_debug/events"
WHERE date(OOEvent_Timestamp) >= date(today) - dur(7 days)
SORT OOEvent_Timestamp DESC
\`\`\`

### Daily Activity Summary (Last 30 Days)
\`\`\`dataview
TABLE date(OOEvent_Timestamp) as "Date", length(rows) as "Events"
FROM "_debug/events"
GROUP BY date(OOEvent_Timestamp)
SORT "Date" DESC
LIMIT 30
\`\`\`

## File Size Analysis

### Files with Size Information
\`\`\`dataview
TABLE OOEvent_FileName, OOEvent_FileSize, OOEvent_Type, OOEvent_Timestamp
FROM "_debug/events"
WHERE OOEvent_FileSize
SORT OOEvent_FileSize DESC
LIMIT 10
\`\`\`

## Search and Filter

### Search by File Name
\`\`\`dataview
TABLE OOEvent_GUID, OOEvent_Type, OOEvent_Timestamp
FROM "_debug/events"
WHERE contains(OOEvent_FileName, "YOUR_SEARCH_TERM")
SORT OOEvent_Timestamp DESC
\`\`\`

### Search by GUID
\`\`\`dataview
TABLE OOEvent_GUID, OOEvent_Type, OOEvent_FileName, OOEvent_Timestamp
FROM "_debug/events"
WHERE OOEvent_GUID = "YOUR_GUID_HERE"
\`\`\`

## Event Types Explained

- **open**: File opened in Obsidian editor
- **save**: File modified and saved
- **close**: File closed in editor
- **create**: New file created
- **delete**: File deleted from vault
- **rename**: File renamed or moved (includes old and new paths)

## Metadata Fields

- **OOEvent_GUID**: Unique Base32 identifier for each event
- **OOEvent_Timestamp**: ISO timestamp of the event
- **OOEvent_Type**: Type of file operation
- **OOEvent_FilePath**: Full path to the file
- **OOEvent_FileName**: Name of the file
- **OOEvent_VaultName**: Name of the vault
- **OOEvent_LastModified**: Last modification time of the file
- **OOEvent_Created**: When the event note was created
- **OOEvent_FileSize**: Size of the file in bytes
- **OOEvent_OldPath**: Previous path (for rename events)
- **OOEvent_NewPath**: New path (for rename events)
`;

      // Check if summary file already exists
      const existingFile = this.app.vault.getAbstractFileByPath(summaryPath);
      
      if (existingFile) {
        console.log(`[ObsidianObserver] Main summary file already exists: ${summaryPath}`);
        return;
      }

      // Create the summary file
      await this.app.vault.create(summaryPath, summaryContent);
      console.log(`[ObsidianObserver] Created main summary file: ${summaryPath}`);
      
    } catch (error) {
      console.error(`[ObsidianObserver] Error creating main summary file:`, error);
    }
  }
}
