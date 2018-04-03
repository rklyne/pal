module Powerbot
  module Database
    # A Discord message
    class Message < Sequel::Model
      # Set timestamp before creation
      def before_create
        super
        self.timestamp = Time.now
      end

      # Log creation
      def after_create
        Discordrb::LOGGER.info "created message: #{inspect}"
      end

      # Fetch message from cache
      def message
        BOT.channel(channel_id).message(message_id)
      end

      # Was a message deleted?
      def deleted?
        message.nil?
      end

      # Store a Discordrb::Message
      def self.store(message)
        create(
         timestamp: message.timestamp,
         server_id: message.channel.server.id,
         server_name: message.channel.server.name,
         channel_id: message.channel.id,
         channel_name: message.channel.name,
         user_id: message.user.id,
         user_name: message.user.distinct,
         message_id: message.id,
         message_content: message.content,
         attachment_url: message.attachments.first&.url
        )
      end

      # Convert a message to TSV
      def to_tsv
        self.to_hash.values.join("\t")
      end

      # Dump all messages to a file
      def self.dump
        servers = all.collect(&:server_id).uniq
        servers.each do |server|
          data = where(server_id: server)
          file = File.open("data/logs/chatlog_#{data.first.server_name}.tsv", 'w')
          data = where(server_id: server).collect do |m|
            "#{m.timestamp}\t"\
            "#{m.server_name}\t"\
            "#{m.channel_name}\t"\
            "#{m.user_name}\t"\
            "#{m.message_content.gsub("\n",'')}\t"\
            "#{m.attachment_url}"
          end.join("\n")
          file.write(data)
          file.close
        end
      end
    end
  end
end
