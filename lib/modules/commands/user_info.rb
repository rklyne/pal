require 'time_difference'

module Powerbot
  module DiscordCommands
    module UserInfo
      extend Discordrb::Commands::CommandContainer

      command([:ui, :user_info],
              description: 'shows you information about yourself or another member',
              usage: "#{BOT.prefix}user_info") do |event, *tag|
        next 'This command can only be used in servers.' if event.channel.private?

        member = if event.message.mentions.any?
                   event.message.mentions.first
                 elsif tag.any?
                   name, discrim = tag.join.split('#')
                   user = event.bot.find_user(name, discrim)
                   user.is_a?(Array) ? user.first : user
                 else
                   event.user
                end

        next 'Member not found' unless member

        member = member.on(event.server)

        next 'User is not on this server' unless member

        event.channel.send_embed do |e|
          e.author = {
            name: member.nick.nil? ? member.distinct : "#{member.distinct} (#{member.nick})",
          }

          e.thumbnail = { url: member.avatar_url }

          e.color = member.roles.any? ? member.roles.sort_by(&:position).last.color.combined : 0

          time = TimeDifference.between(::Time.now, member.joined_at)
                               .humanize
                               .sub(/\sand.*/, '')

          e.add_field(
            name: 'Member since',
            inline: false,
            value: "#{member.joined_at.strftime('%Y-%m-%d')} (#{time})"
          )

          e.add_field(
            name: 'Joined Discord',
            inline: true,
            value: member.creation_time.strftime('%Y-%m-%d')
          )

          e.add_field(
            name: 'Roles',
            inline: true,
            value: member.roles.map { |r| "`#{r.name}`" }.join(', ')
          )

          e.footer = { text: event.server.name, icon_url: event.server.icon_url }

          e.timestamp = ::Time.now
        end
      end
    end
  end
end
