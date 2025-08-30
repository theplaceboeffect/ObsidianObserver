# ObsidianObserver

A comprehensive Obsidian plugin that tracks file events (open, save, close) and stores them as individual notes with rich metadata for enhanced DataView compatibility and analysis.

## Features

- **Event Tracking**: Logs file open, save, and close events
- **Individual Note Storage**: Each event stored as a separate markdown file
- **Rich Metadata**: Includes file paths, timestamps, vault information, and modification times
- **DataView Compatible**: Optimized frontmatter structure for DataView queries
- **Unique GUIDs**: Base32-encoded identifiers for each event
- **Professional Styling**: CSS integration for DataView tables

## Quick Start

### Installation
1. Download the latest release
2. Extract to your Obsidian vault's `.obsidian/plugins/` directory
3. Enable the plugin in Obsidian settings

### Deployment
Use the provided deployment scripts to deploy the plugin:

```bash
# Deploy to existing vault (Bash)
./bin/deploy.sh "/path/to/your/vault"

# Deploy with force overwrite
./bin/deploy.sh "/path/to/your/vault" -f

# Deploy with verbose output
./bin/deploy.sh "/path/to/your/vault" -v

# Deploy to existing vault (PowerShell)
./bin/deploy.ps1 -VaultPath "C:\path\to\your\vault"

# Deploy with force overwrite (PowerShell)
./bin/deploy.ps1 -VaultPath "C:\path\to\your\vault" -Force -Verbose
```

## Documentation

See `docs/README.md` for comprehensive documentation including:
- Installation and configuration
- DataView query examples
- Event types and metadata fields
- Troubleshooting guide

## Development

### Building
```bash
# Standard build
npm run build

# Build with version parameterization (recommended)
./bin/build.sh -v "00.01.17"

# Build with custom options
./bin/build.sh -v "00.01.17" -s -p  # Skip dependencies, create package
./bin/build.sh -v "00.01.17" -n "TestVault"  # Update specific vault
```

### Testing
The plugin includes test utilities for GUID generation and event logging.

## License

MIT License
