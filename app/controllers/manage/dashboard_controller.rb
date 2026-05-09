# frozen_string_literal: true

module Manage
  class DashboardController < BaseController
    def index
      @resource_configs = ResourceRegistry.configs_for(current_user)
      @stats = {
        users: @guild.users.count,
        events: @guild.events.count,
        pending_mission_submissions: @guild.missions.joins(:mission_submissions).merge(MissionSubmission.pending).count,
        pending_store_orders: StoreOrder.joins(:store_item).where(store_items: { guild_id: @guild.id }, status: "pending").count,
        audit_logs: AuditLog.where(guild: @guild).count
      }
    end
  end
end
