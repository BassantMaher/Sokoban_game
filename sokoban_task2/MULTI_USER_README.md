# 🎮 Multi-User Sokoban Platform - Microservices Edition

A sophisticated, multi-user Sokoban puzzle platform built with **Elixir**, **Phoenix LiveView**, and **microservices architecture**. Features user authentication, role-based access, real-time leaderboards, and admin-managed puzzle creation.

![Architecture](https://img.shields.io/badge/Architecture-Microservices-blue) ![Elixir](https://img.shields.io/badge/Elixir-1.15+-purple) ![Phoenix](https://img.shields.io/badge/Phoenix-LiveView-orange) ![Redis](https://img.shields.io/badge/Redis-JWT_Storage-red) ![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Database-blue)

## 🏗️ Architecture Overview

### Microservices Design
- **Auth Service** (`apps/auth_service`): Handles user management, authentication, JWT tokens
- **Game Service** (`apps/game_service`): Manages gameplay, levels, scores, LiveView frontend
- **Shared Database**: PostgreSQL with Ecto schemas
- **Inter-Service Communication**: HTTP/REST API calls with Tesla client
- **Session Storage**: Redis for JWT token persistence (Upstash compatible)

```
┌─────────────────┐    HTTP/REST    ┌─────────────────┐
│   Game Service  │◄───────────────►│   Auth Service  │
│   Port 4000     │    (Tesla)      │   Port 4001     │
│                 │                 │                 │
│ ┌─────────────┐ │                 │ ┌─────────────┐ │
│ │ LiveView UI │ │                 │ │ JSON API    │ │
│ │ Leaderboard │ │                 │ │ JWT/Guardian│ │
│ │ Game Board  │ │                 │ │ User Mgmt   │ │
│ │ Admin Panel │ │                 │ │ Role Control│ │
│ └─────────────┘ │                 │ └─────────────┘ │
└─────────────────┘                 └─────────────────┘
         │                                   │
         └─────────────┬─────────────────────┘
                       │
         ┌─────────────▼─────────────┐
         │   Shared PostgreSQL       │
         │   (Users, Roles, Levels,  │
         │    Scores, Sessions)      │
         └─────────────┬─────────────┘
                       │
         ┌─────────────▼─────────────┐
         │     Redis / Upstash       │
         │   (JWT Token Storage)     │
         └───────────────────────────┘
```

## ✨ Features

### 🔐 **Authentication & Authorization**
- **Registration/Login**: Secure user registration with bcrypt password hashing
- **JWT Tokens**: Guardian-based JWT tokens stored in Redis with 30-day expiration
- **Role-Based Access**: Anonymous, Player, and Admin roles with different permissions
- **Session Management**: Server-side token validation and revocation

### 🎯 **Role Capabilities**
- **Anonymous**: 
  - Play games without login
  - Scores not saved or displayed
  - Limited access to features
- **Player**: 
  - Full game access with score tracking
  - Leaderboard participation
  - Personal score history
- **Admin**: 
  - All player capabilities
  - Create and manage puzzle levels
  - Access to admin dashboard
  - Daily level creation tools

### 🎮 **Game Features**
- **Multi-Level Platform**: Database-driven level system
- **Real-Time Leaderboard**: Live updates showing top players
- **Score Tracking**: Moves and time tracking for competitive play
- **Advanced Game Logic**: Extended from Task 1 with multi-level support
- **Responsive UI**: Beautiful purple-themed interface with animations

## 🚀 Quick Start

### Prerequisites
- **Elixir 1.15+** and **Erlang/OTP 26+**
- **PostgreSQL 12+**
- **Redis** (local or Upstash)

### Setup Commands

```bash
# Clone and setup
git clone https://github.com/BassantMaher/Sokoban_game.git
cd Sokoban_game/sokoban_task2

# Install dependencies
mix deps.get
cd apps/game_service/assets && npm install && cd ../../..

# Setup database
mix ecto.create
mix ecto.migrate
mix run priv/repo/seeds.exs

# Start services
mix phx.server
```

### Access Points
- **Game Service**: http://localhost:4000 (Main UI)
- **Auth Service API**: http://localhost:4001/api (Backend)

### Default Credentials
- **Admin**: admin@example.com / password
- **Player**: Register at game service

## 🎮 Usage Guide

### 1. **Registration & Login**
Visit `http://localhost:4000` and:
- Create a new player account
- Or login with admin credentials

### 2. **Playing Games**
- **Anonymous**: Play without registration (scores not saved)
- **Player**: Login to save scores and appear on leaderboard
- **Admin**: Full access plus level creation

### 3. **Leaderboard**
Landing page shows top 10 players with:
- Player name, best score, level completed, completion time

### 4. **Admin Features**
Admins can access `/admin/levels/new` to create new puzzle levels

## 🏗️ Project Structure

```
sokoban_task2/
├── apps/
│   ├── auth_service/              # Authentication microservice
│   │   ├── lib/auth_service/
│   │   │   ├── accounts/          # User, Role, Score, Level schemas
│   │   │   ├── accounts.ex        # Context for user management
│   │   │   └── guardian.ex        # JWT implementation
│   │   └── lib/auth_service_web/
│   │       ├── controllers/       # JSON API controllers
│   │       └── router.ex          # API routes
│   │
│   └── game_service/              # Game & UI microservice
│       ├── lib/game_service/
│       │   ├── game/game.ex       # Extended game logic from Task 1
│       │   └── auth_client.ex     # HTTP client for Auth Service
│       ├── lib/game_service_web/
│       │   ├── live/              # Phoenix LiveView components
│       │   └── plugs/             # Authentication plugs
│       └── assets/                # Frontend assets with purple theme
│
├── config/                        # Shared configuration
├── priv/repo/                     # Database migrations & seeds
├── lib/repo.ex                    # Shared Ecto repository
└── mix.exs                        # Umbrella project config
```

## 🔧 API Endpoints

### Auth Service (Port 4001)
```
POST /api/register     - Register new user
POST /api/login        - User login
DELETE /api/logout     - User logout
POST /api/verify       - Verify JWT token
GET /api/user/:id      - Get user details
```

### Game Service (Port 4000)
```
GET /                  - Landing page with leaderboard
GET /game/:level_id    - Play specific level
GET /admin/levels/new  - Create new level (admin only)
```

## 📊 Challenges & Solutions

### Challenges Addressed
1. **Inter-Service Latency**: HTTP calls between services add latency
   - *Solution*: Local caching, async operations where possible

2. **Database Bottlenecks**: Shared database could become bottleneck
   - *Solution*: Connection pooling, read replicas for scaling

3. **Redis Dependency**: Critical path dependency on Redis
   - *Solution*: Redis clustering, fallback mechanisms

### Methodology
- **Shared Repository**: Simplified development while maintaining service boundaries
- **REST Communication**: Simple, debuggable inter-service communication
- **Stateless Services**: Each service can be scaled independently
- **Database-First**: Single source of truth with proper relationships

## 🔒 Security Features

- **Password Hashing**: bcrypt with salt
- **JWT Tokens**: Signed and stored server-side in Redis
- **CORS Protection**: Configured for cross-origin requests
- **Input Validation**: Server-side validation on all inputs
- **Role-Based Authorization**: Granular access control
- **Session Management**: Token expiration and revocation

## 🧪 Testing

```bash
# Run all tests
mix test

# Test specific service
cd apps/auth_service && mix test
cd apps/game_service && mix test

# Test with coverage
mix test --cover
```

## 🚀 Deployment

### Environment Variables
```bash
# Database
DATABASE_URL="postgresql://user:pass@host:5432/sokoban_prod"

# Redis
UPSTASH_REDIS_URL="redis://upstash-host:port"

# Secrets
SECRET_KEY_BASE="your-64-char-secret"
JWT_SECRET_KEY="your-jwt-secret"
```

## 🎯 Future Enhancements

- [ ] **Real-time Multiplayer**: WebSocket-based multiplayer games
- [ ] **Level Editor UI**: Visual level creation interface
- [ ] **Tournament System**: Organized competitions with brackets
- [ ] **Social Features**: Friend systems, challenges, chat
- [ ] **Mobile App**: React Native or Flutter mobile client
- [ ] **Analytics Dashboard**: Game statistics and user behavior

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## 📝 License

This project is licensed under the MIT License.

---

**Built with ❤️ using Elixir, Phoenix LiveView, and Microservices Architecture**

🎮 **Happy Gaming!** 🎮