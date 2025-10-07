# 🤖 AI Development Prompts - Sokoban Game Project

This document contains all the prompts used to build the Sokoban Game with Elixir Phoenix LiveView, documenting the development journey, successes, and challenges encountered.

---

## 📚 Initial Learning Phase

### Prompt 1: Understanding Elixir Programming
```
What is Elixir programming and where is it used?
```

**Purpose**: Understanding the fundamentals of Elixir before starting the project.

---

### Prompt 2: Phoenix Framework Overview
```
Explain Phoenix framework
```

**Purpose**: Learning about Phoenix web framework and its ecosystem.

---

### Prompt 3: Phoenix LiveView Project Structure
```
Explain Phoenix project structure for a LiveView game app.
```

**Purpose**: Understanding how to organize a LiveView-based game application.

---

## 🏗️ Architecture & Design Phase

### Prompt 4: Database Selection & Architecture
```
What is the Best database for Elixir Sokoban game? Design architecture for single-player that can be scalable for multi-player and admins.
```

**Purpose**: Determining the optimal database choice and designing a scalable architecture from the start.

**Result**: Chose PostgreSQL with Ecto for its reliability, ACID compliance, and excellent Elixir integration.

---

### Prompt 5: Game Logic Structure
```
Provide an Elixir structure for a Sokoban board with push validation.
```

**Purpose**: Designing the core game logic with proper immutable data structures and validation.

---

## 🎮 Core Game Implementation

### Prompt 6: Complete Game Generation
```
You are an expert Elixir and Phoenix developer. Generate a complete, working single-player Sokoban game clone as a Phoenix web app using LiveView for the reactive frontend. 

**Requirements:**
- **Tech Stack**: Elixir 1.15+, Phoenix 1.7+ with LiveView (no separate JS framework). Use Tailwind CSS for styling.
- **Game Rules**:
  - Board: Represent as a list of strings (immutable). Symbols: `#` (wall), `@` (player, yellow square), `$` (box, red), `.` (goal, green), ` ` (empty, white).
  - Player moves: All 4 directions via keyboard (WASD or arrow keys). JS hook in LiveView captures keys and sends events.
  - Pushing: Only push adjacent box if the space behind it is empty (no pulling, no pushing multiple boxes or into walls).
  - Win: All boxes on goals (detect via counting boxes on `.` positions—no loose `$`).
  - UI: 2D CSS grid (e.g., 8x6 cells, 32px each). Reset button. Message for "You won!" or instructions.
- **Architecture**: Follow **MVC pattern** adapted for LiveView:
  - **Model**: Pure Elixir struct/logic in a separate module (no side effects).
  - **View**: HEEx template in LiveView for rendering (loop over board for grid).
  - **Controller**: LiveView module handles events (mount for init, handle_event for moves/reset).
- **No Database**: In-memory only (state in LiveView assigns)—session-based, lost on refresh.
- **Scalability/Immutability**: Use structs for game state; each move returns a new struct.
- **File Structure**: Generate code for a fresh `mix phx.new sokoban_task1 --live --no-ecto` project. Ensure correct paths:

sokoban_task1/
├── lib/sokoban_task1/game.ex              # Model: %Game{} struct, new_level/0, move/2 (with push validation), check_win?/1
├── lib/sokoban_task1_web/live/game_live.ex # Controller + View: mount/3, handle_event/3 ("move" with dir, "reset"), render/1 (HEEx grid)
├── lib/sokoban_task1_web/router.ex        # Scope: live "/", GameLive
├── assets/css/app.css                     # Tailwind imports + custom (e.g., .wall { background: gray; })
├── assets/js/app.js                       # LiveView hooks: KeyboardListener for key events (up/down/left/right)
├── test/sokoban_task1_web/live/game_live_test.exs # Basic tests: e.g., push succeeds, win detects
└── config/config.exs                      # Basic setup (no Ecto)

- **Sample Level** (hardcode in new_level/0):
#######
#@ $  #
#  . .#
#     #
#######

