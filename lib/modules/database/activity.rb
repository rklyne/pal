module Powerbot
  module Database
    class Activity < Sequel::Model
      one_to_many :participants

      def channel
        BOT.channel channel_id
      end

      def server
        BOT.server server_id
      end

      def role
        return unless role_id
        server.role role_id
      end

      def message
        channel&.message message_id
      end

      # Generates a header string for the Activity
      def header
        <<~STRING
          **#{name}**
          #{description}

          #{role&.mention}
        STRING
      end

      # Generates an embed to send to discord
      def embed
        e = Discordrb::Webhooks::Embed.new(
          color: role.color.combined,
          footer: { text: %Q(activity ID: #{id}) },
          description: <<~TEXT
            **No active participants.**
            Opt-in or out by pressing the #{ACTIVITY_EMOJI} below.
          TEXT
        )

        return e unless participants.any?

        e.description = <<~TEXT
          **#{participants.count} active participants**
          Opt-in or out by pressing the #{ACTIVITY_EMOJI} below.
        TEXT

        participants.each_slice(10) do |parts|
          e.add_field(
            name: %Q(\u200b),
            value: parts.map { |p| p.member.mention }.join(%Q(\n)),
            inline: true
          )
        end

        e
      end

      ACTIVITY_EMOJI = %Q(\u{2611})

      # Hook to create role and message
      def after_create
        m = channel.send_message(header)
        r = server.create_role(name: %Q(activity-#{name}), mentionable: true, packed_permissions: 0)
        update message_id: m.id, role_id: r.id
        m.react ACTIVITY_EMOJI
        update_message
        register_handlers!
      end

      def after_destroy
        message&.delete
        role&.delete
      end

      def update_message
        e = embed
        message.edit(header, e)
      end

      # Registers event handlers on the BOT
      # that affect this model
      def register_handlers!
        # Add a participant
        BOT.reaction_add(emoji: ACTIVITY_EMOJI) do |event|
          next unless event.message.id == message_id
          Participant.find_or_create(discord_id: event.user.id, activity: self)
        end

        # Remove a participant
        BOT.reaction_remove(emoji: ACTIVITY_EMOJI) do |event|
          next unless event.message.id == message_id
          participant = Participant.find(discord_id: event.user.id, activity: self)
          participant&.destroy
        end

        BOT.message_delete(id: message_id) { destroy }
        BOT.channel_delete { |e| destroy if e.id == channel_id }
      end

      # Registers all event handlers currently in the Database
      def self.register_handlers!
        each { |a| a.register_handlers! }
      end
    end

    class Participant < Sequel::Model
      many_to_one :activity

      def member
        BOT.member(activity.server.id, discord_id)
      end

      def after_create
        member.add_role(activity.role)
        Activity[activity.id].update_message
      end

      def after_destroy
        member.remove_role(activity.role)
        Activity[activity.id].update_message
      end
    end
  end
end
