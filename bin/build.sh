#!/bin/bash

# build.sh
# Build script for ObsidianObserver plugin
# Follows the same requirements as build.ps1

# Default values
BUILD_VERSION=""
VAULT_NAME=""
SKIP_DEPENDENCIES=false
SKIP_BUILD=false
CREATE_PACKAGE=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

# Function to print colored output
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [-v <version>] [OPTIONS]"
    echo ""
    echo "Parameters:"
    echo "  -v, --version VERSION    Build version (e.g., '00.01.08') - auto-detected from git branch or directory if not provided"
    echo ""
    echo "Options:"
    echo "  -n, --vault NAME         Vault name to update with the built plugin"
    echo "  -s, --skip-deps          Skip npm install step"
    echo "  -b, --skip-build         Skip the actual build step"
    echo "  -p, --package            Create a distributable package"
    echo "  -h, --help               Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Auto-detect version from git branch or directory name"
    echo "  $0 -v '00.01.08'                      # Specify version manually"
    echo "  $0 -n TestSidian-ObsidianObserver    # Auto-detect version and update vault"
    echo "  $0 -s -p                             # Skip deps, create package, auto-detect version"
}

# Function to validate version format
validate_version() {
    local version="$1"
    if [[ ! $version =~ ^[0-9]{2}\.[0-9]{2}\.[0-9]{2}$ ]]; then
        print_color $RED "Error: Invalid version format. Expected format: XX.XX.XX (e.g., '00.01.08')"
        exit 1
    fi
}

