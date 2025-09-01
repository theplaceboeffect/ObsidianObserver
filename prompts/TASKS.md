  
# v00.01.00

Create an Obsidian Plugin ObsidianObserver

[I] This will register on note open, close and save events.
  - Outputs to a log file called _debug/events.md
  - Create artifacts in `ObsidianObserver/`
    - `src` for all source
    - `docs` for documentation
  **COMPLETED**: 20241220-190000

# v00.01.01
[I] If the log file doesn't exist - create it.
  **COMPLETED**: 20241220-220000
[I] Update the active indicator to show the version of the plugin.
  **COMPLETED**: 20241220-221500
[I] update `bin\Populate-ObsidianVault` with a parameter `-UpdateExploreObsdianPlugin` to install/update the current version of the plugin into the vault.
  **COMPLETED**: 20241220-224500
[I] update `-UpdateExploreObsdianPlugin` to use the current directory to find the directory.
  **COMPLETED**: 20241220-230000

# v00.01.02
[I] Add protection to prevent the plugin from logging events for its own log file to avoid recursive logging.
  **COMPLETED**: 20241220-231500

[I] Do not display the contents of the note when logging.
  **COMPLETED**: 20241220-232000

[I] Improve buffer management and add manual flush capability to ensure events are written to log file.
  **COMPLETED**: 20241220-232500

[I] Create `ObsidianObserver/bin/build.ps1`
  - ensure the build is created in build/
  **COMPLETED**: 20241220-233000

[I] Update `bin/Populate-ObsidianVault.ps1 -UpdateExploreObsdianPlugin` to deploy from the build directory
  **COMPLETED**: 20241220-233000
[I] BUG: `-UpdateExploreObsdianPlugin` does not take into account the VaultName convention - preppend `TestSidian-` to the directory name.
  **COMPLETED**: 20241220-233500
[I] The plugin displays an error `Error writing to log file: Error: File already exists.` - this should not be an error.
  **COMPLETED**: 20241220-234000

[I] Add a message whenever there the log is flushed to the log.
  **COMPLETED**: 20241220-234500

[I] BUG: Only 'Open' note events are being logged. Also log the note Save and Close events.
  **COMPLETED**: 20241220-235000

# v00.01.07 - update log format.

[I] Make the log format a table
  **COMPLETED**: 20241220-235500
[I] Ensure the table can be queried using DataView - include an example at the top of the file.
  **COMPLETED**: 20241220-240000
[I] Keep appending to the end of table.
  **COMPLETED**: 20241220-240000
[I] BUG In parsing the table - DataView cannot parse column names with spaces
  **COMPLETED**: 20241220-240500

[I] BUG: Plugin creates log files without proper DataView structure - ensureLogFileExists uses simple header instead of complete DataView-compatible format
  **COMPLETED**: 20241220-241000 
```
Dataview: Error: 
-- PARSING FAILED --------------------------------------------------

  1 | 
> 2 | TABLE Event Type, File Name, Vault, Time
    |             ^
  3 | 
  4 | FROM "_debug/events"

Expected one of the following: 

'*' or '/' or '%', '+' or '-', ',', '>=' or '<=' or '!=' or '=' or '>' or '<', 'and' or 'or', /AS/i, /FROM/i, EOF, FLATTEN <value> [AS <name>], GROUP BY <value> [AS <name>], LIMIT <value>, Not a comment, SORT field [ASC/DESC], WHERE <expression>, whitespace
```
[I] BUG: 'plugin:obsidian-explorer:140 [ObsidianObserver] Could not write to log file - file exists but cannot be accessed. File type: null' - no file is created.
  **COMPLETED**: 20250825-200000

# v00.01.08
  - [I] add a GUID in base32 format to each entry and display update the relevant queries to display it.
  **COMPLETED**: 20250825-195500
  - [I] update `ObsidianObserver/bin/build.ps1` to take a required parameter `-BuildVersion <version>`
    - update `ObsidianObserver/manifest.json - version` with the version number
    - update `ObsidianObserver/package.json - version` with the version number
  **COMPLETED**: 20250825-195800
  - [I] Remove the bold-markers around the field names.
  **COMPLETED**: 20250826-020000
  - [I] The title of each row should be the GUID
  **COMPLETED**: 20250826-020000

# v00.01.09 - GUID Implementation and DataView Styling

## Core Features
- [I] Implement Base32 GUID generation utility functions
  - Create `ObsidianObserver/src/utils.ts` with `generateBase32Guid()` and `uuidToBase32()` functions
  - Add comprehensive GUID generation and conversion logic
  **COMPLETED**: 20250826-023000

