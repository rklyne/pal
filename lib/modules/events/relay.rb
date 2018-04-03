module Powerbot
  module DiscordEvents
    # Relay events that trigger syndication
    module Relay
      extend Discordrb::EventContainer
      message do |event|
        next if event.message.content.start_with?(CONFIG.prefix)
        targets = Database::RelayTarget.where(channel_id: event.channel.id).all
        next unless targets.any?

        reacted = false
        targets.map(&:relay).each do |r|
          if event.message.content.match? /.?#{r.key}\b/
            r.syndicate(event.message)
            event.message.react "\u{1F6F0}" unless reacted
            reacted = true
          end
        end
      end
    end
  end
end