# Function to increment build number
increment_build_number() {
    local plugin_dir="$1"
    local build_number_path="$plugin_dir/build-number.txt"
    local current_build_number=0
    
    # Read current build number
    if [ -f "$build_number_path" ]; then
        current_build_number=$(cat "$build_number_path" | tr -d '\n\r')
        current_build_number=$((10#$current_build_number))  # Force decimal interpretation
    fi
    
    # Increment build number
    local new_build_number=$((current_build_number + 1))
    
    # Save new build number (4-digit format)
    printf "%04d" $new_build_number > "$build_number_path"
    
    echo $new_build_number
}

# Function to update version in JSON file
update_json_version() {
    local file_path="$1"
    local new_version="$2"
    local file_name="$3"
    
    if [ -f "$file_path" ]; then
        # Use jq if available, otherwise use sed
        if command -v jq &> /dev/null; then
            jq --arg version "$new_version" '.version = $version' "$file_path" > "${file_path}.tmp" && mv "${file_path}.tmp" "$file_path"
        else
            # Fallback to sed (less reliable but works for simple cases)
            sed -i.bak "s/\"version\": \"[^\"]*\"/\"version\": \"$new_version\"/" "$file_path"
            rm -f "${file_path}.bak"
        fi
        print_color $GREEN "  ✅ Updated $file_name version to $new_version"
    else
        print_color $RED "Error: $file_name not found: $file_path"
        exit 1
    fi
}

# Function to create distributable package
create_package() {
    local build_dir="$1"
    local version="$2"
    local project_root="$3"
    
    print_color $YELLOW "📦 Creating distributable package..."
    
    local package_name="ObsidianObserver-v$version"
    local package_dir="$project_root/packages"
    local package_path="$package_dir/$package_name"
    
    # Create packages directory if it doesn't exist
    mkdir -p "$package_dir"
    
    # Remove existing package if it exists
    if [ -d "$package_path" ]; then
        rm -rf "$package_path"
    fi
    
    # Create package directory
    mkdir -p "$package_path"
    
    # Copy required files from build directory
    local files_to_copy=("main.js" "manifest.json")
    
    for file in "${files_to_copy[@]}"; do
        local source_path="$build_dir/$file"
        local dest_path="$package_path/$file"
        
        if [ -f "$source_path" ]; then
            cp "$source_path" "$dest_path"
            print_color $GRAY "  📄 Copied $file"
        else
            print_color $YELLOW "Warning: File not found: $file"
        fi
    done
    
    # Create zip file
    local zip_path="$package_path.zip"
    if [ -f "$zip_path" ]; then
        rm -f "$zip_path"
    fi
    
    # Create zip file (using zip command if available)
    if command -v zip &> /dev/null; then
        (cd "$package_dir" && zip -r "$package_name.zip" "$package_name")
        print_color $GREEN "✅ Package created: $zip_path"
    else
        print_color $YELLOW "Warning: zip command not found. Package directory created at: $package_path"
    fi
    
    print_color $CYAN "📦 Package contents:"
    for file in "$package_path"/*; do
        if [ -f "$file" ]; then
            print_color $GRAY "  📄 $(basename "$file")"
        fi
    done
}

# Function to update vault
update_vault() {
    local vault_name="$1"
    local project_root="$2"
    
    print_color $YELLOW "🔄 Updating plugin in vault: $vault_name"
    
    # Prepend TestSidian- to vault name to match project naming convention
    local full_vault_name="TestSidian-$vault_name"
    local vault_path="$project_root/vaults/$full_vault_name"
    
    if [ ! -d "$vault_path" ]; then
        print_color $RED "Error: Vault not found: $vault_path"
        exit 1
    fi
    
    # Use the existing Populate-ObsidianVault script
    local populate_script="$project_root/bin/Populate-ObsidianVault.ps1"
    if [ -f "$populate_script" ]; then
        # Try to run PowerShell script if available
        if command -v pwsh &> /dev/null; then
            pwsh "$populate_script" -VaultName "$vault_name" -UpdateExploreObsdianPlugin
            if [ $? -eq 0 ]; then
                print_color $GREEN "✅ Plugin updated in vault successfully"
            else
                print_color $RED "Error: Failed to update plugin in vault"
                exit 1
            fi
        else
            print_color $YELLOW "Warning: PowerShell not available. Skipping vault update."
        fi
    else
        print_color $RED "Error: Populate-ObsidianVault.ps1 script not found"
        exit 1
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--version)
            BUILD_VERSION="$2"
            shift 2
            ;;
        -n|--vault)
            VAULT_NAME="$2"
            shift 2
            ;;
        -s|--skip-deps)
            SKIP_DEPENDENCIES=true
            shift
            ;;
        -b|--skip-build)
            SKIP_BUILD=true
            shift
            ;;
        -p|--package)
            CREATE_PACKAGE=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_color $RED "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Auto-determine version from git branch or current directory name if not provided
if [ -z "$BUILD_VERSION" ]; then
    # Try to get version from git branch first
    if command -v git &> /dev/null; then
        git_branch=$(git branch --show-current 2>/dev/null)
        if [[ $git_branch =~ ^v([0-9]{2}\.[0-9]{2}\.[0-9]{2})$ ]]; then
            BUILD_VERSION="${BASH_REMATCH[1]}"
            print_color $YELLOW "📝 Auto-detected version from git branch: $BUILD_VERSION"
        else
            # Fall back to directory name
            current_dir=$(basename "$(pwd)")
            if [[ $current_dir =~ ^v([0-9]{2}\.[0-9]{2}\.[0-9]{2})$ ]]; then
                BUILD_VERSION="${BASH_REMATCH[1]}"
                print_color $YELLOW "📝 Auto-detected version from directory name: $BUILD_VERSION"
            else
                print_color $RED "Error: Could not auto-detect version from git branch '$git_branch' or directory name '$current_dir'"
                print_color $RED "Please provide -v or --version parameter, or use format: vXX.XX.XX (e.g., 'v00.01.08')"
                show_usage
                exit 1
            fi
        fi
    else
        # Fall back to directory name if git command is not available
        current_dir=$(basename "$(pwd)")
        if [[ $current_dir =~ ^v([0-9]{2}\.[0-9]{2}\.[0-9]{2})$ ]]; then
            BUILD_VERSION="${BASH_REMATCH[1]}"
            print_color $YELLOW "📝 Auto-detected version from directory name: $BUILD_VERSION"
        else
            print_color $RED "Error: Could not auto-detect version from directory name '$current_dir'"
            print_color $RED "Please provide -v or --version parameter, or use directory format: vXX.XX.XX (e.g., 'v00.01.08')"
            show_usage
            exit 1
        fi
    fi
fi

# Validate version format
validate_version "$BUILD_VERSION"

# Get script directory and project paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$PLUGIN_DIR")"
BUILD_DIR="$PLUGIN_DIR/build"

print_color $CYAN "🔨 Building ObsidianObserver Plugin v$BUILD_VERSION"
print_color $GRAY "Script Directory: $SCRIPT_DIR"
print_color $GRAY "Plugin Directory: $PLUGIN_DIR"
print_color $GRAY "Project Root: $PROJECT_ROOT"
print_color $GRAY "Build Directory: $BUILD_DIR"

# Check if we're in the right location
if [ ! -f "$PLUGIN_DIR/package.json" ]; then
    print_color $RED "Error: package.json not found in plugin directory: $PLUGIN_DIR"
    exit 1
fi

# Create build directory if it doesn't exist
if [ ! -d "$BUILD_DIR" ]; then
    print_color $YELLOW "📁 Creating build directory..."
    mkdir -p "$BUILD_DIR"
fi

# Change to plugin directory
cd "$PLUGIN_DIR"

# Step 1: Increment build number and update version numbers
build_number=$(increment_build_number "$PLUGIN_DIR")
full_version="${BUILD_VERSION}_$(printf "%04d" $build_number)"

print_color $YELLOW "📝 Updating version numbers to $full_version (Build #$build_number)..."

# Update manifest.json
update_json_version "$PLUGIN_DIR/manifest.json" "$full_version" "manifest.json"

# Update package.json
update_json_version "$PLUGIN_DIR/package.json" "$full_version" "package.json"

# Update CSS file version
CSS_PATH="$PLUGIN_DIR/obsidian/snippets/obsidianObserverEventsTable.css"
if [ -f "$CSS_PATH" ]; then
    CSS_VERSION="v$BUILD_VERSION"
    if command -v sed &> /dev/null; then
        sed -i.bak "s/version: \"v[^\"]*\"/version: \"$CSS_VERSION\"/" "$CSS_PATH"
        rm -f "${CSS_PATH}.bak"
    else
        print_color $RED "Error: sed command not available for CSS version update"
        exit 1
    fi
    print_color $GREEN "  ✅ Updated CSS file version to $CSS_VERSION"
else
    print_color $YELLOW "  ⚠️  CSS file not found: $CSS_PATH"
fi

# Update EventsSummary.md version in logger.ts
LOGGER_PATH="$PLUGIN_DIR/src/logger.ts"
if [ -f "$LOGGER_PATH" ]; then
    if command -v sed &> /dev/null; then
        sed -i.bak "s/version: \"[^\"]*\"/version: \"$BUILD_VERSION\"/" "$LOGGER_PATH"
        rm -f "${LOGGER_PATH}.bak"
    else
        print_color $RED "Error: sed command not available for logger version update"
        exit 1
    fi
    print_color $GREEN "  ✅ Updated EventsSummary.md version to $BUILD_VERSION"
else
    print_color $YELLOW "  ⚠️  Logger file not found: $LOGGER_PATH"
fi

# Step 2: Install dependencies (unless skipped)
if [ "$SKIP_DEPENDENCIES" = false ]; then
    print_color $YELLOW "📦 Installing dependencies..."
    npm install
    if [ $? -ne 0 ]; then
        print_color $RED "Error: Failed to install dependencies"
        exit 1
    fi
    print_color $GREEN "✅ Dependencies installed successfully"
else
    print_color $YELLOW "⏭️  Skipping dependency installation"
fi

# Step 3: Build the plugin (unless skipped)
if [ "$SKIP_BUILD" = false ]; then
    print_color $YELLOW "🔨 Building plugin..."
    npm run build
    if [ $? -ne 0 ]; then
        print_color $RED "Error: Failed to build plugin"
        exit 1
    fi
    print_color $GREEN "✅ Plugin built successfully"
else
    print_color $YELLOW "⏭️  Skipping build step"
fi

# Step 4: Copy build output to build directory
print_color $YELLOW "📁 Copying build output to build directory..."

# Copy main.js to build directory
MAIN_JS_SOURCE="$PLUGIN_DIR/main.js"
MAIN_JS_DEST="$BUILD_DIR/main.js"

if [ -f "$MAIN_JS_SOURCE" ]; then
    cp "$MAIN_JS_SOURCE" "$MAIN_JS_DEST"
    print_color $GRAY "  📄 Copied main.js to build directory"
else
    print_color $RED "Error: Build output not found: $MAIN_JS_SOURCE"
    exit 1
fi

# Copy manifest.json to build directory
MANIFEST_SOURCE="$PLUGIN_DIR/manifest.json"
MANIFEST_DEST="$BUILD_DIR/manifest.json"

if [ -f "$MANIFEST_SOURCE" ]; then
    cp "$MANIFEST_SOURCE" "$MANIFEST_DEST"
    print_color $GRAY "  📄 Copied manifest.json to build directory"
else
    print_color $RED "Error: Manifest file not found: $MANIFEST_SOURCE"
    exit 1
fi

# Step 5: Verify build output
if [ ! -f "$MAIN_JS_DEST" ]; then
    print_color $RED "Error: Build output not found in build directory: $MAIN_JS_DEST"
    exit 1
fi

if [ ! -f "$MANIFEST_DEST" ]; then
    print_color $RED "Error: Manifest file not found in build directory: $MANIFEST_DEST"
    exit 1
fi

# Get file sizes for verification
MAIN_JS_SIZE=$(stat -f%z "$MAIN_JS_DEST" 2>/dev/null || stat -c%s "$MAIN_JS_DEST" 2>/dev/null || echo "unknown")

# Extract version from manifest (using jq if available, otherwise grep)
if command -v jq &> /dev/null; then
    PLUGIN_VERSION=$(jq -r '.version' "$MANIFEST_DEST")
    PLUGIN_NAME=$(jq -r '.name' "$MANIFEST_DEST")
else
    PLUGIN_VERSION=$(grep -o '"version": "[^"]*"' "$MANIFEST_DEST" | cut -d'"' -f4)
    PLUGIN_NAME=$(grep -o '"name": "[^"]*"' "$MANIFEST_DEST" | cut -d'"' -f4)
fi

print_color $CYAN "📊 Build Summary:"
print_color $GRAY "  Build directory: $BUILD_DIR"
print_color $GRAY "  Main.js size: $MAIN_JS_SIZE bytes"
print_color $GRAY "  Plugin version: $PLUGIN_VERSION"
print_color $GRAY "  Plugin name: $PLUGIN_NAME"

# Step 6: Create distributable package (if requested)
if [ "$CREATE_PACKAGE" = true ]; then
    create_package "$BUILD_DIR" "$BUILD_VERSION" "$PROJECT_ROOT"
fi

# Step 7: Update vault if specified
if [ -n "$VAULT_NAME" ]; then
    # Change to the project root to run the Populate-ObsidianVault script
    cd "$PROJECT_ROOT"
    update_vault "$VAULT_NAME" "$PROJECT_ROOT"
fi

print_color $GREEN "🎉 Build completed successfully!"
print_color $CYAN "📁 Build output available in: $BUILD_DIR"
print_color $CYAN "📝 Version updated to: $full_version (Build #$build_number)"
