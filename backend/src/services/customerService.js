const crypto = require('crypto');
const { getStore } = require('../db');
const { AppError, nowIso, maskAccount, maskMobile, maskCitizenship } = require('../utils/helpers');
const { paisaToRupees } = require('../utils/money');
const { audit, auditInTx } = require('./auditService');
const { resolveAddress } = require('./locationService');
const { resolveOccupation } = require('./occupationService');

const fullName = (c) => [c.firstName, c.middleName, c.lastName].filter(Boolean).join(' ');

function summary(c, accounts = []) {
  return {
    customerId: c.id,
    name: fullName(c),
    mobileMasked: maskMobile(c.mobile),
    citizenshipMasked: maskCitizenship(c.citizenshipNo),
    kycStatus: c.kycStatus,
    photoUrl: c.photoUrl || null,
    accounts: accounts.map((a) => ({
      accountNo: a.id,
      accountMasked: maskAccount(a.id),
      productName: a.productName,
      status: a.status,
    })),
  };
}

async function accountsFor(customerId) {
  return getStore().query('accounts', { where: [['customerId', '==', customerId]] });
}

// Search by exact mobile number, account number or citizenship number, or by name prefix.
async function search(q) {
  const store = getStore();
  const term = q.trim();
  const found = new Map();
  const add = (list) => list.forEach((c) => found.set(c.id, c));

  if (/^\d{10}$/.test(term)) add(await store.query('customers', { where: [['mobile', '==', term]] }));
  if (/^[\d-]{6,}$/.test(term)) add(await store.query('customers', { where: [['citizenshipNo', '==', term]] }));
  if (/^\d{8,}$/.test(term)) {
    const acc = await store.get('accounts', term);
    if (acc) {
      const c = await store.get('customers', acc.customerId);
      if (c) found.set(c.id, c);
    }
  }
  if (/^[a-zA-Z ]{2,}$/.test(term)) {
    const lower = term.toLowerCase();
    add(await store.query('customers', {
      where: [['nameLower', '>=', lower], ['nameLower', '<=', `${lower}`]],
      limit: 20,
    }));
  }
  const results = [];
  for (const c of found.values()) results.push(summary(c, await accountsFor(c.id)));
  return results;
}

async function getForAgent(customerId) {
  const c = await getStore().get('customers', customerId);
  if (!c) throw new AppError(404, 'CUSTOMER_NOT_FOUND', 'Customer not found');
  return { ...summary(c, await accountsFor(c.id)), gender: c.gender, occupation: c.occupation, occupationCode: c.occupationCode || null, address: c.address };
}

// Onboarding (UC3). Creates the customer and a pending savings account in one transaction.
// No real identity verification happens: the bank supervisor reviews the application.
async function onboard(agentId, input) {
  const store = getStore();
  const dupes = await store.query('customers', { where: [['citizenshipNo', '==', input.citizenshipNo]] });
  if (dupes.length) throw new AppError(409, 'DUPLICATE_CITIZENSHIP', 'A customer with this citizenship number already exists');
  const mobileDupes = await store.query('customers', { where: [['mobile', '==', input.mobile]] });
  if (mobileDupes.length) throw new AppError(409, 'DUPLICATE_MOBILE', 'This mobile number is already registered');
  const { address, issueDistrict } = await resolveAddress(input.address, input.citizenshipIssueDistrict);
  const job = await resolveOccupation(input.occupationCode, input.occupation);
  input = { ...input, ...job, address, citizenshipIssueDistrict: issueDistrict };

  const customerId = `CUST-${crypto.randomInt(100000, 999999)}`;
  const accountNo = `0102${crypto.randomInt(10000000, 99999999)}`;
  const customer = {
    ...input,
    nameLower: fullName(input).toLowerCase(),
    kycStatus: 'pending_review',
    createdByAgent: agentId,
    createdAt: nowIso(),
  };
  await store.runTransaction(async (tx) => {
    tx.create('customers', customerId, customer);
    tx.create('accounts', accountNo, {
      customerId, productName: 'Bachat Khata (Savings)', type: 'savings', balance: 0, status: 'pending', openedAt: nowIso(),
    });
    auditInTx(tx, store, agentId, 'CUSTOMER_ONBOARDED', { customerId, accountNo });
  });
  return { customerId, accountNo, accountMasked: maskAccount(accountNo), kycStatus: 'pending_review' };
}

async function reviewKyc(supervisorId, customerId, { decision, reason }) {
  const store = getStore();
  const c = await store.get('customers', customerId);
  if (!c) throw new AppError(404, 'CUSTOMER_NOT_FOUND', 'Customer not found');
  if (c.kycStatus !== 'pending_review') throw new AppError(409, 'NOT_PENDING', 'This application has already been reviewed');
  const accounts = await accountsFor(customerId);
  await store.runTransaction(async (tx) => {
    tx.update('customers', customerId, {
      kycStatus: decision === 'approve' ? 'verified' : 'rejected',
      kycReviewedBy: supervisorId,
      kycReviewedAt: nowIso(),
      kycRejectReason: decision === 'reject' ? reason : null,
    });
    if (decision === 'approve') accounts.forEach((a) => tx.update('accounts', a.id, { status: 'active' }));
    auditInTx(tx, store, supervisorId, decision === 'approve' ? 'KYC_APPROVED' : 'KYC_REJECTED', { customerId, reason });
  });
  await audit(supervisorId, 'KYC_REVIEWED', { customerId, decision });
}

async function balanceFor(accountNo) {
  const a = await getStore().get('accounts', accountNo);
  return a ? paisaToRupees(a.balance) : null;
}

module.exports = { search, getForAgent, onboard, reviewKyc, fullName, balanceFor };
