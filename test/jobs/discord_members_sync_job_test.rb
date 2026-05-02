require "test_helper"

class DiscordMembersSyncJobTest < ActiveJob::TestCase
  test "sincroniza usuario especifico" do
    user = users(:five)

    DiscordMemberRoleSync.stubs(:call).returns(true)

    assert_equal({ synced: 1, failed: 0 }, DiscordMembersSyncJob.perform_now(user.guild_id, user.id))
  end
end
