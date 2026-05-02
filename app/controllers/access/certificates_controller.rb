module Access
  class CertificatesController < AccessController
    before_action :require_guild_access
    before_action :load_user_context
    before_action :set_certificate, only: [ :show ]

    def index
      @certificates = @guild.certificates.active.includes(:role).order(:category, :name)
      @user_certificates = current_user.user_certificates.includes(:certificate).index_by(&:certificate_id)
    end

    def show
      @user_certificate = current_user.user_certificates.find_by(certificate: @certificate)
    end

    private

    def set_certificate
      @certificate = @guild.certificates.active.includes(:role).find(params[:id])
    end
  end
end
