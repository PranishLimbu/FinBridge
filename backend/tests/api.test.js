process.env.NODE_ENV = 'test';
const request = require('supertest');
const { createMemoryStore } = require('../src/db/memoryStore');
const { setStore } = require('../src/db');
const { seed } = require('../src/seed');
const { createApp } = require('../src/app');
const { amountInWords, formatNpr } = require('../src/utils/money');

let app;
let store;

const login = async (agentId = 'AGT-98412', pin = '123456') => {
  const res = await request(app).post('/api/auth/login').send({ agentId, pin });
  return res.body.token;
};
const auth = (t) => ({ Authorization: `Bearer ${t}` });
let keyN = 0;
const key = () => `test-key-${++keyN}-${Date.now()}`;
const HARI = { customerId: 'CUST-884102', accountNo: '010201750004092' };

// TEST_DB=sqlite runs the same tests against a fresh in-memory SQLite database.
const newStore = () => (process.env.TEST_DB === 'sqlite'
  ? require('../src/db/sqliteStore').createSqliteStore({ file: ':memory:' })
  : createMemoryStore());

beforeEach(async () => {
  store = newStore();
  setStore(store);
  await seed(store);
  app = createApp();
});

describe('money helpers', () => {
  test('amount in words uses lakh and crore', () => {
    expect(amountInWords(500000)).toBe('Five Thousand Nepalese Rupees Only');
    expect(amountInWords(12345678)).toBe('One Lakh Twenty Three Thousand Four Hundred Fifty Six Nepalese Rupees and Seventy Eight Paisa Only');
  });
  test('NPR formatting uses Nepali grouping', () => {
    expect(formatNpr(10000000)).toBe('Rs. 1,00,000.00');
  });
});

describe('UC1 login', () => {
  test('valid credentials return a token; IDs are case-insensitive', async () => {
    const res = await request(app).post('/api/auth/login').send({ agentId: 'agt-98412', pin: '123456' });
    expect(res.status).toBe(200);
    expect(res.body.agent.name).toBe('Sita Sharma');
    expect(res.body.agent.pinHash).toBeUndefined();
  });
  test('wrong PIN reports attempts left, and 5 failures lock the account', async () => {
    for (let i = 1; i <= 4; i++) {
      const r = await request(app).post('/api/auth/login').send({ agentId: 'AGT-98412', pin: '000000' });
      expect(r.status).toBe(401);
      expect(r.body.error.details.attemptsRemaining).toBe(5 - i);
    }
    const locked = await request(app).post('/api/auth/login').send({ agentId: 'AGT-98412', pin: '000000' });
    expect(locked.status).toBe(423);
    const correctButLocked = await request(app).post('/api/auth/login').send({ agentId: 'AGT-98412', pin: '123456' });
    expect(correctButLocked.status).toBe(423);
    // supervisor unlocks
    const sup = await login('SUP-001');
    expect((await request(app).post('/api/supervisor/agents/AGT-98412/unlock').set(auth(sup))).status).toBe(200);
    expect((await request(app).post('/api/auth/login').send({ agentId: 'AGT-98412', pin: '123456' })).status).toBe(200);
  });
  test('unknown agent gives the same message as a wrong PIN', async () => {
    const r = await request(app).post('/api/auth/login').send({ agentId: 'AGT-00000', pin: '123456' });
    expect(r.status).toBe(401);
    expect(r.body.error.message).toBe('Agent ID or PIN is incorrect');
  });
  test('protected routes need a token', async () => {
    expect((await request(app).get('/api/dashboard')).status).toBe(401);
  });
});

describe('UC2 customer lookup', () => {
  test('finds by mobile, account number and name, with masked details', async () => {
    const t = await login();
    for (const q of ['9851012347', '010201750004092', 'hari']) {
      const r = await request(app).get('/api/customers').query({ q }).set(auth(t));
      expect(r.body.results[0].customerId).toBe('CUST-884102');
      expect(r.body.results[0].mobileMasked).toBe('98510****7');
    }
  });
});

