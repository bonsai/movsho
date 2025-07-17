import * as vscode from 'vscode';
import * as fs from 'fs';
import * as path from 'path';
import { FSWatcher, watch } from 'chokidar';

export function activate(context: vscode.ExtensionContext) {
    console.log('Screenshot Auto Mover extension is now active!');

    const screenshotMover = new ScreenshotAutoMover(context);
    
    // Register commands
    const selectSourceCommand = vscode.commands.registerCommand(
        'screenshotAutoMover.selectSourceFolder',
        () => screenshotMover.selectSourceFolder()
    );

    const selectDestinationCommand = vscode.commands.registerCommand(
        'screenshotAutoMover.selectDestinationFolder', 
        () => screenshotMover.selectDestinationFolder()
    );

    const startWatchingCommand = vscode.commands.registerCommand(
        'screenshotAutoMover.startWatching',
        () => screenshotMover.startWatching()
    );

    const stopWatchingCommand = vscode.commands.registerCommand(
        'screenshotAutoMover.stopWatching',
        () => screenshotMover.stopWatching()
    );

    const showStatusCommand = vscode.commands.registerCommand(
        'screenshotAutoMover.showStatus',
        () => screenshotMover.showStatus()
    );

    context.subscriptions.push(
        selectSourceCommand,
        selectDestinationCommand,
        startWatchingCommand,
        stopWatchingCommand,
        showStatusCommand
    );

    // Auto-start if configured
    const config = vscode.workspace.getConfiguration('screenshotAutoMover');
    if (config.get('autoStart')) {
        screenshotMover.startWatching();
    }
}

class ScreenshotAutoMover {
    private watcher: FSWatcher | undefined;
    private statusBarItem: vscode.StatusBarItem;
    private isWatching = false;
    private moveCount = 0;

    constructor(private context: vscode.ExtensionContext) {
        this.statusBarItem = vscode.window.createStatusBarItem(
            vscode.StatusBarAlignment.Right,
            100
        );
        this.statusBarItem.command = 'screenshotAutoMover.showStatus';
        this.statusBarItem.show();
        this.updateStatusBar();
        
        this.context.subscriptions.push(this.statusBarItem);
    }

    async selectSourceFolder() {
        const options: vscode.OpenDialogOptions = {
            canSelectMany: false,
            canSelectFolders: true,
            canSelectFiles: false,
            openLabel: 'Select Source Folder'
        };

        const folderUri = await vscode.window.showOpenDialog(options);
        if (folderUri && folderUri[0]) {
            const config = vscode.workspace.getConfiguration('screenshotAutoMover');
            await config.update('sourceFolder', folderUri[0].fsPath, vscode.ConfigurationTarget.Global);
            
            vscode.window.showInformationMessage(
                `Source folder set to: ${folderUri[0].fsPath}`
            );
            this.updateStatusBar();
        }
    }

    async selectDestinationFolder() {
        const options: vscode.OpenDialogOptions = {
            canSelectMany: false,
            canSelectFolders: true,
            canSelectFiles: false,
            openLabel: 'Select Destination Folder'
        };

        const folderUri = await vscode.window.showOpenDialog(options);
        if (folderUri && folderUri[0]) {
            const config = vscode.workspace.getConfiguration('screenshotAutoMover');
            await config.update('destinationFolder', folderUri[0].fsPath, vscode.ConfigurationTarget.Global);
            
            vscode.window.showInformationMessage(
                `Destination folder set to: ${folderUri[0].fsPath}`
            );
            this.updateStatusBar();
        }
    }

    async startWatching() {
        if (this.isWatching) {
            vscode.window.showWarningMessage('Already watching for screenshots!');
            return;
        }

        const config = vscode.workspace.getConfiguration('screenshotAutoMover');
        const sourceFolder = config.get<string>('sourceFolder');
        const destinationFolder = config.get<string>('destinationFolder');

        if (!sourceFolder || !destinationFolder) {
            vscode.window.showErrorMessage(
                'Please select both source and destination folders first!'
            );
            return;
        }

        if (!fs.existsSync(sourceFolder)) {
            vscode.window.showErrorMessage(`Source folder does not exist: ${sourceFolder}`);
            return;
        }

        if (!fs.existsSync(destinationFolder)) {
            vscode.window.showErrorMessage(`Destination folder does not exist: ${destinationFolder}`);
            return;
        }

        const fileExtensions = config.get<string[]>('fileExtensions') || ['.png', '.jpg', '.jpeg'];
        const watchPattern = fileExtensions.map(ext => `**/*${ext}`);

        this.watcher = watch(watchPattern, {
            cwd: sourceFolder,
            ignoreInitial: true
        });

        this.watcher.on('add', (filePath) => {
            this.moveScreenshot(path.join(sourceFolder, filePath), destinationFolder);
        });

        this.watcher.on('error', (error) => {
            vscode.window.showErrorMessage(`Watcher error: ${error.message}`);
        });

        this.isWatching = true;
        this.moveCount = 0;
        this.updateStatusBar();
        
        vscode.window.showInformationMessage(
            `Started watching for screenshots in: ${sourceFolder}`
        );
    }

