const crypto = require('crypto');

class AppError extends Error {
  constructor(status, code, message, details) {
    super(message);
    this.status = status;
    this.code = code;
    this.details = details;
  }
}

const maskAccount = (acc) => (acc ? `••••${String(acc).slice(-4)}` : null);
const maskMobile = (m) => (m ? `${String(m).slice(0, 5)}****${String(m).slice(-1)}` : null);
const maskCitizenship = (c) => (c ? `${'*'.repeat(Math.max(0, c.length - 4))}${c.slice(-4)}` : null);

// TXN-20261120-4F7A2C : date plus 6 random hex characters, upper case.
function transactionReference(date = new Date()) {
  const d = date.toISOString().slice(0, 10).replace(/-/g, '');
  return `TXN-${d}-${crypto.randomBytes(3).toString('hex').toUpperCase()}`;
}

const nowIso = () => new Date().toISOString();

// Start of the current day in Nepal Time (UTC+05:45), returned as an ISO string.
function startOfNepalDay(date = new Date()) {
  const offsetMs = (5 * 60 + 45) * 60 * 1000;
  const local = new Date(date.getTime() + offsetMs);
  local.setUTCHours(0, 0, 0, 0);
  return new Date(local.getTime() - offsetMs).toISOString();
}

const sha256 = (s) => crypto.createHash('sha256').update(s).digest('hex');

module.exports = {
  AppError, maskAccount, maskMobile, maskCitizenship, transactionReference, nowIso, startOfNepalDay, sha256,
};
