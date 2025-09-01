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

# v00.00.04

1. [I] Add the following events to audit:
  - 'quit'
  - 'ready'
  - 'rename'
  - 'delete'
  **COMPLETED**: 20241231-203000

1. [I] Update EventSummary.md to use `OOEvent_LocalTimestamp` rather than `OOEvent_Timestamp`.
  **COMPLETED**: 20241231-204000
1. [I] Add seconds to the timestamp.
  **COMPLETED**: 20241231-204500
1. [I] Add a new command "ObsdianObserverRefreshSummary" that will write a new updated copy of the `EventSummary.md` file.
  **COMPLETED**: 20241231-205000
1. [R] Update the `Daily Notes` template to use the syntax from the `Daily Notes Plugin`