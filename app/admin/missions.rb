ActiveAdmin.register Mission do
  permit_params :guild_id, :name, :description, :mission_type, :frequency, :reward_mode,
                :reward_currency, :reward_xp, :reward_currency_per_unit, :reward_xp_per_unit,
                :max_submissions_per_period, :active, :metadata_json

  index do
    selectable_column
    id_column
    column :guild
    column :name
    column :mission_type
    column :frequency
    column :reward_mode
    column :active
    column :max_submissions_per_period
    actions
  end

  filter :guild
  filter :name
  filter :mission_type, as: :select, collection: Mission.mission_types.keys
  filter :frequency, as: :select, collection: Mission.frequencies.keys
  filter :active

  form do |f|
    f.inputs "Missão" do
      f.input :guild
      f.input :name
      f.input :description
      f.input :mission_type, as: :select, collection: Mission.mission_types.keys
      f.input :frequency, as: :select, collection: Mission.frequencies.keys
      f.input :reward_mode, as: :select, collection: Mission.reward_modes.keys
      f.input :reward_xp
      f.input :reward_currency
      f.input :reward_xp_per_unit
      f.input :reward_currency_per_unit
      f.input :max_submissions_per_period
      f.input :active
      f.input :metadata_json, as: :text, input_html: { rows: 6 }
    end
    f.actions
  end

  show do
    attributes_table do
      row :guild
      row :name
      row :description
      row :mission_type
      row :frequency
      row :reward_mode
      row :reward_xp
      row :reward_currency
      row :reward_xp_per_unit
      row :reward_currency_per_unit
      row :max_submissions_per_period
      row :active
      row :metadata
    end

    panel "Submissões recentes" do
      table_for mission.mission_submissions.includes(:user).order(created_at: :desc).limit(20) do
        column :user
        column :week_reference
        column :period_sequence
        column :status
        column :quantity
        column :reward_xp_awarded
        column :reward_currency_awarded
      end
    end
  end
end
