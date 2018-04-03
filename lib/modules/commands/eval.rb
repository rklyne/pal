module Powerbot
  module DiscordCommands
    # Command for evaluating Ruby code in an active bot.
    # Only the `event.user` with matching discord ID of `CONFIG.owner`
    # can use this command.
    module Eval
      extend Discordrb::Commands::CommandContainer
      extend Discordrb::EventContainer

      command(:eval, help_available: false) do |event, *code|
        break unless event.user.id == CONFIG.owner

        m = event.channel.send_embed { |e| e.color = 0xffa500 ; e.description = '`working..`' }
        new_embed = Discordrb::Webhooks::Embed.new

        begin
          result = eval code.join(' ')

          new_embed.color = 0x00ff00
          new_embed.description = "`done`"
          m.edit(result.to_s, new_embed)
          event.message.react "\u267B"
          nil
        rescue => e
          new_embed.color = 0xff0000
          new_embed.title = 'backtrace'
          new_embed.description = "```#{e.backtrace.join("\n")[0..2048]}```"
          m.edit("`#{e.to_s.gsub('`',"\'")}`", new_embed)
          nil
        end
      end

      reaction_add(emoji: "\u267B") do |event|
        next unless event.user.id == CONFIG.owner
        next unless event.message.content.start_with? 'pal.eval'

        new_event = Discordrb::Commands::CommandEvent.new event.message, BOT 

        BOT.execute_command(:eval, new_event, event.message.content[8..-1])
        nil
      end
    end
  end
end
