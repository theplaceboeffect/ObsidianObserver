#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Deploy ObsidianObserver plugin to an existing vault

.DESCRIPTION
    This script deploys the ObsidianObserver plugin to an existing Obsidian vault.
    It creates the necessary directory structure, copies plugin files, and enables the plugin.

.PARAMETER VaultPath
    Required path to the Obsidian vault where the plugin should be deployed

.PARAMETER Force
    Force overwrite of existing plugin files

.PARAMETER VerboseOutput
    Enable verbose output

.EXAMPLE
    .\deploy.ps1 -VaultPath "C:\Users\username\Documents\MyVault"

.EXAMPLE
    .\deploy.ps1 -VaultPath "C:\Users\username\Documents\MyVault" -Force -VerboseOutput
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$VaultPath,
    [switch]$Force,
    [switch]$VerboseOutput
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Colors for output
$Red = "Red"
$Green = "Green"
$Yellow = "Yellow"
$Cyan = "Cyan"
$Gray = "Gray"

# Function to print colored output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

# Function to get plugin version from manifest.json
function Get-PluginVersion {
    try {
        $ScriptDir = Split-Path -Parent $PSCommandPath
        $PluginDir = Split-Path -Parent $ScriptDir
        $manifestPath = Join-Path $PluginDir "manifest.json"
        
        if (Test-Path $manifestPath) {
            try {
                $manifest = Get-Content $manifestPath | ConvertFrom-Json
                return $manifest.version
            } catch {
                Write-ColorOutput "Warning: Could not read version from manifest.json" $Yellow
                return "unknown"
            }
        } else {
            Write-ColorOutput "Warning: manifest.json not found" $Yellow
            return "unknown"
        }
    } catch {
        Write-ColorOutput "Warning: Could not determine script path" $Yellow
        return "unknown"
    }
}

# Function to validate vault path
function Test-VaultPath {
    param([string]$Path)
    
    if (!(Test-Path $Path)) {
        Write-ColorOutput "Error: Vault path does not exist: $Path" $Red
        return $false
    }
    
    # Check if it looks like an Obsidian vault (has .obsidian folder or markdown files)
    $hasObsidianFolder = Test-Path (Join-Path $Path ".obsidian")
    $hasMarkdownFiles = Get-ChildItem -Path $Path -Filter "*.md" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    
    if (!$hasObsidianFolder -and !$hasMarkdownFiles) {
        Write-ColorOutput "Warning: Path does not appear to be an Obsidian vault (no .obsidian folder or markdown files found)" $Yellow
        Write-ColorOutput "Continuing anyway..." $Yellow
    }
    
    return $true
}

# Function to create Obsidian directory structure
function New-ObsidianStructure {
    param([string]$VaultPath)
    
    $obsidianPath = Join-Path $VaultPath ".obsidian"
    $pluginsPath = Join-Path $obsidianPath "plugins"
    $snippetsPath = Join-Path $obsidianPath "snippets"
    
    # Create .obsidian directory if it doesn't exist
    if (!(Test-Path $obsidianPath)) {
        Write-ColorOutput "📁 Creating .obsidian directory..." $Yellow
        New-Item -Path $obsidianPath -ItemType Directory -Force | Out-Null
    }
    
    # Create plugins directory if it doesn't exist
    if (!(Test-Path $pluginsPath)) {
        Write-ColorOutput "📁 Creating plugins directory..." $Yellow
        New-Item -Path $pluginsPath -ItemType Directory -Force | Out-Null
    }
    
    # Create snippets directory if it doesn't exist
    if (!(Test-Path $snippetsPath)) {
        Write-ColorOutput "📁 Creating snippets directory..." $Yellow
        New-Item -Path $snippetsPath -ItemType Directory -Force | Out-Null
    }
}

# Function to deploy plugin files
function Deploy-PluginFiles {
    param([string]$VaultPath, [string]$PluginName)
    
    $pluginDir = Join-Path $VaultPath ".obsidian" "plugins" $PluginName
    
    # Create plugin directory
    if (!(Test-Path $pluginDir)) {
        Write-ColorOutput "📁 Creating plugin directory: $PluginName" $Yellow
        New-Item -Path $pluginDir -ItemType Directory -Force | Out-Null
    }
    
    # Get script directory and project paths
    $ScriptDir = Split-Path -Parent $PSCommandPath
    $PluginDir = Split-Path -Parent $ScriptDir
    $BuildDir = Join-Path $PluginDir "build"
    
    # Define source files
    $sourceFiles = @{
        "main.js" = Join-Path $BuildDir "main.js"
        "manifest.json" = Join-Path $BuildDir "manifest.json"
    }
    
    # Copy files
    foreach ($file in $sourceFiles.Keys) {
        $sourcePath = $sourceFiles[$file]
        $destPath = Join-Path $pluginDir $file
        
        if (Test-Path $sourcePath) {
            if ($Force -or !(Test-Path $destPath)) {
                Copy-Item -Path $sourcePath -Destination $destPath -Force
                Write-ColorOutput "  📄 Deployed $file" $Gray
            } else {
                Write-ColorOutput "  ⏭️  Skipped $file (use -Force to overwrite)" $Yellow
            }
        } else {
            Write-ColorOutput "  ❌ Source file not found: $sourcePath" $Red
            return $false
        }
    }
    
    return $true
}

