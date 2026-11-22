const express = require('express');
const rateLimit = require('express-rate-limit');
const S = require('./schemas');
const { requireAuth, requireRole, validate } = require('./middleware');
const { rupeesToPaisa } = require('./utils/money');
const authService = require('./services/authService');
const customers = require('./services/customerService');
const txns = require('./services/transactionService');
const ops = require('./services/agentOpsService');
const locations = require('./services/locationService');
const { audit } = require('./services/auditService');

const router = express.Router();
const toPaisa = (body) => ({ ...body, amount: rupeesToPaisa(body.amount) });

// ---------------------------------------------------------------- auth
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, limit: 20, standardHeaders: true, legacyHeaders: false,
  skip: () => process.env.NODE_ENV === 'test',
  handler: (_req, res) => res.status(429).json({ error: { code: 'TOO_MANY_ATTEMPTS', message: 'Too many login attempts. Wait 15 minutes.' } }),
});

router.post('/auth/login', loginLimiter, validate(S.login), async (req, res) => {
  res.json(await authService.login(req.body));
});

router.use(requireAuth); // everything below needs a valid session

router.get('/auth/me', async (req, res) => res.json({ user: req.user }));
router.post('/auth/logout', async (req, res) => {
  await audit(req.user.id, 'LOGOUT');
  res.status(204).end();
});
router.post('/auth/change-pin', validate(S.changePin), async (req, res) => {
  await authService.changePin(req.user.id, req.body);
  res.json({ message: 'PIN changed' });
});

// Provinces, districts and municipalities for the address dropdowns.
router.get('/locations', async (_req, res) => {
  res.set('Cache-Control', 'private, max-age=3600');
  res.json(await locations.getLocations());
});

// ---------------------------------------------------------------- agent
router.get('/dashboard', requireRole('agent'), async (req, res) => res.json(await ops.dashboard(req.user.id)));

router.get('/customers', requireRole('agent'), async (req, res) => {
  const q = String(req.query.q || '');
  if (q.trim().length < 2) return res.json({ results: [] });
  return res.json({ results: await customers.search(q) });
});
router.get('/customers/:id', async (req, res) => res.json(await customers.getForAgent(req.params.id)));
router.post('/customers', requireRole('agent'), validate(S.onboarding), async (req, res) => {
  const { consent, ...data } = req.body;
  res.status(201).json(await customers.onboard(req.user.id, data));
});

router.post('/transactions/deposits', requireRole('agent'), validate(S.cashTxn), async (req, res) => {
  const r = await txns.deposit(req.user.id, toPaisa(req.body));
  res.status(r.replayed ? 200 : 201).json(r);
});
router.post('/transactions/withdrawals', requireRole('agent'), validate(S.cashTxn), async (req, res) => {
  const r = await txns.startWithdrawal(req.user.id, toPaisa(req.body));
  res.status(r.replayed ? 200 : 201).json(r);
});
router.post('/transactions/:id/confirm-otp', requireRole('agent'), validate(S.confirmOtp), async (req, res) => {
  res.json(await txns.confirmWithdrawal(req.user.id, req.params.id, req.body.otp));
});
router.post('/transactions/:id/resend-otp', requireRole('agent'), async (req, res) => {
  res.json(await txns.resendOtp(req.user.id, req.params.id));
});
router.post('/transactions/:id/cancel', requireRole('agent'), async (req, res) => {
  await txns.cancel(req.user.id, req.params.id);
  res.json({ message: 'Withdrawal cancelled' });
});
router.get('/transactions', requireRole('agent'), validate(S.historyQuery, 'query'), async (req, res) => {
  res.json({ results: await txns.list(req.user.id, req.validQuery) });
});
router.get('/transactions/:id', async (req, res) => res.json(await txns.getReceipt(req.user, req.params.id)));
router.post('/transactions/:id/receipt/sms', requireRole('agent'), async (req, res) => {
  await txns.resendReceipt(req.user.id, req.params.id);
  res.json({ message: 'Receipt sent by SMS' });
});
router.post('/transactions/:id/disputes', requireRole('agent'), validate(S.dispute), async (req, res) => {
  res.status(201).json(await txns.reportDispute(req.user.id, req.params.id, req.body.reason));
});

router.get('/eod/preview', requireRole('agent'), async (req, res) => res.json(await ops.eodPreview(req.user.id)));
router.post('/eod', requireRole('agent'), validate(S.eod), async (req, res) => {
  res.status(201).json(await ops.submitEod(req.user.id, req.body));
});
router.post('/float/rebalance', requireRole('agent'), validate(S.rebalance), async (req, res) => {
  res.status(201).json(await ops.requestRebalance(req.user.id, req.body));
});

// ---------------------------------------------------------------- supervisor
router.get('/supervisor/overview', requireRole('supervisor'), async (req, res) => res.json(await ops.supervisorOverview()));
router.post('/supervisor/customers/:id/kyc', requireRole('supervisor'), validate(S.kycDecision), async (req, res) => {
  await customers.reviewKyc(req.user.id, req.params.id, req.body);
  res.json({ message: 'Decision saved' });
});
router.post('/supervisor/agents/:id/unlock', requireRole('supervisor'), async (req, res) => {
  await ops.unlockAgent(req.user.id, req.params.id);
  res.json({ message: 'Agent unlocked' });
});
router.post('/supervisor/float-requests/:id', requireRole('supervisor'), async (req, res) => {
  res.json(await ops.decideRebalance(req.user.id, req.params.id, req.body.approve === true));
});

module.exports = router;
