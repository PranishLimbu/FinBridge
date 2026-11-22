// SQLite implementation of the document store, using the SQLite built into Node (node:sqlite).
// Each collection is a table with an `id` column and a `data` column holding the document as
// JSON, so the services keep the same document interface as Firestore and the memory store.
// Data is saved in one file and survives restarts.
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const { DatabaseSync } = require('node:sqlite');

const IDENT = /^[A-Za-z_][A-Za-z0-9_]*$/;
const FIELD = /^[A-Za-z_][A-Za-z0-9_.]*$/;
const OPS = new Set(['==', '!=', '>', '>=', '<', '<=', 'in']);

function checkName(name, pattern, what) {
  if (!pattern.test(name)) throw new Error(`Invalid ${what} name: ${name}`);
  return name;
}

// SQLite has no boolean type: JSON true/false read back from json_extract as 1/0.
const param = (v) => (typeof v === 'boolean' ? Number(v) : v);

function createSqliteStore({ file }) {
  if (file !== ':memory:') fs.mkdirSync(path.dirname(file), { recursive: true });
  const db = new DatabaseSync(file);
  db.exec('PRAGMA journal_mode = WAL; PRAGMA synchronous = NORMAL; PRAGMA busy_timeout = 5000;');

  const known = new Set();
  const table = (collection) => {
    const name = checkName(collection, IDENT, 'collection');
    if (!known.has(name)) {
      db.exec(`CREATE TABLE IF NOT EXISTS "${name}" (id TEXT PRIMARY KEY, data TEXT NOT NULL)`);
      known.add(name);
    }
    return `"${name}"`;
  };
  const row = (r) => (r ? { id: r.id, ...JSON.parse(r.data) } : null);
  const json = (v) => JSON.stringify(v);

  // Synchronous primitives; the async store methods and transaction commits share them.
  const getSync = (c, id) => row(db.prepare(`SELECT id, data FROM ${table(c)} WHERE id = ?`).get(id));
  const setSync = (c, id, value) =>
    db.prepare(`INSERT INTO ${table(c)} (id, data) VALUES (?, ?) ON CONFLICT(id) DO UPDATE SET data = excluded.data`)
      .run(id, json(value));
  const createSync = (c, id, value) => {
    const res = db.prepare(`INSERT OR IGNORE INTO ${table(c)} (id, data) VALUES (?, ?)`).run(id, json(value));
    if (res.changes === 0) throw Object.assign(new Error('Document exists'), { code: 'ALREADY_EXISTS' });
  };
  const updateSync = (c, id, partial) => {
    const existing = getSync(c, id);
    if (!existing) throw new Error(`No document ${c}/${id}`);
    const { id: _id, ...doc } = existing;
    db.prepare(`UPDATE ${table(c)} SET data = ? WHERE id = ?`).run(json({ ...doc, ...partial }), id);
  };

  // Transactions run one at a time, like the memory store. Reads go straight to the database;
  // writes are collected and applied together inside BEGIN/COMMIT, so they all land or none do.
  let lock = Promise.resolve();

  const store = {
    driver: 'sqlite',
    file,
    newId: () => crypto.randomUUID(),

    async get(collection, id) {
      return getSync(collection, id);
    },
    async set(collection, id, value) {
      setSync(collection, id, value);
    },
    async create(collection, id, value) {
      createSync(collection, id, value);
    },
    async update(collection, id, partial) {
      updateSync(collection, id, partial);
    },
    async query(collection, { where = [], orderBy, limit } = {}) {
      const t = table(collection);
      const col = (f) => (f === 'id' ? 'id' : `json_extract(data, '$.${checkName(f, FIELD, 'field')}')`);
      const clauses = [];
      const params = [];
      for (const [field, op, value] of where) {
        if (!OPS.has(op)) throw new Error(`Unsupported operator ${op}`);
        if (op === 'in') {
          if (!Array.isArray(value) || !value.length) return [];
          clauses.push(`${col(field)} IN (${value.map(() => '?').join(', ')})`);
          params.push(...value.map(param));
        } else {
          clauses.push(`${col(field)} ${op === '==' ? '=' : op} ?`);
          params.push(param(value));
        }
      }
      let sql = `SELECT id, data FROM ${t}`;
      if (clauses.length) sql += ` WHERE ${clauses.join(' AND ')}`;
      if (orderBy) sql += ` ORDER BY ${col(orderBy[0])} ${orderBy[1] === 'desc' ? 'DESC' : 'ASC'}`;
      if (limit) {
        sql += ' LIMIT ?';
        params.push(limit);
      }
      return db.prepare(sql).all(...params).map(row);
    },
    async runTransaction(fn) {
      const run = lock.then(async () => {
        const writes = [];
        const tx = {
          get: async (c, id) => getSync(c, id),
          set: (c, id, v) => writes.push(() => setSync(c, id, v)),
          create: (c, id, v) => writes.push(() => createSync(c, id, v)),
          update: (c, id, v) => writes.push(() => updateSync(c, id, v)),
        };
        const result = await fn(tx);
        db.exec('BEGIN IMMEDIATE');
        try {
          for (const w of writes) w();
          db.exec('COMMIT');
        } catch (err) {
          db.exec('ROLLBACK');
          throw err;
        }
        return result;
      });
      lock = run.catch(() => {});
      return run;
    },
    async isEmpty() {
      return (await store.query('agents', { limit: 1 })).length === 0;
    },
    close() {
      db.close();
    },
  };
  return store;
}

module.exports = { createSqliteStore };
