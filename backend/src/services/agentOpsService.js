// Dashboard, end-of-day reconciliation (UC7) and float rebalancing.
const { getStore } = require('../db');
const { AppError, nowIso, startOfNepalDay } = require('../utils/helpers');
const { paisaToRupees, formatNpr } = require('../utils/money');
const { audit } = require('./auditService');
const { currentFloat, publicTxn } = require('./transactionService');
const { publicAgent } = require('./authService');

const rupeesFloat = (f) => ({
  cash: paisaToRupees(f.cash),
  opening: paisaToRupees(f.opening),
  limit: paisaToRupees(f.limit),
  minReserve: paisaToRupees(f.minReserve),
  utilisation: Math.round((f.cash / f.limit) * 1000) / 10,
});

async function todaysTransactions(agentId) {
  return getStore().query('transactions', {
    where: [['agentId', '==', agentId], ['createdAt', '>=', startOfNepalDay()]],
    orderBy: ['createdAt', 'desc'],
  });
}

function totals(txns) {
  const confirmed = txns.filter((t) => t.status === 'confirmed');
  const sum = (type) => confirmed.filter((t) => t.type === type).reduce((s, t) => s + t.amount, 0);
  const count = (type) => confirmed.filter((t) => t.type === type).length;
  return {
    inflows: paisaToRupees(sum('deposit')),
    inflowCount: count('deposit'),
    outflows: paisaToRupees(sum('withdrawal')),
    outflowCount: count('withdrawal'),
    feesEarned: paisaToRupees(confirmed.reduce((s, t) => s + t.fee, 0)),
  };
}

async function dashboard(agentId) {
  const store = getStore();
  const agent = await store.get('agents', agentId);
  const { float } = currentFloat(agent);
  const txns = await todaysTransactions(agentId);
  const pendingKyc = await store.query('customers', {
    where: [['createdByAgent', '==', agentId], ['kycStatus', '==', 'pending_review']],
  });
  const eodToday = await store.query('eodReports', {
    where: [['agentId', '==', agentId], ['date', '==', startOfNepalDay()]],
  });

  const alerts = [];
  if (pendingKyc.length) alerts.push({ type: 'kyc_pending', count: pendingKyc.length, message: `${pendingKyc.length} onboarding application(s) waiting for bank review` });
  if (!eodToday.length) alerts.push({ type: 'eod_due', message: 'End-of-day cash count not yet submitted' });
  const awaitingOtp = txns.filter((t) => t.status === 'awaiting_otp');
  if (awaitingOtp.length) alerts.push({ type: 'pending_otp', count: awaitingOtp.length, message: `${awaitingOtp.length} withdrawal(s) waiting for customer OTP` });
  if (float.cash - float.minReserve < 5000 * 100) alerts.push({ type: 'low_float', message: 'Cash drawer is close to the minimum reserve' });
  if (float.limit - float.cash < 5000 * 100) alerts.push({ type: 'high_float', message: 'Cash drawer is close to its limit; request a rebalance' });

  return {
    agent: publicAgent(agent),
    float: rupeesFloat(float),
    today: totals(txns),
    alerts,
    recent: txns.slice(0, 5).map(publicTxn),
    eodSubmitted: eodToday.length > 0,
  };
}

async function eodPreview(agentId) {
  const agent = await getStore().get('agents', agentId);
  const { float } = currentFloat(agent);
  const txns = await todaysTransactions(agentId);
  return {
    date: startOfNepalDay(),
    openingFloat: paisaToRupees(float.opening),
    ...totals(txns),
    expectedCash: paisaToRupees(float.cash),
    pending: txns.filter((t) => t.status === 'awaiting_otp').map(publicTxn),
  };
}

