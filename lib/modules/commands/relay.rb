module Powerbot
  module DiscordCommands
    module Relay
      extend Discordrb::Commands::CommandContainer
      # Create a new relay
      command(:create_relay, permission_level: 4, help_available: false) do |event, name, key|
        next 'you must supply a name' unless name
        next 'you must supply a key' unless key

        Database::Relay.create(
          name: name,
          key: key
        )

        "created relay: `#{name}`"
      end

      # Designate a channel as a relay
      command(:set_relay, permission_level: 3, help_available: false) do |event, name|
        relay = Database::Relay.find name: name
        next 'relay not found' unless relay

        next 'this channel is already subscribed to that relay' if relay.relay_targets.map(&:channel_id).include? event.channel.id

        relay.add_relay_target channel_id: event.channel.id
        "subscribed to relay: `#{name}`"
      end

      # Sets a relay's carrier message
      command(:set_carrier, permission_level: 3, help_available: false) do |event, name, *text|
        relay = Database::Relay.find name: name
        next 'relay not found' unless relay

        target = Database::RelayTarget.find(relay: relay, channel_id: event.channel.id)
        next 'relay target not found' unless target

        text = text.join(' ')
        target.update(carrier: text)
        "updated carrier text for relay: `#{relay.name}`"
      end

      # Remove a relay bound to the current channel
      command(:remove_relay, permission_level: 3, help_available: false) do |event, name|
        relay = Database::Relay.find name: name
        next 'relay not found' unless relay

        target =Database::RelayTarget.find(relay: relay, channel_id: event.channel.id)
        next 'relay target not found' unless target

        target.destroy
        "removed from relay: `#{name}`"
      end

      # Delete a relay
      command(:delete_relay, permission_level: 4, help_available: false) do |event, name|
        relay = Database::Relay.find name: name
        next 'relay not found' unless relay

        relay.destroy
        "destroyed relay: `#{name}`"
      end

      # Inspect relays in the active channel
      command(:relays, description: 'displays relays linked to this channel') do |event|
        relays = Database::RelayTarget.where(channel_id: event.channel.id).all
        next 'channel is not linked to any relays' unless relays.any?

        relays.map!(&:relay)

        event.channel.send_embed do |e|
          e.title = 'Relays'

          relays.each do |r|
            e.add_field(
              name: r.name,
              value: "**relay key:** #{r.key}\n" + r.relay_targets.map { |t| "#{t.channel.name} (#{t.channel.server.name})" }.join("\n")
            )
          end
        end
      end
    end
  end
end
