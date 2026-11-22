// Fictional demo data. Every person, account and amount here is illustrative.
const bcrypt = require('bcryptjs');
const { nowIso, startOfNepalDay } = require('./utils/helpers');
const { importLocations } = require('./services/locationService');

const P = (rupees) => rupees * 100;
const DEMO_BANK = 'Himalaya Partner Bank (fictional)';

async function seed(store, { log = false } = {}) {
  const pinHash = await bcrypt.hash('123456', 10);

  const agents = [
    {
      id: 'AGT-98412', name: 'Sita Sharma', role: 'agent', location: 'Koteshwor Point, Ward 32, Kathmandu',
      terminalId: 'KTM-WARD-32', supervisorId: 'SUP-001',
    },
    {
      id: 'AGT-77020', name: 'Ramesh Adhikari', role: 'agent', location: 'Dhulikhel Bazaar, Kavrepalanchok',
      terminalId: 'KAV-DHU-01', supervisorId: 'SUP-001',
    },
  ];
  for (const a of agents) {
    await store.set('agents', a.id, {
      ...a,
      partnerBank: DEMO_BANK,
      pinHash,
      status: 'active',
      failedPinAttempts: 0,
      float: { cash: P(42500), opening: P(42500), limit: P(100000), minReserve: P(10000) },
      floatDate: startOfNepalDay(),
      createdAt: nowIso(),
    });
  }
  await store.set('agents', 'SUP-001', {
    name: 'Pratima Karki', role: 'supervisor', location: 'District Branch, Kathmandu', partnerBank: DEMO_BANK,
    pinHash, status: 'active', failedPinAttempts: 0, createdAt: nowIso(),
  });

  const customers = [
    ['CUST-884102', 'Hari', 'Bahadur', 'Thapa', '9851012347', '27-01-78-04912', '010201750004092', 25000, 'male'],
    ['CUST-884103', 'Sunita', null, 'Tamang', '9841234567', '27-02-70-11873', '010201750004311', 8200, 'female'],
    ['CUST-884104', 'Bikash', null, 'Shrestha', '9803456789', '25-03-75-22019', '010201750004587', 61000, 'male'],
    ['CUST-884105', 'Maya', 'Kumari', 'Gurung', '9812345670', '41-01-80-03321', '010201750004722', 1500, 'female'],
  ];
  for (const [id, first, middle, last, mobile, cit, acc, bal, gender] of customers) {
    const c = {
      firstName: first, middleName: middle || undefined, lastName: last,
      nameLower: [first, middle, last].filter(Boolean).join(' ').toLowerCase(),
      gender, mobile, citizenshipNo: cit, occupation: 'Agriculture / Farmer',
      address: {
        province: 'Bagmati', district: 'Kavreplanchowk', municipality: 'Dhulikhel Municipality', ward: 4, districtId: '26', localBodyId: '313',
      },
      kycStatus: 'verified', createdByAgent: 'AGT-98412', createdAt: nowIso(),
    };
    Object.keys(c).forEach((k) => c[k] === undefined && delete c[k]);
    await store.set('customers', id, c);
    await store.set('accounts', acc, {
      customerId: id, productName: 'Bachat Khata (Savings)', type: 'savings', balance: P(bal), status: 'active', openedAt: nowIso(),
    });
  }
  const places = await importLocations(store);
  if (log) {
    console.log('Seeded 2 agents (PIN 123456), 1 supervisor SUP-001 (PIN 123456), 4 customers.');
    console.log(`Loaded ${places.districts} districts and ${places.localBodies} municipalities.`);
  }
}

module.exports = { seed, DEMO_BANK };
