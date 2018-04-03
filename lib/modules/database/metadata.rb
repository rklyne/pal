module Powerbot
  module Database
    class Metadata < Sequel::Model(:metadata)
      def self.from_hash(snowflake, data)
        create snowflake: snowflake, data: data.to_json
      end

      def self.create?(data)
        find_or_create data
      end

      def before_create
        self.data ||= '{}'
      end

      def read
        JSON.parse data
      end

      def self.read(snowflake, create_if_nil = false)
        m = find(snowflake: snowflake)&.read

        if create_if_nil && m.nil?
          create snowflake: snowflake, data: {}.to_json
        else
          m
        end
      end

      def write(hash)
        update data: hash.to_json
      end

      def merge(hash)
        write read.merge(hash)
      end

      def delete(key)
        write read.delete(key)
      end
    end

    Metadata.unrestrict_primary_key
  end
end
