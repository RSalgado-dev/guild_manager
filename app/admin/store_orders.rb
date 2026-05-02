ActiveAdmin.register StoreOrder do
  actions :all, except: [ :new, :create ]
  permit_params :admin_notes

  member_action :fulfill, method: :post do
    resource.fulfill!(actor: current_user)
    redirect_to resource_path, notice: "Pedido entregue."
  rescue ArgumentError, ActiveRecord::RecordInvalid => e
    redirect_to resource_path, alert: e.message
  end

  member_action :reject, method: :post do
    resource.reject!(actor: current_user)
    redirect_to resource_path, notice: "Pedido rejeitado e reembolsado."
  rescue ArgumentError, ActiveRecord::RecordInvalid => e
    redirect_to resource_path, alert: e.message
  end

  member_action :cancel, method: :post do
    resource.cancel!(actor: current_user)
    redirect_to resource_path, notice: "Pedido cancelado e reembolsado."
  rescue ArgumentError, ActiveRecord::RecordInvalid => e
    redirect_to resource_path, alert: e.message
  end

  action_item :fulfill, only: :show, if: proc { resource.pending? } do
    link_to "Entregar", fulfill_admin_store_order_path(resource), method: :post
  end

  action_item :reject, only: :show, if: proc { resource.pending? } do
    link_to "Rejeitar", reject_admin_store_order_path(resource), method: :post
  end

  action_item :cancel, only: :show, if: proc { resource.pending? } do
    link_to "Cancelar", cancel_admin_store_order_path(resource), method: :post
  end

  index do
    selectable_column
    id_column
    column :user
    column :store_item
    column :price_paid
    column :status
    column :fulfilled_at
    column :rejected_at
    column :canceled_at
    column :refunded_at
    actions
  end

  filter :user
  filter :store_item
  filter :status, as: :select, collection: StoreOrder::STATUSES
  filter :created_at

  form do |f|
    f.inputs "Pedido da loja" do
      f.input :admin_notes
    end
    f.actions
  end

  show do
    attributes_table do
      row :user
      row :store_item
      row :price_paid
      row :status
      row :admin_notes
      row :fulfilled_by
      row :fulfilled_at
      row :rejected_by
      row :rejected_at
      row :canceled_by
      row :canceled_at
      row :refunded_at
      row :created_at
      row :updated_at
    end
  end
end
