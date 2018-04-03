module Powerbot
  module DiscordCommands
    # Commands for managing a server's Starboard
    module Starboard
      extend Discordrb::Commands::CommandContainer

      # Link the starboard channel
      command(:'starboard.link', permission_level: 3, help_available: false) do |event, channel_id|
        server_options = Database::Metadata.create? event.server.id

        server_options.merge(star_channel_id: channel_id.to_i)

        '🆗'
      end

      # Toggles allowing messages to be starred in the channel its run in
      command(:'allow_stars', permission_level: 3, help_available: false) do |event|
        channel_options = Database::Metadata.create? snowflake: event.channel.id

        current_option = channel_options.read['allow_stars']

        channel_options.merge(allow_stars: !current_option)

        '🆗'
      end

      command(:who_starred, help_available: false) do |event, id|
        maybe_star = Database::StarMessage.find id: id.to_i

        next 'Message not found or not starred..' unless maybe_star

        users = maybe_star.stars.map do |s|
          BOT.users[s.user_id]
        end.compact

        users.map(&:name).join ', '
      end

      command(:star,
              description: 'adds a star to a starred message by ID',
              usage: "#{BOT.prefix}.star <message ID>") do |event, id|
        maybe_star = Database::StarMessage.find id: id.to_i

        next 'Message not found or not starred..' unless maybe_star
        next 'You can only star a message once.' if maybe_star.starred_by? event.user.id

        maybe_star.add_star user_id: event.user.id

        DiscordEvents::Star.update_star maybe_star

        event.message.delete
      end

      command(:quote) do |event, id|
        channel_options = Database::Metadata.read(event.channel.id)

        next unless channel_options['allow_stars']

        maybe_star = Database::StarMessage.find id: id.to_i
        next 'Message not found..' unless maybe_star

        event.channel.send_embed(nil, maybe_star.embed)
      end

      command(:rep,
              description: 'Shows your total starboard rep',
              usage: "#{BOT.prefix}rep") do |event|
        rep = Database::StarMessage.user_rep(event.user.id)
        event.channel.send_embed do |e|
          e.author = { name: event.user.display_name, icon_url: event.user.avatar_url }
          e.description = "\u2b50 **#{rep}**"
          e.color = 0xf7a631
        end
      end

      LEADERBOARD_SQL = 'select star_messages.author_id, count(stars.id) as star_count from stars left join star_messages on stars.star_message_id = star_messages.id group by star_messages.author_id order by star_count desc limit 10'

      command(:board) do |event|
        results = Database::DB[LEADERBOARD_SQL].all

        event << '**Starboard Leaderboard**'

        rows = results.map.with_index do |hash, index|
          name = if hash[:author_id]
                   BOT.user(hash[:author_id])&.distinct || '(Unknown)'
                 else
                   '(Unknown)'
                 end
          [index + 1, name, hash[:star_count]]
        end

        "```hs\n#{Terminal::Table.new(headings: %w(# Name Stars), rows: rows)}\n```"
      end
    end
  end
end
