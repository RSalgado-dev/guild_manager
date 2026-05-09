# frozen_string_literal: true

namespace :demo do
  desc "Recria uma guilda mock completa para apresentacao com 30 dias de uso"
  task seed_presentation_guild: :environment do
    user_count = ENV.fetch("USERS", PresentationGuildSeeder::DEFAULT_USER_COUNT).to_i
    reset = ENV.fetch("RESET", "true") != "false"
    summary = PresentationGuildSeeder.call(user_count: user_count, reset: reset)

    puts "Guilda mock criada: #{summary[:guild_name]} (ID #{summary[:guild_id]})"
    summary.each do |key, value|
      next if key.in?(%i[guild_id guild_name])

      puts "#{key}: #{value}"
    end
  end
end
