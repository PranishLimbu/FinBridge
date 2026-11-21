const { getStore } = require('../db');
const { nowIso } = require('../utils/helpers');

// Append-only audit log. Entries are never updated or deleted by the API.
async function audit(actorId, action, details = {}) {
  const store = getStore();
  await store.set('auditLogs', store.newId(), { actorId: actorId || 'anonymous', action, details, at: nowIso() });
}

// Same, but queued inside a store transaction so it commits atomically with the change.
function auditInTx(tx, store, actorId, action, details = {}) {
  tx.set('auditLogs', store.newId(), { actorId, action, details, at: nowIso() });
}

module.exports = { audit, auditInTx };
