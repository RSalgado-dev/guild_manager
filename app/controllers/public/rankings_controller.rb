module Public
  class RankingsController < ApplicationController
    def index
      @guild = Guild.find(params[:guild_id])
      @rankings = @guild.rankings.active.ordered
      @ranking = selected_ranking
      @entries = @ranking ? @ranking.entries : []
    end

    private

    def selected_ranking
      return @rankings.first if params[:ranking_id].blank?

      @rankings.find_by(id: params[:ranking_id]) || @rankings.first
    end
  end
end
