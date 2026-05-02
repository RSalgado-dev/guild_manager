ActiveAdmin.register Ranking do
  permit_params :guild_id, :name, :description, :ranking_scope, :metric, :sort_direction,
                :entries_limit, :position, :active

  index do
    selectable_column
    id_column
    column :guild
    column :name
    column :ranking_scope
    column :metric do |ranking|
      ranking.metric_label
    end
    column :sort_direction
    column :entries_limit
    column :position
    column :active
    actions
  end

  filter :guild
  filter :name
  filter :ranking_scope, as: :select, collection: Ranking::RANKING_SCOPES
  filter :metric, as: :select, collection: Ranking::METRIC_LABELS.map { |key, label| [ label, key ] }
  filter :active

  form do |f|
    f.inputs "Ranking" do
      f.input :guild
      f.input :name
      f.input :description
      f.input :ranking_scope, as: :select, collection: Ranking::RANKING_SCOPES
      f.input :metric, as: :select, collection: Ranking::METRIC_LABELS.map { |key, label| [ label, key ] }
      f.input :sort_direction, as: :select, collection: Ranking::SORT_DIRECTIONS
      f.input :entries_limit
      f.input :position
      f.input :active
    end
    f.actions
  end

  show do
    attributes_table do
      row :guild
      row :name
      row :description
      row :ranking_scope
      row :metric do |ranking|
        ranking.metric_label
      end
      row :sort_direction
      row :entries_limit
      row :position
      row :active
    end
  end
end
