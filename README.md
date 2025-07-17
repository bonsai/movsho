# Screenshot Auto Mover

[![CI/CD Pipeline](https://github.com/username/screenshot-auto-mover/actions/workflows/ci.yml/badge.svg)](https://github.com/username/screenshot-auto-mover/actions/workflows/ci.yml)
[![Version](https://img.shields.io/badge/version-0.0.1-blue.svg)](https://github.com/username/screenshot-auto-mover)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

A VS Code extension that automatically moves screenshot files from a source folder to a destination folder with GUI folder selection.

## Features

- **GUI Folder Selection**: Easy-to-use dialog boxes for selecting source and destination folders
- **Real-time Monitoring**: Automatically detects new screenshot files using file system watching
- **Status Bar Integration**: Shows current status and move count in the VS Code status bar
- **Multiple Format Support**: Supports PNG, JPG, and JPEG files
- **Smart Renaming**: Automatically renames files if conflicts occur
- **Persistent Configuration**: Remembers your folder selections across VS Code sessions

## Installation

1. Open this project in VS Code
2. Press `F5` to launch a new Extension Development Host window
3. In the new window, the extension will be automatically loaded

## Usage

### Setting Up Folders

1. Open the Command Palette (`Ctrl+Shift+P` or `Cmd+Shift+P`)
2. Run `Screenshot Auto Mover: Select Source Folder` to choose where screenshots are saved
3. Run `Screenshot Auto Mover: Select Destination Folder` to choose where they should be moved

### Starting the Watcher

1. Open the Command Palette
2. Run `Screenshot Auto Mover: Start Watching`
3. The extension will now monitor the source folder and automatically move new screenshots

### Monitoring Status

- Check the status bar (bottom right) for current watching status and move count
- Click the status bar item to see detailed status information
- Run `Screenshot Auto Mover: Show Status` for a detailed status dialog

### Available Commands

- `Screenshot Auto Mover: Select Source Folder` - Choose the folder to monitor
- `Screenshot Auto Mover: Select Destination Folder` - Choose where to move screenshots
- `Screenshot Auto Mover: Start Watching` - Begin monitoring for new files
- `Screenshot Auto Mover: Stop Watching` - Stop the file monitoring
- `Screenshot Auto Mover: Show Status` - Display current configuration and status

## Configuration

The extension can be configured through VS Code settings:

- `screenshotAutoMover.sourceFolder`: Source folder path
- `screenshotAutoMover.destinationFolder`: Destination folder path  
- `screenshotAutoMover.autoStart`: Automatically start watching when VS Code starts
- `screenshotAutoMover.fileExtensions`: File extensions to monitor (default: .png, .jpg, .jpeg)

## Development

### Automated Build and Installation

This project includes several automation tools for easy development and deployment:

#### Quick Start (One Command)
```bash
# Linux/macOS
./build-and-install.sh

# Windows
.\build-and-install.ps1
```

#### Using Makefile
```bash
make setup          # Install dependencies and compile
make all             # Full build, test, package, and install
make quick           # Quick build and install (for development)
make dev             # Start watch mode for development
```

#### Using npm scripts
```bash
npm run setup            # Install dependencies and compile
npm run build-and-install # Build, package, and install
npm run compile          # Compile TypeScript
npm run watch            # Watch for changes
npm run lint             # Run ESLint
npm run test             # Run tests
npm run package          # Package as .vsix
npm run clean            # Clean build artifacts
```

#### Using VS Code Tasks
- `Ctrl+Shift+P` → `Tasks: Run Task`
- Choose from:
  - **Build and Install Extension** - Complete automation
  - **npm: compile** - Compile only
  - **npm: watch** - Watch mode
  - **npm: lint** - Run linting
  - **Package Extension** - Create .vsix file

### Building

```bash
npm install
npm run compile
```

### Testing

```bash
npm run test    # Run all tests
npm run lint    # Run linting only
```

### Packaging

```bash
npm run package          # Creates .vsix file
npm run install-local    # Installs locally in VS Code
```

### Project Structure

- `src/extension.ts` - Main extension code
- `package.json` - Extension manifest and dependencies
- `tsconfig.json` - TypeScript configuration

## License

This project is licensed under the MIT License.
