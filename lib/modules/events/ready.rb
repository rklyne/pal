module Powerbot
  module DiscordEvents
    # This event is processed when the bot connects to Discord.
    module Ready
      extend Discordrb::EventContainer
      ready do |event|
        # Configure bot
        event.bot.game = CONFIG.game

        # Set owner permission level
        # 1 - standard pledge commands
        # 2 - registered traikoa user
        # 3 - powerbot moderator
        # 4 - powerbot admin

        # Load all persistant permission settings
        Database::Permission.apply_all!

        # Prevent one-time schedulers from being
        # scheduled again if we reconnect to Discord
        next if @init
        @init = true

        # Set up all activity handlers
        Database::Activity.register_handlers!
      end
    end
  end
end
