// Nepal's provinces, districts and local bodies (municipalities / rural municipalities).
// Source files live in reference-data/; importLocations() cleans them and writes three
// collections: provinces, districts, localBodies. The app loads them for its address dropdowns
// and onboarding checks every address against them.
const fs = require('fs');
const path = require('path');
const { getStore } = require('../db');
const { AppError } = require('../utils/helpers');

const DATA_DIR = path.resolve(__dirname, '../../reference-data');

const PROVINCES = [
  { id: '1', name: 'Koshi', nameNe: 'कोशी' },
  { id: '2', name: 'Madhesh', nameNe: 'मधेश' },
  { id: '3', name: 'Bagmati', nameNe: 'बागमती' },
  { id: '4', name: 'Gandaki', nameNe: 'गण्डकी' },
  { id: '5', name: 'Lumbini', nameNe: 'लुम्बिनी' },
  { id: '6', name: 'Karnali', nameNe: 'कर्णाली' },
  { id: '7', name: 'Sudurpashchim', nameNe: 'सुदूरपश्चिम' },
];

// Districts whose names in the source file are ambiguous in a dropdown.
const DISTRICT_FIXES = {
  46: { name: 'Nawalparasi (Bardaghat Susta East)', nameNe: 'नवलपरासी (बर्दघाट सुस्ता पूर्व)' },
  58: { name: 'Nawalparasi (Bardaghat Susta West)', nameNe: 'नवलपरासी (बर्दघाट सुस्ता पश्चिम)' },
  57: { nameNe: 'रुकुम (पूर्व)' },
  67: { name: 'Western Rukum', nameNe: 'रुकुम (पश्चिम)' },
};

// The source file has 758 rows; Nepal has 753 local levels. These rows are duplicates:
// three Eastern Rukum bodies repeated under Western Rukum, and two old names listed next to
// their renamed successors (the new name keeps the old CBS code).
const DROP_LOCAL_BODIES = new Set(['647', '648', '649']);
const RENAMED = { 1754: '100', 759: '131' }; // new id -> old id it replaces

const LOCAL_BODY_TYPES = [
  ['Sub-Metropolitan City', 'sub_metropolitan'],
  ['Metropolitan City', 'metropolitan'],
  ['Rural Municipality', 'rural_municipality'],
  ['Municipality', 'municipality'],
];

const clean = (s) => String(s).replace(/\s+/g, ' ').trim();

function readSource() {
  const districtLines = fs.readFileSync(path.join(DATA_DIR, 'districts.csv'), 'utf8').trim().split(/\r?\n/).slice(1);
  const districts = districtLines.map((line) => {
    const m = line.match(/^(\d+),([^,]+),([^,]+),(\d+),"?(\d+)"?$/);
    if (!m) throw new Error(`Cannot read district line: ${line}`);
    const id = m[1];
    return {
      id, name: clean(m[2]), nameNe: clean(m[3]), provinceId: m[4], cbsCode: m[5], ...DISTRICT_FIXES[id],
    };
  });

  const rows = fs.readFileSync(path.join(DATA_DIR, 'local_bodies.tsv'), 'utf8').trim().split(/\r?\n/).slice(1)
    .map((line) => {
      const [id, name, nameNe, districtId, code] = line.split('\t');
      return {
        id: id.replace(/,/g, ''), name: clean(name), nameNe: clean(nameNe), districtId: clean(districtId),
        cbsCode: code && clean(code) !== '[NULL]' ? clean(code) : null,
      };
    });
  const byId = new Map(rows.map((r) => [r.id, r]));
  const replaced = new Set(Object.values(RENAMED));
  const localBodies = rows
    .filter((r) => !DROP_LOCAL_BODIES.has(r.id) && !replaced.has(r.id))
    .map((r) => {
      const name = r.name.replace(/ Gaunpalika$/, ' Rural Municipality');
      const type = LOCAL_BODY_TYPES.find(([suffix]) => name.endsWith(suffix))?.[1] || 'municipality';
      const cbsCode = r.cbsCode || byId.get(RENAMED[r.id])?.cbsCode || null;
      return { ...r, name, type, cbsCode };
    });
  return { provinces: PROVINCES, districts, localBodies };
}

// Writes the location collections into the given store, replacing earlier imports.
async function importLocations(store = getStore()) {
  const { provinces, districts, localBodies } = readSource();
  const write = async (collection, docs) => {
    for (let i = 0; i < docs.length; i += 50) {
      await Promise.all(docs.slice(i, i + 50).map(({ id, ...doc }) => store.set(collection, id, doc)));
    }
  };
  await write('provinces', provinces);
  await write('districts', districts);
  await write('localBodies', localBodies);
  cache.delete(store);
  return { provinces: provinces.length, districts: districts.length, localBodies: localBodies.length };
}

// The lists change only when re-imported, so each store's copy is kept in memory.
const cache = new WeakMap();
const byName = (a, b) => a.name.localeCompare(b.name);

async function getLocations() {
  const store = getStore();
  if (!cache.has(store)) {
    const load = (async () => {
      const [provinces, districts, localBodies] = await Promise.all(
        ['provinces', 'districts', 'localBodies'].map((c) => store.query(c)),
      );
      return {
        provinces: provinces.sort((a, b) => Number(a.id) - Number(b.id)),
        districts: districts.sort(byName),
        localBodies: localBodies.sort(byName).map(({ id, name, nameNe, districtId, type }) => ({ id, name, nameNe, districtId, type })),
      };
    })();
    cache.set(store, load);
    // Do not keep a failed or empty load: the lists may be imported while the server runs.
    load.then((l) => { if (!l.localBodies.length) cache.delete(store); }, () => cache.delete(store));
  }
  return cache.get(store);
}

const same = (a, b) => clean(a).toLowerCase() === clean(b).toLowerCase();
const fieldError = (field, message) => new AppError(400, 'VALIDATION_ERROR', `${field}: ${message}`, { fields: [{ field, message }] });

let warnedEmpty = false;

// Checks that province, district and municipality exist and belong together, and that the
// citizenship issue district exists. Returns the canonical names plus their IDs.
async function resolveAddress(address, issueDistrict) {
  const { provinces, districts, localBodies } = await getLocations();
  if (!localBodies.length) {
    if (!warnedEmpty) {
      warnedEmpty = true;
      console.warn('No location data in the database, so addresses are not checked. Run: npm run import:locations');
    }
    return { address, issueDistrict };
  }
  const province = provinces.find((p) => same(p.name, address.province));
  if (!province) throw fieldError('address.province', 'Choose a province from the list');
  const district = districts.find((d) => d.provinceId === province.id && same(d.name, address.district));
  if (!district) throw fieldError('address.district', `Choose a district in ${province.name} Province`);
  const body = localBodies.find((l) => l.districtId === district.id && same(l.name, address.municipality));
  if (!body) throw fieldError('address.municipality', `Choose a municipality in ${district.name} district`);
  const issue = districts.find((d) => same(d.name, issueDistrict));
  if (!issue) throw fieldError('citizenshipIssueDistrict', 'Choose the issue district from the list');
  return {
    address: {
      ...address, province: province.name, district: district.name, municipality: body.name, districtId: district.id, localBodyId: body.id,
    },
    issueDistrict: issue.name,
  };
}

module.exports = { importLocations, getLocations, resolveAddress, readSource };
