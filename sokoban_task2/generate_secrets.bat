@echo off
REM Generate secrets for Sokoban multi-user platform
REM Run this script to generate secure random secrets for your environment

echo 🔐 Generating secure secrets for Sokoban platform...
echo.

REM Generate Phoenix secret key base
echo SECRET_KEY_BASE=
mix phx.gen.secret

echo.
echo JWT_SECRET_KEY=
mix phx.gen.secret

echo.
echo 📝 Copy these values to your .env file
echo ⚠️  NEVER commit these secrets to version control!
echo.

REM Generate a random admin password using PowerShell
for /f %%i in ('powershell -Command "[System.Web.Security.Membership]::GeneratePassword(12,3)"') do set ADMIN_PASSWORD=%%i

echo 💡 Suggested admin password: %ADMIN_PASSWORD%
echo.
echo 🎯 Full admin configuration:
echo ADMIN_EMAIL=admin@yourdomain.com
echo ADMIN_PASSWORD=%ADMIN_PASSWORD%
echo ADMIN_NAME=System Administrator

pause