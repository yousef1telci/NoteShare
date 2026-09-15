# 📚 NoteShare

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Gemini](https://img.shields.io/badge/Gemini-8E75B2?style=for-the-badge&logo=google&logoColor=white)](https://ai.google.dev/)

**NoteShare** is a powerful cross-platform educational application built to help students collaborate, share study materials, and engage in real-time academic discussions.

---

## ✨ Key Features

- **🔐 Secure Authentication:** Seamless sign-up and login utilizing Supabase Auth.
- **🏛️ Class Management:** Create private or public classes, and join existing ones using a dedicated dashboard.
- **☁️ Material Sharing:** Upload, download, and organize study notes securely via Supabase Storage.
- **💬 Real-time Chat:** Instant messaging inside classrooms powered by Supabase Realtime streams.
- **🤖 AI Tutor Integration:** Built-in intelligent AI assistant using the **Google Gemini** API to help answer academic questions.
- **🛡️ Data Privacy:** Strict Row Level Security (RLS) policies implemented on the backend to ensure users only access their authorized data.

## 🛠️ Tech Stack

- **Frontend:** Flutter & Dart
- **State Management:** Riverpod (`flutter_riverpod`)
- **Routing:** GoRouter (`go_router`)
- **Backend as a Service:** Supabase (PostgreSQL, Auth, Storage, Realtime)
- **AI Integration:** Google Generative AI (`google_generative_ai`)

## 🚀 Getting Started

Follow these steps to set up the project locally on your machine.

### Prerequisites
- Flutter SDK (>= 3.0.0)
- A Supabase Project (URL and Anon Key)
- Google Gemini API Key

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yousef1telci/NoteShare.git
   cd NoteShare
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Environment Setup:**
   Create a `.env` file in the root directory of the project and add your Gemini API Key:
   ```env
   GEMINI_API_KEY=your_api_key_here
   ```
   *(Note: The Supabase URL and Key are currently initialized in `main.dart`, but for production, they should also be moved to `.env`).*

4. **Run the app:**
   ```bash
   flutter run
   ```

## 🔒 Security Note
This project uses `.env` files to manage sensitive API keys (like the Gemini API). Ensure that `.env` remains in your `.gitignore` and is **never** committed to version control.

---
*Developed with ❤️ by Yousef Taljbini*
