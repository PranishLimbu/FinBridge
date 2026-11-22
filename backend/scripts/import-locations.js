// Loads provinces, districts and municipalities from reference-data/ into the database chosen
// by DB_DRIVER in .env (Firestore or SQLite). Safe to run again after editing the files.
// Usage: npm run import:locations
const config = require('../src/config');
const { getStore } = require('../src/db');
const { importLocations } = require('../src/services/locationService');

importLocations(getStore())
  .then((n) => {
    console.log(`Imported ${n.provinces} provinces, ${n.districts} districts and ${n.localBodies} municipalities into ${config.dbDriver}.`);
    if (config.dbDriver === 'memory') console.log('Note: DB_DRIVER=memory keeps nothing; the server loads this data itself at start.');
    process.exit(0);
  })
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
