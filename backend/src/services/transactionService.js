const crypto = require('crypto');
const config = require('../config');
const { getStore } = require('../db');
const {
  AppError, nowIso, maskAccount, transactionReference, startOfNepalDay, sha256,
} = require('../utils/helpers');
const { paisaToRupees, amountInWords, formatNpr } = require('../utils/money');
const { auditInTx, audit } = require('./auditService');
const sms = require('./smsService');
const { fullName } = require('./customerService');

const R = config.rules;

// ---------------------------------------------------------------- helpers

// Resets the opening float at the start of each Nepal day.
function currentFloat(agent) {
  const today = startOfNepalDay();
  const f = agent.float;
  if (!agent.floatDate || agent.floatDate < today) {
    return { float: { ...f, opening: f.cash }, floatDate: today };
  }
  return { float: { ...f }, floatDate: agent.floatDate };
}

function checkAmount(amount) {
  if (!Number.isInteger(amount) || amount <= 0) throw new AppError(400, 'INVALID_AMOUNT', 'Enter a valid amount');
  if (amount < R.minTransaction || amount > R.maxTransaction) {
    throw new AppError(400, 'AMOUNT_OUT_OF_RANGE',
      `Amount must be between ${formatNpr(R.minTransaction)} and ${formatNpr(R.maxTransaction)}`);
  }
}

function checkAccount(account, customer, customerId) {
  if (!customer) throw new AppError(404, 'CUSTOMER_NOT_FOUND', 'Customer not found');
  if (!account || account.customerId !== customerId) {
    throw new AppError(404, 'ACCOUNT_NOT_FOUND', 'This account does not belong to the selected customer');
  }
  if (account.status === 'pending') throw new AppError(409, 'ACCOUNT_PENDING', 'This account is waiting for KYC approval by the bank');
  if (account.status !== 'active') throw new AppError(409, 'ACCOUNT_INACTIVE', 'This account cannot be used for transactions');
}

const otpHash = (txnId, code) => sha256(`${txnId}:${code}`);
const newOtp = () => String(crypto.randomInt(0, 10 ** R.otpLength)).padStart(R.otpLength, '0');

function publicTxn(t) {
  return {
    id: t.id,
    reference: t.reference,
    type: t.type,
    status: t.status,
    customerId: t.customerId,
    customerName: t.customerName,
    accountMasked: maskAccount(t.accountNo),
    amount: paisaToRupees(t.amount),
    fee: paisaToRupees(t.fee),
    total: paisaToRupees(t.total),
    amountInWords: amountInWords(t.amount),
    createdAt: t.createdAt,
    confirmedAt: t.confirmedAt || null,
    failureReason: t.failureReason || null,
    otpExpiresAt: t.status === 'awaiting_otp' ? t.otp.expiresAt : undefined,
    otpAttemptsRemaining: t.status === 'awaiting_otp' ? R.otpMaxAttempts - t.otp.attempts : undefined,
  };
}

function receipt(t) {
  return {
    ...publicTxn(t),
    service: t.type === 'deposit' ? 'Cash deposit (branchless)' : 'Cash withdrawal (branchless)',
    totalLabel: t.type === 'deposit' ? 'Total credited' : 'Total debited',
    agent: { agentId: t.agentId, name: t.agentName, location: t.agentLocation },
    partnerBank: t.partnerBank,
    simulated: true,
  };
}

async function idempotentReplay(tx, agentId, key) {
  const idem = await tx.get('idempotency', `${agentId}:${key}`);
  if (!idem) return null;
  return tx.get('transactions', idem.transactionId);
}

function baseTxn({ id, type, agent, customer, account, amount, fee, idempotencyKey }) {
  return {
    reference: transactionReference(),
    type,
    agentId: agent.id,
    agentName: agent.name,
    agentLocation: agent.location,
    partnerBank: agent.partnerBank,
    customerId: customer.id,
    customerName: fullName(customer),
    customerMobile: customer.mobile,
    accountNo: account.id,
    amount,
    fee,
    total: type === 'deposit' ? amount - fee : amount + fee,
    idempotencyKey,
    createdAt: nowIso(),
    id,
  };
}

// ---------------------------------------------------------------- deposit (UC4)