async function submitEod(agentId, { countedCash, notes }) {
  const store = getStore();
  const preview = await eodPreview(agentId);
  const counted = Math.round(countedCash * 100);
  const expected = Math.round(preview.expectedCash * 100);
  const difference = counted - expected;
  const id = `${agentId}_${preview.date.slice(0, 10)}`;
  if (await store.get('eodReports', id)) throw new AppError(409, 'EOD_ALREADY_SUBMITTED', 'Today’s end-of-day report has already been submitted');

  const report = {
    agentId,
    date: preview.date,
    openingFloat: preview.openingFloat,
    inflows: preview.inflows,
    outflows: preview.outflows,
    expectedCash: preview.expectedCash,
    countedCash: paisaToRupees(counted),
    difference: paisaToRupees(difference),
    status: difference === 0 ? 'balanced' : 'mismatch',
    pendingTransactionIds: preview.pending.map((t) => t.id),
    notes: notes || null,
    submittedAt: nowIso(),
  };
  await store.create('eodReports', id, report);
  await audit(agentId, 'EOD_SUBMITTED', { reportId: id, status: report.status, difference: report.difference });
  return {
    reportId: id,
    ...report,
    message: difference === 0
      ? 'Cash balanced. Report sent to your supervisor.'
      : `Difference of ${formatNpr(Math.abs(difference))} (${difference > 0 ? 'over' : 'short'}). Report sent to your supervisor for review.`,
  };
}

async function requestRebalance(agentId, { direction, amount, notes }) {
  const store = getStore();
  const id = store.newId();
  await store.set('floatRequests', id, {
    agentId, direction, amount: Math.round(amount * 100), notes: notes || null, status: 'pending', createdAt: nowIso(),
  });
  await audit(agentId, 'FLOAT_REBALANCE_REQUESTED', { requestId: id, direction, amount });
  return { requestId: id, status: 'pending' };
}

// ---------------------------------------------------------------- supervisor

async function supervisorOverview() {
  const store = getStore();
  const agents = await store.query('agents', { where: [['role', '==', 'agent']] });
  return {
    agents: agents.map((a) => ({ ...publicAgent(a), float: rupeesFloat(currentFloat(a).float), failedPinAttempts: a.failedPinAttempts || 0 })),
    pendingKyc: (await store.query('customers', { where: [['kycStatus', '==', 'pending_review']] }))
      .map((c) => ({ customerId: c.id, name: [c.firstName, c.middleName, c.lastName].filter(Boolean).join(' '), createdByAgent: c.createdByAgent, createdAt: c.createdAt })),
    eodMismatches: await store.query('eodReports', { where: [['status', '==', 'mismatch']] }),
    openDisputes: await store.query('disputes', { where: [['status', '==', 'open']] }),
    floatRequests: (await store.query('floatRequests', { where: [['status', '==', 'pending']] }))
      .map((r) => ({ ...r, amount: paisaToRupees(r.amount) })),
  };
}

async function unlockAgent(supervisorId, agentId) {
  const store = getStore();
  const a = await store.get('agents', agentId);
  if (!a) throw new AppError(404, 'AGENT_NOT_FOUND', 'Agent not found');
  await store.update('agents', agentId, { status: 'active', failedPinAttempts: 0, unlockedBy: supervisorId, unlockedAt: nowIso() });
  await audit(supervisorId, 'AGENT_UNLOCKED', { agentId });
}

async function decideRebalance(supervisorId, requestId, approve) {
  const store = getStore();
  const outcome = await store.runTransaction(async (tx) => {
    const r = await tx.get('floatRequests', requestId);
    if (!r || r.status !== 'pending') return { error: new AppError(404, 'REQUEST_NOT_FOUND', 'No pending request with this ID') };
    const agent = await tx.get('agents', r.agentId);
    if (!approve) {
      tx.update('floatRequests', requestId, { status: 'rejected', decidedBy: supervisorId, decidedAt: nowIso() });
      return { status: 'rejected' };
    }
    const { float, floatDate } = currentFloat(agent);
    // cash_to_bank: agent hands excess cash to the bank; cash_from_bank: bank tops the drawer up.
    const cash = r.direction === 'cash_to_bank' ? float.cash - r.amount : float.cash + r.amount;
    if (cash < 0 || cash > float.limit) return { error: new AppError(409, 'INVALID_REBALANCE', 'This rebalance would put the drawer outside its limits') };
    tx.update('agents', r.agentId, { float: { ...float, cash }, floatDate });
    tx.update('floatRequests', requestId, { status: 'approved', decidedBy: supervisorId, decidedAt: nowIso() });
    return { status: 'approved', newCash: paisaToRupees(cash) };
  });
  if (outcome.error) throw outcome.error;
  await audit(supervisorId, 'FLOAT_REBALANCE_DECIDED', { requestId, ...outcome });
  return outcome;
}

module.exports = {
  dashboard, eodPreview, submitEod, requestRebalance, supervisorOverview, unlockAgent, decideRebalance,
};
