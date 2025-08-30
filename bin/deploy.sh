#!/bin/bash

# deploy.sh
# Deploy ObsidianObserver plugin to an existing vault
# Bash equivalent of deploy.ps1

# Default values
VAULT_PATH=""
FORCE=false
VERBOSE=false

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

# Function to get plugin version from manifest.json
get_plugin_version() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local plugin_dir_root="$(dirname "$script_dir")"
    local manifest_path="$plugin_dir_root/manifest.json"
    
    if [ -f "$manifest_path" ]; then
        if command -v jq >/dev/null 2>&1; then
            local version=$(jq -r '.version' "$manifest_path" 2>/dev/null)
            if [ "$version" != "null" ] && [ -n "$version" ]; then
                echo "$version"
                return 0
            fi
        else
            # Fallback: use grep and sed if jq is not available
            local version=$(grep '"version"' "$manifest_path" | sed 's/.*"version":\s*"\([^"]*\)".*/\1/' 2>/dev/null)
            if [ -n "$version" ]; then
                echo "$version"
                return 0
            fi
        fi
    fi
    
    print_color $YELLOW "Warning: Could not read version from manifest.json"
    echo "unknown"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 <vault_path> [OPTIONS]"
    echo ""
    echo "Required Parameters:"
    echo "  vault_path              Path to the Obsidian vault where the plugin should be deployed"
    echo ""
    echo "Options:"
    echo "  -f, --force             Force overwrite of existing plugin files"
    echo "  -v, --verbose           Enable verbose output"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 \"/path/to/my/vault\""
    echo "  $0 \"/path/to/my/vault\" -f -v"
}

# Function to validate vault path
validate_vault_path() {
    local path="$1"
    
    if [ ! -d "$path" ]; then
        print_color $RED "Error: Vault path does not exist: $path"
        return 1
    fi
    
    # Check if it looks like an Obsidian vault (has .obsidian folder or markdown files)
    local has_obsidian_folder=false
    local has_markdown_files=false
    
    if [ -d "$path/.obsidian" ]; then
        has_obsidian_folder=true
    fi
    
    if find "$path" -name "*.md" -type f | head -n 1 | grep -q .; then
        has_markdown_files=true
    fi
    
    if [ "$has_obsidian_folder" = false ] && [ "$has_markdown_files" = false ]; then
        print_color $YELLOW "Warning: Path does not appear to be an Obsidian vault (no .obsidian folder or markdown files found)"
        print_color $YELLOW "Continuing anyway..."
    fi
    
    return 0
}

# Function to create Obsidian directory structure
create_obsidian_structure() {
    local vault_path="$1"
    
    local obsidian_path="$vault_path/.obsidian"
    local plugins_path="$obsidian_path/plugins"
    local snippets_path="$obsidian_path/snippets"
    
    # Create .obsidian directory if it doesn't exist
    if [ ! -d "$obsidian_path" ]; then
        print_color $YELLOW "📁 Creating .obsidian directory..."
        mkdir -p "$obsidian_path"
    fi
    
    # Create plugins directory if it doesn't exist
    if [ ! -d "$plugins_path" ]; then
        print_color $YELLOW "📁 Creating plugins directory..."
        mkdir -p "$plugins_path"
    fi
    
    # Create snippets directory if it doesn't exist
    if [ ! -d "$snippets_path" ]; then
        print_color $YELLOW "📁 Creating snippets directory..."
        mkdir -p "$snippets_path"
    fi
}

# Function to deploy plugin files
deploy_plugin_files() {
    local vault_path="$1"
    local plugin_name="$2"
    
    local plugin_dir="$vault_path/.obsidian/plugins/$plugin_name"
    
    # Create plugin directory
    if [ ! -d "$plugin_dir" ]; then
        print_color $YELLOW "📁 Creating plugin directory: $plugin_name"
        mkdir -p "$plugin_dir"
    fi
    
    # Get script directory and project paths
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local plugin_dir_root="$(dirname "$script_dir")"
    local build_dir="$plugin_dir_root/build"
    
    # Define source files
    local main_js_source="$build_dir/main.js"
    local manifest_source="$build_dir/manifest.json"
    
    # Copy main.js
    if [ -f "$main_js_source" ]; then
        if [ "$FORCE" = true ] || [ ! -f "$plugin_dir/main.js" ]; then
            cp "$main_js_source" "$plugin_dir/main.js"
            print_color $GRAY "  📄 Deployed main.js"
        else
            print_color $YELLOW "  ⏭️  Skipped main.js (use -f to overwrite)"
        fi
    else
        print_color $RED "  ❌ Source file not found: $main_js_source"
        return 1
    fi
    
    # Copy manifest.json
    if [ -f "$manifest_source" ]; then
        if [ "$FORCE" = true ] || [ ! -f "$plugin_dir/manifest.json" ]; then
            cp "$manifest_source" "$plugin_dir/manifest.json"
            print_color $GRAY "  📄 Deployed manifest.json"
        else
            print_color $YELLOW "  ⏭️  Skipped manifest.json (use -f to overwrite)"
        fi
    else
        print_color $RED "  ❌ Source file not found: $manifest_source"
        return 1
    fi
    
    return 0
}

