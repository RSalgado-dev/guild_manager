require "test_helper"

class DiscordGuildRolesSyncJobTest < ActiveJob::TestCase
  test "sincroniza guild especifica" do
    guild = guilds(:one)

    DiscordGuildRolesSync.expects(:call).with(guild: guild).returns(true)

    assert_equal({ synced: 1, failed: 0 }, DiscordGuildRolesSyncJob.perform_now(guild.id))
  end
end