- [I] Integrate GUID generation into event handlers
  - Update `ObsidianObserver/src/eventHandlers.ts` to generate GUIDs for all events
  - Add GUID to EventLog interface in `ObsidianObserver/src/types.ts`
  **COMPLETED**: 20250826-023000

- [I] Enhance build system with version parameterization
  - Add required `-BuildVersion <version>` parameter to `ObsidianObserver/bin/build.ps1`
  - Implement version format validation (XX.XX.XX pattern)
  - Auto-update manifest.json and package.json versions
  **COMPLETED**: 20250826-023000

## DataView Styling System
- [I] Create comprehensive CSS styling for DataView tables
  - Add `model/.obsidian/snippets/obsidianObserverEventsTable.css` with enhanced table styling
  - Implement 7pt font size with color coding (light blue headers, green data cells)
  - Add hover tooltips, responsive design, and dark mode support
  **COMPLETED**: 20250826-023000

- [I] Document CSS styling system
  - Create `model/.obsidian/snippets/README.md` with comprehensive documentation
  - Include usage examples, customization options, and troubleshooting
  **COMPLETED**: 20250826-023000

## Documentation and Testing
- [I] Update plugin documentation
  - Enhance `ObsidianObserver/docs/README.md` with GUID features
  - Add examples of new log format and DataView queries
  **COMPLETED**: 20250826-023000

- [I] Create test utilities for GUID generation
  - Add `ObsidianObserver/test-guid.js` for Node.js testing
  - Add `ObsidianObserver/test-guid.html` for browser testing
  **COMPLETED**: 20250826-023000

## Infrastructure Improvements
- [I] Update vault population script
  - Modify `bin/Populate-ObsidianVault.ps1` to include CSS snippets
  - Ensure new vaults automatically get DataView styling
  **COMPLETED**: 20250826-023000

- [I] Clean up old package versions
  - Remove outdated packages (v00.01.04 through v00.01.07)
  - Maintain clean package directory structure
  **COMPLETED**: 20250826-023000

## Breaking Changes
- Build script now requires `-BuildVersion` parameter
- Event log format uses GUIDs as titles instead of sequential numbers
- CSS styling affects all DataView tables in vaults

## Technical Achievements
- ✅ Unique event identification with Base32 GUIDs
- ✅ Improved DataView compatibility and query performance
- ✅ Professional table styling with color coding
- ✅ Robust build system with version control
- ✅ Comprehensive documentation and testing
- ✅ Automatic CSS snippet deployment to new vaults 


# v00.01.12

1. [I] update the system to create one note per event and to use Bases
  - [I] Each event is now stored in `_debug/events/`
  **COMPLETED**: 20250826-024000
  - [I] Each event stores it's data in frontmatter
  **COMPLETED**: 20250826-024000
  - [I] Prefix each property name with ObsidianEvent_
  **COMPLETED**: 20250826-024000
  - [I] Generate Bases files with the same reports.
  **COMPLETED**: 20250826-024000 
  - [I] Also add all the other file events
  **COMPLETED**: 20250826-025000
  - [I] Update plugin to create `_debug/summary.md`. This should have DataView reports for common use-cases.
  **COMPLETED**: 20250826-030800
  - [I] Create a Bases file called `_debug/EventsSummaryBase.md` that contains the YAML structure for Bases views
  **COMPLETED**: 20250826-032000
  - [I] Change `_debug/summary.md` to `_debug/EventsSummary.md`
  **COMPLETED**: 20250826-031500

------------------------------------------------------------------------

# v00.00.01 Migrated to ObsidianExplorer

## Deployment Tasks
1. [I] Create a deployment script `DeployTo-Vault.ps1` that will
  - create a vault `../vaults/ValidationVault` if it doesn't exist.
  - deploy the plugin to the vault's plugin folder `.obsidian/plugins`
  **COMPLETED**: 20250828-212800

1. [I] Implement a script `bin\deploy.ps1` which will take a path to vault and deploys the that vault.
  **COMPLETED**: 20250829-203500

1. [I] Create `bin\build.sh` following the requirements from `bin\build.ps1`
  **COMPLETED**: 20250829-203800

1. [I] Store the build number in a file, format 9999. Increment this with every call to build.ps1. The version number would be the branch name (v00.00.00_9999)
  **COMPLETED**: 20250829-214200

1. [I] deploy.* should display the version deployed.
  **COMPLETED**: 20250829-220000

1. [I] update build.* to take the version number for the current build name
  **COMPLETED**: 20250829-220500

