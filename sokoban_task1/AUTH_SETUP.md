# Sokoban Game - Authentication Setup Guide

## Overview
This is a clean, incremental authentication system for the Sokoban game built with Phoenix LiveView and Ecto.

## Features Implemented

### 1. Database Setup
- PostgreSQL database with Ecto
- Users table with:
  - `email` (unique)
  - `password_hash` (Pbkdf2 encrypted - pure Elixir, no C compiler needed)
  - `role` (admin/user)
  - timestamps

### 2. User Authentication
- **Registration**: Create new accounts with email, password, and role selection
- **Login**: Authenticate with email and password
- **Anonymous Mode**: Play without registration (no database link)
- **Logout**: Clear session and return to login

### 3. Authorization
- Protected routes requiring authentication or anonymous mode
- Admin role support for future features
- Session-based authentication

### 4. User Interface
- Beautiful login page with email/password form
- "Play as Anonymous" button for guest access
- Registration page with role selection
- Game page shows current user info (or anonymous status)
- Logout button in game interface

## Setup Instructions

### 1. Install Dependencies
```cmd
cd d:\bassant\Freelancing\sokoban-game\sokoban_task1
mix deps.get
```

### 2. Configure Database
Make sure PostgreSQL is running and update credentials in `config/dev.exs` if needed:
- Username: `postgres`
- Password: `postgres`
- Database: `sokoban_task1_dev`

### 3. Create Database and Run Migrations
```cmd
mix ecto.create
mix ecto.migrate
```

### 4. Start the Server
```cmd
mix phx.server
```

### 5. Access the Application
Open your browser to: http://localhost:4000

## User Flow

### First Time User
1. Visit http://localhost:4000 → Redirects to `/login`
2. Click "Don't have an account? Register here"
3. Fill in email, password, and select role (User or Admin)
4. Click "Create Account"
5. Redirected to login page
6. Enter credentials and click "Sign in"
7. Game opens with user info displayed

### Returning User
1. Visit http://localhost:4000 → Redirects to `/login`
2. Enter email and password
3. Click "Sign in"
4. Game opens

### Anonymous User
1. Visit http://localhost:4000 → Redirects to `/login`
2. Click "🎭 Play as Anonymous" button
3. Game opens immediately (no database connection)
4. User info shows "Playing as Anonymous"

### Logout
- Click the "Logout" button in the top-right of the game page
- Returns to login page

## Routes

| Route | Purpose | Authentication Required |
|-------|---------|------------------------|
| `/` | Redirects to login | No |
| `/login` | Login page | No (redirects to game if already logged in) |
| `/register` | Registration page | No (redirects to game if already logged in) |
| `/game` | Game interface | Yes (user or anonymous) |
| `/logout` | Clear session | No |
| `/auth/login_user/:id` | Internal: Set user session | No |
| `/auth/login_anonymous` | Internal: Set anonymous session | No |

## Key Files

### Authentication
- `lib/sokoban_task1/accounts.ex` - User management context
- `lib/sokoban_task1/accounts/user.ex` - User schema with validation
- `lib/sokoban_task1_web/auth.ex` - Authentication plug
- `priv/repo/migrations/20250107000001_create_users.exs` - Users table migration

### Controllers
- `lib/sokoban_task1_web/controllers/auth_controller.ex` - Session management
- `lib/sokoban_task1_web/controllers/session_controller.ex` - Logout
- `lib/sokoban_task1_web/controllers/page_controller.ex` - Root redirect

### LiveViews
- `lib/sokoban_task1_web/live/login_live.ex` - Login interface
- `lib/sokoban_task1_web/live/register_live.ex` - Registration interface
- `lib/sokoban_task1_web/live/game_live.ex` - Game interface (updated with auth)

### Configuration
- `config/config.exs` - General config with ecto_repos
- `config/dev.exs` - Development database config
- `config/test.exs` - Test database config
- `lib/sokoban_task1/repo.ex` - Ecto repository
- `lib/sokoban_task1/application.ex` - App supervision tree (includes Repo)

## Database Schema

```sql
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  email VARCHAR(160) NOT NULL UNIQUE,
  password_hash VARCHAR NOT NULL,
  role VARCHAR NOT NULL DEFAULT 'user',
  inserted_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE UNIQUE INDEX users_email_index ON users (email);
```

## Security Features

1. **Password Hashing**: Uses Pbkdf2 for secure password storage (pure Elixir - no Windows compilation issues)
2. **Session Management**: Phoenix sessions with secure cookie signing
3. **CSRF Protection**: Built-in Phoenix CSRF protection
4. **Timing Attack Prevention**: Consistent-time password verification
5. **Email Validation**: Format and uniqueness checking
6. **Role-based Access**: Admin/User role support

## Why Pbkdf2 Instead of Bcrypt?

This project uses `pbkdf2_elixir` instead of `bcrypt_elixir` because:
- **Pure Elixir**: No C compilation required (avoids "nmake not found" errors on Windows)
- **No External Dependencies**: Works on all platforms without additional setup
- **Industry Standard**: Pbkdf2 is a well-tested, secure password hashing algorithm
- **Easy Setup**: Just `mix deps.get` - no compiler toolchain needed

## Testing the System

### Create an Admin User
```cmd
iex -S mix

# In IEx console:
SokobanTask1.Accounts.register_user(%{
  email: "admin@sokoban.com",
  password: "admin123",
  role: "admin"
})
```

### Create a Regular User
```cmd
# In IEx console:
SokobanTask1.Accounts.register_user(%{
  email: "user@sokoban.com",
  password: "user123",
  role: "user"
})
```

## Next Steps (Future Enhancements)

1. **Game Progress Tracking**: Save game state for logged-in users
2. **Leaderboard**: Track scores and completion times
3. **Level Management**: Admin interface to create/edit levels
4. **Password Reset**: Email-based password recovery
5. **Email Verification**: Confirm email addresses
6. **Profile Management**: Update email, password, etc.
7. **Game History**: Track all completed games per user

## Troubleshooting

### Database Connection Error
- Ensure PostgreSQL is running
- Check credentials in `config/dev.exs`
- Try: `mix ecto.reset` to recreate the database

### Migration Error
- Run: `mix ecto.drop && mix ecto.create && mix ecto.migrate`

### Dependencies Not Found
- Run: `mix deps.get`
- Try: `mix deps.clean --all && mix deps.get`

### Server Won't Start
- Check if port 4000 is available
- Look for error messages in the console
- Try: `mix deps.compile` to recompile dependencies

## Architecture Notes

### MVC Pattern
- **Model**: `SokobanTask1.Accounts.User` + `SokobanTask1.Accounts` context
- **View**: LiveView templates in `LoginLive`, `RegisterLive`, `GameLive`
- **Controller**: Event handlers in LiveViews + helper controllers for session

### Authentication Flow
1. User submits login form
2. LiveView validates credentials via `Accounts.authenticate_user/2`
3. On success, redirects to AuthController
4. AuthController sets session via `Auth.log_in_user/2`
5. Redirects to `/game`
6. `fetch_current_user` plug loads user from session
7. `require_authenticated_or_anonymous` plug protects route
8. GameLive mounts with user info from socket assigns

### Anonymous Mode
- No user record created
- Session flag `anonymous: true` set
- Game operates normally
- No database persistence for anonymous users