describe('UC4 deposit', () => {
  test('credits account, raises float and records the transaction', async () => {
    const t = await login();
    const r = await request(app).post('/api/transactions/deposits').set(auth(t)).send({ ...HARI, amount: 5000, idempotencyKey: key() });
    expect(r.status).toBe(201);
    expect(r.body.status).toBe('confirmed');
    expect(r.body.amountInWords).toBe('Five Thousand Nepalese Rupees Only');
    expect((await store.get('accounts', HARI.accountNo)).balance).toBe(30000 * 100);
    expect((await store.get('agents', 'AGT-98412')).float.cash).toBe(47500 * 100);
    const sms = await store.query('smsOutbox', {});
    expect(sms.some((m) => m.kind === 'deposit_receipt')).toBe(true);
  });
  test('same idempotency key never creates a second transaction', async () => {
    const t = await login();
    const body = { ...HARI, amount: 1000, idempotencyKey: key() };
    const a = await request(app).post('/api/transactions/deposits').set(auth(t)).send(body);
    const b = await request(app).post('/api/transactions/deposits').set(auth(t)).send(body);
    expect(b.status).toBe(200);
    expect(b.body.replayed).toBe(true);
    expect(b.body.id).toBe(a.body.id);
    expect((await store.get('accounts', HARI.accountNo)).balance).toBe(26000 * 100);
  });
  test('rejects amounts outside the Rs 100 – 25,000 limits', async () => {
    const t = await login();
    for (const amount of [50, 30000]) {
      const r = await request(app).post('/api/transactions/deposits').set(auth(t)).send({ ...HARI, amount, idempotencyKey: key() });
      expect(r.body.error.code).toBe('AMOUNT_OUT_OF_RANGE');
    }
  });
  test('blocks a deposit that would exceed the float limit', async () => {
    const t = await login();
    await store.update('agents', 'AGT-98412', { float: { cash: 90000 * 100, opening: 90000 * 100, limit: 100000 * 100, minReserve: 10000 * 100 } });
    const r = await request(app).post('/api/transactions/deposits').set(auth(t)).send({ ...HARI, amount: 15000, idempotencyKey: key() });
    expect(r.body.error.code).toBe('FLOAT_LIMIT_EXCEEDED');
  });
  test('rejects an account that belongs to another customer', async () => {
    const t = await login();
    const r = await request(app).post('/api/transactions/deposits').set(auth(t))
      .send({ customerId: 'CUST-884103', accountNo: HARI.accountNo, amount: 500, idempotencyKey: key() });
    expect(r.body.error.code).toBe('ACCOUNT_NOT_FOUND');
  });
});

describe('UC5 withdrawal with OTP', () => {
  const start = async (t, amount = 2000) => request(app).post('/api/transactions/withdrawals').set(auth(t)).send({ ...HARI, amount, idempotencyKey: key() });

  test('nothing moves until the correct OTP is entered', async () => {
    const t = await login();
    const s = await start(t);
    expect(s.body.transaction.status).toBe('awaiting_otp');
    expect((await store.get('accounts', HARI.accountNo)).balance).toBe(25000 * 100);
    const c = await request(app).post(`/api/transactions/${s.body.transaction.id}/confirm-otp`).set(auth(t)).send({ otp: s.body.devOtp });
    expect(c.body.status).toBe('confirmed');
    expect((await store.get('accounts', HARI.accountNo)).balance).toBe((25000 - 2010) * 100);
    expect((await store.get('agents', 'AGT-98412')).float.cash).toBe((42500 - 2000) * 100);
  });
  test('three wrong OTPs cancel the withdrawal', async () => {
    const t = await login();
    const s = await start(t);
    const wrong = s.body.devOtp === '000000' ? '111111' : '000000';
    const id = s.body.transaction.id;
    const r1 = await request(app).post(`/api/transactions/${id}/confirm-otp`).set(auth(t)).send({ otp: wrong });
    expect(r1.body.error.details.attemptsRemaining).toBe(2);
    await request(app).post(`/api/transactions/${id}/confirm-otp`).set(auth(t)).send({ otp: wrong });
    const r3 = await request(app).post(`/api/transactions/${id}/confirm-otp`).set(auth(t)).send({ otp: wrong });
    expect(r3.body.error.code).toBe('OTP_ATTEMPTS_EXCEEDED');
    const late = await request(app).post(`/api/transactions/${id}/confirm-otp`).set(auth(t)).send({ otp: s.body.devOtp });
    expect(late.body.error.code).toBe('NOT_AWAITING_OTP');
    expect((await store.get('accounts', HARI.accountNo)).balance).toBe(25000 * 100);
  });
  test('expired OTP cancels the withdrawal', async () => {
    const t = await login();
    const s = await start(t);
    const id = s.body.transaction.id;
    const doc = await store.get('transactions', id);
    await store.update('transactions', id, { otp: { ...doc.otp, expiresAt: new Date(Date.now() - 1000).toISOString() } });
    const r = await request(app).post(`/api/transactions/${id}/confirm-otp`).set(auth(t)).send({ otp: s.body.devOtp });
    expect(r.body.error.code).toBe('OTP_EXPIRED');
  });
  test('insufficient balance and insufficient float are blocked', async () => {
    const t = await login();
    const poor = await request(app).post('/api/transactions/withdrawals').set(auth(t))
      .send({ customerId: 'CUST-884105', accountNo: '010201750004722', amount: 1500, idempotencyKey: key() });
    expect(poor.body.error.code).toBe('INSUFFICIENT_BALANCE');
    await store.update('agents', 'AGT-98412', { float: { cash: 11000 * 100, opening: 11000 * 100, limit: 100000 * 100, minReserve: 10000 * 100 } });
    const lowFloat = await start(t, 2000);
    expect(lowFloat.body.error.code).toBe('INSUFFICIENT_FLOAT');
  });
  test('another agent cannot confirm someone else’s withdrawal', async () => {
    const t = await login();
    const s = await start(t);
    const other = await login('AGT-77020');
    const r = await request(app).post(`/api/transactions/${s.body.transaction.id}/confirm-otp`).set(auth(other)).send({ otp: s.body.devOtp });
    expect(r.status).toBe(404);
  });
});