async function deposit(agentId, { customerId, accountNo, amount, idempotencyKey }) {
  checkAmount(amount);
  const store = getStore();
  const id = store.newId();

  const result = await store.runTransaction(async (tx) => {
    const existing = await idempotentReplay(tx, agentId, idempotencyKey);
    if (existing) return { txn: existing, replayed: true };

    const agent = await tx.get('agents', agentId);
    const customer = await tx.get('customers', customerId);
    const account = await tx.get('accounts', accountNo);
    checkAccount(account, customer, customerId);

    const { float, floatDate } = currentFloat(agent);
    if (float.cash + amount > float.limit) {
      throw new AppError(409, 'FLOAT_LIMIT_EXCEEDED',
        `This deposit would take your cash drawer above its ${formatNpr(float.limit)} limit. Request a float rebalance first.`,
        { cash: paisaToRupees(float.cash), limit: paisaToRupees(float.limit) });
    }

    const txn = { ...baseTxn({ id, type: 'deposit', agent, customer, account, amount, fee: R.depositFee, idempotencyKey }), status: 'confirmed' };
    txn.confirmedAt = txn.createdAt;
    txn.floatBefore = float.cash;
    txn.floatAfter = float.cash + amount;

    tx.update('agents', agentId, { float: { ...float, cash: float.cash + amount }, floatDate });
    tx.update('accounts', accountNo, { balance: account.balance + txn.total });
    tx.create('transactions', id, txn);
    tx.create('idempotency', `${agentId}:${idempotencyKey}`, { transactionId: id, at: txn.createdAt });
    auditInTx(tx, store, agentId, 'DEPOSIT_CONFIRMED', { transactionId: id, reference: txn.reference, amount });
    return { txn, replayed: false };
  });

  if (!result.replayed) {
    const t = result.txn;
    await sms.send(t.customerMobile,
      `FinBridge: ${formatNpr(t.total)} deposited to A/C ${maskAccount(t.accountNo)} via agent ${t.agentId}. Ref ${t.reference}.`,
      { transactionId: t.id, kind: 'deposit_receipt' });
  }
  return { ...receipt(result.txn), replayed: result.replayed };
}

// ---------------------------------------------------------------- withdrawal (UC5)

async function startWithdrawal(agentId, { customerId, accountNo, amount, idempotencyKey }) {
  checkAmount(amount);
  const store = getStore();
  const id = store.newId();
  const code = newOtp();

  const result = await store.runTransaction(async (tx) => {
    const existing = await idempotentReplay(tx, agentId, idempotencyKey);
    if (existing) return { txn: existing, replayed: true };

    const agent = await tx.get('agents', agentId);
    const customer = await tx.get('customers', customerId);
    const account = await tx.get('accounts', accountNo);
    checkAccount(account, customer, customerId);

    const fee = R.withdrawalFee;
    if (account.balance < amount + fee) {
      throw new AppError(409, 'INSUFFICIENT_BALANCE', 'The customer’s balance is not enough for this amount plus the fee');
    }
    const { float } = currentFloat(agent);
    if (float.cash - amount < float.minReserve) {
      throw new AppError(409, 'INSUFFICIENT_FLOAT',
        `Your cash drawer has ${formatNpr(float.cash)}. Paying ${formatNpr(amount)} would leave less than the ${formatNpr(float.minReserve)} minimum reserve.`,
        { cash: paisaToRupees(float.cash), minReserve: paisaToRupees(float.minReserve) });
    }

    const sentAt = nowIso();
    const txn = {
      ...baseTxn({ id, type: 'withdrawal', agent, customer, account, amount, fee, idempotencyKey }),
      status: 'awaiting_otp',
      otp: {
        hash: otpHash(id, code),
        expiresAt: new Date(Date.now() + R.otpTtlSeconds * 1000).toISOString(),
        attempts: 0,
        sentAt,
        resends: 0,
      },
    };
    tx.create('transactions', id, txn);
    tx.create('idempotency', `${agentId}:${idempotencyKey}`, { transactionId: id, at: sentAt });
    auditInTx(tx, store, agentId, 'WITHDRAWAL_STARTED', { transactionId: id, amount });
    return { txn, replayed: false };
  });

  const t = result.txn;
  if (!result.replayed) {
    await sms.send(t.customerMobile,
      `FinBridge: your OTP to withdraw ${formatNpr(t.amount)} at agent ${t.agentId} is ${code}. Valid 5 minutes. Never share it with anyone except at the counter.`,
      { transactionId: t.id, kind: 'otp' });
  }
  return {
    transaction: publicTxn(t),
    replayed: result.replayed,
    ...(config.exposeDevOtp && !result.replayed ? { devOtp: code } : {}),
  };
}

