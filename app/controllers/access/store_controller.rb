module Access
  class StoreController < AccessController
    before_action :require_guild_access
    before_action :load_user_context

    def index
      @items = @guild.store_items.available.ordered
      @recent_orders = current_user.store_orders.includes(:store_item).recent.limit(8)
    end
  end
end
