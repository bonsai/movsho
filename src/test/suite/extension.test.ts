import * as assert from 'assert';
import * as vscode from 'vscode';

suite('Extension Test Suite', () => {
	vscode.window.showInformationMessage('Start all tests.');

	test('Extension should be present', () => {
		assert.ok(vscode.extensions.getExtension('undefined_publisher.screenshot-auto-mover'));
	});

	test('Extension should activate', async () => {
		const extension = vscode.extensions.getExtension('undefined_publisher.screenshot-auto-mover');
		if (extension) {
			await extension.activate();
			assert.ok(extension.isActive);
		}
	});

	test('Commands should be registered', async () => {
		const commands = await vscode.commands.getCommands(true);
		
		const expectedCommands = [
			'screenshotAutoMover.selectSourceFolder',
			'screenshotAutoMover.selectDestinationFolder',
			'screenshotAutoMover.startWatching',
			'screenshotAutoMover.stopWatching',
			'screenshotAutoMover.showStatus'
		];

		expectedCommands.forEach(command => {
			assert.ok(commands.includes(command), `Command ${command} should be registered`);
		});
	});

	test('Configuration should have default values', () => {
		const config = vscode.workspace.getConfiguration('screenshotAutoMover');
		
		assert.strictEqual(config.get('sourceFolder'), '');
		assert.strictEqual(config.get('destinationFolder'), '');
		assert.strictEqual(config.get('autoStart'), false);
		assert.deepStrictEqual(config.get('fileExtensions'), ['.png', '.jpg', '.jpeg']);
	});
});
