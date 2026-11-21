const jwt = require('jsonwebtoken');
const config = require('../config');
const { getStore } = require('../db');
const { AppError } = require('../utils/helpers');

// Verifies the bearer token and loads the current agent. Locked or suspended agents are
// rejected even if their token has not expired yet.
async function requireAuth(req, _res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return next(new AppError(401, 'UNAUTHENTICATED', 'Please log in'));
  let payload;
  try {
    payload = jwt.verify(token, config.jwt.secret);
  } catch {
    return next(new AppError(401, 'SESSION_EXPIRED', 'Your session has expired. Please log in again.'));
  }
  const agent = await getStore().get('agents', payload.sub);
  if (!agent || agent.status !== 'active') return next(new AppError(401, 'ACCOUNT_UNAVAILABLE', 'This account is not active'));
  req.user = { id: agent.id, role: agent.role, name: agent.name };
  return next();
}

const requireRole = (role) => (req, _res, next) => (
  req.user.role === role ? next() : next(new AppError(403, 'FORBIDDEN', 'You do not have permission for this action'))
);

// Validates req.body (or req.query) with a zod schema and replaces it with the parsed value.
const validate = (schema, source = 'body') => (req, _res, next) => {
  const result = schema.safeParse(req[source] ?? {});
  if (!result.success) {
    const fields = result.error.issues.map((i) => ({ field: i.path.join('.'), message: i.message }));
    return next(new AppError(400, 'VALIDATION_ERROR', fields[0] ? `${fields[0].field}: ${fields[0].message}` : 'Invalid input', { fields }));
  }
  if (source === 'query') req.validQuery = result.data;
  else req[source] = result.data;
  return next();
};

// eslint-disable-next-line no-unused-vars
function errorHandler(err, _req, res, _next) {
  if (err instanceof AppError) {
    return res.status(err.status).json({ error: { code: err.code, message: err.message, ...(err.details ? { details: err.details } : {}) } });
  }
  if (err.type === 'entity.parse.failed') {
    return res.status(400).json({ error: { code: 'BAD_JSON', message: 'Request body is not valid JSON' } });
  }
  console.error(err);
  return res.status(500).json({ error: { code: 'INTERNAL', message: 'Something went wrong. No money has moved; please try again.' } });
}

module.exports = { requireAuth, requireRole, validate, errorHandler };
