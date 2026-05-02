ActiveAdmin.register MissionSubmission do
  permit_params :mission_id, :user_id, :week_reference, :period_sequence, :quantity, :status,
                :review_notes, :proof

  member_action :approve, method: :post do
    resource.approve!(reviewer: current_user, notes: params[:review_notes])
    redirect_to resource_path, notice: "Submissão aprovada."
  rescue ArgumentError, ActiveRecord::RecordInvalid => e
    redirect_to resource_path, alert: e.message
  end

  member_action :reject, method: :post do
    resource.reject!(reviewer: current_user, notes: params[:review_notes])
    redirect_to resource_path, notice: "Submissão rejeitada."
  rescue ArgumentError, ActiveRecord::RecordInvalid => e
    redirect_to resource_path, alert: e.message
  end

  member_action :reward, method: :post do
    resource.reward!(reviewer: current_user)
    redirect_to resource_path, notice: "Recompensa distribuída."
  rescue ArgumentError, ActiveRecord::RecordInvalid => e
    redirect_to resource_path, alert: e.message
  end

  action_item :approve, only: :show, if: proc { resource.pending? } do
    link_to "Aprovar", approve_admin_mission_submission_path(resource), method: :post
  end

  action_item :reject, only: :show, if: proc { resource.pending? || resource.approved? } do
    link_to "Rejeitar", reject_admin_mission_submission_path(resource), method: :post
  end

  action_item :reward, only: :show, if: proc { resource.approved? } do
    link_to "Distribuir recompensa", reward_admin_mission_submission_path(resource), method: :post
  end

  index do
    selectable_column
    id_column
    column :mission
    column :user
    column :week_reference
    column :period_sequence
    column :status
    column :quantity
    column :reviewer
    column :reward_xp_awarded
    column :reward_currency_awarded
    actions
  end

  filter :mission
  filter :user
  filter :status, as: :select, collection: MissionSubmission.statuses.keys
  filter :week_reference

  show do
    attributes_table do
      row :mission
      row :user
      row :week_reference
      row :period_sequence
      row :status
      row :quantity
      row :answers_json
      row :reviewer
      row :reviewed_at
      row :review_notes
      row :reward_xp_awarded
      row :reward_currency_awarded
      row :rewarded_at
      row :proof do |submission|
        link_to(submission.proof.filename, url_for(submission.proof)) if submission.proof.attached?
      end
    end
  end
end
