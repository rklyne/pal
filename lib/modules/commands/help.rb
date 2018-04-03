module Powerbot
  module DiscordCommands
    module Help
      extend Discordrb::Commands::CommandContainer

      COLOR = %q{7289da}
      FOOTER = { text: %q{Have questions? Send z64#2639 (CMDR Lune) a message!} }
      REACTION = %Q{\u{1f530}}

      command(:halp, description: %q{Lists available commands}) do |event|
        event.message.react REACTION

        event.user.pm.send_embed(%Q{**Available Commands** (all commands start with `#{BOT.prefix}`)}) do |e|
          e.color = COLOR
          e.footer = FOOTER

          e.add_field(
            name: %q{General Commands},
            value: <<~data
              `time` - Displays the current UTC (in-game) time

              `user_info @mention` - Information about a user on a server. Running this command without a mention displays your own information.

              `relays` - Lists relays currently linked to this channel

              `feeds` - Lists available feeds in this server

              `sub [feed name]` - Subscribes to a feed

              `unsub [feed name]` - Unsubscribes from a feed

              `rep` - Displays your starboard reputation points
            data
          )

          e.add_field(
            name: %q{Additional Command Help Pages},
            value: <<~data
              \u{25ab} `halp.elite` - Elite Dangerous related commands
              \u{25ab} `halp.relays` - for managing relays
              \u{25ab} `halp.feeds` - for managing feeds
              \u{25ab} `halp.starboard` - for managing the starboard
              \u{25ab} `halp.mods` - for moderators
              \u{25ab} `halp.tags` - for managing tags
            data
          )
        end
      end

      command(:'halp.elite') do |event|
        event.message.react REACTION

        event.user.pm.send_embed(%Q{**Available Commands** (all commands start with `#{BOT.prefix}`)}) do |e|
          e.color = COLOR
          e.footer = FOOTER
          e.title = %q{Elite Dangerous}

          e.description = <<~data
            `info [system name]` - Displays info about a system.

            `distance [origin], [destination 1], [destination N]..` - Displays the distance between two or more systems

            `route [origin], [destination]..` - Displays the shortest distance route between systems

            `bubble [system name]` - Displays a CC analysis of a region of space
          data
        end
      end

      command(:'halp.relays') do |event|
        event.message.react REACTION

        event.user.pm.send_embed(%Q{**Available Commands** (all commands start with `#{BOT.prefix}`)}) do |e|
          e.color = COLOR
          e.footer = FOOTER
          e.title = %q{Relays}

          e.description = <<~data
            Relays are a system for syndicating chat messages across channels (across servers or within the same server).
            Messages are broadcasted across the relay only if they contain the specified "key" or "trigger" assigned to the relay.
            A single channel can be subscribed to multiple relays with different keys.

            `relays` - List relays linked to this channela

            `create_relay [relay_name] [key]` - Create a new relay with a name (with no spaces, for identification) and a key to trigger syndication in chat.

            `delete_relay [relay_name]` - Deletes a relay

            `set_relay [relay_name]` - Adds this channel as a relay node of the specified relay

            `set_carrier [text]` - Adds a message header ("carrier") to be appended to each incoming relay message

            `remove_relay [relay_name]` - Unbinds the specified relay from this channel
          data
        end
      end

      command(:'halp.feeds') do |event|
        event.message.react REACTION

        event.user.pm.send_embed(%Q{**Available Commands** (all commands start with `#{BOT.prefix}`)}) do |e|
          e.color = COLOR
          e.footer = FOOTER
          e.title = %q{Feeds}

          e.description = <<~data
            `feeds` - List available feeds in this server

            `sub [feed_name]` - Subscribes to a feed

            `unsub [feed_name]` - Unsubscribes from a feed

            `create_feed [feed_name]` - Creates a feed bound to the channel this command was run in. This will create a role with the name `feed-feed_name` that will be given to people that is mentioned when new content is pushed to the feed.

            `delete_feed [feed_name]` - Deletes a feed. Will also remove the associated role.

            `feed_notify [feed_name]` - Toggles this channel to recieve update notifications from that feed when using `edit`

            `push [feed_name] | [post title] | [content]` - Creates a new feed post on `feed_name` with title `post_title` and content `content`.

            \u{25ab} For special `push` syntax, please read [this documentation](https://github.com/z64/powerbot/blob/master/FEEDS.md#push-command-format)

            `edit [post ID] [new content]` - Edits a feed post. The post ID can be found in the footer of the post with the format `#ID`. Runing this command without supplying any new content will repost the article with the markdown exposed for easy editing.
          data
        end
      end

      command(:'halp.tags') do |event|
        event.message.react REACTION

        event.user.pm.send_embed(%Q{**Available Commands**}) do |e|
          e.color = COLOR
          e.footer = FOOTER
          e.title = %q{Tags}

          e.description = <<~data
            Tags are a system for storing and recalling pieces of text bound to specific channels.

            **These commands do not start with `pal.` - use them as-is.**

            `?tags` - List all tags in this channel

            `?tag_name` - Display the tag under `tag_name`

            `!tag_name tag content` - Create a new tag with `tag_name` and `content` bound to the current channel

            `~tag_name tag content` - Modify a tag under `tag_name` with new `content`

            `%tag_name` - Delete a tag with `tag_name`

            **Only the person who created the tag can modify or delete it.**
          data
        end
      end
    end
  end
end
