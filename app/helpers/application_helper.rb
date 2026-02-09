module ApplicationHelper
  # Retorna o caminho para login com Discord via OmniAuth
  def discord_login_path
    "/auth/discord"
  end
end
