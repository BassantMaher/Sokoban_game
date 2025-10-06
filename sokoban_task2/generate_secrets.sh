#!/bin/bash

# Generate secrets for Sokoban multi-user platform
# Run this script to generate secure random secrets for your environment

echo "🔐 Generating secure secrets for Sokoban platform..."
echo ""

# Generate Phoenix secret key base
echo "SECRET_KEY_BASE=$(mix phx.gen.secret)"

# Generate JWT secret key
echo "JWT_SECRET_KEY=$(mix phx.gen.secret)"

echo ""
echo "📝 Copy these values to your .env file"
echo "⚠️  NEVER commit these secrets to version control!"
echo ""

# Optional: Generate a random admin password
ADMIN_PASSWORD=$(openssl rand -base64 12 2>/dev/null || echo "admin$(date +%s)")
echo "💡 Suggested admin password: $ADMIN_PASSWORD"
echo ""
echo "🎯 Full admin configuration:"
echo "ADMIN_EMAIL=admin@yourdomain.com"
echo "ADMIN_PASSWORD=$ADMIN_PASSWORD"
echo "ADMIN_NAME=System Administrator"