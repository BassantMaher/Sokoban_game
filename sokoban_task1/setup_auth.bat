@echo off
echo ================================================
echo Sokoban Game - Authentication Setup Script
echo ================================================
echo.

echo Step 1: Cleaning old dependencies...
call mix deps.clean bcrypt_elixir --unlock

echo.
echo Step 2: Getting dependencies...
call mix deps.get

echo.
echo Step 3: Compiling dependencies...
call mix deps.compile

echo.
echo Step 4: Creating database...
call mix ecto.create

echo.
echo Step 5: Running migrations...
call mix ecto.migrate

echo.
echo ================================================
echo Setup Complete!
echo ================================================
echo.
echo Now you can start the server with: mix phx.server
echo.
echo Then visit: http://localhost:4000
echo.
pause
