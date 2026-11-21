// Simulated SMS gateway. Messages are written to the smsOutbox collection (and the console)
// instead of being sent. Replace send() with a real provider for a live service.
const { getStore } = require('../db');
const { nowIso } = require('../utils/helpers');

async function send(to, message, meta = {}) {
  const store = getStore();
  const id = store.newId();
  await store.set('smsOutbox', id, { to, message, ...meta, status: 'simulated', at: nowIso() });
  if (process.env.NODE_ENV !== 'test') console.log(`[SMS -> ${to}] ${message}`);
  return id;
}

module.exports = { send };
