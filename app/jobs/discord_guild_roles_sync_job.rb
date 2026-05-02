class DiscordGuildRolesSyncJob < ApplicationJob
  queue_as :default

  def perform(guild_id = nil)
    guilds = guild_id ? Guild.where(id: guild_id) : Guild.all

    guilds.find_each.with_object({ synced: 0, failed: 0 }) do |guild, result|
      if DiscordGuildRolesSync.call(guild: guild)
        result[:synced] += 1
      else
        result[:failed] += 1
      end
    end
  end
end
