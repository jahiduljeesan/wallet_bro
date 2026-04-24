# 💸 Wallet Bro

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-039BE5?style=for-the-badge&logo=Firebase&logoColor=white)](https://firebase.google.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

**Wallet Bro** is a premium, AI-powered personal finance management application built with Flutter. It combines sleek design with powerful tracking capabilities and AI-driven financial insights to help you take control of your wealth.

![Promo Banner](assets/images/promo_banner.png)

---

## ✨ Features

### 🤖 AI Chat Assistant
- Get personalized financial advice.
- Ask questions about your spending habits.
- Receive smart insights and budget recommendations.

### 📊 Advanced Analytics
- Beautiful, interactive charts using `fl_chart`.
- Spending breakdown by category and time period.
- Neon-themed visual aesthetics for dark mode.

### 💳 Transaction Management
- Quickly log income and expenses with an intuitive UI.
- Categorize transactions and add notes.
- Real-time updates across all your devices.

### 🏦 Multi-Account Support
- Manage multiple bank accounts, credit cards, and digital wallets.
- View individual account balances and total net worth.
- Seamlessly transition between different financial sources.

### 📱 Premium UX/UI
- Smooth animations powered by `Lottie` and `Flutter Animate`.
- Dark and Light mode support using `Google Fonts (Outfit)`.
- Glassmorphism design elements and responsive layouts.

### 🔒 Secure & Reliable
- Robust authentication via **Firebase Auth** and **Google Sign-In**.
- Data persistence using **Cloud Firestore** and **Hive** for offline-first capabilities.
- Privacy-focused and secure data handling.

---

## 🚀 Tech Stack

- **Framework:** [Flutter](https://flutter.dev)
- **State Management:** [Provider](https://pub.dev/packages/provider)
- **Database:** [Cloud Firestore](https://firebase.google.com/docs/firestore) & [Hive](https://pub.dev/packages/hive)
- **Auth:** [Firebase Authentication](https://firebase.google.com/docs/auth)
- **Networking:** [Dio](https://pub.dev/packages/dio)
- **Animations:** [Lottie](https://pub.dev/packages/lottie) & [Flutter Animate](https://pub.dev/packages/flutter_animate)
- **UI Components:** [Google Fonts](https://pub.dev/packages/google_fonts) (Outfit), [Fl Chart](https://pub.dev/packages/fl_chart)

---

## 🛠️ Getting Started

### Prerequisites

- Flutter SDK (v3.10.3 or higher)
- Android Studio / VS Code
- Firebase Project (for cloud sync)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/jahiduljeesan/wallet_bro.git
   cd wallet_bro
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Set up Firebase:**
   - Create a project on the [Firebase Console](https://console.firebase.google.com/).
   - Add your Android/iOS app and download the configuration files (`google-services.json` / `GoogleService-Info.plist`).
   - Place them in their respective directories (`android/app/` and `ios/Runner/`).

4. **Run the app:**
   ```bash
   flutter run
   ```

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

---

## 🤝 Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

*Built with ❤️ by [Jahidul Jeesan](https://github.com/jahiduljeesan)*
