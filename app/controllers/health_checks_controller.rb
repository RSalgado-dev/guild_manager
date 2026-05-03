class HealthChecksController < ApplicationController
  def show
    checks = {
      database: database_ok?,
      solid_queue: solid_queue_ok?,
      discord_configured: Rails.application.credentials.dig(:discord, :bot_token).present?
    }

    status = checks.values_at(:database, :solid_queue).all? ? :ok : :service_unavailable
    render json: { status: Rack::Utils::SYMBOL_TO_STATUS_CODE[status], checks: checks }, status: status
  end

  private

  def database_ok?
    ActiveRecord::Base.connection.select_value("SELECT 1").to_i == 1
  rescue
    false
  end

  def solid_queue_ok?
    return false unless defined?(SolidQueue::Job)

    SolidQueue::Job.limit(1).count
    true
  rescue
    false
  end
end
