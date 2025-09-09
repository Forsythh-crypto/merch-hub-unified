# Merch Hub - Unified Full-Stack Project

A complete marketplace application with Flutter frontend and Laravel backend, featuring role-based access control for students, admins, and super admins.

## 🏗️ Project Structure

```
Merch Hub Unified/
├── backend/                 # Laravel API Backend
│   ├── app/                # Laravel application code
│   ├── routes/api.php      # API routes
│   ├── database/           # Migrations, seeders
│   └── ...
├── frontend/               # Flutter Web/Mobile Frontend
│   ├── lib/                # Flutter application code
│   ├── pubspec.yaml        # Flutter dependencies
│   └── ...
├── docs/                   # Documentation
├── scripts/                # Development scripts
├── docker-compose.yml      # Docker setup (optional)
└── README.md              # This file
```

## 🚀 Quick Start

### Prerequisites
- XAMPP (with PHP 8.1+ and MySQL)
- Flutter SDK (3.0+)
- Node.js (16+)
- Git

### Detailed Setup
For complete setup instructions, see [SETUP.md](SETUP.md)

### Quick Commands
```bash
# Backend Setup
cd backend
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate
php artisan db:seed
php artisan serve

# Frontend Setup
cd frontend
flutter pub get
flutter run -d web

# Database Export (for sharing)
scripts/export_db.bat
```

## 🔐 Default Users

After running `php artisan db:seed`:

| Role | Email | Password |
|------|-------|----------|
| Super Admin | superadmin@example.com | superadmin123 |
| Admin | admin@example.com | admin123 |
| Student | student@example.com | student123 |

## 🛠️ Development Commands

```bash
# Start both frontend and backend
npm run dev

# Backend only
npm run backend

# Frontend only  
npm run frontend

# Create new super admin
cd backend && php artisan user:create-superadmin

# Reset database
cd backend && php artisan migrate:fresh --seed
```

## 📚 API Documentation

See [API_DOCUMENTATION.md](backend/API_DOCUMENTATION.md) for complete API reference.

## 🔧 Features

### Backend (Laravel)
- ✅ Role-based authentication (Student/Admin/SuperAdmin)
- ✅ JWT token authentication with Laravel Sanctum
- ✅ Department-based access control
- ✅ RESTful API endpoints
- ✅ File upload support
- ✅ Database migrations and seeders

### Frontend (Flutter)
- ✅ Cross-platform (Web/Mobile)
- ✅ Role-based UI rendering
- ✅ HTTP API integration
- ✅ State management
- ✅ Responsive design
- ✅ Authentication flow

## 🐳 Docker Support (Optional)

```bash
# Start all services
docker-compose up -d

# Access:
# Frontend: http://localhost:3000
# Backend: http://localhost:8000
# Database: localhost:3306
```

## 📱 Platforms Supported

- ✅ Web (Chrome, Firefox, Safari, Edge)
- ✅ Android
- ✅ iOS
- ✅ Windows
- ✅ macOS
- ✅ Linux

## 🤝 Contributing

1. Make changes in respective `backend/` or `frontend/` directories
2. Test both applications
3. Update documentation if needed
4. Submit pull request

## 📄 License

This project is licensed under the MIT License.
