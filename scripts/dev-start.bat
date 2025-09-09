@echo off
echo Starting Merch Hub Development Environment...
echo.

:: Check if Node.js is installed
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Node.js is not installed. Please install Node.js first.
    pause
    exit /b 1
)

:: Check if PHP is installed
php --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ PHP is not installed. Please install PHP first.
    pause
    exit /b 1
)

:: Check if Flutter is installed
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Flutter is not installed. Please install Flutter first.
    pause
    exit /b 1
)

:: Install npm dependencies if not exists
if not exist node_modules (
    echo 📦 Installing npm dependencies...
    npm install
)

:: Setup backend if not setup
if not exist backend\.env (
    echo 🔧 Setting up Laravel backend...
    cd backend
    composer install
    copy .env.example .env
    php artisan key:generate
    php artisan migrate
    php artisan db:seed
    cd ..
)

:: Setup frontend if not setup
if not exist frontend\pubspec.lock (
    echo 🔧 Setting up Flutter frontend...
    cd frontend
    flutter pub get
    cd ..
)

echo.
echo ✅ Setup complete! Starting development servers...
echo.
echo 🌐 Backend will be available at: http://localhost:8000
echo 📱 Frontend will be available at: http://localhost:3000
echo.

:: Start both servers
npm run dev
