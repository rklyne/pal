require 'redis'
require 'csv'

module Powerbot
  module DiscordEvents
    module Stats
      extend Discordrb::EventContainer
      extend self

      # Buffer stats for 30 days.
      STATS_TTL = 60 * 60 * 24 * 30

      REDIS = Redis.new

      def count(object, id)
        time = ::Time.now.strftime('%F %H00')
        key = "powerbot:stats:#{object}:#{time}"
        REDIS.hincrby(key, id, 1)
        REDIS.expire(key, STATS_TTL)
      end

      def all_stats
        results = {}

        keys = REDIS.scan_each(match: 'powerbot:stats:*').to_a
        keys.each do |key|
          object, date = key.split(':')[2..-1]
          values = REDIS.hgetall(key)

          results[date] ||= {}

          values.each do |id, value|
            # Discordrb::LOGGER.info "REDIS resolving #{object} #{id}"
            resolved = case object
                       when 'channel'
                         BOT.channel(id)
                       when 'user'
                         BOT.user(id)
                       when 'guild', 'member_leave', 'member_join'
                         BOT.server(id)
                       end

            name = case object
                   when 'user'
                     resolved&.distinct
                   else
                     resolved&.name
                   end

            result = { name: name, value: value.to_i }
            result[:guild] = resolved&.server&.name if object == 'channel'

            (results[date][object] ||= []) << result
          end
        end

        results
      end

      # Credit for this dank code to my man Unleashy#9254! :D
      # He's dope and I really didn't want to write this.
      # @param [Hash] data
      def stats_to_csv(data)
        out_data = {
          member_join: Hash.new { |h, k| h[k] = [] },
          member_leave: Hash.new { |h, k| h[k] = [] },
          guild: Hash.new { |h, k| h[k] = [] },
          channel: Hash.new { |h, k| h[k] = [] },
          user: Hash.new { |h, k| h[k] = [] }
        }

        data.each do |time, props|
          props.each do |k, v|
            v.each { |p| out_data[k.to_sym][time] << p }
          end
        end

        CSV.generate(encoding: Encoding.find('UTF-8')) do |csv|
          first = true
          out_data.each do |type, vals|
            unless vals.empty?
              csv << [] unless first
              csv << [type] << ['timestamp', vals.values[0][0].keys].flatten!

              vals.each do |time, props|
                props.each { |prop| csv << [time, prop.values].flatten! }
              end
            end

            first = false
          end
        end
      end

      message do |event|
        next unless CONFIG.tracked_guilds.include?(event.channel.server&.id)
        next if event.message.webhook?

        count(:channel, event.channel.id)
        count(:user, event.user.id)
        count(:guild, event.server.id)
      end

      member_join do |event|
        next unless CONFIG.tracked_guilds.include?(event.server.id)

        count(:member_join, event.server.id)
      end

      member_leave do |event|
        next unless CONFIG.tracked_guilds.include?(event.server.id)

        count(:member_leave, event.server.id)
      end
    end
  end
end
