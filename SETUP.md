# Merch Hub Unified - Setup Instructions

## Prerequisites
- XAMPP (with PHP 8.1+ and MySQL)
- Flutter SDK (3.0+)
- Composer (for PHP dependencies)
- Git
- Node.js (optional - only for development scripts)

## Quick Setup

### 1. Clone the Repository
```bash
git clone <your-github-repo-url>
cd "Merch Hub Unified"
```

### 2. Backend Setup (Laravel)

#### Install PHP Dependencies
```bash
cd backend
composer install  # Install Laravel dependencies
```

#### Environment Configuration
1. Copy `.env.example` to `.env`
2. Update database credentials in `.env`:
```env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=merch_hub
DB_USERNAME=root
DB_PASSWORD=
```

#### Database Setup
1. Start XAMPP (Apache & MySQL)
2. Create database `merch_hub` in phpMyAdmin
3. Import the database:
   - Option A: Use the SQL file in `scripts/export_database.sql`
   - Option B: Run migrations and seeders:
     ```bash
     php artisan migrate
     php artisan db:seed
     ```

#### Generate Application Key
```bash
php artisan key:generate
```

#### Create Storage Link
```bash
php artisan storage:link
```

#### Start Backend Server
```bash
php artisan serve
```
Backend will run on: http://localhost:8000

### 3. Frontend Setup (Flutter)

#### Install Flutter Dependencies
```bash
cd frontend
flutter pub get  # Install Flutter dependencies
```

#### Update API Configuration
Edit `lib/config/app_config.dart`:
```dart
class AppConfig {
  static const String baseUrl = 'http://localhost:8000'; // Update if needed
  // ... rest of config
}
```

#### Run Flutter App
```bash
flutter run
```

## Development Workflow

### Backend Development
- Backend runs on Laravel 10
- Dependencies: `composer install` (PHP packages)
- API endpoints: `http://localhost:8000/api/*`
- Database: MySQL via XAMPP
- File uploads: `storage/app/public/`

### Frontend Development
- Flutter app with Material Design
- Dependencies: `flutter pub get` (Dart packages)
- API integration via HTTP requests
- State management with setState
- Image handling with cache busting

### Optional: Root Development Scripts
- Node.js scripts in root folder (optional)
- Run `npm install` only if using development scripts
- Main project doesn't require Node.js

## File Structure
```
Merch Hub Unified/
├── backend/                 # Laravel API
│   ├── app/
│   ├── database/
│   ├── routes/
│   └── storage/
├── frontend/               # Flutter App
│   ├── lib/
│   ├── assets/
│   └── android/ios/
├── scripts/               # Setup scripts
└── docs/                 # Documentation
```

## Common Issues & Solutions

### Database Connection Issues
- Ensure XAMPP MySQL is running
- Check database credentials in `.env`
- Verify database exists in phpMyAdmin

### Flutter Dependencies
- Run `flutter clean` then `flutter pub get`
- Check Flutter version compatibility

### API Connection Issues
- Verify backend server is running on port 8000
- Check CORS settings in Laravel
- Ensure proper API endpoints in Flutter config

### File Upload Issues
- Check storage permissions in Laravel
- Verify storage link is created
- Ensure proper file paths in frontend

## API Documentation
See `backend/API_DOCUMENTATION.md` for detailed API endpoints.

## Contributing
1. Create feature branch
2. Make changes
3. Test thoroughly
4. Submit pull request

## Support
For issues, check:
1. Laravel logs: `backend/storage/logs/`
2. Flutter console output
3. Browser developer tools for API calls
