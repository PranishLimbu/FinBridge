// Runs the API test suite against SQLite instead of the memory store: npm run test:sqlite
const { spawnSync } = require('child_process');

const jest = require.resolve('jest/bin/jest');
const res = spawnSync(process.execPath, [jest, '--runInBand', ...process.argv.slice(2)], {
  stdio: 'inherit',
  env: { ...process.env, TEST_DB: 'sqlite' },
});
process.exit(res.status ?? 1);
