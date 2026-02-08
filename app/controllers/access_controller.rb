class AccessController < ApplicationController
  before_action :require_login, except: [ :index ]

  def index
    # Página inicial pública
    if logged_in?
      redirect_to restricted_access_path
    end
  end

  def restricted
    @guild = current_user.guild
  end
end
