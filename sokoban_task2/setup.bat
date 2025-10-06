@echo off
REM Sokoban Multi-User Platform Setup Script
REM This script helps set up your development environment

echo 🎮 Sokoban Multi-User Platform Setup
echo ====================================
echo.

REM Check if .env already exists
if exist ".env.local" (
    echo ⚠️  .env.local file already exists. Skipping environment setup.
    echo    If you want to reset, delete .env.local and run this script again.
) else (
    echo 📝 Creating .env.local file from template...
    copy .env .env.local >nul 2>&1
    if errorlevel 1 (
        echo # Copy from .env template and customize > .env.local
    )
    echo ✅ Created .env.local - please customize with your settings
)

echo.
echo 🔧 Installing dependencies...
mix deps.get

echo.
echo 📦 Installing Node.js dependencies...
cd apps\game_service\assets && npm install && cd ..\..\..

echo.
echo 🗄️  Setting up database...
mix ecto.create
mix ecto.migrate
mix run priv\repo\seeds.exs

echo.
echo 🎉 Setup complete!
echo.
echo 📋 Next steps:
echo 1. Customize your .env.local file with your database and Redis settings
echo 2. Generate secure secrets with: generate_secrets.bat
echo 3. Start the application with: mix phx.server
echo.
echo 🌐 Access points:
echo    • Game UI: http://localhost:4000
echo    • Auth API: http://localhost:4001/api
echo.
echo 👤 Default admin credentials:
echo    • Email: admin@example.com
echo    • Password: password
echo.
echo ⚠️  Remember to change the admin password in production!

pause