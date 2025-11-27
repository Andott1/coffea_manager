# ☕ Coffea Manager (Mobile)

![Flutter](https://img.shields.io/badge/Flutter-3.32%2B-blue?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.8%2B-blue?logo=dart)
![Hive](https://img.shields.io/badge/Hive-Local%20Storage-yellow)
![Supabase](https://img.shields.io/badge/Supabase-Cloud%20Sync-green)
![bcrypt](https://img.shields.io/badge/bcrypt-1.1.3-lightgrey)
![License](https://img.shields.io/badge/License-MIT-green)
![Status](https://img.shields.io/badge/Version-1.1.0-brightgreen)

**Coffea Manager** is the official mobile companion app for the **Coffea Suite ecosystem**.
It provides store owners and managers with an **offline-capable, real-time admin dashboard**—supporting inventory management, payroll processing, attendance verification, and transaction monitoring directly from a smartphone.

This app links seamlessly with the **Tablet POS** system, sharing the same backend (Supabase) and the same offline-first architecture (Hive).

---

## 🚀 Core Features

### 📊 **1. Operational Dashboard**

* **Live Metrics:** Today's revenue, total transactions, and active staff indicators.
* **Quick Action Tiles:** Receive stock, approve attendance, force sync, and more.
* **Activity Timeline:** Chronological feed of sales, stock changes, payroll actions, and attendance events.

### 📦 **2. Inventory Management**

* **Real-Time Stock Levels:** Automatically synced with POS product sales and recipe deductions.
* **Smart Unit Conversions:** Handle purchases in bulk (kg/L) and usage in finer units (g/mL).
* **Inventory Movements:** Record Restock, Wastage, Corrections, and Transfers.
* **Searchable Stock History:** See exactly who changed what and when.

### 👥 **3. Staff & Attendance**

* **Staff "Waterfall" View:** Shows live staff status (On Floor → Break → Done).
* **Photo-Verified Attendance:** Review captured images from tablet clock-ins.
* **Verification Workflow:** Approve, reject, or request changes with reasons.
* **Payroll Automation:**

  * Generate payroll for any date range.
  * Auto-compute gross pay from verified logs.
  * Add bonuses/deductions.
  * Lock payroll to prevent double payments.

### 🧾 **4. Orders & History**

* Browse transaction logs synced from the POS.
* Filter by Paid, Voided, Discounted, or Refunded.
* Full breakdown of items, modifiers, and staff involved.

---

## 🛠️ Tech Stack

| Component            | Technology                      | Purpose                             |
| -------------------- | ------------------------------- | ----------------------------------- |
| **Framework**        | Flutter (Dart 3.8)              | Cross-platform UI                   |
| **Local Storage**    | Hive / Hive Flutter             | Offline-first caching               |
| **Cloud Backend**    | Supabase (PostgreSQL + Storage) | Secure syncing & authentication     |
| **Security**         | bcrypt                          | PIN/password hashing                |
| **State Management** | BLoC + Local setState           | Scalable and predictable state flow |
| **Logging**          | Talker                          | Global error and event tracing      |

---

## 📂 Project Structure

```text
lib/
├── config/               # Themes, Typography, App Colors
├── core/
│   ├── bloc/             # Auth, Connectivity, Sync
│   ├── models/           # Hive Adapters (User, Logs, Stock, Payroll)
│   ├── services/         # Sync, Hive, Logging, Session Service
│   ├── utils/            # Formatters, Dialogs, Responsive helpers
│   └── widgets/          # Reusable UI components (Cards, Lists, Inputs)
├── screens/
│   ├── attendance/       # Verification, Staff Status, Payroll
│   ├── dashboard/        # Metrics, Timeline, Quick Actions
│   ├── inventory/        # Stock Levels, Movements, Adjustments
│   ├── orders/           # Transaction Logs
│   └── startup/          # Login, Splash, Cloud Restore
└── main.dart             # App Entry Point
```

---

## 🔄 Sync Architecture (Offline-First)

Coffea Manager uses the same **queue-based syncing model** as the tablet POS.

1. **Local Writes:**
   All changes (attendance actions, stock adjustments, payroll updates) are written to **Hive** instantly.

2. **SyncQueueModel:**
   Every mutation is logged in an offline queue.

3. **Background Synchronization:**
   `SupabaseSyncService` listens for connectivity restored and pushes pending sync items.

4. **Optimized Updates:**

   * Full upserts for large data (Ingredients, Users, Payroll)
   * Partial updates for verifications, timestamps
   * Attendance images are uploaded to Supabase Storage before syncing logs

5. **Manual Sync Controls:**
   Trigger **Force Push**, **Force Pull**, and **Conflict Resolution** from the Settings page.

---

## ⚙️ Installation & Setup

### 🔧 Prerequisites

* Flutter SDK **3.32+**
* Dart SDK **3.8+**
* Supabase project (URL + Anon Key)
* Android/iOS smartphone

---

### 🚀 1. Clone & Install

```bash
git clone <repo_url>
cd Coffea_phone
flutter pub get
```

### 🧩 2. Generate Hive TypeAdapters

```bash
dart run build_runner build --delete-conflicting-outputs
```

### ▶️ 3. Run the App

```bash
flutter run --dart-define=SUPABASE_URL=[YOUR_URL] --dart-define=SUPABASE_ANON_KEY=[YOUR_ANON_KEY]
```

---

## 📱 Supported Devices

The UI is optimized for:

* iOS smartphones (primary target)
* Android smartphones

---

## 📝 License

Licensed under the **MIT License**.
See the `LICENSE` file for details.
