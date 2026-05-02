module Access
  class AchievementsController < AccessController
    before_action :require_guild_access
    before_action :load_user_context
    before_action :set_achievement, only: [ :show ]

    def index
      @achievements = @guild.achievements.catalog_visible
      @earned_achievement_ids = current_user.user_achievements.pluck(:achievement_id)
    end

    def show
      @user_achievement = current_user.user_achievements.find_by(achievement: @achievement)
    end

    private

    def set_achievement
      @achievement = @guild.achievements.active.find(params[:id])
    end
  end
end
