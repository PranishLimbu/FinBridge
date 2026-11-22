# FinBridge – Agent Banking App (Assessment 2)

FinBridge lets an authorised local agent provide basic banking for a partner bank: customer
lookup, onboarding, cash deposits, cash withdrawals with customer OTP, receipts, a transaction
journal and end-of-day cash reconciliation.

> **Academic prototype.** No real bank, money, identity check or SMS is involved. All people,
> accounts and the partner bank in the demo data are fictional.

```
finbridge/
├── backend/   Firebase setup scripts, Firestore security rules, and the older Node.js API
└── mobile/    Flutter agent app (Android and web), talks straight to Firebase
```

**The app talks to Firebase directly** (project `finbridge-df94f`). Agents sign in with Firebase
Authentication, and the app reads and writes Cloud Firestore itself. Every phone shares the same
data, with no server to host. The business rules (amount limits, cash float, OTP, KYC) run in
`mobile/lib/api/api_client.dart`. `backend/firestore.rules` re-checks the parts that matter on
Firebase's side: who may read or write what, and that a balance or cash drawer only changes
together with a confirmed transaction of exactly that amount.

### Set up Firebase (once, and again after flushing it)

1. In the Firebase console: **Authentication → Get started → Sign-in method → Email/Password →
   Enable**.
2. Put the service-account key at `backend/serviceAccountKey.json` and run:
   ```bash
   cd backend
   npm install
   npm run firebase:setup             # rules + demo logins + demo data + address lists
   npm run firebase:setup -- --reset  # DELETES all FinBridge data first, then the same
   npm run firebase:setup -- --reference-only  # only rules + master data (address lists,
                                               # occupations); customers and balances untouched
   ```
   Master data lives in `backend/reference-data/` (`districts.csv`, `local_bodies.tsv`,
   `occupations.csv`). After editing a file, run the `--reference-only` command again.
3. Run the app (section 3). No backend server is needed.

Sections 1 and 2 describe the older Node.js API, which still works with SQLite or Firestore for
local testing. The app no longer uses it.

---

## 1. Run the backend

Needs **Node.js 20 or newer**.

```bash
cd backend
npm install
cp .env.example .env        # Windows: copy .env.example .env
npm start
```

With `DB_DRIVER=sqlite` (the default in `.env.example`) data is saved to
`backend/data/finbridge.db` and survives restarts. It uses the SQLite built into Node, so there is
nothing to install and no account needed. The first start creates the file with the demo data. You
should see:

```
FinBridge API listening on http://localhost:4000/api (db: sqlite)
```

To start again from clean demo data, stop the server and delete the `backend/data` folder. Open the
file with any SQLite viewer (e.g. DB Browser for SQLite): each collection is a table with an `id`
and a JSON `data` column. `DB_DRIVER=memory` keeps everything in RAM instead (resets on restart).

Run the automated tests (23 tests):

```bash
npm test               # against the in-memory store
npm run test:sqlite    # the same tests against SQLite
```

### Demo logins (PIN `123456` for all)

| ID | Role | Notes |
|---|---|---|
| `AGT-98412` | Agent – Sita Sharma | Main demo agent |
| `AGT-77020` | Agent – Ramesh Adhikari | Second agent |
| `SUP-001` | Supervisor – Pratima Karki | Log in to the app: approve KYC and float requests, unlock agents |

Demo customers: Hari Bahadur Thapa (mobile `9851012347`), Sunita Tamang (`9841234567`),
Bikash Shrestha (`9803456789`), Maya Kumari Gurung (`9812345670`, low balance).

## 2. Switch to Cloud Firestore

1. Create a project at <https://console.firebase.google.com> and add **Cloud Firestore**
   (production mode, region `asia-south1` is closest to Nepal).
2. **Project settings → Service accounts → Generate new private key.** Save the file as
   `backend/serviceAccountKey.json`. Never commit it (it is in `.gitignore`).
3. In `backend/.env` set:
   ```
   DB_DRIVER=firestore
   FIREBASE_PROJECT_ID=<your project id>
   GOOGLE_APPLICATION_CREDENTIALS=./serviceAccountKey.json
   JWT_SECRET=<long random string>
   ```
4. Deploy the security rules and indexes (needs `npm i -g firebase-tools` and `firebase login`):
   ```bash
   cd backend
   firebase use <your project id>
   firebase deploy --only firestore:rules,firestore:indexes
   ```
   Indexes take a few minutes to build. Without the Firebase CLI you can instead create the one
   index that matters by hand (Firestore → Indexes → **Composite** → Create index): collection
   `transactions`, fields `agentId` Ascending and `createdAt` Descending. Until it exists, the API
   still works: it filters those queries itself and logs a link that creates the index.
5. Load the demo data once: `npm run seed:firestore`, then the address lists (7 provinces, 77
   districts, 753 municipalities from `backend/reference-data/`): `npm run import:locations`.
   Run the import again after editing those files. (The memory and SQLite databases load the lists
   by themselves when they are first created.)
6. `npm start`, which should now say `(db: firestore)`.

## 3. Run the Flutter app

Needs **Flutter 3.27 or newer** (`flutter --version`).

```bash
cd mobile
flutter pub get
flutter test                                 # unit tests for money formatting
flutter run                                  # Android phone or emulator
flutter run -d web-server --web-port 8080    # browser, http://localhost:8080
flutter build apk                            # APK to install on any phone
```

