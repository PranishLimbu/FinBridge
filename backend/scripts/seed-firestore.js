// Loads the fictional demo data into Cloud Firestore.
// Usage: DB_DRIVER=firestore node scripts/seed-firestore.js   (reads settings from .env)
process.env.DB_DRIVER = 'firestore';
const { getStore } = require('../src/db');
const { seed } = require('../src/seed');

seed(getStore(), { log: true })
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
