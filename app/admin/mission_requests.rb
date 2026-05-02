ActiveAdmin.register MissionRequest do
  permit_params :guild_id, :requester_id, :title, :description, :status, :admin_notes

  member_action :approve, method: :post do
    resource.approve!(reviewer: current_user, notes: params[:admin_notes])
    redirect_to resource_path, notice: "Requisição aprovada."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to resource_path, alert: e.message
  end

  member_action :reject, method: :post do
    resource.reject!(reviewer: current_user, notes: params[:admin_notes])
    redirect_to resource_path, notice: "Requisição rejeitada."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to resource_path, alert: e.message
  end

  action_item :approve, only: :show, if: proc { resource.pending? } do
    link_to "Aprovar", approve_admin_mission_request_path(resource), method: :post
  end

  action_item :reject, only: :show, if: proc { resource.pending? } do
    link_to "Rejeitar", reject_admin_mission_request_path(resource), method: :post
  end

  index do
    selectable_column
    id_column
    column :guild
    column :requester
    column :title
    column :status
    column :reviewer
    column :reviewed_at
    actions
  end

  filter :guild
  filter :requester
  filter :status, as: :select, collection: MissionRequest.statuses.keys
  filter :title

  show do
    attributes_table do
      row :guild
      row :requester
      row :title
      row :description
      row :status
      row :reviewer
      row :reviewed_at
      row :admin_notes
      row :metadata
    end
  end
end
