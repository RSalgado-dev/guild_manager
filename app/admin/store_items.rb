ActiveAdmin.register StoreItem do
  permit_params :guild_id, :name, :description, :category, :price, :stock_quantity,
                :status, :fulfillment_type

  controller do
    after_action :audit_successful_change, only: [ :create, :update, :destroy ]

    private

    def audit_successful_change
      return unless response.redirect?
      return unless resource&.id

      AuditLog.record!(
        action: "store_item_#{audit_action_suffix}",
        actor: current_user,
        entity: resource,
        metadata: {
          "origin" => "admin",
          "result" => "success",
          "name" => resource.name,
          "price" => resource.price,
          "status" => resource.status
        }
      )
    end

    def audit_action_suffix
      case action_name
      when "create" then "created"
      when "update" then "updated"
      when "destroy" then "destroyed"
      end
    end
  end

  index do
    selectable_column
    id_column
    column :guild
    column :name
    column :category
    column :price
    column :stock_quantity
    column "Status" do |item|
      ApplicationController.helpers.enum_label(item.status)
    end
    column "Entrega" do |item|
      ApplicationController.helpers.enum_label(item.fulfillment_type)
    end
    actions
  end

  filter :guild
  filter :name
  filter :category
  filter :status, as: :select, collection: StoreItem::STATUSES.map { |status| [ ApplicationController.helpers.enum_label(status), status ] }
  filter :fulfillment_type, as: :select, collection: StoreItem::FULFILLMENT_TYPES.map { |type| [ ApplicationController.helpers.enum_label(type), type ] }

  form do |f|
    f.inputs "Item da loja" do
      f.input :guild
      f.input :name
      f.input :description
      f.input :category
      f.input :price
      f.input :stock_quantity, hint: "Deixe vazio para estoque ilimitado."
      f.input :status, as: :select, collection: StoreItem::STATUSES.map { |status| [ ApplicationController.helpers.enum_label(status), status ] }
      f.input :fulfillment_type, as: :select, collection: StoreItem::FULFILLMENT_TYPES.map { |type| [ ApplicationController.helpers.enum_label(type), type ] }
    end
    f.actions
  end

  show do
    attributes_table do
      row :guild
      row :name
      row :description
      row :category
      row :price
      row :stock_quantity
      row "Status" do |item|
        ApplicationController.helpers.enum_label(item.status)
      end
      row "Entrega" do |item|
        ApplicationController.helpers.enum_label(item.fulfillment_type)
      end
      row :created_at
      row :updated_at
    end

    panel "Pedidos recentes" do
      table_for store_item.store_orders.includes(:user).recent.limit(20) do
        column :id
        column :user
        column :price_paid
        column "Status" do |order|
          ApplicationController.helpers.enum_label(order.status)
        end
        column :created_at
      end
    end
  end
end
