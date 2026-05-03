class DiscordWebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :verify_webhook_secret!

  def member_update
    guild = Guild.find_by(discord_guild_id: webhook_params[:guild_id])
    return head :not_found unless guild

    user = guild.users.find_by(discord_id: webhook_params[:user_id])
    DiscordMembersSyncJob.perform_later(guild.id, user&.id)
    DiscordManagedRoleReconciliationJob.perform_later(guild.id, user.id) if user

    AuditLog.record!(
      action: "discord_member_update_webhook_received",
      guild: guild,
      entity: user || guild,
      metadata: {
        "origin" => "discord_webhook",
        "result" => "accepted",
        "discord_user_id" => webhook_params[:user_id]
      }
    )

    head :accepted
  end

  private

  def webhook_params
    {
      guild_id: params[:guild_id].presence || params.dig(:guild, :id),
      user_id: params[:user_id].presence || params.dig(:user, :id)
    }
  end

  def verify_webhook_secret!
    secret = ENV["DISCORD_WEBHOOK_SECRET"].to_s
    return if secret.blank? && !Rails.env.production?

    header_value = request.headers["X-Discord-Webhook-Secret"].to_s
    return if secret.present? && ActiveSupport::SecurityUtils.secure_compare(header_value, secret)

    head :unauthorized
  end
end
