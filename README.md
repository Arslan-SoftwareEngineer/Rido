# Rido — Smart Vehicle Service & Maintenance Tracker

**Rido** is a cross-platform Flutter application designed to simplify vehicle ownership and maintenance tracking. Whether you own a daily commuter bike or multiple family cars, Rido provides a unified dashboard to log service histories, monitor mileage, track upcoming maintenance schedules, and generate verifiable service histories to share with potential buyers or mechanics.

---

## 📌 Table of Contents

- [Overview](#-overview)
- [Key Features](#-key-features)
- [Upcoming Roadmap](#-upcoming-roadmap)
- [Tech Stack](#-tech-stack)
- [Project Architecture](#-project-architecture)
- [Getting Started](#-getting-started)
- [Usage Workflow](#-usage-workflow)
- [Contributing](#-contributing)

---

## 📖 Overview

Keeping manual logs, physical receipts, or mental notes of oil changes, brake pads, and tire rotations often leads to missed intervals and depreciated resale value. **Rido** solves this by acting as a digital logbook and predictive maintenance assistant for both two-wheelers and four-wheelers.

---

## ✨ Key Features

### 1. Dual Fleet Management (Cars & Bikes)
- Dedicated modules for **Cars** and **Bikes**.
- Detailed vehicle profiles: **Make**, **Model**, **Variant/Trim**, **Year**, and current **Odometer/Mileage**.
- Support for multiple vehicles under a single profile.

### 2. Comprehensive Service & Maintenance Log
- Chronological logs of past maintenance events.
- Details logged per entry:
  - Service type (e.g., Engine Oil, Filters, Brake Fluid, Tires, General Inspection).
  - Date performed and odometer reading at service.
  - Workshop/mechanic details, parts replaced, and costs.
  - Custom notes and service receipts/invoices.

### 3. Service Reminders & Due Tracking
- Predictive and interval-based maintenance alerts.
- Configurable alerts based on elapsed mileage or time intervals (e.g., every 5,000 km or 6 months).

### 4. Shareable Vehicle Health & Service Records
- Export and share comprehensive service logs.
- Proof-of-maintenance documentation for prospective buyers to verify upkeep and preserve vehicle resale value.

---

## 🚀 Upcoming Roadmap

- [ ] **Cost Analytics & Fuel Log:** Track monthly running costs, fuel economy (MPG / km/L), and repair expense breakdowns.
- [ ] **Document Vault:** Secure local/cloud storage for Insurance, Registration, and Emission certificates with expiry reminders.
- [ ] **PDF Export:** One-tap export of formatted, printable maintenance ledgers.
- [ ] **Cloud Sync:** Seamless backup across multiple devices.

---

## 🛠️ Tech Stack

- **Framework:** [Flutter](https://flutter.dev/) (Dart)
- **Target Platforms:** Android, iOS (Web/Desktop compatible)
- **State Management:** Provider / Riverpod / Bloc *(customize based on implementation)*
- **Local Storage:** SQLite (sqflite) / Hive / Shared Preferences

---

## 📂 Project Architecture

```text
lib/
├── core/
│   ├── constants/       # App themes, colors, and asset paths
│   ├── utils/           # Date formatters, validators, calculations
│   └── widgets/         # Shared/reusable UI components
├── models/
│   ├── vehicle.dart     # Car & Bike schema (Make, Model, Variant, Mileage)
│   └── service_log.dart # Service record schema (Date, Cost, Part, Interval)
├── screens/
│   ├── home/            # Dashboard switching between Cars & Bikes
│   ├── vehicle_detail/  # Overview and stats for a selected vehicle
│   ├── service_history/ # Timeline view of maintenance records
│   └── add_service/     # Form to input and edit service logs
├── services/            # Database helpers, storage handlers, and notifications
└── main.dart            # Application entry point
```

## ⚙️ Getting Started

### Prerequisites
Ensure you have installed:
* Flutter SDK (`>= 3.0.0`)
* Dart SDK
* Android Studio / Xcode / VS Code with Flutter extensions

### Installation
1. Clone the repository:
```bash
git clone [https://github.com/Arslan-SoftwareEngineer/Rido.git](https://github.com/Arslan-SoftwareEngineer/Rido.git)
cd Rido
```
2. Install Dependencies:
```bash
flutter pub get
```
3. Run the app:
```bash
# List available devices
flutter devices

# Run on connected device or emulator
flutter run
```
## 📱 Usage Workflow

* **Add a Vehicle:** Tap the + button, select Car or Bike, and fill in the make, model, variant, and current mileage.
* **View Fleet:** Select any vehicle card from the dashboard to inspect its profile and maintenance ledger.
* **Log Maintenance:** Record new services with cost, date, mileage, and notes.
* **Monitor Dues:** Check upcoming service badges to stay ahead of scheduled maintenance.
* **Share History:** Export logs to verify maintenance condition whenever needed.

## 🤝 Contributing

Contributions are welcome! If you'd like to improve Rido:
Fork the Project.
Create your Feature Branch (git checkout -b feature/AmazingFeature).
Commit your Changes (git commit -m 'Add some AmazingFeature').
Push to the Branch (git push origin feature/AmazingFeature).
Open a Pull Request.
