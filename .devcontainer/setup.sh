#!/bin/bash
set -e

echo "🚀 Setting up Guild Manager Rails Application..."

# Ensure rbenv is properly initialized
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

# Verify Ruby version
echo "📍 Ruby version: $(ruby --version)"

# Fix vendor directory permissions
if [ -d "vendor" ]; then
  echo "🔧 Fixing vendor directory permissions..."
  sudo chown -R vscode:vscode vendor
  sudo chmod -R u+w vendor
fi

# Configure .ruby-version
if [ ! -f ".ruby-version" ]; then
    echo "4.0.0" > .ruby-version
    echo "✅ Created .ruby-version with Ruby 4.0.0"
    gem install rails -v 8.1.0 --no-document
fi

# Check if Gemfile exists (project already initialized)
if [ ! -f "Gemfile" ]; then
  echo "📦 Creating new Rails application with PostgreSQL and Tailwind CSS..."
  
  # Create Rails app with PostgreSQL and Tailwind CSS
  rails new . --database=postgresql --css=tailwind --skip-git --force
  
  echo "✅ Rails application created!"
else
  echo "📦 Rails application already exists. Installing dependencies..."
fi

# Install Ruby dependencies
echo "💎 Installing Ruby gems..."
bundle install

# Install Node dependencies if package.json exists
if [ -f "package.json" ]; then
  echo "📦 Installing Node dependencies..."
  npm install
fi

# Wait for database to be ready
echo "⏳ Waiting for PostgreSQL to be ready..."
until pg_isready -h db -U postgres; do
  sleep 1
done

echo "Ensuring bin scripts are executable..."
chmod +x bin/*

echo "Updating RubyGems..."
gem update --system -N

echo "Installing foreman..."
gem install foreman

echo "Setup.."
bin/setup

# echo "Seeding database..."
# bin/rails db:seed

echo "Preparing test database..."
RAILS_ENV=test bin/rails db:prepare db:seed

echo "Done!"