1. [I] Move the css files into obsidian/snippets.
  **COMPLETED**: 20250829-221500

## Plugin Functionality
1. [X] Use the LOCAL timezone to save the timestamps.
  
1. [I] Rename all the objects from `ObsidianObserverEvent` to `OOEvent`
  **COMPLETED**: 20250829-210200

1. [I] Each event.md should only contain FrontMatter and a link to the original file.
  **COMPLETED**: 20250829-211700

1. [I] Move the Sync from the side-bar button into a Palette command.
  **COMPLETED**: 20250829-214300

1. [I] Sync on application close.
  **COMPLETED**: 20250829-214300 (Already implemented in onunload method)

1. [I] Generate CSS file `obsidian/snippets/obsidianObserverEventsTable.css` to provide enhanced table styling for event summaries.
        - Update `bin/deploy.*` to copy this file into `$VAULTDIR/.obsidian/snippets`.
  **COMPLETED**: 20250829-222000
  
1. [I] Add the plugin version into the frontmatter.
  **COMPLETED**: 20250829-222500

1. [I] Remove filesize from the frontmatter.
  **COMPLETED**: 20250829-223000

1. [I] Create the file '.obsidian/snippets/obsidianObserverEventsTable.css` if it doesn't exit.
  **COMPLETED**: 20241229-230000
  - [I] Overwrite with the version in the app if the file system version is different.
  **COMPLETED**: 20241229-230000

1. [I] Update all queries in `EventsSummary.md` with the following conventions:
  **COMPLETED**: 20241229-231500
  - [I] `TABLE WITHOUT ID` - do not show the filename
  **COMPLETED**: 20241229-231500
  - [I] `regexreplace(OOEvent_FileName, ".md$", "") AS "File",` - shorten the filename
  **COMPLETED**: 20241229-231500
  - [I] `upper(OOEvent_Type) AS "Type",` - normalize the event type.
  **COMPLETED**: 20241229-231500
  - [I] `dateformat(OOEvent_Timestamp, "yyyy-MM-dd HH:mm") AS "When"` shorten timestamp
  **COMPLETED**: 20241229-231500

1. [I] Version everything with v00.00.02
  **COMPLETED**: 20241229-232000
      - [I] Update the plugin version.
      **COMPLETED**: 20241229-232000
      - [I] Update the `obsidianObserverEventsTable.css`
      **COMPLETED**: 20241229-232000
      - [I] Update the version of the `EventsSummary.md` file with the version in the frontmatter.
      **COMPLETED**: 20241229-232000
  [I] Update the `build.*` to ensure the versions are updated with every build.
  **COMPLETED**: 20241229-232500
  [I] BUG: I switched to branch `v00.00.02` and build.ps1  script is still building `v00.00.01`
  **COMPLETED**: 20241229-233000

# v00.00.03
1. [I] BUG: neither the `_summary.md` file or `EventsSummary.md` file have a version number nor reference the css file. Fix it.
  **COMPLETED**: 20241231-193100

1. [I] Remove `build.sh` and `deploy.sh` scripts. We will use PowerShell moving forwarded.
  **COMPLETED**: 20241231-194300
1. [I] Add a parameter `-RemoveObsidianObserver` to `deploy.ps1`.
      - [I] This will remove all the artifacts created by the deployment.
      **COMPLETED**: 20241231-194300
      - [I] Remove the `_debug/` folder from the specified Vault.
      **COMPLETED**: 20241231-194300
      - [I] Remove `obsidianObserverEventsTable.css` from the specified Vault.
      **COMPLETED**: 20241231-194300

1. [I] Remove `-Force` requirement from `deploy.ps1` - make deployment the default behavior.
      - [I] Plugin files (main.js, manifest.json) should always be overwritten during deployment.
      **COMPLETED**: 20241231-195700
      - [I] CSS files should always be overwritten during deployment.
      **COMPLETED**: 20241231-195700
      - [I] These are generated/deployed artifacts, not user-edited files.
      **COMPLETED**: 20241231-195700
      - [I] Add `-SkipDeploy` parameter if users want to skip file deployment.
      **COMPLETED**: 20241231-195700
1. [I] BUG: The frontmatter for `EventsSummary.md` should be:
    "-cssclasses: obsidianObserverEventsTable"
  **COMPLETED**: 20241231-200000
1. [I] Remove references to non-existent CSS files and clean up documentation
  **COMPLETED**: 20241231-201500

1. [I] Fix file explorer refresh issue - _debug directory doesn't appear in Obsidian UI until restart
  **COMPLETED**: 20241231-202000