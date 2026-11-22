// Occupation master data (code + name) from reference-data/occupations.csv, stored in the
// `occupations` collection with the code as the document ID.
const fs = require('fs');
const path = require('path');
const { getStore } = require('../db');
const { AppError } = require('../utils/helpers');

const FILE = path.resolve(__dirname, '../../reference-data/occupations.csv');

// Splits one CSV line, honouring double-quoted fields that contain commas.
function splitCsv(line) {
  const out = [];
  let cur = '';
  let quoted = false;
  for (let i = 0; i < line.length; i++) {
    const ch = line[i];
    if (ch === '"' && quoted && line[i + 1] === '"') { cur += '"'; i++; } else if (ch === '"') quoted = !quoted;
    else if (ch === ',' && !quoted) { out.push(cur); cur = ''; } else cur += ch;
  }
  out.push(cur);
  return out.map((s) => s.trim());
}

function readSource() {
  const rows = fs.readFileSync(FILE, 'utf8').trim().split(/\r?\n/).slice(1).map(splitCsv);
  const seen = new Set();
  return rows.map(([code, name], i) => {
    if (!code || !name) throw new Error(`occupations.csv line ${i + 2} needs a code and a name`);
    const id = code.toUpperCase();
    if (seen.has(id)) throw new Error(`occupations.csv has the code ${id} twice`);
    seen.add(id);
    // `order` keeps the file's order (common choices first) for the dropdown.
    return { id, name, order: i + 1, active: true };
  });
}

async function importOccupations(store = getStore()) {
  const list = readSource();
  await Promise.all(list.map(({ id, ...doc }) => store.set('occupations', id, doc)));
  cache.delete(store);
  return list.length;
}

const cache = new WeakMap();

async function getOccupations() {
  const store = getStore();
  if (!cache.has(store)) {
    const load = store.query('occupations').then((rows) => rows
      .filter((o) => o.active !== false)
      .sort((a, b) => a.order - b.order)
      .map(({ id, name }) => ({ code: id, name })));
    cache.set(store, load);
    load.then((l) => { if (!l.length) cache.delete(store); }, () => cache.delete(store));
  }
  return cache.get(store);
}

// Returns { occupationCode, occupation } for a code, or for an exact name (older app versions).
async function resolveOccupation(code, name) {
  const list = await getOccupations();
  if (!list.length) return { occupation: name, ...(code ? { occupationCode: code } : {}) };
  const norm = (s) => String(s || '').trim().toLowerCase();
  const found = list.find((o) => code && o.code === String(code).toUpperCase())
    || list.find((o) => !code && norm(o.name) === norm(name));
  if (!found) {
    const field = code ? 'occupationCode' : 'occupation';
    throw new AppError(400, 'VALIDATION_ERROR', `${field}: Choose an occupation from the list`, { fields: [{ field, message: 'Choose an occupation from the list' }] });
  }
  return { occupationCode: found.code, occupation: found.name };
}

module.exports = { importOccupations, getOccupations, resolveOccupation, readSource };