describe('UC3 onboarding and KYC review', () => {
  const application = {
    firstName: 'Kamala', lastName: 'Rai', gender: 'female', maritalStatus: 'married',
    dobBs: '2045-02-10', dobAd: '1988-05-23', occupation: 'Teacher', mobile: '9861112233',
    citizenshipNo: '12-03-79-55120', citizenshipIssueDateBs: '2063-04-01', citizenshipIssueDistrict: 'Sindhupanchowk',
    family: { fatherName: 'Dil Bahadur Rai', motherName: 'Sita Rai', grandfatherName: 'Man Bahadur Rai' },
    address: { province: 'Bagmati', district: 'Sindhupanchowk', municipality: 'Melanchi Municipality', ward: 5 },
    documents: { citizenshipFront: true, citizenshipBack: true, photo: true },
    consent: true,
  };
  test('creates a pending customer; deposits wait for supervisor approval', async () => {
    const t = await login();
    const r = await request(app).post('/api/customers').set(auth(t)).send(application);
    expect(r.status).toBe(201);
    expect(r.body.kycStatus).toBe('pending_review');
    const dep = await request(app).post('/api/transactions/deposits').set(auth(t))
      .send({ customerId: r.body.customerId, accountNo: r.body.accountNo, amount: 500, idempotencyKey: key() });
    expect(dep.body.error.code).toBe('ACCOUNT_PENDING');

    const sup = await login('SUP-001');
    const approve = await request(app).post(`/api/supervisor/customers/${r.body.customerId}/kyc`).set(auth(sup)).send({ decision: 'approve' });
    expect(approve.status).toBe(200);
    const dep2 = await request(app).post('/api/transactions/deposits').set(auth(t))
      .send({ customerId: r.body.customerId, accountNo: r.body.accountNo, amount: 500, idempotencyKey: key() });
    expect(dep2.status).toBe(201);
  });
  test('rejects duplicates, minors and missing documents', async () => {
    const t = await login();
    const dup = await request(app).post('/api/customers').set(auth(t)).send({ ...application, citizenshipNo: '27-01-78-04912' });
    expect(dup.body.error.code).toBe('DUPLICATE_CITIZENSHIP');
    const minor = await request(app).post('/api/customers').set(auth(t)).send({ ...application, dobAd: '2015-01-01' });
    expect(minor.body.error.code).toBe('VALIDATION_ERROR');
    const noDocs = await request(app).post('/api/customers').set(auth(t)).send({ ...application, documents: { citizenshipFront: true, citizenshipBack: false, photo: true } });
    expect(noDocs.body.error.code).toBe('VALIDATION_ERROR');
  });
  test('serves the location lists: 7 provinces, 77 districts, 753 municipalities', async () => {
    const t = await login();
    const r = await request(app).get('/api/locations').set(auth(t));
    expect(r.status).toBe(200);
    expect(r.body.provinces).toHaveLength(7);
    expect(r.body.districts).toHaveLength(77);
    expect(r.body.localBodies).toHaveLength(753);
    const ktm = r.body.districts.find((d) => d.name === 'Kathmandu');
    expect(r.body.localBodies.filter((l) => l.districtId === ktm.id)).toHaveLength(11);
    // Renamed bodies replace their old names; duplicates are gone.
    expect(r.body.localBodies.some((l) => l.name === 'Pathibhara Yangwarak Rural Municipality')).toBe(true);
    expect(r.body.localBodies.some((l) => l.name === 'Yangwarak Rural Municipality')).toBe(false);
  });
  test('rejects addresses that are not in the location list or do not belong together', async () => {
    const t = await login();
    const post = (patch) => request(app).post('/api/customers').set(auth(t)).send({ ...application, ...patch });
    const wrongDistrict = await post({ address: { ...application.address, district: 'Kaski' } });
    expect(wrongDistrict.body.error.details.fields[0].field).toBe('address.district');
    const wrongTown = await post({ address: { ...application.address, municipality: 'Pokhara Metropolitan City' } });
    expect(wrongTown.body.error.details.fields[0].field).toBe('address.municipality');
    const badIssue = await post({ citizenshipIssueDistrict: 'Atlantis' });
    expect(badIssue.body.error.details.fields[0].field).toBe('citizenshipIssueDistrict');
    // Case and spacing do not matter; the stored address uses the official spelling and IDs.
    const ok = await post({ address: { ...application.address, municipality: '  melanchi   municipality ' } });
    expect(ok.status).toBe(201);
    const c = await request(app).get(`/api/customers/${ok.body.customerId}`).set(auth(t));
    expect(c.body.address).toMatchObject({ municipality: 'Melanchi Municipality', districtId: '30', localBodyId: '347' });
  });
  test('agents cannot use supervisor endpoints', async () => {
    const t = await login();
    expect((await request(app).get('/api/supervisor/overview').set(auth(t))).status).toBe(403);
  });
});

