# ☕ Coffea Manager (Mobile)

**Coffea Manager** is the companion mobile application for the Coffea Suite ecosystem. It acts as an **Offline-First Admin Dashboard**, allowing store managers and owners to oversee operations, manage inventory, verify staff attendance, and process payroll directly from their smartphone.

---

## 🚀 Key Features

### 📊 **1. Operational Dashboard**

* **Real-Time Metrics:** View today's total revenue, order count, and active staff at a glance.
* **Quick Actions:** Shortcuts for receiving stock, verifying staff, and manual sync.
* **Activity Feed:** A unified timeline showing recent sales, inventory movements, and staff clock-ins.

### 📦 **2. Inventory Management**

* **Smart Unit Conversion:** Automatically converts between purchasing units (e.g., `kg`, `L`) and base usage units (e.g., `g`, `mL`).
* **Adjustment Logs:** Log wastage, restocks, or corrections.
* **Audit History:** View a searchable history of who moved stock and why.

### 👥 **3. Staff & HR Hub**

* **"Waterfall" Dashboard:** See who is currently On Floor, On Break, or Finished for the day.
* **Attendance Verification:** Review photo proofs for clock-ins. Verify or reject entries with specific reasons.
* **Payroll System:**
  * Generate payroll drafts for specific date ranges based on verified logs.
  * Apply adjustments (Bonuses/Deductions).
  * **Locking Mechanism:** Marking payroll as "Paid" locks the associated attendance logs to prevent double-payment.

### 🧾 **4. Order History**

* View transaction history with status filtering (Paid/Voided) and sorting.
* Detailed breakdown of items, variants, and cashiers.

---

## 🛠 Tech Stack

* **Framework:** Flutter (Dart)
* **State Management:** BLoC (Authentication, Connectivity) & local `setState` for UI widgets.
* **Local Database:** [Hive](https://docs.hivedb.dev/) (NoSQL) for offline persistence.
* **Cloud Backend:** [Supabase](https://supabase.com/) (PostgreSQL, Auth, Storage).
* **Sync Strategy:** Queue-based optimistic UI with `SupabaseSyncService`.

---

## 📂 Project Structure

```text
lib/
├── config/               # Theme, Fonts, and UI Constants
├── core/
│   ├── bloc/             # Global State (Auth, Connectivity)
│   ├── models/           # Hive Adapters (User, Product, Ingredient, Logs, etc.)
│   ├── services/         # Business Logic (Sync, Logger, Session, Hive)
│   ├── utils/            # Formatters, Dialogs, Responsive Logic
│   └── widgets/          # Reusable UI (Avatar, NumericPad)
├── screens/
│   ├── attendance/       # Staff Dashboard, Verification, Payroll
│   ├── dashboard/        # Home Revenue & Activity Feed
│   ├── inventory/        # Stock Levels & History
│   ├── orders/           # Transaction History
│   └── startup/          # Login, Cloud Restore, & Splash
└── main.dart             # App Entry Point
````

---

## 🔄 Sync Architecture

The app uses an **Offline-First** approach.

1. **Reads:** Data is always read from the local **Hive** boxes for instant UI rendering.
2. **Writes:** Changes are written to Hive immediately, then added to a `SyncQueueModel`.
3. **Sync:** `SupabaseSyncService` watches connection status. When online, it processes the queue:
      * **UPSERT:** Full object updates (Ingredients, Payroll).
      * **UPDATE:** Optimized partial updates (Verification Status).
      * **Uploads:** Attendance images are uploaded to Supabase Storage before the log entry is synced.

---

## ⚙️ Setup & Installation

### Prerequisites

* Flutter SDK (Latest Stable)
* Dart SDK

### 1\. Clone & Install

```bash
git clone <repo_url>
cd Coffea_phone
flutter pub get
```

### 2\. Hive Code Generation

If you modify any Models, you must regenerate the TypeAdapters:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 3\. Running the App

```bash
flutter run
```

### ⚠️ Windows Build Note

If you encounter a `compileDebugUnitTestSources` error regarding different drive roots (e.g., Project on `E:` and Cache on `C:`), please move the project to the `C:` drive or update your `PUB_CACHE` environment variable.

---

## 🔐 Credentials & Config

The app connects to Supabase using credentials found in `main.dart`.

* **URL:** `https://vvbjuezcwyakrnkrmgon.supabase.co`
* **Anon Key:** *(See source code)*

> **Note:** For production, these should be moved to `--dart-define` or a `.env` file.

---

## 📱 Supported Devices

The UI is built with a custom `Responsive` utility that scales fonts and padding based on the screen diagonal, optimized for:

* Standard Smartphones (Android/iOS)
* Small Tablets.

---

© 2025 Coffea Suite. All Rights Reserved.
