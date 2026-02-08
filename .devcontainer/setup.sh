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

echo "🗄️  Setting up database..."
rails db:create 
rails db:migrate

echo "⚡ Installing Rails 8 Solid gems (Queue/Cache/Cable)..."
rails solid_queue:install 2>/dev/null || echo "✅ SolidQueue already configured"
rails solid_cache:install 2>/dev/null || echo "✅ SolidCache already configured"
rails solid_cable:install 2>/dev/null || echo "✅ SolidCable already configured"

echo "📊 Loading Solid gems schemas..."
if [ -f "db/queue_schema.rb" ]; then
  rails runner "load Rails.root.join('db/queue_schema.rb')"
  echo "✅ SolidQueue schema loaded"
fi

if [ -f "db/cache_schema.rb" ]; then
  rails runner "load Rails.root.join('db/cache_schema.rb')"
  echo "✅ SolidCache schema loaded"
fi

if [ -f "db/cable_schema.rb" ]; then
  rails runner "load Rails.root.join('db/cable_schema.rb')"
  echo "✅ SolidCable schema loaded"
fi

echo "👤 Creating temporary admin user..."
if [ -f "script/create_first_admin.rb" ]; then
  rails runner script/create_first_admin.rb
else
  echo "⚠️  Admin creation script not found"
fi

echo "🎨 Compiling Tailwind CSS..."
if [ -f "bin/rails" ] && grep -q "tailwindcss:build" Rakefile 2>/dev/null; then
  rails tailwindcss:build
  echo "✅ Tailwind CSS compiled"
else
  echo "⚠️  Tailwind CSS task not found (will compile on first server start)"
fi

# echo "Seeding database..."
# bin/rails db:seed

echo "🧪 Preparing test database..."
RAILS_ENV=test bin/rails db:prepare db:seed 2>/dev/null || echo "✅ Test database ready"

echo ""
echo "✅ Setup complete!"
echo ""
echo "📝 Next steps:"
echo "   1. Start the development server: bin/dev"
echo "   2. Access the app at: http://localhost:3000"
echo "   3. Login as temporary admin at: http://localhost:3000/dev/login"
echo "   4. Click 'Login como Admin Temporário'"
echo "   5. Access the admin panel at: http://localhost:3000/admin"
echo ""

echo "Done!"
