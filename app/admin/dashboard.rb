# frozen_string_literal: true

ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }

  content title: proc { I18n.t("active_admin.dashboard") } do
    columns do
      column do
        panel "Estatísticas Gerais" do
          div class: "stats-grid" do
            div class: "stat-card" do
              p "Guilds"
              h3 Guild.count
            end
            div class: "stat-card" do
              p "Usuários"
              h3 User.count
            end
            div class: "stat-card" do
              p "Com Acesso"
              h3 User.where(has_guild_access: true).count
            end
            div class: "stat-card" do
              p "Squads"
              h3 Squad.count
            end
          end
        end
      end
    end

    columns do
      column do
        panel "Guilds Recentes" do
          table_for Guild.order(created_at: :desc).limit(5) do
            column "Nome" do |guild|
              link_to guild.name, admin_guild_path(guild)
            end
            column "Usuários" do |guild|
              guild.users.count
            end
            column "Acesso Restrito" do |guild|
              guild.required_discord_role_id.present? ? status_tag("Sim", class: "warning") : status_tag("Não", class: "ok")
            end
            column :created_at
          end
        end
      end

      column do
        panel "Usuários Recentes" do
          table_for User.order(created_at: :desc).limit(5) do
            column "Username" do |user|
              link_to user.discord_username, admin_user_path(user)
            end
            column "Guild" do |user|
              user.guild&.name
            end
            column "Acesso" do |user|
              user.has_guild_access ? status_tag("Sim", class: "ok") : status_tag("Não", class: "error")
            end
            column :created_at
          end
        end
      end
    end

    columns do
      column do
        panel "Usuários sem Acesso" do
          if User.where(has_guild_access: false).count > 0
            table_for User.where(has_guild_access: false).limit(10) do
              column "Username" do |user|
                link_to user.discord_username, admin_user_path(user)
              end
              column "Guild" do |user|
                link_to user.guild.name, admin_guild_path(user.guild) if user.guild
              end
              column "Cargo Requerido" do |user|
                user.guild&.required_discord_role_name || "N/A"
              end
            end
            div do
              link_to "Ver Todos", admin_users_path(scope: :without_access)
            end
          else
            para "Todos os usuários têm acesso!"
          end
        end
      end
    end
  end
end
