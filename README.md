# FinBridge – Agent Banking App (Assessment 2)

FinBridge lets an authorised local agent provide basic banking for a partner bank: customer
lookup, onboarding, cash deposits, cash withdrawals with customer OTP, receipts, a transaction
journal and end-of-day cash reconciliation.

> **Academic prototype.** No real bank, money, identity check or SMS is involved. All people,
> accounts and the partner bank in the demo data are fictional.

```
finbridge/
├── backend/   Node.js + Express API, Cloud Firestore (or in-memory demo database)
└── mobile/    Flutter agent app (Android first)
```

The app never talks to Firebase directly. Every request goes through the API, which checks
amounts, limits, cash float and OTPs on the server and writes an audit log. Firestore security
rules deny all direct client access.

---

## 1. Run the backend

Needs **Node.js 20 or newer**.

```bash
cd backend
npm install
cp .env.example .env        # Windows: copy .env.example .env
npm start
```

With the default `DB_DRIVER=memory` it starts with demo data and needs no Firebase account
(data resets on restart). You should see:

```
FinBridge API listening on http://localhost:4000/api (db: memory)
```

Run the automated tests (23 tests):

```bash
npm test
```

### Demo logins (PIN `123456` for all)

| ID | Role | Notes |
|---|---|---|
| `AGT-98412` | Agent – Sita Sharma | Main demo agent |
| `AGT-77020` | Agent – Ramesh Adhikari | Second agent |
| `SUP-001` | Supervisor – Pratima Karki | API only: KYC approval, unlock agents |

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
   Indexes take a few minutes to build. If a query fails with “requires an index”, the error
   message contains a link that creates it.
5. Load the demo data once: `npm run seed:firestore`
6. `npm start`, which should now say `(db: firestore)`.

## 3. Run the Flutter app

Needs **Flutter 3.27 or newer** (`flutter --version`).

```bash
cd mobile
flutter create --platforms=android,ios --org com.finbridge .   # generates android/ and ios/ only
flutter pub get
flutter test                 # unit tests for formatting and amount-in-words
flutter run
```

**Allow plain HTTP to your laptop (development only).** Android blocks `http://` by default.
In `mobile/android/app/src/main/AndroidManifest.xml`, add to the `<application ...>` tag:

```xml
android:usesCleartextTraffic="true"
```

**Which address the app uses for the API:**

| Running on | API address |
|---|---|
| Android emulator | `http://10.0.2.2:4000/api` (default, nothing to change) |
| Real phone on the same Wi-Fi | `flutter run --dart-define=API_URL=http://<laptop IP>:4000/api` |
| iOS simulator | `flutter run --dart-define=API_URL=http://localhost:4000/api` |

Find your laptop's IP with `ipconfig` (Windows) or `ifconfig` / `ip a` (macOS/Linux), and allow
port 4000 through the firewall.

## 4. Try the main flows

1. Log in as `AGT-98412` / `123456`.
2. **Deposit:** Counter → Cash deposit → search `9851012347` → enter 5000 → review → confirm →
   receipt. The cash drawer goes up by Rs 5,000.
3. **Withdrawal:** Counter → Cash withdrawal → Hari → 2000 → *Send OTP*. The demo shows the OTP on
   screen (and in the server console) because there is no SMS gateway. Enter it → receipt.
   Try a wrong OTP three times to see the cancellation.
4. **Onboarding:** Customers → New customer → fill the four steps → submit. The account stays
   *pending* until a supervisor approves it:
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
- Supervisor tasks are API-only; there is no supervisor app or web portal.
- `EXPOSE_DEV_OTP=true` shows OTPs in API responses for demos. The server refuses to start with
  it in production mode.
