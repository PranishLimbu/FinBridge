const config = require('./config');
const { getStore } = require('./db');
const { createApp } = require('./app');
const { seed } = require('./seed');

async function main() {
  const store = getStore();
  if (store.driver === 'memory') {
    await seed(store, { log: true });
    console.log('Using the in-memory database: data resets when the server restarts.');
  }
  createApp().listen(config.port, '0.0.0.0', () => {
    console.log(`FinBridge API listening on http://localhost:${config.port}/api (db: ${store.driver})`);
  });
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
