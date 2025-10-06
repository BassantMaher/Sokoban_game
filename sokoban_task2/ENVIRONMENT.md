# 🔐 Environment Configuration Guide

This guide explains how to properly configure environment variables for the Sokoban multi-user platform.

## 📁 Environment Files

The project supports multiple environment configurations:

- `.env` - Template file (committed to git) with default/example values
- `.env.local` - Local development overrides (not committed)
- `.env.test` - Test environment configuration
- `.env.prod` - Production environment configuration

## 🚀 Quick Setup

### 1. Copy Environment Template
```bash
# Copy the template for local development
cp .env .env.local

# Or use the setup script
./setup.sh        # Linux/Mac
setup.bat         # Windows
```

### 2. Generate Secure Secrets
```bash
# Generate secure keys
./generate_secrets.sh    # Linux/Mac
generate_secrets.bat     # Windows
```

### 3. Customize Your Configuration
Edit `.env.local` with your specific settings:

```bash
# Database (update with your PostgreSQL settings)
DATABASE_URL=postgresql://your_user:your_password@localhost:5432/sokoban_dev

# Redis (update with your Redis settings)
REDIS_URL=redis://localhost:6379

# Security (use generated secrets)
JWT_SECRET_KEY=your-generated-jwt-secret-64-chars-minimum
SECRET_KEY_BASE=your-generated-phoenix-secret-key-base

# Admin credentials (change for production!)
ADMIN_EMAIL=admin@yourdomain.com
ADMIN_PASSWORD=your-secure-admin-password
```

## 🔑 Required Environment Variables

### Database Configuration
```bash
DATABASE_URL=postgresql://user:password@host:port/database
# Or individual components:
DATABASE_HOST=localhost
DATABASE_USER=postgres
DATABASE_PASSWORD=password
DATABASE_NAME=sokoban_dev
```

### Redis Configuration
```bash
# Local Redis
REDIS_URL=redis://localhost:6379

# Upstash Redis (recommended for production)
REDIS_URL=rediss://username:password@host:port

# Redis with authentication and SSL
REDIS_URL=rediss://user:pass@redis-host.com:6380
```

### Security Configuration
```bash
# JWT token signing (generate with mix phx.gen.secret)
JWT_SECRET_KEY=minimum-64-character-secret-for-jwt-tokens

# Phoenix secret key base (generate with mix phx.gen.secret)
SECRET_KEY_BASE=minimum-64-character-secret-for-phoenix-sessions

# Session timeout (in seconds, default: 30 days)
TOKEN_EXPIRY_SECONDS=2592000
```

### Service Configuration
```bash
# Auth Service
AUTH_SERVICE_HOST=localhost
AUTH_SERVICE_PORT=4001
AUTH_SERVICE_URL=http://localhost:4001

# Game Service  
GAME_SERVICE_HOST=localhost
GAME_SERVICE_PORT=4000
GAME_SERVICE_URL=http://localhost:4000

# CORS origins (comma-separated)
CORS_ORIGINS=http://localhost:4000,http://localhost:4001
```

### Admin Configuration
```bash
# Default admin user (created during seeding)
ADMIN_EMAIL=admin@yourdomain.com
ADMIN_PASSWORD=secure-admin-password
ADMIN_NAME=System Administrator
```

## 🌍 Environment-Specific Setup

### Development Environment
Use `.env.local` for your local development settings:
```bash
MIX_ENV=dev
DATABASE_URL=postgresql://postgres:password@localhost:5432/sokoban_dev
REDIS_URL=redis://localhost:6379
```

### Test Environment
Use `.env.test` for testing:
```bash
MIX_ENV=test
DATABASE_URL=postgresql://postgres:password@localhost:5432/sokoban_test
REDIS_URL=redis://localhost:6379/1
AUTH_SERVICE_PORT=4011
GAME_SERVICE_PORT=4010
```

### Production Environment
Use `.env.prod` for production deployment:
```bash
MIX_ENV=prod
DATABASE_URL=postgresql://user:password@prod-host:5432/sokoban_prod
REDIS_URL=rediss://user:pass@upstash-host:port
FORCE_SSL=true
DATABASE_SSL=true
```

## 🔧 Loading Environment Variables

The application automatically loads environment variables using the `SokobanEnv` module:

```elixir
# Get a string value with fallback
SokobanEnv.get("REDIS_URL", "redis://localhost:6379")

# Get an integer value
SokobanEnv.get_integer("AUTH_SERVICE_PORT", 4001)

# Get a boolean value
SokobanEnv.get_boolean("FORCE_SSL", false)

# Get database configuration
SokobanEnv.database_config()

# Get Redis configuration
SokobanEnv.redis_config()
```

## 🛡️ Security Best Practices

### 1. Never Commit Secrets
- Add `.env.local`, `.env.prod` to `.gitignore`
- Only commit template files with example values
- Use different secrets for each environment

### 2. Generate Strong Secrets
```bash
# Generate 64-character secrets
mix phx.gen.secret

# Or use OpenSSL
openssl rand -base64 48
```

### 3. Rotate Secrets Regularly
- Change JWT secrets periodically
- Update admin passwords
- Rotate database credentials

### 4. Environment Separation
- Use different databases for dev/test/prod
- Use different Redis instances
- Use different admin credentials


## 🔍 Troubleshooting

### Application Won't Start
```bash
# Check if environment variables are loaded
mix run -e "IO.inspect(SokobanEnv.database_config())"

# Verify Redis connection
mix run -e "IO.inspect(SokobanEnv.redis_config())"
```

### Database Connection Issues
```bash
# Test database connection
mix ecto.create

# Check database configuration
mix run -e "IO.inspect(Application.get_env(:sokoban_task2, SokobanTask2.Repo))"
```

### Redis Connection Issues
```bash
# Test Redis connection
mix run -e "Redix.command(:redix, [\"PING\"])"
```

### JWT/Authentication Issues
- Verify `JWT_SECRET_KEY` is at least 64 characters
- Check that `SECRET_KEY_BASE` is properly set
- Ensure Redis is accessible for token storage
