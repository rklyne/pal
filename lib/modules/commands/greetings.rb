module Powerbot
  module DiscordCommands
    module Greeting
      extend Discordrb::Commands::CommandContainer

      def self.warnings(metadata, warn_if_off = false)
        hash = metadata.is_a?(Database::Metadata) ? metadata.read : metadata

        warns = []
        warns << %Q{\u{26a0} **Greetings are currently disabled.** Enable them with `pal.toggle_greeting`.} if !hash['greeting_enabled'] && warn_if_off
        warns << %Q{\u{26a0} **A greeting channel hasn't been set. I'll use the server's default channel.** Change this with `pal.greeting_channel #channel`} unless hash['greeting_channel']
        warns << %Q{\u{26a0} **A greeting message hasn't been set.** I'll use a simple greeting, but you can customize this with `pal.greeting_text My welcome message`} unless hash['greeting_string']

        return unless warns.any?

        Discordrb::Webhooks::Embed.new(
          description: warns.join(%Q{\n}),
          color: 0xffcc4d
        )
      end

      PM_MESSAGE = %{**This feature can only be used inside servers.**}

      command(:toggle_greeting, permission_level: 3) do |event|
        next PM_MESSAGE unless event.server
        options = Database::Metadata.find_or_create(snowflake: event.server.id)
        options.merge({ greeting_enabled: !options.read['greeting_enabled'] })
        message = options.read['greeting_enabled'] ? %Q{**Greeting Enabled** \u{2705}} : %Q{**Greeting Disabled** \u{274c}}

        event.channel.send_message message, nil, warnings(options)
      end

      command(:greeting_channel, min_args: 1, permission_level: 3) do |event, channel_id|
        next PM_MESSAGE unless event.server
        channel = BOT.channel event.message.content[/\d+/]
        next %{**Channel not found**} unless channel

        options = Database::Metadata.find_or_create(snowflake: event.server.id)
        options.merge({ greeting_channel: channel.id })

        message = %Q{**Greeting channel set:** #{channel.mention} \u{2705}}

        event.channel.send_message message, nil, warnings(options, true)
      end

      command(:greeting_text, permission_level: 3) do |event, text|
        next PM_MESSAGE unless event.server
        options = Database::Metadata.find_or_create(snowflake: event.server.id)

        unless text
          next %Q{**The current greeting template is:**\n```\n#{options.read['greeting_string']}\n```} if options.read['greeting_string']
          next %Q{**There's no greeting text set.**}
        end

        options.merge({ greeting_string: event.message.content[18..-1] })

        message = %Q{**\u{2705} Greeting Text Set**}

        event.channel.send_message message, nil, warnings(options, true)
      end
    end
  end
end
