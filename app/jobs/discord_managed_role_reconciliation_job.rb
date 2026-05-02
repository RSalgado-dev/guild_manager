class DiscordManagedRoleReconciliationJob < ApplicationJob
  queue_as :default

  def perform(guild_id = nil, user_id = nil)
    guilds = guilds_scope(guild_id, user_id)

    guilds.find_each.with_object({ reconciled: 0, failed: 0 }) do |guild, result|
      user = User.find_by(id: user_id) if user_id
      if DiscordManagedRoleReconciler.call(guild: guild, user: user)
        result[:reconciled] += 1
      else
        result[:failed] += 1
      end
    end
  end

  private

  def guilds_scope(guild_id, user_id)
    return Guild.where(id: guild_id) if guild_id
    return Guild.where(id: User.where(id: user_id).select(:guild_id)) if user_id

    Guild.all
  end
end
