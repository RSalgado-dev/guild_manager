require "test_helper"

class DiscordManagedRoleReconciliationJobTest < ActiveJob::TestCase
  test "reconcilia guild especifica" do
    guild = guilds(:one)

    DiscordManagedRoleReconciler.expects(:call).with(guild: guild, user: nil).returns(true)

    assert_equal({ reconciled: 1, failed: 0 }, DiscordManagedRoleReconciliationJob.perform_now(guild.id))
  end
end
