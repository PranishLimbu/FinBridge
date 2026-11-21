const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const config = require('../config');
const { getStore } = require('../db');
const { AppError, nowIso } = require('../utils/helpers');
const { audit } = require('./auditService');

function publicAgent(a) {
  return {
    agentId: a.id,
    name: a.name,
    role: a.role,
    location: a.location,
    terminalId: a.terminalId,
    partnerBank: a.partnerBank,
    status: a.status,
  };
}

async function login({ agentId, pin, terminalId }) {
  const store = getStore();
  const id = agentId.trim().toUpperCase();
  const agent = await store.get('agents', id);
  // Same message for unknown ID and wrong PIN, so the response does not reveal which IDs exist.
  const invalid = new AppError(401, 'INVALID_CREDENTIALS', 'Agent ID or PIN is incorrect');
  if (!agent) {
    await audit(id, 'LOGIN_FAILED', { reason: 'unknown_agent', terminalId });
    throw invalid;
  }
  if (agent.status === 'locked') {
    await audit(id, 'LOGIN_BLOCKED', { terminalId });
    throw new AppError(423, 'ACCOUNT_LOCKED', 'This agent account is locked. Ask your bank supervisor to unlock it.');
  }
  if (agent.status !== 'active') throw new AppError(403, 'ACCOUNT_INACTIVE', 'This agent account is not active.');

  const ok = await bcrypt.compare(pin, agent.pinHash);
  if (!ok) {
    const attempts = (agent.failedPinAttempts || 0) + 1;
    const locked = attempts >= config.rules.maxPinAttempts;
    await store.update('agents', id, { failedPinAttempts: attempts, ...(locked ? { status: 'locked', lockedAt: nowIso() } : {}) });
    await audit(id, locked ? 'ACCOUNT_LOCKED' : 'LOGIN_FAILED', { attempts, terminalId });
    if (locked) throw new AppError(423, 'ACCOUNT_LOCKED', 'Too many wrong PINs. The account is now locked; ask your supervisor to unlock it.');
    throw new AppError(401, 'INVALID_CREDENTIALS', 'Agent ID or PIN is incorrect', {
      attemptsRemaining: config.rules.maxPinAttempts - attempts,
    });
  }

  await store.update('agents', id, { failedPinAttempts: 0, lastLoginAt: nowIso(), lastTerminalId: terminalId || null });
  await audit(id, 'LOGIN_SUCCESS', { terminalId });
  const token = jwt.sign({ sub: id, role: agent.role }, config.jwt.secret, { expiresIn: config.jwt.expiresIn });
  return { token, agent: publicAgent(agent) };
}

async function changePin(agentId, { currentPin, newPin }) {
  const store = getStore();
  const agent = await store.get('agents', agentId);
  if (!(await bcrypt.compare(currentPin, agent.pinHash))) {
    await audit(agentId, 'PIN_CHANGE_FAILED');
    throw new AppError(400, 'INVALID_PIN', 'Current PIN is incorrect');
  }
  if (currentPin === newPin) throw new AppError(400, 'SAME_PIN', 'New PIN must be different');
  await store.update('agents', agentId, { pinHash: await bcrypt.hash(newPin, 10), pinChangedAt: nowIso() });
  await audit(agentId, 'PIN_CHANGED');
}

module.exports = { login, changePin, publicAgent };