The Firebase settings are in `mobile/lib/firebase_options.dart`, so there is no server address
to set. Any phone with internet access, on any network, uses the same Firebase data.

## 4. Try the main flows

1. Log in as `AGT-98412` / `123456`.
2. **Deposit:** Counter → Cash deposit → search `9851012347` → enter 5000 → review → confirm →
   receipt. The cash drawer goes up by Rs 5,000.
3. **Withdrawal:** Counter → Cash withdrawal → Hari → 2000 → *Send OTP*. The demo shows the OTP on
   screen (and in the server console) because there is no SMS gateway. Enter it → receipt.
   Try a wrong OTP three times to see the cancellation.
4. **Onboarding:** Customers → New customer → fill the four steps → submit. The account stays
   *pending* until a supervisor approves it: log out, log in as `SUP-001` / `123456` and press
   **Approve**. Or from the command line on Windows, from `backend/`:
   ```powershell
   .\scripts\kyc-review.ps1                  # list pending applications
   .\scripts\kyc-review.ps1 -Approve all     # or -Approve CUSTOMER_ID / -Reject ID -Reason "..."
   ```
   Or with curl:
   ```bash
   # get a supervisor token
   curl -s -X POST localhost:4000/api/auth/login -H "content-type: application/json" \
     -d '{"agentId":"SUP-001","pin":"123456"}'
   # approve (replace TOKEN and CUSTOMER_ID)
   curl -X POST localhost:4000/api/supervisor/customers/CUSTOMER_ID/kyc \
     -H "authorization: Bearer TOKEN" -H "content-type: application/json" -d '{"decision":"approve"}'
   ```
5. **End of day:** Terminal → End-of-day cash count → enter a different amount to see a mismatch.
6. **Lockout:** enter a wrong PIN five times; unlock with
   `POST /api/supervisor/agents/AGT-98412/unlock` as the supervisor.

---

## API reference

All routes start with `/api`. Except login, every route needs `Authorization: Bearer <token>`.
Amounts are in rupees. Errors look like `{"error":{"code":"...","message":"...","details":{}}}`.

| Method | Route | Use case | Notes |
|---|---|---|---|
| POST | `/auth/login` | UC1 | `{agentId, pin, terminalId}`; 5 wrong PINs lock the account |
| GET | `/auth/me` | | |
| POST | `/auth/logout` | | |
| POST | `/auth/change-pin` | | `{currentPin, newPin}` |
| GET | `/dashboard` | | Float, today's totals, alerts, last 5 transactions |
| GET | `/customers?q=` | UC2 | Mobile, account no., citizenship no. or name |
| GET | `/customers/:id` | UC2 | |
| POST | `/customers` | UC3 | Onboarding; creates a *pending* account |
| POST | `/transactions/deposits` | UC4 | `{customerId, accountNo, amount, idempotencyKey}` |
| POST | `/transactions/withdrawals` | UC5 | Same body; sends OTP, nothing moves yet |
| POST | `/transactions/:id/confirm-otp` | UC5 | `{otp}`; 3 wrong OTPs or 5 minutes cancel |
| POST | `/transactions/:id/resend-otp` | UC5 | After 60 s, max 3 times |
| POST | `/transactions/:id/cancel` | UC5 | |
| GET | `/transactions` | UC6 | Filters: `type, status, from, to, q, limit` |
| GET | `/transactions/:id` | UC6 | Receipt |
| POST | `/transactions/:id/receipt/sms` | UC6 | Resend receipt (simulated SMS) |
| POST | `/transactions/:id/disputes` | FR-13 | `{reason}` |
| GET | `/eod/preview` | UC7 | Expected cash |
| POST | `/eod` | UC7 | `{countedCash, notes}`; once per day |
| POST | `/float/rebalance` | | `{direction: cash_to_bank / cash_from_bank, amount}` |
| GET | `/supervisor/overview` | | Supervisor only |
| POST | `/supervisor/customers/:id/kyc` | UC3 | `{decision: approve / reject, reason}` |
| POST | `/supervisor/agents/:id/unlock` | | |
| POST | `/supervisor/float-requests/:id` | | `{approve: true / false}` |

### Rules enforced by the server

| Rule | Value |
|---|---|
| Amount per transaction | Rs 100 – Rs 25,000 |
| Withdrawal fee / deposit fee | Rs 10 / free (illustrative) |
| Cash drawer | Can't exceed the Rs 1,00,000 limit or drop below the Rs 10,000 reserve |
| OTP | 6 digits, 5-minute expiry, 3 attempts, stored only as a hash |
| PIN | bcrypt hash; 5 failures lock the account |
| Duplicates | Same `idempotencyKey` returns the original transaction instead of creating a second |
| Atomicity | Balance, float, transaction and audit entry are written in one database transaction |
| Session | JWT expires after 30 minutes; the app logs out after 5 minutes without a touch |

## Known limitations (prototype)

- SMS, OTP delivery, receipt printing and document photos are simulated.
- No connection to a real core banking system; balances live in this database.
- BS and AD dates of birth are entered separately (no automatic calendar conversion yet).
- The supervisor screen in the app covers KYC, float requests and unlocking agents only; there is no separate supervisor portal.
- `EXPOSE_DEV_OTP=true` shows OTPs in API responses for demos. The server refuses to start with
  it in production mode.
