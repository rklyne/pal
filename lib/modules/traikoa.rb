require 'matrix'

module Powerbot
  # Traikoa API
  module Traikoa
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

    # A System in space
    class System
      include Position

      # @return [Integer] system ID
      attr_reader :id

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
        @name = data[:name]
        @x = data[:position][:x]
        @y = data[:position][:y]
        @z = data[:position][:z]
        @population = data[:population]
        @allegiance = data[:allegiance]
        @security = data[:security]
        @needs_permit = data[:needs_permit]
        @stations = data[:stations]
        @cc_value = data[:cc_value]
        @contested = data[:contested]
        @exploitations = data[:exploitations]
        @control_system_id = data[:control_system_id]
      end

      # Load a system from the API
      # @param id [Integer] system ID
      def self.load(id)
        new API::System.get id
      end

      # Loads multiple systems from a search by name
      # @param name [String] name of system
      def self.search(name)
        results = API::System.search name
        results.map { |s| new s }
      end

      # @return [Array<System>] systems within specified radius
      # @param radius [Integer, Float] radius to query
      def bubble(radius = 15)
        results = API::System.bubble id, radius
        results[:systems].map { |s| System.new s }
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

      module System
        NAMESPACE = 'systems'

        module_function

        def get(path = '', params = {})
          API.get "#{NAMESPACE}/#{path}", params
        end

        def resolve_id(id)
          get id
        end

        def search(name)
          get 'search', { name: name }
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
      end

      module Power
        NAMESPACE = 'powers'

        module_function

        def get(path = '', params = {})
          API.get "#{NAMESPACE}/#{path}", params
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

        def resolve_id(id)
          get id
        end
      end
    end
  end
end