# Function to deploy CSS snippets
function Deploy-CssSnippets {
    param([string]$VaultPath)
    
    $snippetsPath = Join-Path $VaultPath ".obsidian" "snippets"
    
    # Define CSS files to deploy
    $cssFiles = @("dataview-table-fixes.css", "widen-property-name.css")
    
    # Get script directory and project paths
    $ScriptDir = Split-Path -Parent $PSCommandPath
    $PluginDir = Split-Path -Parent $ScriptDir
    
    foreach ($cssFile in $cssFiles) {
        $cssSourcePath = Join-Path $PluginDir "obsidian" "snippets" $cssFile
        $cssDestPath = Join-Path $snippetsPath $cssFile
        
        if (Test-Path $cssSourcePath) {
            if ($Force -or !(Test-Path $cssDestPath)) {
                Copy-Item -Path $cssSourcePath -Destination $cssDestPath -Force
                Write-ColorOutput "  📄 Deployed CSS snippet: $cssFile" $Gray
            } else {
                Write-ColorOutput "  ⏭️  Skipped CSS snippet: $cssFile (use -Force to overwrite)" $Yellow
            }
        } else {
            Write-ColorOutput "  ❌ CSS source file not found: $cssSourcePath" $Red
        }
    }
}

# Function to update app.json
function Update-AppJson {
    param([string]$VaultPath, [string]$PluginName)
    
    $appJsonPath = Join-Path $VaultPath ".obsidian" "app.json"
    
    # Read existing app.json or create new one
    if (Test-Path $appJsonPath) {
        try {
            $appConfig = Get-Content $appJsonPath | ConvertFrom-Json
        } catch {
            Write-ColorOutput "Warning: Could not parse existing app.json, creating new one" $Yellow
            $appConfig = [PSCustomObject]@{
                plugins = @{}
            }
        }
    } else {
        $appConfig = [PSCustomObject]@{
            plugins = @{}
        }
    }
    
    # Ensure plugins property exists
    if (!$appConfig.plugins) {
        $appConfig.plugins = @{}
    }
    
    # Enable the plugin
    $appConfig.plugins.$PluginName = $true
    
    # Save app.json
    $appConfig | ConvertTo-Json -Depth 10 | Set-Content $appJsonPath -Encoding UTF8
    Write-ColorOutput "  📄 Updated app.json to enable plugin" $Gray
}

# Main execution
try {
    # Get plugin version
    $pluginVersion = Get-PluginVersion
    
    Write-ColorOutput "🚀 Deploying ObsidianObserver Plugin" $Cyan
    Write-ColorOutput "Version: $pluginVersion" $Cyan
    Write-ColorOutput "Vault Path: $VaultPath" $Gray
    
    if ($VerboseOutput) {
        Write-ColorOutput "Verbose mode enabled" $Gray
    }
    
    # Validate vault path
    if (!(Test-VaultPath $VaultPath)) {
        exit 1
    }
    
    # Create Obsidian directory structure
    New-ObsidianStructure $VaultPath
    
    # Deploy plugin files
    $pluginName = "obsidian-observer"
    if (!(Deploy-PluginFiles $VaultPath $pluginName)) {
        Write-ColorOutput "Error: Failed to deploy plugin files" $Red
        exit 1
    }
    
    # Deploy CSS snippets
    Deploy-CssSnippets $VaultPath
    
    # Update app.json
    Update-AppJson $VaultPath $pluginName
    
    Write-ColorOutput "✅ Plugin deployed successfully!" $Green
    Write-ColorOutput "📁 Plugin location: $(Join-Path $VaultPath '.obsidian' 'plugins' $pluginName)" $Cyan
    Write-ColorOutput "💡 Restart Obsidian or reload the vault to activate the plugin" $Yellow
    
} catch {
    Write-ColorOutput "Error: Deployment failed: $($_.Exception.Message)" $Red
    exit 1
}
