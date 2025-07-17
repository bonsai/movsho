import * as path from 'path';
import * as Mocha from 'mocha';

export function run(): Promise<void> {
	// Create the mocha test
	const mocha = new Mocha({
		ui: 'tdd',
		color: true
	});

	const testsRoot = path.resolve(__dirname, '..');

	return new Promise((c, e) => {
		const testFiles = ['extension.test.js']; // Add test files manually for now
		
		// Add files to the test suite
		testFiles.forEach(f => {
			const testFile = path.resolve(testsRoot, 'suite', f);
			if (require('fs').existsSync(testFile)) {
				mocha.addFile(testFile);
			}
		});

		try {
			// Run the mocha test
			mocha.run((failures: number) => {
				if (failures > 0) {
					e(new Error(`${failures} tests failed.`));
				} else {
					c();
				}
			});
		} catch (err) {
			console.error(err);
			e(err);
		}
	});
}
