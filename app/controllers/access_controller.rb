class AccessController < ApplicationController
  before_action :require_login

  def restricted
    @guild = current_user.guild
  end
end