    stopWatching() {
        if (!this.isWatching) {
            vscode.window.showWarningMessage('Not currently watching!');
            return;
        }

        if (this.watcher) {
            this.watcher.close();
            this.watcher = undefined;
        }

        this.isWatching = false;
        this.updateStatusBar();
        
        vscode.window.showInformationMessage('Stopped watching for screenshots');
    }

    private async moveScreenshot(sourcePath: string, destinationFolder: string) {
        try {
            // Wait a bit to ensure file is fully written
            await new Promise(resolve => setTimeout(resolve, 500));

            const fileName = path.basename(sourcePath);
            const destinationPath = path.join(destinationFolder, fileName);

            // Check if destination file already exists
            if (fs.existsSync(destinationPath)) {
                const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
                const extension = path.extname(fileName);
                const nameWithoutExt = path.basename(fileName, extension);
                const newFileName = `${nameWithoutExt}_${timestamp}${extension}`;
                const newDestinationPath = path.join(destinationFolder, newFileName);
                
                fs.copyFileSync(sourcePath, newDestinationPath);
                fs.unlinkSync(sourcePath);
                
                vscode.window.showInformationMessage(
                    `Screenshot moved: ${fileName} → ${newFileName}`
                );
            } else {
                fs.copyFileSync(sourcePath, destinationPath);
                fs.unlinkSync(sourcePath);
                
                vscode.window.showInformationMessage(
                    `Screenshot moved: ${fileName}`
                );
            }

            this.moveCount++;
            this.updateStatusBar();

        } catch (error) {
            vscode.window.showErrorMessage(
                `Failed to move screenshot: ${error instanceof Error ? error.message : 'Unknown error'}`
            );
        }
    }

    private updateStatusBar() {
        const config = vscode.workspace.getConfiguration('screenshotAutoMover');
        const sourceFolder = config.get<string>('sourceFolder');
        const destinationFolder = config.get<string>('destinationFolder');

        if (this.isWatching) {
            this.statusBarItem.text = `$(eye) Screenshots: ${this.moveCount}`;
            this.statusBarItem.tooltip = `Watching for screenshots\\nMoved: ${this.moveCount} files`;
        } else if (sourceFolder && destinationFolder) {
            this.statusBarItem.text = `$(eye-closed) Screenshots: Ready`;
            this.statusBarItem.tooltip = 'Click to start watching for screenshots';
        } else {
            this.statusBarItem.text = `$(gear) Screenshots: Setup`;
            this.statusBarItem.tooltip = 'Click to configure screenshot folders';
        }
    }

    showStatus() {
        const config = vscode.workspace.getConfiguration('screenshotAutoMover');
        const sourceFolder = config.get<string>('sourceFolder') || 'Not set';
        const destinationFolder = config.get<string>('destinationFolder') || 'Not set';
        
        const status = [
            'Screenshot Auto Mover Status:',
            '',
            `Source Folder: ${sourceFolder}`,
            `Destination Folder: ${destinationFolder}`,
            `Status: ${this.isWatching ? 'Watching' : 'Stopped'}`,
            `Screenshots Moved: ${this.moveCount}`,
            '',
            'Available Commands:',
            '• Screenshot Auto Mover: Select Source Folder',
            '• Screenshot Auto Mover: Select Destination Folder', 
            '• Screenshot Auto Mover: Start Watching',
            '• Screenshot Auto Mover: Stop Watching'
        ].join('\\n');

        vscode.window.showInformationMessage(status, { modal: true });
    }
}

export function deactivate() {
    console.log('Screenshot Auto Mover extension deactivated');
}
