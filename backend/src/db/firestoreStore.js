// Cloud Firestore implementation of the document store, via the Firebase Admin SDK.
// The Admin SDK bypasses Firestore security rules, so all access control is enforced
// by this API; firestore.rules denies every direct client request.
const { initializeApp, cert, applicationDefault, getApps } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const fs = require('fs');
const { matches } = require('./memoryStore');

const FAILED_PRECONDITION = 9; // gRPC status Firestore uses for "this query requires an index"

function createFirestoreStore({ projectId, credentialsPath }) {
  if (!getApps().length) {
    const credential = credentialsPath
      ? cert(JSON.parse(fs.readFileSync(credentialsPath, 'utf8')))
      : applicationDefault();
    initializeApp({ credential, projectId });
  }
  const db = getFirestore();
  db.settings({ ignoreUndefinedProperties: true });

  const snap = (s) => (s.exists ? { id: s.id, ...s.data() } : null);

  // A query that combines filters with a range or sort needs a composite index. While one is
  // missing (not created yet, or still building), run only the equality filters, which Firestore
  // can always serve, and apply the rest here. Fine for this app's per-agent result sizes.
  const warned = new Set();
  async function queryWithoutIndex(collection, { where, orderBy, limit }, err) {
    const link = /https:\/\/\S+/.exec(err.details || err.message || '')?.[0];
    if (!warned.has(link)) {
      warned.add(link);
      console.warn(`Firestore index missing for "${collection}"; filtering in the API instead.`
        + (link ? ` Create the index here to speed this up: ${link}` : ''));
    }
    const equality = where.filter(([, op]) => op === '==');
    if (!equality.length) throw err; // nothing narrow enough to fall back to
    let q = db.collection(collection);
    for (const [field, op, value] of equality) q = q.where(field, op, value);
    let docs = (await q.get()).docs.map((d) => ({ id: d.id, ...d.data() }));
    docs = docs.filter((d) => where.every((w) => matches(d, w)));
    if (orderBy) {
      const [field, dir = 'asc'] = orderBy;
      docs.sort((a, b) => (a[field] < b[field] ? -1 : a[field] > b[field] ? 1 : 0) * (dir === 'desc' ? -1 : 1));
    }
    return limit ? docs.slice(0, limit) : docs;
  }

  return {
    driver: 'firestore',
    newId: () => db.collection('_ids').doc().id,

    async get(collection, id) {
      return snap(await db.collection(collection).doc(id).get());
    },
    async set(collection, id, value) {
      await db.collection(collection).doc(id).set(value);
    },
    async create(collection, id, value) {
      await db.collection(collection).doc(id).create(value);
    },
    async update(collection, id, partial) {
      await db.collection(collection).doc(id).update(partial);
    },
    async query(collection, { where = [], orderBy, limit } = {}) {
      let q = db.collection(collection);
      for (const [field, op, value] of where) q = q.where(field, op, value);
      if (orderBy) q = q.orderBy(orderBy[0], orderBy[1] || 'asc');
      if (limit) q = q.limit(limit);
      try {
        const res = await q.get();
        return res.docs.map((d) => ({ id: d.id, ...d.data() }));
      } catch (err) {
        if (err.code !== FAILED_PRECONDITION) throw err;
        return queryWithoutIndex(collection, { where, orderBy, limit }, err);
      }
    },
    // Firestore transactions require every read to happen before any write.
    async runTransaction(fn) {
      return db.runTransaction(async (t) => {
        const ref = (c, id) => db.collection(c).doc(id);
        const tx = {
          get: async (c, id) => snap(await t.get(ref(c, id))),
          set: (c, id, v) => t.set(ref(c, id), v),
          create: (c, id, v) => t.create(ref(c, id), v),
          update: (c, id, v) => t.update(ref(c, id), v),
        };
        return fn(tx);
      });
    },
  };
}

module.exports = { createFirestoreStore };
