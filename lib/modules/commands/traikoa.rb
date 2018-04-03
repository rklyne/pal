module Powerbot

  module DiscordCommands
    # Commands related to the Traikoa API
    module Traikoa
      extend Discordrb::Commands::CommandContainer

      # Displays system metadata
      command(:info,
              permission_level: 1,
              description: 'Displays info about a system',
              usage: "#{BOT.prefix}info (system name)") do |event, *name|
        name = name.join ' '
        sys = Powerbot::Traikoa::System.search(name).first
        next 'System not found..' unless sys
        event.channel.send_embed "🌟 **#{sys.name}**", system_embed(sys)
      end

      # Displays a collection of distances to multiple systems
      # from a singular origin point
      command(:distance,
              permission_level: 1,
              description: 'Get the distance between one or more systems',
              usage: "#{BOT.prefix}distance system_a, system_b...") do |event, *names|
        names = names.join(' ').split(',').map(&:strip)
        next 'Please specify two or more systems.' unless names.count > 1

        origin = Powerbot::Traikoa::System.search(names.shift).first
        next 'Origin not found..' unless origin

        systems = names.map { |n| Powerbot::Traikoa::System.search(n).first }

        event << "**#{origin.name}**"
        systems.each_with_index do |s, i|
          event << "System not found: `#{names[i]}`" if s.nil?
          next if s.nil?
          event << "→ #{s.name} : `#{origin.distance(s).round 2} ly`"
        end
        nil
      end

      # Displays the shortest distance route
      # between a collection of systems
      command(:route,
              permission_level: 1,
              description: 'Get the shortest-distance route between a collection of systems',
              usage: "#{BOT.prefix}route system_a, system_b...") do |event, *names|
        names = names.join(' ').split(',').map(&:strip)
        next 'Please specify three or more systems.' unless names.count > 2

        systems = names.map { |n| Powerbot::Traikoa::System.search(n).first || n }

        if systems.any? { |e| e.is_a? String }
          systems.select { |e| e.is_a? String }.each do |e|
            event << "Unknown system: `#{e}`"
          end

          next
        end

        event << "**#{systems.first.name}** (`origin`)"
        until systems.count == 1 do
          origin  = systems.shift
          systems.sort_by! { |s| s.distance(origin) }
          nex = systems.first
          event << "→ #{nex.name} (`#{origin.distance(nex).round 2} ly`)"
        end

        nil
      end

      # Displays CC statistics about a region of space
      command(:bubble,
              permission_level: 3,
              description: 'Gives you CC stats about a region of space',
              usage: "#{BOT.prefix}bubble system name") do |event, *name|
        name = name.join(' ')
        sys = Powerbot::Traikoa::System.search(name).first
        next 'System not found.' unless sys

        event.channel.start_typing

        bubble = sys.bubble

        total_cc = bubble.map(&:cc_value).compact.reduce(:+)

        uncontrolled = bubble.select { |s| !s.exploitations.any? }
        uncontrolled_cc = uncontrolled.map(&:cc_value).compact.reduce(:+)

        contested = bubble.select(&:contested)
        contested_cc = contested.map(&:cc_value).compact.reduce(:+)

        controlled = bubble - contested - uncontrolled
        controlled_cc = controlled.map(&:cc_value).compact.reduce(:+)

        control_systems = Powerbot::Traikoa::ControlSystem.search(
          bubble.map(&:exploitations).flatten.uniq
        )

        powers = Powerbot::Traikoa::API::Power.list.map { |p| p[:name] }

        event.channel.send_embed do |e|
          e.author = { name: 'Bubble Analysis', icon_url: "#{BOT.profile.avatar_url}" }

          e.description = "Overview for **#{sys.name}**\n\n"\
                          "Total: #{total_cc || 0}\n"\
                          "Uncontrolled: #{uncontrolled_cc || 0}\n"\
                          "Controlled: #{controlled_cc || 0}\n"\
                          "Contested: #{contested_cc || 0}"

          control_systems.each do |cs|
            systems = bubble.select { |s| s.exploitations.include? cs.id }
            e.add_field(
              name: "#{cs.name} (#{systems.map(&:cc_value).compact.reduce(:+)}, #{powers[cs.power_id - 1]})",
              value: systems.map do |s|
                       "#{s.name} (#{s.cc_value.nil? ? '?' : s.cc_value})#{s.exploitations.count > 1 ? '*' : '' }"
                     end.join("\n"),
              inline: true
            )
          end unless control_systems.empty?

          e.add_field(
            name: "Contested (#{contested_cc})",
            value: contested.map do |s|
                     "#{s.name} (#{s.cc_value})"
                   end.join("\n")
          ) unless contested.empty?

          e.add_field(
            name: "Uncontrolled (#{uncontrolled_cc})",
            value: uncontrolled.map do |s|
                     "#{s.name} (#{s.cc_value.nil? ? '?' : s.cc_value})"
                   end.join("\n")
          ) unless uncontrolled.empty?

          e.footer = { text: "* - overlapped | served in #{(::Time.now - event.timestamp).round(4)}s" }
        end
      end

      # Registers a discord account for use with the API
      command(:register,
              description: 'Registers your discord account with PAL\'s CMDR network.',
              usage: "#{BOT.prefix}register",
              permission_level: 1) do |event|
        cmdr = Powerbot::Traikoa::Cmdr.load event.user.id
        next '❌ You are already registered.' if cmdr
        Powerbot::Traikoa::Cmdr.new(
          {
            discord_id: event.user.id,
            discord_name: event.user.distinct
          }
        ).register!
        '☑️'
      end

      # Sets the power assigned to the Discord
      command(:set_power, permission_level: 3, help_available: false) do |event, *power|
        power = Powerbot::Traikoa::Power.list.find { |p| p.name == power.join(' ') }
        next 'power not found' unless power
        data = Database::Metadata.create? snowflake: event.server.id
        data.merge({ power_id: power.id })
        '☑️'
      end

      module_function

      def system_embed(sys)
        e = Discordrb::Webhooks::Embed.new(
          title: 'View on EDDB',
          url: sys.eddb_url,
          colour: 0xFCCB0D,
          footer: { text: "id: #{sys.id} x: #{sys.x} y: #{sys.y} z: #{sys.z}" }
        )

        e.add_field(
          name: 'Info',
          value: "Population: #{sys.population}\n"\
                 "Allegiance: #{sys.allegiance}\n"\
                 "Security: #{sys.security}\n"\
                 "Permit locked: #{sys.permit? ? 'Yes' : 'No'}\n"\
                 "CC value: #{sys.cc_value}\n"\
                 "Contested: #{sys.contested? ? 'Yes' : 'No'}\n",
          inline: true
        )

        stations = sys.stations.sort_by { |s| s.distance || 0 }.take(10)

        if sys.stations.any?
          e.add_field(
            name: "Stations (#{stations.count} / #{sys.stations.count})",
            value: stations.map { |s| "[#{s.pad_size}] [#{s.name}](#{s.eddb_url}), #{s.distance.nil? ? '?' : s.distance}ls #{s.planetary? ? '(planetary)' : ''}" }.join("\n"),
            inline: true
          )
        end

        if sys.exploitations.any?
          control_systems = sys.exploitations.map { |id| Powerbot::Traikoa::ControlSystem.load(id) }
          e.add_field(
            name: 'Powerplay',
            value: control_systems.map { |cs| "#{cs.power.name} (#{cs.name})" }.join("\n")
          )
        end

        e
      end
    end
  end
end
