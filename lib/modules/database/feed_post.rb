module Powerbot
  module Database
    class FeedPost < Sequel::Model
      many_to_one :feed

      def message
        feed.channel.message message_id
      end

      def author
        BOT.member feed.server, author_id
      end

      def tagline
        "🛰️ #{feed.role.mention} **| #{title}**"
      end

      def update_post(quiet = false)
        if message_id
          message.edit "#{tagline} `updated: #{::Time.now.utc}`", parse_content
          notify if feed.notification_channel && !quiet
        else
          feed.role.mentionable = true
          m = feed.channel.send_embed tagline, parse_content
          feed.role.mentionable = false

          update message_id: m.id
        end
      end

      def notify
        feed.notification_channel.send_embed("**#{title}** has been updated! #{feed.channel.mention}") do |e|
          e.author = { name: author.display_name, icon_url: author.avatar_url }
          e.timestamp = ::Time.now
          e.color = feed.role.color.combined
        end
      end

      def parse_content
        data = content.split '|'

        fields = data[1..-1].map do |f|
          Discordrb::Webhooks::EmbedField.new(
            name: "\u200b",
            value: f
          )
        end

        Discordrb::Webhooks::Embed.new(
          description: data.first,
          fields: fields,
          color: feed.role.color.combined,
          footer: {
            text: "##{id} | [use 'pal.unsub #{feed.name}' to unsub]",
            icon_url: feed.server.icon_url
          },
          author: {
            name: author.display_name,
            icon_url: author.avatar_url
          },
          timestamp: Time.now,
          image: { url: attachment_url }
        )
      end
    end
  end
end
