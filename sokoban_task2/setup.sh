#!/bin/bash

# Sokoban Multi-User Platform Setup Script
# This script helps set up your development environment

echo "🎮 Sokoban Multi-User Platform Setup"
echo "===================================="
echo ""

# Check if .env already exists
if [ -f ".env" ]; then
    echo "⚠️  .env file already exists. Skipping environment setup."
    echo "   If you want to reset, delete .env and run this script again."
else
    echo "📝 Creating .env file from template..."
    cp .env .env.local 2>/dev/null || echo "# Copy from .env template and customize" > .env.local
    echo "✅ Created .env.local - please customize with your settings"
fi

echo ""
echo "🔧 Installing dependencies..."
mix deps.get

echo ""
echo "📦 Installing Node.js dependencies..."
cd apps/game_service/assets && npm install && cd ../../..

echo ""
echo "🗄️  Setting up database..."
mix ecto.create
mix ecto.migrate
mix run priv/repo/seeds.exs

echo ""
echo "🎉 Setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Customize your .env.local file with your database and Redis settings"
echo "2. Generate secure secrets with: ./generate_secrets.sh"
echo "3. Start the application with: mix phx.server"
echo ""
echo "🌐 Access points:"
echo "   • Game UI: http://localhost:4000"
echo "   • Auth API: http://localhost:4001/api"
echo ""
echo "👤 Default admin credentials:"
echo "   • Email: admin@example.com"
echo "   • Password: password"
echo ""
echo "⚠️  Remember to change the admin password in production!"