# Function to deploy CSS snippets
deploy_css_snippets() {
    local vault_path="$1"
    
    local snippets_path="$vault_path/.obsidian/snippets"
    
    # Define CSS files to deploy
    local css_files=("dataview-table-fixes.css" "widen-property-name.css")
    
    # Get script directory and project paths
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local plugin_dir_root="$(dirname "$script_dir")"
    
    for css_file in "${css_files[@]}"; do
        local css_source_path="$plugin_dir_root/obsidian/snippets/$css_file"
        local css_dest_path="$snippets_path/$css_file"
        
        if [ -f "$css_source_path" ]; then
            if [ "$FORCE" = true ] || [ ! -f "$css_dest_path" ]; then
                cp "$css_source_path" "$css_dest_path"
                print_color $GRAY "  📄 Deployed CSS snippet: $css_file"
            else
                print_color $YELLOW "  ⏭️  Skipped CSS snippet: $css_file (use -f to overwrite)"
            fi
        else
            print_color $RED "  ❌ CSS source file not found: $css_source_path"
        fi
    done
}

# Function to update app.json
update_app_json() {
    local vault_path="$1"
    local plugin_name="$2"
    
    local app_json_path="$vault_path/.obsidian/app.json"
    local temp_json_path="$app_json_path.tmp"
    
    # Create or update app.json
    if [ -f "$app_json_path" ]; then
        # Try to parse existing JSON and add plugin
        if command -v jq &> /dev/null; then
            # Use jq to safely update the JSON
            jq --arg plugin "$plugin_name" '.plugins[$plugin] = true' "$app_json_path" > "$temp_json_path" 2>/dev/null
            if [ $? -eq 0 ]; then
                mv "$temp_json_path" "$app_json_path"
            else
                # Fallback: create new app.json
                echo "{\"plugins\":{\"$plugin_name\":true}}" > "$app_json_path"
            fi
        else
            # Fallback: create new app.json
            echo "{\"plugins\":{\"$plugin_name\":true}}" > "$app_json_path"
        fi
    else
        # Create new app.json
        echo "{\"plugins\":{\"$plugin_name\":true}}" > "$app_json_path"
    fi
    
    print_color $GRAY "  📄 Updated app.json to enable plugin"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--force)
            FORCE=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        -*)
            print_color $RED "Unknown option: $1"
            show_usage
            exit 1
            ;;
        *)
            if [ -z "$VAULT_PATH" ]; then
                VAULT_PATH="$1"
            else
                print_color $RED "Error: Multiple vault paths specified"
                show_usage
                exit 1
            fi
            shift
            ;;
    esac
done

# Check if required vault path was provided
if [ -z "$VAULT_PATH" ]; then
    print_color $RED "Error: Vault path is required"
    show_usage
    exit 1
fi

# Main execution
# Get plugin version
plugin_version=$(get_plugin_version)

print_color $CYAN "🚀 Deploying ObsidianObserver Plugin"
print_color $CYAN "Version: $plugin_version"
print_color $GRAY "Vault Path: $VAULT_PATH"

if [ "$VERBOSE" = true ]; then
    print_color $GRAY "Verbose mode enabled"
fi

# Validate vault path
if ! validate_vault_path "$VAULT_PATH"; then
    exit 1
fi

# Create Obsidian directory structure
create_obsidian_structure "$VAULT_PATH"

# Deploy plugin files
plugin_name="obsidian-observer"
if ! deploy_plugin_files "$VAULT_PATH" "$plugin_name"; then
    print_color $RED "Error: Failed to deploy plugin files"
    exit 1
fi

# Deploy CSS snippets
deploy_css_snippets "$VAULT_PATH"

# Update app.json
update_app_json "$VAULT_PATH" "$plugin_name"

print_color $GREEN "✅ Plugin deployed successfully!"
print_color $CYAN "📁 Plugin location: $VAULT_PATH/.obsidian/plugins/$plugin_name"
print_color $YELLOW "💡 Restart Obsidian or reload the vault to activate the plugin"
