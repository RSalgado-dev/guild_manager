ActiveAdmin.register AuditLog do
  actions :index, :show
  config.batch_actions = false

  index do
    id_column
    column :guild
    column :user
    column :action
    column :entity_type
    column :entity_id
    column :created_at
    actions
  end

  filter :guild
  filter :user
  filter :action
  filter :entity_type
  filter :created_at

  show do
    attributes_table do
      row :guild
      row :user
      row :action
      row :entity_type
      row :entity_id
      row :metadata do |log|
        pre JSON.pretty_generate(log.metadata || {})
      end
      row :created_at
      row :updated_at
    end
  end
end
