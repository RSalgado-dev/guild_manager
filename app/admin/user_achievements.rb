ActiveAdmin.register UserAchievement do
  permit_params :user_id, :achievement_id, :earned_at, :source_type, :source_id

  index do
    selectable_column
    id_column
    column :user
    column :achievement
    column :earned_at
    column :source_type
    actions
  end

  filter :user
  filter :achievement
  filter :earned_at
  filter :source_type

  form do |f|
    f.inputs "Concessão de conquista" do
      f.input :user
      f.input :achievement
      f.input :earned_at
      f.input :source_type
      f.input :source_id
    end
    f.actions
  end
end
