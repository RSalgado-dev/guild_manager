ActiveAdmin.register User do
  menu priority: 2

  permit_params :discord_id, :discord_username, :discord_avatar_url, :email,
                :guild_id, :squad_id, :xp_points, :currency_balance, :has_guild_access

  # Configura os includes para otimizar queries
  config.sort_order = "created_at_desc"

  controller do
    def scoped_collection
      super.includes(:guild, :squad)
    end
  end

  scope :all, default: true
  scope :with_access do |users|
    users.where(has_guild_access: true)
  end
  scope :without_access do |users|
    users.where(has_guild_access: false)
  end
  scope :admins do |users|
    users.joins(:roles).where(roles: { is_admin: true }).distinct
  end

  index do
    selectable_column
    id_column
    column :discord_username do |user|
      if user.discord_avatar_url.present?
        image_tag(user.discord_avatar_url, height: 32, style: "border-radius: 50%; margin-right: 8px;") + user.discord_username
      else
        user.discord_username
      end
    end
    column :email
    column :guild
    column :squad
    column "Acesso" do |user|
      user.has_guild_access ? status_tag("Sim", class: "ok") : status_tag("Não", class: "error")
    end
    column :xp_points
    column :currency_balance
    column "Admin" do |user|
      user.admin? ? status_tag("Sim", class: "warning") : ""
    end
    column :created_at
    actions
  end

  filter :discord_username
  filter :discord_id
  filter :email
  filter :guild
  filter :guild_name, as: :string, label: "Nome da Guild"
  filter :squad
  filter :squad_name, as: :string, label: "Nome do Squad"
  filter :has_guild_access, as: :select, collection: [ [ "Com Acesso", true ], [ "Sem Acesso", false ] ]
  filter :xp_points
  filter :currency_balance
  filter :created_at

  form do |f|
    f.inputs "Informações do Discord" do
      f.input :discord_id, label: "Discord ID"
      f.input :discord_username, label: "Discord Username"
      f.input :discord_avatar_url, label: "Avatar URL"
      f.input :email, label: "Email"
    end

    f.inputs "Guild e Squad" do
      f.input :guild, label: "Guild"
      f.input :squad, label: "Squad (Opcional)"
    end

    f.inputs "Pontos e Moedas" do
      f.input :xp_points, label: "Pontos XP"
      f.input :currency_balance, label: "Saldo de Moedas"
    end

    f.inputs "Acesso" do
      f.input :has_guild_access, label: "Tem Acesso aos Recursos Internos",
              hint: "Marque se o usuário deve ter acesso completo"
    end

    f.actions
  end

  show do
    attributes_table do
      row :id
      row "Avatar" do |user|
        if user.discord_avatar_url.present?
          image_tag user.discord_avatar_url, height: 64, style: "border-radius: 50%;"
        else
          "Sem avatar"
        end
      end
      row :discord_username
      row :discord_id
      row :email
      row :guild do |user|
        link_to user.guild.name, admin_guild_path(user.guild) if user.guild
      end
      row :squad do |user|
        link_to user.squad.name, admin_squad_path(user.squad) if user.squad
      end
      row "Tem Acesso" do |user|
        user.has_guild_access ? status_tag("Sim", class: "ok") : status_tag("Não", class: "error")
      end
      row :xp_points
      row :currency_balance
      row "É Admin" do |user|
        user.admin? ? status_tag("Sim", class: "warning") : status_tag("Não")
      end
      row :created_at
      row :updated_at
    end

    panel "Cargos (Roles)" do
      table_for user.user_roles.includes(:role) do
        column "Cargo" do |ur|
          link_to ur.role.name, admin_role_path(ur.role)
        end
        column "Primário" do |ur|
          ur.primary ? status_tag("Sim", class: "ok") : ""
        end
      end
    end

    panel "Conquistas (Achievements)" do
      table_for user.user_achievements.includes(:achievement).order(earned_at: :desc).limit(10) do
        column "Conquista" do |ua|
          ua.achievement.name
        end
        column :earned_at
      end
    end

    panel "Transações de Moeda" do
      table_for user.currency_transactions.order(created_at: :desc).limit(10) do
        column :amount do |ct|
          number_to_currency(ct.amount, unit: "", precision: 0)
        end
        column :description
        column :balance_after
        column :created_at
      end
    end

    active_admin_comments
  end

  action_item :check_access, only: :show do
    link_to "Verificar Acesso", check_access_admin_user_path(user), method: :post
  end

  member_action :check_access, method: :post do
    user = User.find(params[:id])
    has_access = User.check_guild_role_access(user.guild, user.discord_id)
    user.update(has_guild_access: has_access)

    redirect_to admin_user_path(user), notice: "Acesso verificado. Status: #{has_access ? 'Com Acesso' : 'Sem Acesso'}"
  end
end
