// In-memory document store with the same interface as firestoreStore.js.
// Used for automated tests and for demoing the app without a Firebase project.
const crypto = require('crypto');

const clone = (v) => (v === undefined ? undefined : structuredClone(v));

function matches(doc, [field, op, value]) {
  const v = doc[field];
  switch (op) {
    case '==': return v === value;
    case '!=': return v !== value;
    case '>': return v > value;
    case '>=': return v >= value;
    case '<': return v < value;
    case '<=': return v <= value;
    case 'in': return Array.isArray(value) && value.includes(v);
    default: throw new Error(`Unsupported operator ${op}`);
  }
}

function createMemoryStore() {
  const data = new Map(); // collection -> Map(id -> doc)
  const col = (name) => {
    if (!data.has(name)) data.set(name, new Map());
    return data.get(name);
  };
  // Serialise transactions so concurrent requests cannot interleave (like Firestore's retries).
  let lock = Promise.resolve();

  const store = {
    driver: 'memory',
    newId: () => crypto.randomUUID(),

    async get(collection, id) {
      const doc = col(collection).get(id);
      return doc ? { id, ...clone(doc) } : null;
    },
    async set(collection, id, value) {
      col(collection).set(id, clone(value));
    },
    async create(collection, id, value) {
      if (col(collection).has(id)) throw Object.assign(new Error('Document exists'), { code: 'ALREADY_EXISTS' });
      col(collection).set(id, clone(value));
    },
    async update(collection, id, partial) {
      const existing = col(collection).get(id);
      if (!existing) throw new Error(`No document ${collection}/${id}`);
      col(collection).set(id, { ...existing, ...clone(partial) });
    },
    async query(collection, { where = [], orderBy, limit } = {}) {
      let docs = [...col(collection).entries()].map(([id, d]) => ({ id, ...clone(d) }));
      docs = docs.filter((d) => where.every((w) => matches(d, w)));
      if (orderBy) {
        const [field, dir = 'asc'] = orderBy;
        docs.sort((a, b) => (a[field] < b[field] ? -1 : a[field] > b[field] ? 1 : 0) * (dir === 'desc' ? -1 : 1));
      }
      return limit ? docs.slice(0, limit) : docs;
    },
    async runTransaction(fn) {
      const run = lock.then(async () => {
        const writes = [];
        const tx = {
          get: (c, id) => store.get(c, id),
          set: (c, id, v) => writes.push(() => store.set(c, id, v)),
          create: (c, id, v) => writes.push(() => store.create(c, id, v)),
          update: (c, id, v) => writes.push(() => store.update(c, id, v)),
        };
        const result = await fn(tx);
        for (const w of writes) await w(); // commit only if fn did not throw
        return result;
      });
      lock = run.catch(() => {});
      return run;
    },
    async clear() {
      data.clear();
    },
  };
  return store;
}

module.exports = { createMemoryStore, matches };
