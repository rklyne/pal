module Powerbot
  module DiscordCommands
    module Activity
      extend Discordrb::Commands::CommandContainer

      def self.parse(str)
        args = str.split(%(|)).map(&:strip)
        { name: args[0], description: args[1] }
      end

      def self.existing_activity(name, server_id)
        Database::Activity.where(server_id: server_id).where(Sequel.ilike(:name, name)).first
      end

      command(:create_activity, permission_level: 3) do |event|
        args = parse event.message.content[20..-1]
        args.merge!({ channel_id: event.channel.id, server_id: event.server.id })

        next %(**Activity already exists with this name!**) if existing_activity(args[:name], event.server.id)

        Database::Activity.create(args)
        event.message.delete
      end
    end
  end
end
