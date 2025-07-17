# Screenshot Auto Mover - Build and Install Script (PowerShell)

param(
    [switch]$SkipTests = $false
)

# Set error action preference
$ErrorActionPreference = "Stop"

Write-Host "🚀 Starting automated build and installation process..." -ForegroundColor Blue

# Functions for colored output
function Write-Status {
    param($Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
    param($Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param($Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param($Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

try {
    # Check if we're in the right directory
    if (-not (Test-Path "package.json")) {
        Write-Error "package.json not found. Please run this script from the project root."
        exit 1
    }

    # Clean previous builds
    Write-Status "Cleaning previous builds..."
    if (Test-Path "out") { Remove-Item -Recurse -Force "out" }
    Get-ChildItem -Filter "*.vsix" | Remove-Item -Force
    Write-Success "Clean completed"

    # Install dependencies
    Write-Status "Installing dependencies..."
    if (Get-Command npm -ErrorAction SilentlyContinue) {
        npm install
        Write-Success "Dependencies installed successfully"
    } else {
        Write-Error "npm not found. Please install Node.js and npm first."
        exit 1
    }

    # Compile TypeScript
    Write-Status "Compiling TypeScript..."
    npm run compile
    Write-Success "TypeScript compilation completed"

    # Run linting
    Write-Status "Running ESLint..."
    try {
        npm run lint
        Write-Success "Linting passed"
    } catch {
        Write-Warning "Linting found issues (continuing anyway)"
    }

    # Package extension
    Write-Status "Packaging extension..."
    if (Get-Command vsce -ErrorAction SilentlyContinue) {
        vsce package
    } else {
        Write-Warning "vsce not found globally. Installing locally..."
        npx vsce package
    }
    Write-Success "Extension packaged successfully"

    # Find the generated .vsix file
    $VsixFile = Get-ChildItem -Filter "*.vsix" | Select-Object -First 1

    if (-not $VsixFile) {
        Write-Error "No .vsix file found after packaging"
        exit 1
    }

    Write-Success "Generated package: $($VsixFile.Name)"

    # Install extension locally
    Write-Status "Installing extension locally..."
    if (Get-Command code -ErrorAction SilentlyContinue) {
        code --install-extension $VsixFile.Name --force
        Write-Success "Extension installed successfully"
    } else {
        Write-Error "VS Code CLI not found. Please install VS Code and ensure 'code' command is available."
        exit 1
    }

    # Run tests (optional)
    if (-not $SkipTests) {
        $runTests = Read-Host "Do you want to run tests? (y/n)"
        if ($runTests -eq "y" -or $runTests -eq "Y") {
            Write-Status "Running tests..."
            try {
                npm test
                Write-Success "All tests passed"
            } catch {
                Write-Warning "Some tests failed (extension still installed)"
            }
        }
    }

    Write-Success "🎉 Build and installation completed successfully!"
    Write-Status "You can now use the extension in VS Code."
    Write-Status "Commands available:"
    Write-Host "  • Screenshot Auto Mover: Select Source Folder"
    Write-Host "  • Screenshot Auto Mover: Select Destination Folder"
    Write-Host "  • Screenshot Auto Mover: Start Watching"
    Write-Host "  • Screenshot Auto Mover: Stop Watching"
    Write-Host "  • Screenshot Auto Mover: Show Status"

} catch {
    Write-Error "Build process failed: $($_.Exception.Message)"
    exit 1
}
