#!/bin/bash

# Screenshot Auto Mover - Build and Install Script

set -e  # Exit on any error

echo "🚀 Starting automated build and installation process..."

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    print_error "package.json not found. Please run this script from the project root."
    exit 1
fi

# Clean previous builds
print_status "Cleaning previous builds..."
rm -rf out/
rm -f *.vsix

# Install dependencies
print_status "Installing dependencies..."
if command -v npm &> /dev/null; then
    npm install
    print_success "Dependencies installed successfully"
else
    print_error "npm not found. Please install Node.js and npm first."
    exit 1
fi

# Compile TypeScript
print_status "Compiling TypeScript..."
if npm run compile; then
    print_success "TypeScript compilation completed"
else
    print_error "TypeScript compilation failed"
    exit 1
fi

# Run linting
print_status "Running ESLint..."
if npm run lint; then
    print_success "Linting passed"
else
    print_warning "Linting found issues (continuing anyway)"
fi

# Package extension
print_status "Packaging extension..."
if command -v vsce &> /dev/null; then
    if vsce package; then
        print_success "Extension packaged successfully"
    else
        print_error "Extension packaging failed"
        exit 1
    fi
else
    print_warning "vsce not found globally. Installing locally..."
    npx vsce package
    if [ $? -eq 0 ]; then
        print_success "Extension packaged successfully"
    else
        print_error "Extension packaging failed"
        exit 1
    fi
fi

# Find the generated .vsix file
VSIX_FILE=$(find . -maxdepth 1 -name "*.vsix" | head -n 1)

if [ -z "$VSIX_FILE" ]; then
    print_error "No .vsix file found after packaging"
    exit 1
fi

print_success "Generated package: $VSIX_FILE"

# Install extension locally
print_status "Installing extension locally..."
if command -v code &> /dev/null; then
    if code --install-extension "$VSIX_FILE" --force; then
        print_success "Extension installed successfully"
    else
        print_error "Extension installation failed"
        exit 1
    fi
else
    print_error "VS Code CLI not found. Please install VS Code and ensure 'code' command is available."
    exit 1
fi

# Run tests (optional)
read -p "Do you want to run tests? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Running tests..."
    if npm test; then
        print_success "All tests passed"
    else
        print_warning "Some tests failed (extension still installed)"
    fi
fi

print_success "🎉 Build and installation completed successfully!"
print_status "You can now use the extension in VS Code."
print_status "Commands available:"
echo "  • Screenshot Auto Mover: Select Source Folder"
echo "  • Screenshot Auto Mover: Select Destination Folder"
echo "  • Screenshot Auto Mover: Start Watching"
echo "  • Screenshot Auto Mover: Stop Watching"
echo "  • Screenshot Auto Mover: Show Status"
