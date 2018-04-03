module Powerbot
  module DiscordEvents
    # These events are called when a memeber leaves and joins a server.
    module MemberJoinLeave
      extend Discordrb::EventContainer
      member_join do |event|
        channel = event.server.channels.find { |c| c.name == CONFIG.events_channel }
        unless channel.nil?
          channel.send_embed '', user_embed(event.user, true)
        end
        nil
      end

      member_leave do |event|
        channel = event.server.channels.find { |c| c.name == CONFIG.events_channel }
        unless channel.nil?
          channel.send_embed '', user_embed(event.user, false)
        end
        nil
      end

      # Event handler that sends a custom greeting message upon a member joining.
      member_join do |event|
        options = Database::Metadata.read(event.server.id, true)
        next unless options['greeting_enabled']

        greeting_string = options['greeting_string'] || "Welcome to **#{event.server.name}**, #{event.user.mention}!"
        greeting_channel = options['greeting_channel'].nil? ? event.server.default_channel : BOT.channel(options['greeting_channel'])

        # Greeting string option replacements
        greeting_string.gsub!('%server%', event.server.name)
        greeting_string.gsub!('%user%', event.user.mention)

        greeting_channel.send_message greeting_string
      end

      module_function

      def user_embed(user, join)
        e = Discordrb::Webhooks::Embed.new
        e.author = {
          name: "#{join ? 'Member Joined' : 'Member Left'}",
          icon_url: "#{join ? 'http://emojipedia-us.s3.amazonaws.com/cache/72/7d/727d10a592ac37ab2844286e0cd70168.png' : 'http://emojipedia-us.s3.amazonaws.com/cache/32/9d/329df0e266f6e63ed5a4be23840b3513.png'}"
        }
        e.color = join ? 0xa8ff99 : 0xff7777
        e.thumbnail = { url: user.avatar_url }
        e.description = "**#{user.distinct}** (#{user.mention})"
        e.footer = { text: user.id.to_s }
        e.timestamp = Time.now
        e.add_field(name: 'Joined Discord', value: user.creation_time)
        e
      end
    end
  end
end
