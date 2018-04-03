module Powerbot
  module Database
    # A chat relay between channels
    class Relay < Sequel::Model
      one_to_many :relay_targets

      def syndicate(message)
        relay_targets.each do |t|
          t.syndicate(message) unless t.server == message.channel.server
        end
      end
    end

    # A relay target
    class RelayTarget < Sequel::Model
      many_to_one :relay

      def channel
        BOT.channel channel_id
      end

      def server
        if channel
          channel.server
        else
          Discordrb::LOGGER.warn("Channel #{channel_id} does not exist")
        end
      end

      def embed(message)
        Discordrb::Webhooks::Embed.new(
          author: { name: message.author.display_name, icon_url: message.author.avatar_url },
          footer: { text: "#{message.channel.server.name} [##{message.channel.name}]", icon_url: message.channel.server.icon_url },
          description: message.content,
          fields: [
                    { name: 'User', value: message.author.mention, inline: true },
                    { name: 'Channel', value: message.channel.mention, inline: true },
                  ],
          timestamp: Time.now,
          color: message.author.roles.sort_by(&:position).last.color.combined
        )
      end

      def syndicate(message)
        channel.send_embed carrier, embed(message)
      rescue => e
        Discordrb::LOGGER.warn("Relay target failed: #{e.inspect}")
        Discordrb::LOGGER.warn("Relay target failed: [#{relay.id} : #{relay.name} => #{id} @ #{server.name} : #{channel.name} (#{channel.id})] #{message.author.name}: #{message.content}")
      end
    end
  end
end
