module Powerbot
  module Database
    # A help entry.
    class Tag < Sequel::Model
      # Set up class on creation
      def before_create
        super
        self.timestamp ||= Time.now
      end

      # Log creation
      def after_create
        Discordrb::LOGGER.info "created tag #{inspect}"
      end

      # Returns a Discord embed
      def embed
        Discordrb::Webhooks::Embed.new(
          author: { name: author.display_name, icon_url: author.avatar_url },
          description: text,
          timestamp: timestamp,
          color: 0xdd2e44,
          footer: { text: "#{server.name} [##{channel.name}]" }
        )
      end

      # Tag channel
      def channel
        BOT.channel channel_id
      end

      # Tag server
      def server
        channel.server
      end

      # Tag member
      def author
        BOT.member server.id, author_id
      end

      # Search for a tag
      def self.search(tag_key, channel)
        where(Sequel.ilike(:key, tag_key)).all.find { |t| t.channel_id == channel.id }
      end

      # return a hash with some useful information resolved
      def hash_exp
        {
          'id' => id,
          'author' => author_name,
          'timestamp' => timestamp,
          'channel' => channel.name,
          'key' => key,
          'text' => text
        }
      end
    end
  end
end