async function confirmWithdrawal(agentId, txnId, otp) {
  const store = getStore();

  // The transaction returns an outcome rather than throwing, so that failed attempts are saved.
  const outcome = await store.runTransaction(async (tx) => {
    const t = await tx.get('transactions', txnId);
    if (!t || t.agentId !== agentId || t.type !== 'withdrawal') return { error: new AppError(404, 'TRANSACTION_NOT_FOUND', 'Transaction not found') };
    const agent = await tx.get('agents', agentId);
    const account = await tx.get('accounts', t.accountNo);

    if (t.status === 'confirmed') return { txn: t, already: true };
    if (t.status !== 'awaiting_otp') return { error: new AppError(409, 'NOT_AWAITING_OTP', `This withdrawal is ${t.status}`) };

    if (new Date(t.otp.expiresAt) < new Date()) {
      tx.update('transactions', txnId, { status: 'cancelled', failureReason: 'otp_expired' });
      auditInTx(tx, store, agentId, 'WITHDRAWAL_OTP_EXPIRED', { transactionId: txnId });
      return { error: new AppError(410, 'OTP_EXPIRED', 'The OTP has expired. Start the withdrawal again.') };
    }

    const given = Buffer.from(otpHash(txnId, String(otp)));
    const stored = Buffer.from(t.otp.hash);
    if (!crypto.timingSafeEqual(given, stored)) {
      const attempts = t.otp.attempts + 1;
      if (attempts >= R.otpMaxAttempts) {
        tx.update('transactions', txnId, { status: 'cancelled', failureReason: 'otp_attempts_exceeded', otp: { ...t.otp, attempts } });
        auditInTx(tx, store, agentId, 'WITHDRAWAL_OTP_LOCKED', { transactionId: txnId });
        return { error: new AppError(423, 'OTP_ATTEMPTS_EXCEEDED', 'Wrong OTP entered 3 times. The withdrawal has been cancelled.') };
      }
      tx.update('transactions', txnId, { otp: { ...t.otp, attempts } });
      auditInTx(tx, store, agentId, 'WITHDRAWAL_OTP_WRONG', { transactionId: txnId, attempts });
      return { error: new AppError(400, 'WRONG_OTP', 'The OTP is incorrect', { attemptsRemaining: R.otpMaxAttempts - attempts }) };
    }

    // Re-check balance and float at the moment of payout: they may have changed since the OTP was sent.
    const { float, floatDate } = currentFloat(agent);
    const fail = (code, message) => {
      tx.update('transactions', txnId, { status: 'failed', failureReason: code });
      auditInTx(tx, store, agentId, 'WITHDRAWAL_FAILED', { transactionId: txnId, reason: code });
      return { error: new AppError(409, code, message) };
    };
    if (account.status !== 'active') return fail('ACCOUNT_INACTIVE', 'This account cannot be used for transactions');
    if (account.balance < t.total) return fail('INSUFFICIENT_BALANCE', 'The customer’s balance is no longer enough');
    if (float.cash - t.amount < float.minReserve) return fail('INSUFFICIENT_FLOAT', 'Your cash drawer no longer has enough cash');

    const confirmedAt = nowIso();
    const update = {
      status: 'confirmed', confirmedAt, floatBefore: float.cash, floatAfter: float.cash - t.amount, otp: { ...t.otp, usedAt: confirmedAt },
    };
    tx.update('agents', agentId, { float: { ...float, cash: float.cash - t.amount }, floatDate });
    tx.update('accounts', t.accountNo, { balance: account.balance - t.total });
    tx.update('transactions', txnId, update);
    auditInTx(tx, store, agentId, 'WITHDRAWAL_CONFIRMED', { transactionId: txnId, reference: t.reference, amount: t.amount });
    return { txn: { ...t, ...update } };
  });

  if (outcome.error) throw outcome.error;
  const t = outcome.txn;
  if (!outcome.already) {
    await sms.send(t.customerMobile,
      `FinBridge: ${formatNpr(t.amount)} withdrawn from A/C ${maskAccount(t.accountNo)} via agent ${t.agentId} (fee ${formatNpr(t.fee)}). Ref ${t.reference}.`,
      { transactionId: t.id, kind: 'withdrawal_receipt' });
  }
  return receipt(t);
}

