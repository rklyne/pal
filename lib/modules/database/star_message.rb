module Powerbot
  module Database
    class StarMessage < Sequel::Model
      one_to_many :stars

      def before_destroy
        message&.delete
      end

      def starred_message_channel
        BOT.channel(starred_channel_id)
      end

      def starred_message
        starred_message_channel.message(starred_message_id)
      end

      def channel
        BOT.channel(channel_id)
      end

      def message
        channel.message(message_id)
      end

      def author
        BOT.member channel.server, author_id
      end

      def rep
        stars.count
      end

      def self.user_rep(id)
        where(author_id: id).all.map(&:rep).reduce(:+) || 0
      end

      def star_by(user_id)
        stars.find { |s| s.user_id == user_id }
      end

      def starred_by?(user_id)
        !!star_by(user_id)
      end

      def dead?
        stars.count.zero?
      end

      def embed
        msg = starred_message
        e = Discordrb::Webhooks::Embed.new(
          description: msg.content,
          author: { name: author.name, icon_url: author.avatar_url },
          timestamp: msg.timestamp,
          footer: { text: "id: #{id}" },
          color: 0xf7a631
        )

        e.image = { url: msg.attachments.first.url } if msg.attachments.any?

        uris = URI.extract msg.content
        if e.image.nil? && uris.any?
          uri = uris.first
          e.image = { url: uri } if %w(images.discordapp.net .jpg .png .gif).any? { |f| uri.include? f }
        end

        e
      end

      dataset_module do
        def random
          order(Sequel.lit('RANDOM()'))
        end
      end
    end

    class Star < Sequel::Model
      many_to_one :star_message
    end
  end
end
