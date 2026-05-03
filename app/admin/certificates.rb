ActiveAdmin.register Certificate do
  permit_params :guild_id, :role_id, :code, :name, :description, :category, :icon_url, :active

  index do
    selectable_column
    id_column
    column :guild
    column :code
    column :name
    column :category
    column :role
    column :active
    actions
  end

  filter :guild
  filter :code
  filter :name
  filter :category
  filter :active

  form do |f|
    f.inputs "Certificado" do
      f.input :guild
      f.input :code
      f.input :name
      f.input :description
      f.input :category
      f.input :icon_url
      f.input :role,
              collection: Role.cosmetic.order(:name),
              hint: "Cargo cosmético obrigatório concedido junto com o certificado."
      f.input :active
    end
    f.actions
  end

  show do
    attributes_table do
      row :guild
      row :code
      row :name
      row :description
      row :category
      row :icon_url
      row :role
      row :active
    end
  end
end
