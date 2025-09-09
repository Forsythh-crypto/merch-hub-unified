@echo off
echo Setting up Merch Hub Full-Stack Project...
echo.

:: Install npm dependencies
echo 📦 Installing npm dependencies...
npm install

:: Setup Laravel Backend
echo 🔧 Setting up Laravel backend...
cd backend

:: Install Composer dependencies
composer install

:: Copy environment file
if not exist .env (
    copy .env.example .env
    echo ✅ Created .env file
)

:: Generate application key
php artisan key:generate

:: Run migrations and seed database
php artisan migrate
php artisan db:seed

:: Create storage link
php artisan storage:link

cd ..

:: Setup Flutter Frontend
echo 📱 Setting up Flutter frontend...
cd frontend

:: Get Flutter dependencies
flutter pub get

:: Enable web platform if not enabled
flutter config --enable-web

cd ..

echo.
echo ✅ Setup complete!
echo.
echo 🔐 Default users created:
echo   Super Admin: superadmin@example.com (password: superadmin123)
echo   Admin: admin@example.com (password: admin123)
echo   Student: student@example.com (password: student123)
echo.
echo 🚀 To start development:
echo   npm run dev
echo.
echo 🌐 URLs:
echo   Backend API: http://localhost:8000
echo   Frontend: http://localhost:3000
echo.
pause
