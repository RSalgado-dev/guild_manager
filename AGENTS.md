# Repository Guidelines

## Project Structure & Module Organization

This is a Rails 8.1 guild management app using Ruby 4.0.0, PostgreSQL, Discord OAuth, ActiveAdmin, Hotwire, and Tailwind. Main code lives in `app/`: models in `app/models`, controllers in `app/controllers`, access-facing controllers in `app/controllers/access`, views in `app/views`, admin resources in `app/admin`, and jobs/services in `app/jobs` and `app/services`. Assets are under `app/assets`; static pages and icons are in `public/`. Database schema and migrations are in `db/`. Tests mirror app structure under `test/`, with fixtures in `test/fixtures`.

## Build, Test, and Development Commands

Run every command inside the development container, never on the host machine. Use Rails binstubs when possible:

- Existing container name: `guild_manager_devcontainer-app-1`.
- Command wrapper:
  `docker exec guild_manager_devcontainer-app-1 bash -lc 'export PATH=/home/vscode/.rbenv/bin:/home/vscode/.rbenv/shims:$PATH; cd /workspace && <command>'`
- Example: replace `<command>` with `bin/rails test`, `bin/rubocop`, `bin/ci`, `bin/rails db:migrate`, or `bin/dev`.

- `bundle install` installs Ruby dependencies.
- `bin/setup` prepares the app for local development.
- `bin/dev` starts the development server and Tailwind watcher.
- `bin/rails db:prepare` creates, migrates, and seeds the database as needed.
- `bin/rails test` runs the Minitest suite.
- `bin/rails test test/models/user_test.rb` runs one test file.
- `bin/rubocop` checks Ruby style.
- `bin/ci` runs setup, style, audits, tests, system tests, and seeds.

## Coding Style & Naming Conventions

Follow Rails conventions and the configured `rubocop-rails-omakase` style. Use two-space indentation for Ruby, ERB, YAML, and Rails config. Use `snake_case` for files, methods, variables, fixtures, and database columns; use `PascalCase` for Ruby classes and modules. Keep controllers focused on request flow, put domain behavior in models or service objects, and keep ActiveAdmin customizations in `app/admin`.

## Testing Guidelines

The project uses Rails Minitest with fixtures, Capybara/Selenium for system tests, WebMock for HTTP isolation, and Mocha for stubs/mocks. Name test files after the code they cover, such as `test/models/squad_test.rb` for `Squad`. Update fixtures when relationships change. For Discord, OAuth, and role-access behavior, avoid live network calls and cover allowed and denied paths. Run the focused test first, then `bin/rails test`; run `bin/ci` before larger PRs.

## Commit & Pull Request Guidelines

Git history mostly uses concise imperative messages, often Conventional Commit style such as `feat: add event management features`. Prefer `feat:`, `fix:`, `refactor:`, `docs:`, or `test:` prefixes. Pull requests should include what changed, why, tests run, linked issues when applicable, screenshots for UI/Admin changes, and notes for migrations or Discord config changes.

## Security & Configuration Tips

Copy `.env.example` to `.env` for local database settings. Store Discord secrets in encrypted Rails credentials, not environment files. Never commit `config/master.key`, tokens, `.env`, logs, or local uploads. Document new setup requirements in `docs/`.
