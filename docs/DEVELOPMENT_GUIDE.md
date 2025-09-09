# 🚀 Merch Hub Development Guide

Complete guide for developing the unified Flutter + Laravel application.

## 📋 Prerequisites

### Required Software
- **PHP 8.2+** with extensions: `pdo_sqlite`, `mbstring`, `xml`, `ctype`, `json`
- **Composer** (PHP package manager)
- **Flutter SDK 3.0+**
- **Node.js 18+** and npm
- **Git**

### Optional (Recommended)
- **Visual Studio Code** with extensions:
  - Laravel Blade Snippets
  - Flutter/Dart
  - PHP Intelephense
- **Postman** for API testing
- **Docker Desktop** (for containerized development)

## 🏗️ Project Setup

### 1. Clone/Setup Project
```bash
# If cloning from repo
git clone <repository-url>
cd merch-hub-unified

# If using existing unified setup
cd "C:\Capstone\Merch Hub Unified"
```

### 2. Quick Setup (Recommended)
```bash
# Run the setup script (Windows)
.\scripts\setup.bat

# Or manually:
npm run setup
```

### 3. Manual Setup

#### Backend Setup
```bash
cd backend

# Install PHP dependencies
composer install

# Environment setup
copy .env.example .env
php artisan key:generate

# Database setup
php artisan migrate
php artisan db:seed
php artisan storage:link

# Start backend server
php artisan serve
```

#### Frontend Setup
```bash
cd frontend

# Install Flutter dependencies
flutter pub get

# Enable web platform
flutter config --enable-web

# Start frontend (web)
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 3000

# Or for mobile
flutter run
```

## 🔧 Development Workflow

### Starting Development
```bash
# Start both servers simultaneously
npm run dev

# Or individually:
npm run backend    # Laravel API (port 8000)
npm run frontend   # Flutter Web (port 3000)
```

### URLs
- **Backend API**: http://localhost:8000
- **Frontend Web**: http://localhost:3000
- **API Documentation**: http://localhost:8000/api/documentation

### Default Login Credentials
| Role | Email | Password |
|------|-------|----------|
| Super Admin | superadmin@example.com | superadmin123 |
| Admin | admin@example.com | admin123 |
| Student | student@example.com | student123 |

## 🛠️ Common Development Tasks

### Backend Tasks
```bash
cd backend

# Create new migration
php artisan make:migration create_table_name

# Create new controller
php artisan make:controller ControllerName

# Create new model
php artisan make:model ModelName -m

# Reset database
php artisan migrate:fresh --seed

# Create super admin
php artisan user:create-superadmin

# Run tests
php artisan test

# Clear caches
php artisan config:clear
php artisan cache:clear
php artisan route:clear
```

### Frontend Tasks
```bash
cd frontend

# Add new package
flutter pub add package_name

# Run tests
flutter test

# Build for web
flutter build web

# Build for Android
flutter build apk

# Analyze code
flutter analyze

# Format code
dart format .
```

### Full-Stack Tasks
```bash
# Run all tests
npm run test

# Build everything
npm run build:frontend

# Reset everything
npm run backend:fresh
```

## 🏗️ Architecture Overview

### Backend (Laravel)
```
backend/
├── app/
│   ├── Http/Controllers/     # API controllers
│   ├── Models/              # Eloquent models
│   ├── Middleware/          # Custom middleware
│   └── Console/Commands/    # Artisan commands
├── routes/api.php          # API routes
├── database/
│   ├── migrations/         # Database schema
│   └── seeders/           # Sample data
└── config/                # Configuration files
```

### Frontend (Flutter)
```
frontend/
├── lib/
│   ├── models/            # Data models
│   ├── services/          # API services
│   ├── screens/           # UI screens
│   ├── widgets/           # Reusable widgets
│   └── main.dart         # App entry point
├── config/
│   └── app_config.dart   # API configuration
└── pubspec.yaml          # Dependencies
```

## 🔐 Authentication Flow

### 1. User Registration/Login
```dart
// Frontend calls
POST /api/register or /api/login
```

### 2. Token Storage
```dart
// Store token securely
SharedPreferences prefs = await SharedPreferences.getInstance();
await prefs.setString('auth_token', token);
```

### 3. Authenticated Requests
```dart
// Add token to headers
headers: {
  'Authorization': 'Bearer $token',
  'Content-Type': 'application/json',
  'Accept': 'application/json',
}
```

## 🎨 UI Development

### Role-Based UI Rendering
```dart
// Check user role
if (userSession.isSuperAdmin) {
  return SuperAdminDashboard();
} else if (userSession.isAdmin) {
  return AdminDashboard();
} else {
  return StudentDashboard();
}
```

### Department Access Control
```dart
// Check department access
if (userSession.canManageDepartment(departmentId)) {
  return ManagementPanel();
} else {
  return UnauthorizedWidget();
}
```

## 🧪 Testing

### Backend Testing
```bash
cd backend
php artisan test

# Specific test
php artisan test --filter UserTest

# With coverage
php artisan test --coverage
```

### Frontend Testing
```bash
cd frontend
flutter test

# Widget tests
flutter test test/widget_test.dart

# Integration tests
flutter drive --target=test_driver/app.dart
```

## 🐛 Debugging

### Backend Debugging
- Enable debug mode in `.env`: `APP_DEBUG=true`
- Check logs: `storage/logs/laravel.log`
- Use `dd()` for debugging
- Use Telescope for request monitoring

### Frontend Debugging
- Use Flutter DevTools
- Add breakpoints in VS Code
- Use `print()` statements
- Check browser console for web

## 🚀 Deployment

### Backend Deployment
```bash
# Production setup
composer install --optimize-autoloader --no-dev
php artisan config:cache
php artisan route:cache
php artisan view:cache
```

### Frontend Deployment
```bash
# Build for web
flutter build web

# Build for mobile
flutter build apk --release
flutter build ios --release
```

## 📱 Platform-Specific Development

### Web Development
- Uses Chrome/Edge for development
- Responsive design with MediaQuery
- Web-specific features in `web/` directory

### Mobile Development
- Android: Uses Android Studio/VS Code
- iOS: Requires Xcode (macOS only)
- Platform-specific code in `android/` and `ios/`

## 🔧 VS Code Integration

### Workspace Setup
1. Open `merch-hub.code-workspace`
2. Install recommended extensions
3. Use built-in tasks:
   - `Ctrl+Shift+P` → "Tasks: Run Task"
   - Select "🚀 Start Development Servers"

### Debugging
- Backend: Use PHP Debug extension
- Frontend: Use Dart/Flutter extensions
- Set breakpoints and debug simultaneously

## 📚 API Integration Examples

### Authentication
```dart
// Login
final response = await http.post(
  AppConfig.login(),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'email': email,
    'password': password,
  }),
);

final data = jsonDecode(response.body);
final userSession = UserSession.fromJson(data['user']);
```

### CRUD Operations
```dart
// Get listings
final response = await http.get(
  AppConfig.listings(),
  headers: {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  },
);
```

## 🤝 Contributing Guidelines

1. **Branch Naming**: `feature/description` or `fix/description`
2. **Commits**: Use conventional commit format
3. **Testing**: Add tests for new features
4. **Documentation**: Update docs for API changes
5. **Code Style**: Follow Dart/PHP standards

## 📞 Support

- Check logs in `backend/storage/logs/`
- Use Flutter Doctor: `flutter doctor`
- Check Laravel requirements: `php artisan --version`
- Join development Discord/Slack for team communication
