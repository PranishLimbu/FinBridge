const path = require('path');
require('dotenv').config({ quiet: true });

const env = process.env;

const config = {
  port: Number(env.PORT || 4000),
  nodeEnv: env.NODE_ENV || 'development',
  // 'sqlite' saves to a local file; 'memory' keeps everything in RAM (tests, quick demos);
  // 'firestore' uses Cloud Firestore.
  dbDriver: env.DB_DRIVER || 'memory',
  sqlite: {
    // Relative paths are resolved from the backend folder, wherever the server is started from.
    file: path.resolve(__dirname, '..', env.SQLITE_FILE || 'data/finbridge.db'),
  },
  firebase: {
    projectId: env.FIREBASE_PROJECT_ID,
    // Path to the service-account JSON downloaded from the Firebase console.
    credentialsPath: env.GOOGLE_APPLICATION_CREDENTIALS,
  },
  jwt: {
    secret: env.JWT_SECRET || 'dev-only-change-me',
    expiresIn: env.JWT_EXPIRES_IN || '30m',
  },
  // When true, OTP codes are returned in API responses so the prototype can be demoed
  // without a real SMS gateway. Must be false in any real deployment.
  exposeDevOtp: (env.EXPOSE_DEV_OTP || 'true') === 'true',
  rules: {
    minTransaction: 100 * 100, // paisa (Rs 100)
    maxTransaction: 25000 * 100, // paisa (Rs 25,000)
    withdrawalFee: 10 * 100, // paisa (Rs 10), illustrative only
    depositFee: 0,
    maxPinAttempts: 5,
    otpLength: 6,
    otpTtlSeconds: 5 * 60,
    otpMaxAttempts: 3,
    otpResendAfterSeconds: 60,
  },
};

if (config.nodeEnv === 'production' && config.jwt.secret === 'dev-only-change-me') {
  throw new Error('JWT_SECRET must be set in production');
}
if (config.nodeEnv === 'production' && config.exposeDevOtp) {
  throw new Error('EXPOSE_DEV_OTP must be false in production');
}

module.exports = config;
