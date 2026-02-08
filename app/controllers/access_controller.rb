class AccessController < ApplicationController
  before_action :require_login, except: [ :index ]

  def index
    # Página initial - mostra opções de login ou dashboard
  end

  def restricted
    @guild = current_user.guild
  end
end
