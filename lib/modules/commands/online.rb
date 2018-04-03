module Powerbot
  module DiscordCommands
    module Online
      extend Discordrb::Commands::CommandContainer
      command(:online, permission_level: 1) do |event|
        next 'This command can only be used inside of a server.' if event.channel.pm?
        members = event.server.online_members.select { |m| m.game == 'Elite: Dangerous' }

        # :facepalm: on ElitePatreus. Also, the cache is fucked up.
        picard = event.bot.server(121851668936654848).emoji[244969861619515403]

        next "No one playing Elite right now! #{picard}" if members.empty?

        activities = Database::Activity.where(server_id: event.server.id).all

        # :o7: on ElitePatreus
        emoji = event.bot.emoji 320429167227174924

        event.channel.send_embed("#{emoji} **#{members.size} CMDRs playing Elite**") do |embed|
          embed.description = members.map do |m|
            active_activities = activities.select { |a| a.participants.find { |p| p.discord_id == m.id } }
            "#{m.display_name} (`#{m.roles.sort_by(&:position).last&.name || 'no roles'}`) #{active_activities.empty? ? nil : active_activities.map { |a| a.role.mention }.join(' ')}"
          end.sort.join("\n")
        end
      end
    end
  end
end
