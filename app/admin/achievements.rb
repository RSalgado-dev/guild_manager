ActiveAdmin.register Achievement do
  permit_params :guild_id, :code, :name, :description, :category, :icon_url, :active,
                :achievement_type, :visibility, :criteria_json, :reward_xp,
                :reward_currency, :reward_profile_name_color

  index do
    selectable_column
    id_column
    column :guild
    column :code
    column :name
    column :achievement_type
    column :visibility
    column :active
    column :reward_xp
    column :reward_currency
    actions
  end

  filter :guild
  filter :code
  filter :name
  filter :achievement_type, as: :select, collection: Achievement.achievement_types.keys
  filter :visibility, as: :select, collection: Achievement.visibilities.keys
  filter :active

  form do |f|
    f.inputs "Conquista" do
      f.input :guild
      f.input :code
      f.input :name
      f.input :description
      f.input :category
      f.input :icon_url
      f.input :achievement_type, as: :select, collection: Achievement.achievement_types.keys
      f.input :visibility, as: :select, collection: Achievement.visibilities.keys
      f.input :reward_xp
      f.input :reward_currency
      f.input :reward_profile_name_color,
              hint: "Use #RRGGBB apenas em conquistas preexistentes."
      f.input :criteria_json, as: :text, input_html: { rows: 6 }
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
      row :achievement_type
      row :visibility
      row :reward_xp
      row :reward_currency
      row :reward_profile_name_color
      row :criteria
      row :active
    end
  end
end
