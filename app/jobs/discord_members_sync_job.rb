class DiscordMembersSyncJob < ApplicationJob
  queue_as :default

  def perform(guild_id = nil, user_id = nil)
    users = users_scope(guild_id, user_id)
    client = DiscordApiClient.new

    users.find_each.with_object({ synced: 0, failed: 0 }) do |user, result|
      if DiscordMemberRoleSync.call(user: user, guild: user.guild, client: client)
        result[:synced] += 1
      else
        result[:failed] += 1
      end
    end
  end

  private

  def users_scope(guild_id, user_id)
    users = User.includes(:guild)
    users = users.where(guild_id: guild_id) if guild_id
    users = users.where(id: user_id) if user_id
    users
  end
end
