module Powerbot
  module DiscordCommands
    # Die rolling features
    module Roll
      extend Discordrb::Commands::CommandContainer

      # A Die
      class Die
        attr_reader :sides

        attr_reader :value

        def initialize(sides = 6)
          @sides = sides
          @value = roll
        end

        def roll
          rand 1..@sides
        end

        private :roll

        def to_s
          "`#{@value}`"
        end
      end

      # A collection of dice
      class DiceSet
        attr_reader :dice

        attr_reader :sum

        def initialize(number = 1, sides = 6)
          @dice = Array.new(number) { Die.new(sides) }
          @sum  = roll
        end

        def roll
          @dice.map(&:value).reduce(:+)
        end

        def to_s(seperator = ' ')
          values = @dice.map(&:value).join seperator
          "`#{values} = #{@sum}`"
        end
      end

      ERROR = '( ͠° ͟ʖ ͡°)'.freeze

      command(:roll,
              description: 'rolls a die, or many dice DnD style',
              usage: 'roll (number) or NdS') do |_event, args|
        next Die.new.to_s unless args
        args = args.split('d').map(&:to_i)
        next ERROR if args.any? { |a| !a.between? 1, 100 }
        next Die.new(args.first).to_s if args.count == 1
        next DiceSet.new(args.first, args.last).to_s(' + ') if args.count == 2
        ERROR
      end
    end
  end
end