async function resendOtp(agentId, txnId) {
  const store = getStore();
  const t = await store.get('transactions', txnId);
  if (!t || t.agentId !== agentId || t.status !== 'awaiting_otp') throw new AppError(404, 'TRANSACTION_NOT_FOUND', 'No withdrawal is waiting for an OTP');
  const wait = new Date(t.otp.sentAt).getTime() + R.otpResendAfterSeconds * 1000 - Date.now();
  if (wait > 0) throw new AppError(429, 'RESEND_TOO_SOON', `Wait ${Math.ceil(wait / 1000)} seconds before resending`);
  if (t.otp.resends >= 3) throw new AppError(429, 'RESEND_LIMIT', 'OTP resend limit reached. Start a new withdrawal.');
  const code = newOtp();
  // Attempts are not reset, so resending cannot be used to get more guesses.
  await store.update('transactions', txnId, {
    otp: {
      ...t.otp, hash: otpHash(txnId, code), sentAt: nowIso(), resends: t.otp.resends + 1,
      expiresAt: new Date(Date.now() + R.otpTtlSeconds * 1000).toISOString(),
    },
  });
  await sms.send(t.customerMobile, `FinBridge: your new OTP is ${code}. Valid 5 minutes.`, { transactionId: txnId, kind: 'otp' });
  await audit(agentId, 'WITHDRAWAL_OTP_RESENT', { transactionId: txnId });
  return config.exposeDevOtp ? { devOtp: code } : {};
}

async function cancel(agentId, txnId) {
  const store = getStore();
  const t = await store.get('transactions', txnId);
  if (!t || t.agentId !== agentId) throw new AppError(404, 'TRANSACTION_NOT_FOUND', 'Transaction not found');
  if (t.status !== 'awaiting_otp') throw new AppError(409, 'CANNOT_CANCEL', 'Only a withdrawal waiting for its OTP can be cancelled');
  await store.update('transactions', txnId, { status: 'cancelled', failureReason: 'cancelled_by_agent' });
  await audit(agentId, 'WITHDRAWAL_CANCELLED', { transactionId: txnId });
}

// ---------------------------------------------------------------- history and receipts (UC6)

async function list(agentId, { type, status, from, to, q, limit = 50 } = {}) {
  const rows = await getStore().query('transactions', {
    where: [['agentId', '==', agentId]], orderBy: ['createdAt', 'desc'], limit: 500,
  });
  const needle = q ? q.toLowerCase() : null;
  return rows
    .filter((t) => !type || t.type === type)
    .filter((t) => !status || t.status === status)
    .filter((t) => !from || t.createdAt >= from)
    .filter((t) => !to || t.createdAt <= to)
    .filter((t) => !needle || t.customerName.toLowerCase().includes(needle) || t.reference.toLowerCase().includes(needle))
    .slice(0, limit)
    .map(publicTxn);
}

async function getReceipt(user, txnId) {
  const t = await getStore().get('transactions', txnId);
  if (!t || (user.role !== 'supervisor' && t.agentId !== user.id)) throw new AppError(404, 'TRANSACTION_NOT_FOUND', 'Transaction not found');
  return receipt(t);
}

async function resendReceipt(agentId, txnId) {
  const t = await getStore().get('transactions', txnId);
  if (!t || t.agentId !== agentId) throw new AppError(404, 'TRANSACTION_NOT_FOUND', 'Transaction not found');
  if (t.status !== 'confirmed') throw new AppError(409, 'NOT_CONFIRMED', 'Only confirmed transactions have a receipt');
  await sms.send(t.customerMobile,
    `FinBridge receipt: ${t.type} ${formatNpr(t.amount)}, fee ${formatNpr(t.fee)}, A/C ${maskAccount(t.accountNo)}. Ref ${t.reference}.`,
    { transactionId: t.id, kind: 'receipt_resend' });
  await audit(agentId, 'RECEIPT_RESENT', { transactionId: txnId });
}

// FR-13 (Could): customer reports a disputed transaction through the agent.
async function reportDispute(agentId, txnId, reason) {
  const store = getStore();
  const t = await store.get('transactions', txnId);
  if (!t || t.agentId !== agentId) throw new AppError(404, 'TRANSACTION_NOT_FOUND', 'Transaction not found');
  const id = store.newId();
  await store.set('disputes', id, {
    transactionId: txnId, reference: t.reference, agentId, customerId: t.customerId, reason, status: 'open', createdAt: nowIso(),
  });
  await audit(agentId, 'DISPUTE_REPORTED', { transactionId: txnId, disputeId: id });
  return { disputeId: id, status: 'open' };
}

module.exports = {
  deposit, startWithdrawal, confirmWithdrawal, resendOtp, cancel, list, getReceipt, resendReceipt, reportDispute,
  currentFloat, publicTxn,
};
