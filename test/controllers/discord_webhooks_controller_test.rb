require "test_helper"

class DiscordWebhooksControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  test "member update webhook enfileira sync e reconciliação" do
    user = users(:five)

    assert_enqueued_with(job: DiscordMembersSyncJob, args: [ user.guild.id, user.id ]) do
      assert_enqueued_with(job: DiscordManagedRoleReconciliationJob, args: [ user.guild.id, user.id ]) do
        post discord_member_update_webhook_path, params: {
          guild_id: user.guild.discord_guild_id,
          user_id: user.discord_id
        }
      end
    end

    assert_response :accepted
    assert_equal "discord_member_update_webhook_received", AuditLog.order(:created_at).last.action
  end

  test "member update webhook exige segredo em produção" do
    Rails.env.stubs(:production?).returns(true)

    post discord_member_update_webhook_path, params: {
      guild_id: guilds(:one).discord_guild_id,
      user_id: users(:five).discord_id
    }

    assert_response :unauthorized
  end
end
