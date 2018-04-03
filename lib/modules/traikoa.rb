require 'matrix'

module Powerbot
  # Traikoa API
  module Traikoa
    EDDB_URL = 'https://eddb.io'.freeze

    # Position in 3D space
    module Position
      attr_reader :x
      attr_reader :y
      attr_reader :z

      def distance(other)
        (vector - other.vector).r
      end

      def vector
        Vector[x, y, z]
      end
    end

    # Station
    class Station
      # @return [Integer] station id
      attr_reader :id

      # @return [Integer] eddb station id
      attr_reader :eddb_id

      # @return [String] station name
      attr_reader :name

      # @return [true, false] whether the station is planetary
      attr_reader :planetary
      alias planetary? planetary

      # @return [String] pad size
      attr_reader :pad_size

      # @return [Integer] station distance from primary star
      attr_reader :distance

      def initialize(data)
        @id = data[:id]

        @eddb_id = data[:eddb_id]

        @name = data[:name]

        @planetary = data[:is_planetary]

        @pad_size = data[:pad_size]

        @distance = data[:distance]
      end

      def eddb_url
        "#{EDDB_URL}/station/#{eddb_id}"
      end
    end

    # A System in space
    class System
      include Position

      # @return [Integer] system ID
      attr_reader :id

      # @return [Integer] eddb system ID
      attr_reader :eddb_id

      # @return [String] name
      attr_reader :name

      # @return [Position] position
      attr_reader :position

      # @return [Integer] population
      attr_reader :population

      # @return [String] allegiance
      attr_reader :allegiance

      # @return [String] security level
      attr_reader :security

      # @return [true, false] whether this system needs a permit
      attr_reader :needs_permit
      alias permit? needs_permit

      # @return [Hash] station metadata
      attr_reader :stations

      # @return [Integer] cc_value
      attr_reader :cc_value

      # @return [true, false] whether this system is contested
      attr_reader :contested
      alias contested? contested

      # @return [Hash] exploitation metadata
      attr_reader :exploitations

      # @return [Integer] id of this system as a control system, if applicable
      attr_reader :control_system_id

      def initialize(data)
        @id = data[:id]
        @eddb_id = data[:eddb_id]
        @name = data[:name]
        @x = data[:position][:x]
        @y = data[:position][:y]
        @z = data[:position][:z]
        @population = data[:population]
        @allegiance = data[:allegiance]
        @security = data[:security]
        @needs_permit = data[:needs_permit]
        @stations = data[:stations].map { |e| Station.new e }
        @cc_value = data[:cc_value]
        @contested = data[:contested]
        @exploitations = data[:exploitations]
        @control_system_id = data[:control_system_id]
      end

      # Load a system from the API
      # @param id [Integer] system ID
      # @return [System]
      def self.load(id)
        new API::System.get id
      end

      # Loads multiple systems from a search by name
      # @param name [String, Array<Integer>] name of system, or array of IDs
      # @return [Array<System>] possible matches
      def self.search(data)
        results = API::System.search data
        results.map { |s| new s }
      end

      # @param radius [Integer, Float] radius to query
      # @return [Array<System>] systems within specified radius
      def bubble(radius = 15)
        results = API::System.bubble id, radius
        results.map { |s| System.new s }
      end

      # @return [true, false] whether this system is exploited
      def exploited?
        @exploitations.any?
      end

      # @return [ControlSystem, nil] the control system bound to this system, if present
      def control_system
        ControlSystem.load control_system_id if control_system_id
      end

      def eddb_url
        "#{EDDB_URL}/system/#{eddb_id}"
      end
    end

    # Power
    class Power
      # @return [Integer] id
      attr_reader :id

      # @return [String] name
      attr_reader :name

      # @return [String] superfaction this power is aligned with
      attr_reader :superfaction

      # @return [Array<Integer>] collection of control system ids this power controls
      attr_reader :control_system_ids

      # @return [Integer] raw cc income
      attr_reader :income

      # @return [Float] cc overhead costs
      attr_reader :overhead

      # @return [Integer] initial cc upkeep
      attr_reader :default_upkeep

      # @return [Integer] predicted cc balance
      attr_reader :predicted

      def initialize(data)
        @id = data[:id]
        @name = data[:name]
        @superfaction = data[:superfaction]
        @control_system_ids = data[:control_systems]
        @income = data[:income]
        @overhead = data[:overhead]
        @default_upkeep = data[:default_upkeep]
        @predicted = data[:predicted]
      end

      # Load a power from the API
      # @param [Integer] id
      def self.load(id)
        new API::Power.get id
      end

      # Get a list of powers
      # @return [Hash] hash structures resembling a Power
      def self.list
        API::Power.list.map { |data| new data }
      end
    end

    class ControlData
      attr_reader :timestamp

      attr_reader :discord_id

      attr_reader :upkeep_default

      attr_reader :upkeep_undermined

      attr_reader :upkeep

      attr_reader :status

      attr_reader :fortification_trigger

      attr_reader :fortification_progress

      attr_reader :undermining_trigger

      attr_reader :undermining_progress

      def initialize(data)
        @timestamp = data[:timestamp]
        @discord_id = data[:discord_id]
        @upkeep_default = data[:upkeep_default]
        @upkeep_undermined = data[:upkeep_undermined]
        @upkeep = data[:upkeep]
        @status = data[:status]
        @fortification_trigger = data[:fortification_trigger]
        @fortification_progress = data[:fortification_progress]
        @undermining_trigger = data[:undermining_trigger]
        @undermining_progress = data[:undermining_progress]
      end
    end

    # A Control System controlled by a Power
    class ControlSystem
      # @return [Integer] control system ID
      attr_reader :id

      # @return [Integer] power id
      attr_reader :power_id

      # @return [Integer] id of this control system's host system
      attr_reader :system_id

      # @return [System] system that hosts this control system
      attr_reader :system

      # @return [ControlData] volatile data related to this control system
      attr_reader :control_data
      alias data control_data

      # @return [Hash] exploitation metadata
      attr_reader :exploitations

      def initialize(data, sys = nil)
        @id = data[:id]
        @power_id = data[:power_id]
        @system_id = data[:system_id]
        @control_data = ControlData.new data[:control_data] if data[:control_data]
        @exploitations = data[:exploitations]

        @system = sys || System.load(@system_id)
        raise 'Tried to attach a control system to a system with mismatched id!' if @system.id != @system_id
      end

      # @return [String] name of the control system
      def name
        @system.name
      end

      # @param [ControlSystem, System] what to measure distance to
      # @return [Float] distance to other system
      def distance(target)
        target = target.system if target.is_a? ControlSystem
        @system.distance target
      end

      # Load a control system from the API
      # @param [Integer] ID of the control system
      # @return [ControlSystem]
      def self.load(id)
        new API::ControlSystem.resolve_id id
      end

      # Load multiple control systems from an array of IDs
      # @param [Array<Integer>] IDs of control systems
      # @return [Array<ControlSystem>]
      def self.search(ids)
        results = API::ControlSystem.search ids
        results.map { |cs| ControlSystem.new cs }
      end

      # Load the power associated with this ControlSystem
      def power
        @power ||= Power.load(power_id)
      end
    end

    # Cmdr
    class Cmdr
      # @return [Integer] discord id
      attr_reader :discord_id

      # @return [String] discord name
      attr_reader :discord_name

      # @return [Integer] system id of where this cmdr is located, if known
      attr_reader :system_id

      # @return [Integer] ID of power this cmdr is pledged to, if known
      attr_reader :power_id

      def initialize(data)
        @discord_id = data[:discord_id]
        @discord_name = data[:discord_name]
        @system_id = data[:system_id]
        @power_id = data[:power_id]
      end

      # Load a Cmdr from the API
      # @param discord_id [Integer] discord_id of the cmdr
      # @return [Cmdr]
      def self.load(discord_id)
        data = API::Cmdr.get discord_id
        new(data) if data
      end

      # Register (create) a new Cmdr
      # in the API with this Cmdr's data
      def register!
        API::Cmdr.post(
          @discord_id,
          @discord_name,
          @system_id,
          @power_id
        )
      end
    end

    # REST
    module API
      API_URL = CONFIG.api_url
      API_VERSION = 'v1'

      module_function

      # Generic GET request
      def get(path = '', params = {})
        response = RestClient.get "#{API_URL}/#{API_VERSION}/#{path}", params: params
        JSON.parse response, symbolize_names: true
      end

      # Generic POST request
      def post(path = '', payload = {})
        response = RestClient.post "#{API_URL}/#{API_VERSION}/#{path}", payload.to_json, { content_type: :json }
        JSON.parse response
      end

      # Generic PATCH request
      def patch(path = '', payload = {})
        response = RestClient.patch "#{API_URL}/#{API_VERSION}/#{path}", payload.to_json, { content_type: :json }
        JSON.parse response
      end

      module System
        NAMESPACE = 'systems'

        module_function

        def get(path = '', params = {})
          API.get "#{NAMESPACE}/#{path}", params
        end

        def resolve_id(id)
          get id
        end

        def search(data)
          if data.is_a? String
            data = URI.encode data
            return get "search?name=#{data}"
          end

          if data.is_a? Array
            return get 'search', ids: data
          end
        end

        def bubble(id, radius)
          get 'bubble', { id: id, radius: radius }
        end
      end

      module ControlSystem
        NAMESPACE = 'control_systems'

        module_function

        def get(path = '', params = {})
          API.get "#{NAMESPACE}/#{path}", params
        end

        def resolve_id(id)
          get id
        end

        def search(ids)
          get 'search', ids: ids
        end

        def post_data(id, discord_id, fortification_progress: nil, fortification_trigger: nil, undermining_progress: nil, undermining_trigger: nil, upkeep_default: nil, upkeep_undermined: nil)
          API.post(
            "#{NAMESPACE}/#{id}/control_data",
            {
              fortification_progress: fortification_progress,
              fortification_trigger: fortification_trigger,
              undermining_progress: undermining_progress,
              undermining_trigger: undermining_trigger,
              upkeep_default: upkeep_default,
              upkeep_undermined: upkeep_undermined
            }.compact
          )
        end
      end

      module Power
        NAMESPACE = 'powers'

        module_function

        def get(path = '', params = {})
          API.get "#{NAMESPACE}/#{path}", params
        end

        def list
          get
        end

        def resolve_id(id)
          get id
        end
      end

      module Cmdr
        NAMESPACE = 'cmdrs'

        module_function

        def get(path = '', params = {})
          API.get "#{NAMESPACE}/#{path}", params
        end

        def post(discord_id, discord_name, system_id = nil, power_id = nil)
          API.post(
            "#{NAMESPACE}",
            {
              discord_id: discord_id,
              discord_name: discord_name,
              system_id: system_id,
              power_id: power_id
            }
          )
        end

        def patch(discord_id, discord_name: nil, system_id: nil, power_id: nil)
          API.patch(
            "#{NAMESPACE}/#{discord_id}",
            {
              discord_name: discord_name,
              system_id: system_id,
              power_id: power_id
            }.compact
          )
        end

        def resolve_id(id)
          get id
        end
      end
    end
  end
end
