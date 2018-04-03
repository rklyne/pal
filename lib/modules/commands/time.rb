module Powerbot
  module DiscordCommands
    module Time
      extend Discordrb::Commands::CommandContainer
      command(:time,
              description: 'displays the current in-game (UTC) time',
              usage: "#{BOT.prefix}time") do |event|
        ::Time.now.strftime "`%Y-%m-%d %H:%M`"
      end
    end
  end
end

