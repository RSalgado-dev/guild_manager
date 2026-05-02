module Access
  class StoreOrdersController < AccessController
    before_action :require_guild_access
    before_action :load_user_context

    def index
      @orders = current_user.store_orders.includes(:store_item).recent
    end

    def create
      store_item = @guild.store_items.find(params[:store_item_id])
      order = StoreOrder.checkout!(user: current_user, store_item: store_item)

      redirect_to store_orders_path, notice: "✅ Pedido ##{order.id} criado com sucesso."
    rescue ArgumentError, ActiveRecord::RecordInvalid => e
      redirect_to store_path, alert: "❌ Não foi possível concluir a compra: #{e.message}"
    end

    def cancel
      order = current_user.store_orders.find(params[:id])
      order.cancel!(actor: current_user)

      redirect_to store_orders_path, notice: "✅ Pedido cancelado e moedas reembolsadas."
    rescue ArgumentError, ActiveRecord::RecordInvalid => e
      redirect_to store_orders_path, alert: "❌ Não foi possível cancelar o pedido: #{e.message}"
    end
  end
end
