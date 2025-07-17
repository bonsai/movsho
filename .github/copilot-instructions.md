<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

# Screenshot Auto Mover VS Code Extension

This is a VS Code extension project. Please use the get_vscode_api with a query as input to fetch the latest VS Code API references.

## Project Overview
This extension automatically monitors a source folder for new screenshot files and moves them to a destination folder. It provides a GUI interface for folder selection and real-time status updates.

## Key Features
- GUI-based folder selection using VS Code's native dialogs
- File system watching using chokidar library
- Status bar integration showing current status and move count
- Configuration persistence using VS Code settings
- Support for multiple image formats (PNG, JPG, JPEG)
- Automatic file renaming to prevent conflicts

## Development Guidelines
- Use TypeScript for all source code
- Follow VS Code extension best practices
- Implement proper error handling for file operations
- Use VS Code's configuration API for persistent settings
- Provide user feedback through information/error messages
- Maintain clean separation between UI and file operations
