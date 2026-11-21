const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const routes = require('./routes');
const config = require('./config');
const { errorHandler } = require('./middleware');

function createApp() {
  const app = express();
  app.disable('x-powered-by');
  app.set('trust proxy', 1);
  app.use(helmet());
  app.use(cors());
  app.use(express.json({ limit: '100kb' }));

  app.get('/api/health', (_req, res) => res.json({ status: 'ok', db: config.dbDriver, simulated: true }));
  app.use('/api', routes);
  app.use((_req, res) => res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Route not found' } }));
  app.use(errorHandler);
  return app;
}

module.exports = { createApp };