**Key Features**:
- Reactive: Keypress → WebSocket event → Server updates state → DOM diff/patch (only changed cells).
- Validation: Server-side only (prevent cheats). Ignore invalid moves (out of bounds, wall, can't push).
- Win Detection: After each move, check if all `$` are on `.` (e.g., via Enum.count and position matching).
- **Edge Cases**: Can't push into wall/another box; player can't occupy wall; focus board for keys.

**Output Format**:
- Start with setup commands: `mix phx.new sokoban_task1 --live --no-ecto && cd sokoban_task1 && mix deps.get`.
- Then, provide full code for each key file (e.g., // game.ex contents).
- End with run command: `mix phx.server` and test notes (e.g., http://localhost:4000, use arrows to push box to goal).
- Include a brief README snippet for challenges (e.g., "Immutable string swaps used charlists.").

Generate the code now—make it runnable out-of-the-box!
```

**Purpose**: Generate the complete single-player game with proper architecture and best practices.

**Result**: ✅ Successfully created a fully functional Sokoban game with LiveView.

---

## 🎨 UI/UX Enhancement Phase

### Prompt 7: Visual Theme Upgrade
```
Edit the app.css styles to make the theme shades of purple and add gradient purple background, then remove the man @ symbol and add the man image in the assets folder and remove the $ for boxes and add the box image in the assets folder
```

**Purpose**: Transform the basic UI into a modern, visually appealing purple-themed interface with custom graphics.

**Result**: ✅ Implemented animated purple gradients, glassmorphism effects, and custom image assets.

---

## 🏢 Microservices Architecture Exploration

### Prompt 8: Umbrella App Structure
```
Explain umbrella app structure in details
```

**Purpose**: Understanding Elixir umbrella applications for microservices architecture.

**Result**: ✅ Learned about umbrella apps but decided on monolithic approach for simplicity.

---

## 💾 Database Integration Phase

### Prompt 9: Adding Ecto and PostgreSQL
```
Add Ecto PG for users/roles/scores/levels to existing LiveView app.
```

**Purpose**: Integrate database support for persistent data storage.

**Result**: ✅ Successfully integrated PostgreSQL with proper schema design:
- `users` table (email, password_hash, role)
- `levels` table (name, difficulty, board_data, order, description)
- `scores` table (user_id, level_id, time_seconds, moves, completed_at)

---

## 🔐 Authentication & Microservices Attempt

### Prompt 10: Redis JWT Integration (Microservices Attempt)
```
Integrate Upstash Redis for JWT token storage in Phoenix sessions, we will be working with microservices, authentication is a microservice and the game logic is a separate microservice using umbrella app structure
```

**Purpose**: Attempt to split the application into microservices with separate auth service.

**Result**: ❌ **FAILED** - The integration was too complicated. The AI agent struggled to properly coordinate between microservices, manage JWT tokens, and handle cross-service communication. The complexity outweighed the benefits for this project size.

**Decision**: Reverted to monolithic architecture with session-based authentication using Pbkdf2.

---

## 👑 Admin Features Implementation

### Prompt 11: Admin Role & Level Creator
```
Add admin role and puzzle creator for admins to create new levels and save them in the database
```

**Purpose**: Implement role-based access control and admin dashboard for level management.

**Result**: ✅ Successfully created:
- Role-based authentication (admin/user)
- Admin dashboard with level creation form
- Live preview with visual blocks
- Auto-padding feature for consistent board dimensions
- Level validation and sanitization

---

### Prompt 12: Admin Seeder
```
Create admin seeders that runs during project first run
```

**Purpose**: Automate admin user creation for initial setup.

**Result**: ✅ Created seed scripts for initial admin and sample levels.

---

## 🏆 Leaderboard System

### Prompt 13: Leaderboard Implementation
```
Add a leaderboard landing page to display top players from the database
```

**Purpose**: Create competitive ranking system with global and per-level leaderboards.

**Result**: ✅ Implemented:
- Per-level leaderboard (best score per user)
- Global leaderboard (most levels completed, best average time)
- Optimized queries with subqueries to prevent N+1 issues
- Full-width purple-themed responsive UI
- Top 3 badges (🥇 🥈 🥉)

---

## 🐛 Troubleshooting Phase

### Prompt 14: Bcrypt & OpenSSL Error
```
How to fix bcrypt_elixir error and openSSL
```

**Purpose**: Resolve compilation errors with bcrypt native dependencies.

**Result**: ✅ Switched from bcrypt_elixir to pbkdf2_elixir for better cross-platform compatibility.

---

## 🔧 Manual Fixes & Version Compatibility

### Issue 1: Authentication Form HTML Deprecation
**Problem**: The AI agent failed to integrate the auth form HTML correctly due to version deprecations between Phoenix versions.

**Solution**: ✅ Manually read the Phoenix LiveView documentation and discovered breaking changes in form helpers between versions. Fixed by:
- Replacing deprecated `<.input>` components with standard HTML `<input>` elements
- Updating form submission handlers to match Phoenix 1.7+ conventions
- Properly structuring `<.form>` components with correct LiveView bindings

**Lesson Learned**: Always verify generated code against official documentation, especially when dealing with rapidly evolving frameworks.

---

### Issue 2: Microservices Integration Failure
**Problem**: The AI agent failed to create a proper microservices architecture with umbrella apps.

**Challenges**:
1. Complex inter-service communication setup
2. JWT token management across services
3. Shared code and dependencies between auth and game services
4. Network latency overhead for local development
5. Debugging difficulties across multiple processes
6. Database connection pooling conflicts

**Solution**: ✅ Reverted to **monolithic architecture** with proper context separation:
- `Accounts` context for user management
- `Levels` context for level data
- `Scores` context for performance tracking
- `Web` layer for LiveView components

**Lesson Learned**: Microservices add significant complexity and are often unnecessary for applications of this size. Phoenix's context-based architecture provides excellent separation of concerns without the overhead of distributed systems.

---

## 📊 Advanced Features Added

### Prompt 15: UI Modernization
```
Make the UI of the admin modern and clear and make the admin container as 100% wide and the preview also, I want vertical scrolling not horizontal
```

**Purpose**: Modernize admin dashboard with full-width responsive design.

**Result**: ✅ Implemented:
- Single-column full-width layout
- Responsive card grid for existing levels
- Improved form grouping (2-column and 3-column grids)
- Better board preview with overflow handling
- Modern purple theme throughout

---

### Prompt 16: Login/Register Theme Consistency
```
Change the register and login CSS to match the application theme, change to purple
```

**Purpose**: Ensure consistent purple theme across all pages.

**Result**: ✅ Updated:
- Login page with purple gradient background
- Register page matching theme
- Purple input borders and focus states
- Gradient buttons with hover effects
- Glassmorphism effects with backdrop blur

---

### Prompt 17: Comprehensive Documentation
```
Make a full readme with all the project details by explaining the methodology and the implementation details and the database structure and schema and how its linked and user roles, levels and creation, scoring system and admin dashboard and admin level creation and how leaderboard works and add this demo link for task 1 and leave a space for task 2 video link
```

**Purpose**: Create detailed technical documentation for the project.

**Result**: ✅ Created comprehensive README.md covering:
- Complete architecture explanation
- Database schema diagrams
- Implementation methodology
- User authentication flow
- Scoring system details
- Admin dashboard workflow
- Leaderboard query optimization
- Security features
- Installation instructions
- Project structure

---

## 🎯 Key Takeaways

### ✅ Successes
1. **Phoenix LiveView**: Excellent for real-time game state management
2. **PostgreSQL + Ecto**: Powerful database integration with great query builder
3. **Context-based Architecture**: Clean separation without microservices complexity
4. **Purple Theme**: Consistent, modern, and visually appealing design
5. **Auto-padding Feature**: Prevents jagged level layouts in admin panel
6. **Optimized Queries**: Subquery approach for leaderboards performs excellently
7. **Session-based Auth**: Simple, secure, and effective with Pbkdf2

### ❌ Failures & Lessons
1. **Microservices Attempt**: Too complex for this project size; monolith is better
2. **Version Deprecations**: Always verify against official docs, not just AI output
3. **Bcrypt Issues**: Native dependencies can cause cross-platform problems
4. **Component Libraries**: Phoenix 1.7+ changed form helpers significantly

### 💡 Best Practices Learned
1. Start simple, scale when needed (YAGNI principle)
2. Context-based architecture provides good boundaries without microservices overhead
3. Database indexing matters for leaderboard performance
4. Immutable data structures make game logic predictable
5. Server-side validation prevents cheating in browser-based games
6. Proper foreign key cascades prevent orphaned records
7. Preloading associations prevents N+1 query problems

---

**Note**: This document serves as a record of the development journey, including both successes and failures. The microservices failure was a valuable learning experience that reinforced the principle of choosing the right architecture for the problem at hand.

**Built with**: Elixir, Phoenix, LiveView, PostgreSQL, and a lot of iteration! 🚀
