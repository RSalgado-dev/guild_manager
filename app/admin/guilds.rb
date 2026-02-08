ActiveAdmin.register Guild do
  menu priority: 1

  permit_params :name, :description, :discord_guild_id, :discord_name, 
                :discord_icon_url, :required_discord_role_id, :required_discord_role_name

  index do
    selectable_column
    id_column
    column :name
    column :discord_guild_id
    column "Usuários" do |guild|
      guild.users.count
    end
    column "Acesso Restrito" do |guild|
      guild.required_discord_role_id.present? ? status_tag("Sim", :warning) : status_tag("Não", :ok)
    end
    column :created_at
    actions
  end

  filter :name
  filter :discord_guild_id
  filter :created_at

  form do |f|
    f.inputs "Informações Básicas" do
      f.input :name, label: "Nome"
      f.input :description, label: "Descrição", input_html: { rows: 4 }
    end

    f.inputs "Discord" do
      f.input :discord_guild_id, label: "ID do Servidor Discord", 
              hint: "ID do servidor no Discord (obrigatório)"
      f.input :discord_name, label: "Nome no Discord"
      f.input :discord_icon_url, label: "URL do Ícone"
    end

    f.inputs "Controle de Acesso" do
      f.input :required_discord_role_id, label: "ID do Cargo Requerido",
              hint: "Deixe vazio para permitir acesso a todos os membros do servidor"
      f.input :required_discord_role_name, label: "Nome do Cargo"
    end

    f.actions
  end

  show do
    attributes_table do
      row :id
      row :name
      row :description
      row :discord_guild_id
      row :discord_name
      row :discord_icon_url do |guild|
        if guild.discord_icon_url.present?
          image_tag guild.discord_icon_url, height: 64
        else
          "Sem ícone"
        end
      end
      row "Cargo Requerido" do |guild|
        if guild.required_discord_role_id.present?
          "#{guild.required_discord_role_name} (#{guild.required_discord_role_id})"
        else
          status_tag("Acesso Livre", :ok)
        end
      end
      row :created_at
      row :updated_at
    end

    panel "Estatísticas" do
      attributes_table_for guild do
        row "Total de Usuários" do |g|
          g.users.count
        end
        row "Usuários com Acesso" do |g|
          g.users.where(has_guild_access: true).count
        end
        row "Usuários sem Acesso" do |g|
          g.users.where(has_guild_access: false).count
        end
        row "Total de Roles" do |g|
          g.roles.count
        end
        row "Total de Squads" do |g|
          g.squads.count
        end
        row "Total de Missões" do |g|
          g.missions.count
        end
      end
    end

    panel "Usuários" do
      table_for guild.users.order(created_at: :desc).limit(10) do
        column :id
        column "Discord Username" do |user|
          link_to user.discord_username, admin_user_path(user)
        end
        column "Tem Acesso" do |user|
          user.has_guild_access ? status_tag("Sim", :ok) : status_tag("Não", :error)
        end
        column :xp_points
        column :currency_balance
      end
      div do
        link_to "Ver Todos os Usuários", admin_users_path(q: { guild_id_eq: guild.id })
      end
    end

    active_admin_comments
  end

  action_item :sync_access, only: :show do
    link_to "Atualizar Acesso dos Usuários", sync_access_admin_guild_path(guild), method: :post
  end

  member_action :sync_access, method: :post do
    guild = Guild.find(params[:id])
    updated_count = 0

    guild.users.find_each do |user|
      has_access = User.check_guild_role_access(guild, user.discord_id)
      if user.has_guild_access != has_access
        user.update(has_guild_access: has_access)
        updated_count += 1
      end
    end

    redirect_to admin_guild_path(guild), notice: "Acesso atualizado para #{updated_count} usuário(s)."
  end
end