describe('UC6 history, receipts, disputes and UC7 end of day', () => {
  test('history filters and receipt resend', async () => {
    const t = await login();
    const d = await request(app).post('/api/transactions/deposits').set(auth(t)).send({ ...HARI, amount: 700, idempotencyKey: key() });
    const list = await request(app).get('/api/transactions').query({ type: 'deposit' }).set(auth(t));
    expect(list.body.results).toHaveLength(1);
    expect((await request(app).get(`/api/transactions/${d.body.id}`).set(auth(t))).body.reference).toBe(d.body.reference);
    expect((await request(app).post(`/api/transactions/${d.body.id}/receipt/sms`).set(auth(t))).status).toBe(200);
    const dispute = await request(app).post(`/api/transactions/${d.body.id}/disputes`).set(auth(t)).send({ reason: 'Customer says only Rs 600 was handed over' });
    expect(dispute.status).toBe(201);
  });
  test('EOD reports balanced and mismatched counts, once per day', async () => {
    const t = await login();
    await request(app).post('/api/transactions/deposits').set(auth(t)).send({ ...HARI, amount: 1000, idempotencyKey: key() });
    const preview = await request(app).get('/api/eod/preview').set(auth(t));
    expect(preview.body.expectedCash).toBe(43500);
    const r = await request(app).post('/api/eod').set(auth(t)).send({ countedCash: 43000 });
    expect(r.body.status).toBe('mismatch');
    expect(r.body.difference).toBe(-500);
    const again = await request(app).post('/api/eod').set(auth(t)).send({ countedCash: 43500 });
    expect(again.body.error.code).toBe('EOD_ALREADY_SUBMITTED');
    const sup = await login('SUP-001');
    const ov = await request(app).get('/api/supervisor/overview').set(auth(sup));
    expect(ov.body.eodMismatches).toHaveLength(1);
  });
  test('every money movement is in the audit log', async () => {
    const t = await login();
    await request(app).post('/api/transactions/deposits').set(auth(t)).send({ ...HARI, amount: 1000, idempotencyKey: key() });
    const logs = await store.query('auditLogs', {});
    expect(logs.map((l) => l.action)).toEqual(expect.arrayContaining(['LOGIN_SUCCESS', 'DEPOSIT_CONFIRMED']));
  });
});
