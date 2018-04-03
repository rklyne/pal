module Powerbot
  module Database
    class Permission < Sequel::Model
      def after_create
        apply!
      end

      def after_update
        apply!
      end

      def apply!
        if level > 0
          BOT.set_user_permission snowflake, level if type == 'user'
          BOT.set_role_permission snowflake, level if type == 'role'
        else
          BOT.ignore_user snowflake if type == 'user'
        end
      end

      def self.apply_all!
        all.map(&:apply!)
      end
    end
  end
end
